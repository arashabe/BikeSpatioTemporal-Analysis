clc;
clearvars;
warning off;

%% Data loading
addpath('../D-STEAM_v2\Src\');
load('../data_inputs_for_matlab/daily_data.mat');

%% Extract data
data.Y{1} = daily_data.bs_data.pickups;  % Pickups
data.Y_name{1} = 'Pickups';
data.Y{2} = daily_data.bs_data.duration;  % Duration
data.Y_name{2} = 'Duration';

%% Number of stations and days
n_stations = length(daily_data.id_stations);  % Number of stations
d = length(daily_data.datetime_calendar);  % Number of days

%% Selected covariates
c1 = 6;  % Number of covariates for Pickups
c2 = 6;  % Number of covariates for Duration

%% Construct X
X1 = ones(n_stations, c1, d);  % Constant covariate
X1(:, 2, :) = repmat(daily_data.weather_data.temp, n_stations, 1);  % Temperature
X1(:, 3, :) = repmat(daily_data.weather_data.precip, n_stations, 1);  % Precipitation
X1(:, 4, :) = repmat(daily_data.weather_data.visibility, n_stations, 1);  % Visibility
X1(:, 5, :) = repmat(daily_data.weather_data.uvindex, n_stations, 1);  % UV index
X1(:, 6, :) = repmat(daily_data.weekend, n_stations, 1);  % Weekend

data.X_beta{1} = X1;
data.X_beta_name{1} = {'Constant', 'Temp', 'Precip', 'Visibility', 'UVIndex', 'Weekend'};

X2 = ones(n_stations, c2, d);  % Constant covariate
X2(:, 2, :) = repmat(daily_data.weather_data.temp, n_stations, 1);  % Temperature
X2(:, 3, :) = repmat(daily_data.weather_data.precip, n_stations, 1);  % Precipitation
X2(:, 4, :) = repmat(daily_data.weather_data.visibility, n_stations, 1);  % Visibility
X2(:, 5, :) = repmat(daily_data.weather_data.uvindex, n_stations, 1);  % UV index
X2(:, 6, :) = repmat(daily_data.weekend, n_stations, 1);  % Weekend

data.X_beta{2} = X2;
data.X_beta_name{2} = {'Constant', 'Temp', 'Precip', 'Visibility', 'UVIndex', 'Weekend'};

%% Additional covariates (X_z and X_p)
data.X_z{1} = ones(n_stations, 1);  % Constant
data.X_z_name{1} = {'Constant'};

data.X_z{2} = ones(n_stations, 1);  % Constant
data.X_z_name{2} = {'Constant'};

data.X_p{1} = ones(n_stations, 1);  % Constant
data.X_p_name{1} = {'Constant'};

data.X_p{2} = ones(n_stations, 1);  % Constant
data.X_p_name{2} = {'Constant'};

%% Create stem_varset object
obj_stem_varset_p = stem_varset(data.Y, data.Y_name, [], [], ...
                                data.X_beta, data.X_beta_name, ...
                                data.X_z, data.X_z_name, ...
                                data.X_p, data.X_p_name);

%% Create stem_gridlist object
obj_stem_gridlist_p = stem_gridlist();

% Spatial grids
lat = daily_data.lat'; % Latitude (transpose to column vector)
lon = daily_data.lon'; % Longitude (transpose to column vector)
coordinates = [lat, lon]; % Combine lat and lon into Nx2 matrix

% Assign coordinates to ground.coordinates
ground.coordinates{1} = coordinates; % Coordinates for pickups
ground.coordinates{2} = coordinates; % Coordinates for duration

obj_stem_grid1 = stem_grid(ground.coordinates{1}, 'deg', 'sparse', 'point');
obj_stem_grid2 = stem_grid(ground.coordinates{2}, 'deg', 'sparse', 'point');
obj_stem_gridlist_p.add(obj_stem_grid1);
obj_stem_gridlist_p.add(obj_stem_grid2);

%% Timestamp
obj_stem_datestamp = stem_datestamp('01-01-2023 00:00', '31-12-2023 00:00', d);

%% Cross-validation
S_val = [4, 42, 50, 32, 38, 30, 25, 49, 31, 33, 28, 43, 46, 51, 26];  % Validation stations
obj_stem_validation = stem_validation({'Pickups', 'Duration'}, {S_val, S_val}, 0, {'point', 'point'});

%% Model type
obj_stem_modeltype = stem_modeltype('DCM');

%% Create stem_data object
obj_stem_data = stem_data(obj_stem_varset_p, obj_stem_gridlist_p, ...
                          [], [], obj_stem_datestamp, obj_stem_validation, obj_stem_modeltype, []);

%% Parameter constraints
obj_stem_par_constraints = stem_par_constraints();
obj_stem_par_constraints.time_diagonal = 1;

%% Initialize parameters
obj_stem_par = stem_par(obj_stem_data, 'exponential', obj_stem_par_constraints);
obj_stem_par.v_p = [1, 0.6; 0.6, 1];  % Covariance matrix
obj_stem_par.theta_p = 0.06;  % Scale parameter
obj_stem_par.sigma_eta = diag([0.02, 0.02]);  % Process variance
obj_stem_par.G = diag([0.8, 0.8]);  % Transition matrix
obj_stem_par.sigma_eps = diag([0.3, 0.3]);  % Error variance

%% Create the model
bivariate_selected_model = stem_model(obj_stem_data, obj_stem_par);

%% Data transform
bivariate_selected_model.stem_data.log_transform;
bivariate_selected_model.stem_data.standardize;

%% Set initial values
bivariate_selected_model.set_initial_values(obj_stem_par);

%% EM algorithm options
obj_stem_EM_options = stem_EM_options();
obj_stem_EM_options.max_iterations = 300;
obj_stem_EM_options.exit_tol_par = 0.001;

%% Model estimation
bivariate_selected_model.EM_estimate(obj_stem_EM_options);

%% Model validation
bivariate_selected_model.set_varcov;
bivariate_selected_model.set_logL;

%% Save results
save('bivariate_selected_model_results.mat', 'bivariate_selected_model');