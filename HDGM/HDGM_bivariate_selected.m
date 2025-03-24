%% HDGM Model for Pickups and Duration (Selected Covariates)
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
weekend = daily_data.weekend;                 % Weekend days
datetime_calendar = daily_data.datetime_calendar; % Daily calendar
id_stations = daily_data.id_stations;         % Station IDs

%% Data Preparation for the HDGM Model

% Number of stations and days
n_stations = length(id_stations); % Total number of stations
n_days = length(datetime_calendar); % Total number of days

% Build dependent variables (Y)
data.Y{1} = Y_pickups;       % Pickup counts
data.Y_name{1} = 'Pickups';  % Name for pickup variable
data.Y{2} = Y_duration;      % Trip duration
data.Y_name{2} = 'Duration'; % Name for duration variable

% Build covariates (X_beta) - SELECTED COVARIATES ONLY
X = ones(n_stations, 6, n_days); % Initialize covariate matrix (6 covariates: constant + 5 selected)

% Add selected covariates
X(:, 2, :) = repmat(weather_data.temp, n_stations, 1);         % Temperature
X(:, 3, :) = repmat(weather_data.precip, n_stations, 1);       % Precipitation
X(:, 4, :) = repmat(weather_data.visibility, n_stations, 1);   % Visibility
X(:, 5, :) = repmat(weather_data.uvindex, n_stations, 1);      % UV index
X(:, 6, :) = repmat(weekend, n_stations, 1);                   % Weekend

% Assign covariates to the model
data.X_beta{1} = X; % Covariates for pickups
data.X_beta_name{1} = {'Constant', 'Temp', 'Precip', 'Visibility', 'UVIndex', 'Weekend'}; 
data.X_beta{2} = X; % Covariates for duration
data.X_beta_name{2} = data.X_beta_name{1}; % Same covariate names for duration

% Additional covariates (X_z)
data.X_z{1} = ones(n_stations, 1); % Constant term for pickups
data.X_z_name{1} = {'Constant'};   % Name for X_z
data.X_z{2} = ones(n_stations, 1); % Constant term for duration
data.X_z_name{2} = {'Constant'};   % Name for X_z

% Create stem_varset object
obj_stem_varset_p = stem_varset(data.Y, data.Y_name, [], [], ...
                                data.X_beta, data.X_beta_name, ...
                                data.X_z, data.X_z_name);

% Create stem_gridlist object
obj_stem_gridlist_p = stem_gridlist();

% Spatial grids
lat = daily_data.lat'; % Latitude (transpose to column vector)
lon = daily_data.lon'; % Longitude (transpose to column vector)
coordinates = [lat, lon]; % Combine lat and lon into Nx2 matrix

% Create spatial grids
obj_stem_grid1 = stem_grid(coordinates, 'deg', 'sparse', 'point'); % Grid for pickups
obj_stem_grid2 = stem_grid(coordinates, 'deg', 'sparse', 'point'); % Grid for duration

% Add grids to gridlist
obj_stem_gridlist_p.add(obj_stem_grid1); % Add pickup grid
obj_stem_gridlist_p.add(obj_stem_grid2); % Add duration grid

% Timestamp for the data
obj_stem_datestamp = stem_datestamp('01-01-2023 00:00', '31-12-2023 00:00', n_days);

% Cross-validation setup
S_val = [4, 42, 50, 32, 38, 30, 25, 49, 31, 33, 28, 43, 46, 51, 26]; % Validation station indices
obj_stem_validation = stem_validation({'Pickups', 'Duration'}, {S_val, S_val}, 0, {'point', 'point'});

% Model type
obj_stem_modeltype = stem_modeltype('HDGM'); % Hierarchical Dynamic Generalized Model

% Create stem_data object
obj_stem_data = stem_data(obj_stem_varset_p, obj_stem_gridlist_p, ...
                          [], [], obj_stem_datestamp, obj_stem_validation, obj_stem_modeltype, []);

% Parameter constraints
obj_stem_par_constraints = stem_par_constraints();
obj_stem_par_constraints.time_diagonal = 0; % No diagonal time constraints

% Initialize model parameters
obj_stem_par = stem_par(obj_stem_data, 'exponential', obj_stem_par_constraints);

% Create the model
hdgm_selected_model = stem_model(obj_stem_data, obj_stem_par);

% Set initial parameter values
obj_stem_par.beta = hdgm_selected_model.get_beta0(); % Initial beta values
obj_stem_par.theta_z = 10; % Spatial scale parameter
obj_stem_par.v_z = [1, 0.6; 0.6, 1]; % Spatial covariance matrix
obj_stem_par.sigma_eta = diag([0.2, 0.2]); % Process variance
obj_stem_par.G = diag([0.8, 0.8]); % Transition matrix
obj_stem_par.sigma_eps = diag([0.3, 0.3]); % Error variance

% Set initial values
hdgm_selected_model.set_initial_values(obj_stem_par);

%% Model Estimation

% Data transform
hdgm_selected_model.stem_data.log_transform; % Log-transform the data
hdgm_selected_model.stem_data.standardize;   % Standardize the data

% EM algorithm options
obj_stem_EM_options = stem_EM_options();
obj_stem_EM_options.max_iterations = 200; % Maximum iterations
obj_stem_EM_options.exit_tol_par = 0.001; % Convergence tolerance

% Estimate the model using EM algorithm
hdgm_selected_model.EM_estimate(obj_stem_EM_options);

%% Model Validation

% Compute performance metrics
hdgm_selected_model.set_varcov; % Set variance-covariance
hdgm_selected_model.set_logL;   % Set log-likelihood

% Validation results
RMSE_pickups = sqrt(mean(hdgm_selected_model.stem_validation_result{1, 1}.cv_mse_s)); % RMSE for pickups
RMSE_duration = sqrt(mean(hdgm_selected_model.stem_validation_result{1, 2}.cv_mse_s)); % RMSE for duration

% Print results
fprintf('RMSE Pickups: %.2f\n', RMSE_pickups);
fprintf('RMSE Duration: %.2f\n', RMSE_duration);

%% Save Results
save('hdgm_selected_model_results.mat', 'hdgm_selected_model'); 

%% Save results to text file
fileID = fopen('hdgm_selected_model_results.txt', 'w');

% Write header
fprintf(fileID, 'HDGM MODEL RESULTS (SELECTED COVARIATES)\n');
fprintf(fileID, '=======================================\n\n');
fprintf(fileID, 'Selected covariates: Temperature, Precipitation, Visibility, UV index, Weekend\n\n');

% Write beta coefficients
beta = hdgm_selected_model.stem_par.beta;
num_covariates = length(data.X_beta_name{1});

% Pickups coefficients
fprintf(fileID, 'BETA COEFFICIENTS FOR PICKUPS:\n');
fprintf(fileID, '-------------------------------\n');
for i = 1:num_covariates
    fprintf(fileID, '%-12s: %8.4f\n', data.X_beta_name{1}{i}, beta(i));
end
fprintf(fileID, '\n');

% Duration coefficients
fprintf(fileID, 'BETA COEFFICIENTS FOR DURATION:\n');
fprintf(fileID, '--------------------------------\n');
for i = 1:num_covariates
    fprintf(fileID, '%-12s: %8.4f\n', data.X_beta_name{2}{i}, beta(num_covariates+i));
end
fprintf(fileID, '\n');

% Performance metrics
fprintf(fileID, 'MODEL PERFORMANCE:\n');
fprintf(fileID, '-----------------\n');
fprintf(fileID, 'RMSE Pickups : %8.4f\n', RMSE_pickups);
fprintf(fileID, 'RMSE Duration: %8.4f\n', RMSE_duration);
fprintf(fileID, 'Log-Likelihood: %8.4f\n\n', hdgm_selected_model.stem_EM_result.logL);

% Covariance parameters
fprintf(fileID, 'COVARIANCE PARAMETERS:\n');
fprintf(fileID, '----------------------\n');
fprintf(fileID, 'Spatial cross-covariance (v_z):\n');
fprintf(fileID, '%8.4f %8.4f\n', hdgm_selected_model.stem_par.v_z(1,:));
fprintf(fileID, '%8.4f %8.4f\n\n', hdgm_selected_model.stem_par.v_z(2,:));

fprintf(fileID, 'Spatial range (theta_z): %8.4f\n', hdgm_selected_model.stem_par.theta_z);
fprintf(fileID, 'Process variance (sigma_eta):\n');
fprintf(fileID, '%8.4f %8.4f\n', hdgm_selected_model.stem_par.sigma_eta(1,:));
fprintf(fileID, '%8.4f %8.4f\n\n', hdgm_selected_model.stem_par.sigma_eta(2,:));

fclose(fileID);
disp('Results saved to hdgm_selected_model_results.txt');