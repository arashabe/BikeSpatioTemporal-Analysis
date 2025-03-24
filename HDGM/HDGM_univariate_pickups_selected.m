%% Univariate HDGM for Pickups (Selected Covariates)
clc; clearvars; warning off;

%% Data Loading
addpath('../D-STEAM_v2\Src\');
load('../data_inputs_for_matlab/daily_data.mat');

%% Extract data
data.Y{1} = daily_data.bs_data.pickups;  % Pickups only
data.Y_name{1} = 'Pickups';

%% Number of stations and days
n_stations = length(daily_data.id_stations);
n_days = length(daily_data.datetime_calendar);

%% Selected covariates (same as bivariate selected model)
X = ones(n_stations, 6, n_days);  % Constant + 5 covariates
X(:, 2, :) = repmat(daily_data.weather_data.temp, n_stations, 1);      % Temperature
X(:, 3, :) = repmat(daily_data.weather_data.precip, n_stations, 1);    % Precipitation
X(:, 4, :) = repmat(daily_data.weather_data.visibility, n_stations, 1);% Visibility
X(:, 5, :) = repmat(daily_data.weather_data.uvindex, n_stations, 1);  % UV index
X(:, 6, :) = repmat(daily_data.weekend, n_stations, 1);               % Weekend

%% Assign covariates
data.X_beta{1} = X;
data.X_beta_name{1} = {'Constant', 'Temp', 'Precip', 'Visibility', 'UVIndex', 'Weekend'};

%% Additional covariates
data.X_z{1} = ones(n_stations, 1);
data.X_z_name{1} = {'Constant'};

%% Create stem objects
obj_stem_varset = stem_varset(data.Y, data.Y_name, [], [], ...
                             data.X_beta, data.X_beta_name, ...
                             data.X_z, data.X_z_name);

obj_stem_gridlist = stem_gridlist();
coordinates = [daily_data.lat', daily_data.lon'];
obj_stem_grid = stem_grid(coordinates, 'deg', 'sparse', 'point');
obj_stem_gridlist.add(obj_stem_grid);

obj_stem_datestamp = stem_datestamp('01-01-2023 00:00', '31-12-2023 00:00', n_days);

%% Cross-validation
S_val = [4, 42, 50, 32, 38, 30, 25, 49, 31, 33, 28, 43, 46, 51, 26];
obj_stem_validation = stem_validation({'Pickups'}, {S_val}, 0, {'point'});

%% Model specification
obj_stem_modeltype = stem_modeltype('HDGM');
obj_stem_data = stem_data(obj_stem_varset, obj_stem_gridlist, ...
                         [], [], obj_stem_datestamp, obj_stem_validation, obj_stem_modeltype, []);

%% Parameter initialization
obj_stem_par_constraints = stem_par_constraints();
obj_stem_par = stem_par(obj_stem_data, 'exponential', obj_stem_par_constraints);
obj_stem_par.theta_z = 10;       % Spatial range
obj_stem_par.v_z = 1;            % Spatial variance
obj_stem_par.sigma_eta = 0.02;   % Process variance
obj_stem_par.G = 0.8;            % Transition matrix
obj_stem_par.sigma_eps = 0.3;    % Error variance

%% Create and estimate model
pickups_model = stem_model(obj_stem_data, obj_stem_par);
pickups_model.stem_data.log_transform;
pickups_model.stem_data.standardize;
pickups_model.set_initial_values(obj_stem_par);

obj_stem_EM_options = stem_EM_options();
obj_stem_EM_options.max_iterations = 200;
pickups_model.EM_estimate(obj_stem_EM_options);

%% Validation and results
pickups_model.set_varcov;
pickups_model.set_logL;
RMSE_pickups = sqrt(mean(pickups_model.stem_validation_result{1,1}.cv_mse_s));

%% Save results
save('univariate_hdgm_pickups_results.mat', 'pickups_model');

%% Export results to text file
fileID = fopen('univariate_hdgm_pickups_results.txt', 'w');

fprintf(fileID, 'UNIVARIATE HDGM RESULTS - PICKUPS\n');
fprintf(fileID, '================================\n\n');
fprintf(fileID, 'Selected covariates: Temperature, Precipitation, Visibility, UV index, Weekend\n\n');

% Beta coefficients
fprintf(fileID, 'BETA COEFFICIENTS:\n');
fprintf(fileID, '------------------\n');
for i = 1:length(data.X_beta_name{1})
    fprintf(fileID, '%-12s: %8.4f\n', data.X_beta_name{1}{i}, pickups_model.stem_par.beta(i));
end
fprintf(fileID, '\n');

% Performance metrics
fprintf(fileID, 'MODEL PERFORMANCE:\n');
fprintf(fileID, '-----------------\n');
fprintf(fileID, 'RMSE          : %8.4f\n', RMSE_pickups);
fprintf(fileID, 'Log-Likelihood: %8.4f\n\n', pickups_model.stem_EM_result.logL);

% Covariance parameters
fprintf(fileID, 'COVARIANCE PARAMETERS:\n');
fprintf(fileID, '----------------------\n');
fprintf(fileID, 'Spatial variance (v_z)      : %8.4f\n', pickups_model.stem_par.v_z);
fprintf(fileID, 'Spatial range (theta_z)     : %8.4f\n', pickups_model.stem_par.theta_z);
fprintf(fileID, 'Process variance (sigma_eta): %8.4f\n', pickups_model.stem_par.sigma_eta);
fprintf(fileID, 'Transition matrix (G)       : %8.4f\n', pickups_model.stem_par.G);
fprintf(fileID, 'Error variance (sigma_eps)  : %8.4f\n', pickups_model.stem_par.sigma_eps);

fclose(fileID);
disp('Univariate HDGM (Pickups) results saved.');