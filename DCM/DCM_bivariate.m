%% Part 1: Estimation and Validation of the DCM (the dynamic coregionalization model)

clc;                
clearvars;          
warning off;        

%% Data Loading
addpath('../D-STEAM_v2\Src\'); % Add path to D-STEAM source files
load('../data_inputs_for_matlab/daily_data.mat'); % Load daily data


% Extract data from daily_data
Y_pickups = daily_data.bs_data.pickups;       % Daily pickup counts
Y_duration = daily_data.bs_data.duration;     % Daily average trip duration
weather_data = daily_data.weather_data;       % Weather data
temp_data = weather_data.temp;                % Temperature data
non_working_days = daily_data.non_working_days; % Non-working days
weekend = daily_data.weekend;                 % Weekend days
holidays = daily_data.holidays;               % Holidays
datetime_calendar = daily_data.datetime_calendar; % Daily calendar
id_stations = daily_data.id_stations;         % Station IDs

%% Data Preparation for the DCM Model

% Number of stations and days
n_stations = length(id_stations); % Total number of stations
n_days = length(datetime_calendar); % Total number of days

% Build dependent variables (Y)
data.Y{1} = Y_pickups;       % Pickup counts
data.Y_name{1} = 'Pickups';  % Name for pickup variable
data.Y{2} = Y_duration;      % Trip duration
data.Y_name{2} = 'Duration'; % Name for duration variable




% Build covariates (X_beta)
X = ones(n_stations, 12, n_days); % Initialize covariate matrix (12 covariates)

% Add weather-related covariates
X(:, 2, :) = repmat(weather_data.temp, n_stations, 1);         % Temperature
X(:, 3, :) = repmat(weather_data.feelslike, n_stations, 1);     % Feels-like temperature
X(:, 4, :) = repmat(weather_data.precip, n_stations, 1);       % Precipitation
X(:, 5, :) = repmat(weather_data.windspeed, n_stations, 1);    % Wind speed
X(:, 6, :) = repmat(weather_data.cloudcover, n_stations, 1);   % Cloud cover
X(:, 7, :) = repmat(weather_data.visibility, n_stations, 1);   % Visibility
X(:, 8, :) = repmat(weather_data.uvindex, n_stations, 1);      % UV index
X(:, 9, :) = repmat(non_working_days, n_stations, 1);          % Non-working days
X(:, 10, :) = repmat(weekend, n_stations, 1);                  % Weekend
X(:, 11, :) = repmat(holidays, n_stations, 1);                 % Holidays
X(:, 12, :) = repmat(weather_data.humidity, n_stations, 1);    % Humidity

% Assign covariates to the model
data.X_beta{1} = X; % Covariates for pickups
data.X_beta_name{1} = {'Constant', 'Temp', 'FeelsLike', 'Precip', 'Windspeed', ...
                       'CloudCover', 'Visibility', 'UVIndex', 'NonWorkingDays', ...
                       'Weekend', 'Holidays', 'Humidity'}; % Covariate names
data.X_beta{2} = X; % Covariates for duration
data.X_beta_name{2} = data.X_beta_name{1}; % Same covariate names for duration

% Additional covariates (X_z and X_p)
data.X_z{1} = ones(n_stations, 1); % Constant term for pickups
data.X_z_name{1} = {'Constant'};   % Name for X_z
data.X_z{2} = ones(n_stations, 1); % Constant term for duration
data.X_z_name{2} = {'Constant'};   % Name for X_z

data.X_p{1} = ones(n_stations, 1); % Constant term for pickups
data.X_p_name{1} = {'Constant'};   % Name for X_p
data.X_p{2} = ones(n_stations, 1); % Constant term for duration
data.X_p_name{2} = {'Constant'};   % Name for X_p

%% DCM Model Configuration

% Create stem_varset object for the model
obj_stem_varset_p = stem_varset(data.Y, data.Y_name, [], [], ...
                                data.X_beta, data.X_beta_name, ...
                                data.X_z, data.X_z_name, ...
                                data.X_p, data.X_p_name);

% Create stem_gridlist object
obj_stem_gridlist_p = stem_gridlist();

% Spatial grids
lat = daily_data.lat'; % Latitude (transpose to column vector)
lon = daily_data.lon'; % Longitude (transpose to column vector)
coordinates = [lat, lon]; % Combine lat and lon into Nx2 matrix

% Verify dimensions
disp(size(coordinates)); % Should be Nx2
% Check the source of your coordinates
disp(size(daily_data.lat));  % Should be 100×1
disp(size(daily_data.lon));  % Should be 100×1

% Assign coordinates to ground.coordinates
ground.coordinates{1} = coordinates; % Coordinates for pickups
ground.coordinates{2} = coordinates; % Coordinates for duration

% Create spatial grids
obj_stem_grid1 = stem_grid(ground.coordinates{1}, 'deg', 'sparse', 'point'); % Grid for pickups
obj_stem_grid2 = stem_grid(ground.coordinates{2}, 'deg', 'sparse', 'point'); % Grid for duration

% Add grids to gridlist
obj_stem_gridlist_p.add(obj_stem_grid1); % Add pickup grid
obj_stem_gridlist_p.add(obj_stem_grid2); % Add duration grid

% Timestamp for the data
obj_stem_datestamp = stem_datestamp('01-01-2023 00:00', '31-12-2023 00:00', n_days);

% Cross-validation setup
S_val = [4, 42, 50, 32, 38, 30, 25, 49, 31, 33, 28, 43, 46, 51, 26]; % Validation station indices
obj_stem_validation = stem_validation({'Pickups', 'Duration'}, {S_val, S_val}, 0, {'point', 'point'});

% Model type
obj_stem_modeltype = stem_modeltype('DCM'); % Dynamic Core Model

% Create stem_data object
obj_stem_data = stem_data(obj_stem_varset_p, obj_stem_gridlist_p, ...
                          [], [], obj_stem_datestamp, obj_stem_validation, obj_stem_modeltype, []);

% Parameter constraints
obj_stem_par_constraints = stem_par_constraints();
obj_stem_par_constraints.time_diagonal = 1; % Diagonal time constraints

% Initialize model parameters
obj_stem_par = stem_par(obj_stem_data, 'exponential', obj_stem_par_constraints);
obj_stem_par.v_p = [1, 0.6; 0.6, 1]; % Covariance matrix
obj_stem_par.theta_p = 0.06;         % Scale parameter
obj_stem_par.sigma_eta = diag([0.2, 0.2]); % Process variance
obj_stem_par.G = diag([0.8, 0.8]);   % Transition matrix
obj_stem_par.sigma_eps = diag([0.3, 0.3]); % Error variance

% Create the model
bivariate_model = stem_model(obj_stem_data, obj_stem_par);

%% Model Estimation

bivariate_model.stem_data.log_transform; % Log-transform the data
bivariate_model.stem_data.standardize;   % Standardize the data

% Set initial parameter values
bivariate_model.set_initial_values(obj_stem_par);

% EM algorithm options
obj_stem_EM_options = stem_EM_options();
obj_stem_EM_options.max_iterations = 300; % Maximum iterations
obj_stem_EM_options.exit_tol_par = 0.001; % Convergence tolerance

% Estimate the model using EM algorithm
bivariate_model.EM_estimate(obj_stem_EM_options);

%% Model Validation

% Compute performance metrics
bivariate_model.set_varcov; % Set variance-covariance
bivariate_model.set_logL;   % Set log-likelihood

% Validation results
RMSE_pickups = sqrt(mean(bivariate_model.stem_validation_result{1, 1}.cv_mse_s)); % RMSE for pickups
RMSE_duration = sqrt(mean(bivariate_model.stem_validation_result{1, 2}.cv_mse_s)); % RMSE for duration

% Print results
fprintf('RMSE Pickups: %.2f\n', RMSE_pickups);
fprintf('RMSE Duration: %.2f\n', RMSE_duration);

%% Save Results
save('bivariate_model_results.mat', 'bivariate_model'); 