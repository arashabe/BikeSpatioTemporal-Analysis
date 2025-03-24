%% Part 1: Estimation and validation of the DCM (Univariate model for Duration)

clc;
clearvars;
warning off;

%% Data loading
addpath('../D-STEAM_v2\Src\'); % Add path to D-STEAM source files
load('../data_inputs_for_matlab/daily_data.mat'); % Load daily data

%% Extract data
data.Y{1} = daily_data.bs_data.duration;  % Duration
data.Y_name{1} = 'Duration';

%% Number of stations and days
n_stations = length(daily_data.id_stations);  % Number of stations
d = length(daily_data.datetime_calendar);  % Number of days

%% Selected covariates
p = 6;  % Number of covariates

% Construct X (covariates)
X = ones(n_stations, p, d);  % Constant covariate
X(:, 2, :) = repmat(daily_data.weather_data.temp, n_stations, 1);  % Temperature
X(:, 3, :) = repmat(daily_data.weather_data.precip, n_stations, 1);  % Precipitation
X(:, 4, :) = repmat(daily_data.weather_data.visibility, n_stations, 1);  % Visibility
X(:, 5, :) = repmat(daily_data.weather_data.uvindex, n_stations, 1);  % UV index
X(:, 6, :) = repmat(daily_data.weekend, n_stations, 1);  % Weekend

%% Assign covariates to the model
data.X_beta{1} = X;
data.X_beta_name{1} = {'Constant', 'Temp', 'Precip', 'Visibility', 'UVIndex', 'Weekend'};

%% Additional covariates (X_z and X_p)
data.X_z{1} = ones(n_stations, 1);  % Constant
data.X_z_name{1} = {'Constant'};

data.X_p{1} = X(:, 1, 1);  % Constant
data.X_p_name{1} = {'Constant'};

%% Create stem_varset object
obj_stem_varset_p = stem_varset(data.Y, data.Y_name, [], [], ...
                                data.X_beta, data.X_beta_name, ...
                                data.X_z, data.X_z_name, ...
                                data.X_p, data.X_p_name);

% Create stem_gridlist object
obj_stem_gridlist_p = stem_gridlist();

lat = daily_data.lat'; % Latitude (transpose to column vector)
lon = daily_data.lon'; % Longitude (transpose to column vector)
coordinates = [lat, lon]; % Combine lat and lon into Nx2 matrix

ground.coordinates{1} = coordinates;

obj_stem_grid = stem_grid(ground.coordinates{1}, 'deg', 'sparse', 'point');
obj_stem_gridlist_p.add(obj_stem_grid);

%% Timestamp
obj_stem_datestamp = stem_datestamp('01-01-2023 00:00', '31-12-2023 00:00', d);

%% Cross-validation
S_val = [4, 42, 50, 32, 38, 30, 25, 49, 31, 33, 28, 43, 46, 51, 26];  % Validation stations
obj_stem_validation = stem_validation({'Duration'}, {S_val}, 0, {'point'});

%% Model type
obj_stem_modeltype = stem_modeltype('DCM');

% Create stem_data object
obj_stem_data = stem_data(obj_stem_varset_p, obj_stem_gridlist_p, ...
                          [], [], obj_stem_datestamp, obj_stem_validation, obj_stem_modeltype, []);

%% Parameter constraints
obj_stem_par_constraints = stem_par_constraints();

%% Initialize parameters
obj_stem_par = stem_par(obj_stem_data, 'exponential', obj_stem_par_constraints);
obj_stem_par.v_p = 1;  % Variance of the spatial process
obj_stem_par.theta_p = 0.01;  % Scale parameter
obj_stem_par.sigma_eta = diag([0.02]);  % Variance of the temporal process
obj_stem_par.G = diag([0.9]);  % Transition matrix
obj_stem_par.sigma_eps = 0.3;  % Variance of the measurement error

%% Create the model
duration_selected_model = stem_model(obj_stem_data, obj_stem_par);

%% Data transform
duration_selected_model.stem_data.log_transform;
duration_selected_model.stem_data.standardize;

%% Set initial values
duration_selected_model.set_initial_values(obj_stem_par);

%% EM algorithm options
obj_stem_EM_options = stem_EM_options();
obj_stem_EM_options.max_iterations = 200;
obj_stem_EM_options.exit_tol_par = 0.0001;

%% Model estimation
duration_selected_model.EM_estimate(obj_stem_EM_options);

%% Model validation
duration_selected_model.set_varcov;
duration_selected_model.set_logL;

%% Save results
save('duration_selected_model_results.mat', 'duration_selected_model');