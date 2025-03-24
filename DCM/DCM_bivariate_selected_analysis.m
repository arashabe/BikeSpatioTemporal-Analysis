%% Results Saving Script for Bivariate D-STEAM Model
clc;
warning off;

%% Load the results if not already loaded
if ~exist('bivariate_selected_model', 'var')
    load('bivariate_selected_model_results.mat');
end

%% Extract and prepare all results
results = struct();

% 1. Extract beta coefficients
beta = bivariate_selected_model.stem_par.beta;
num_covariates = size(beta, 1) / 2;  % Half for Pickups, half for Duration

% Separate coefficients
results.beta_pickups = beta(1:num_covariates);
results.beta_duration = beta(num_covariates+1:end);

% Get covariate names (from your model setup)
covar_names = {'Constant', 'Temp', 'Precip', 'Visibility', 'UVIndex', 'Weekend'};

% 2. Extract RMSE values from validation
results.RMSE_pickups = sqrt(mean(bivariate_selected_model.stem_validation_result{1,1}.cv_mse_s));
results.RMSE_duration = sqrt(mean(bivariate_selected_model.stem_validation_result{1,2}.cv_mse_s));

% 3. Extract Log-Likelihood
results.logL = bivariate_selected_model.stem_EM_result.logL;

% 4. Extract covariance parameters
results.v_p = bivariate_selected_model.stem_par.v_p;         % Cross-covariance
results.theta_p = bivariate_selected_model.stem_par.theta_p; % Spatial range
results.sigma_eta = bivariate_selected_model.stem_par.sigma_eta; % Process variance
results.G = bivariate_selected_model.stem_par.G;             % Transition matrix
results.sigma_eps = bivariate_selected_model.stem_par.sigma_eps; % Error variance

%% Create and write to text file
filename = 'bivariate_selected_model_results.txt';
fileID = fopen(filename, 'w');

% Write header
fprintf(fileID, 'BIVARIATE D-STEAM MODEL RESULTS\n');
fprintf(fileID, '===============================\n\n');
fprintf(fileID, 'Model estimation date: %s\n\n', datetime);

% 1. Write beta coefficients
fprintf(fileID, 'BETA COEFFICIENTS:\n');
fprintf(fileID, '------------------\n');

% For Pickups
fprintf(fileID, '\nPICKUPS:\n');
for i = 1:num_covariates
    fprintf(fileID, '%-12s: %8.4f\n', covar_names{i}, results.beta_pickups(i));
end

% For Duration
fprintf(fileID, '\nDURATION:\n');
for i = 1:num_covariates
    fprintf(fileID, '%-12s: %8.4f\n', covar_names{i}, results.beta_duration(i));
end

% 2. Write performance metrics
fprintf(fileID, '\nMODEL PERFORMANCE:\n');
fprintf(fileID, '-----------------\n');
fprintf(fileID, 'RMSE Pickups : %8.4f\n', results.RMSE_pickups);
fprintf(fileID, 'RMSE Duration: %8.4f\n', results.RMSE_duration);
fprintf(fileID, 'Log-Likelihood: %8.4f\n\n', results.logL);

% 3. Write covariance parameters
fprintf(fileID, 'COVARIANCE PARAMETERS:\n');
fprintf(fileID, '----------------------\n');
fprintf(fileID, 'Cross-covariance matrix (v_p):\n');
fprintf(fileID, '%8.4f %8.4f\n', results.v_p(1,:));
fprintf(fileID, '%8.4f %8.4f\n\n', results.v_p(2,:));

fprintf(fileID, 'Spatial range (theta_p): %8.4f\n', results.theta_p);
fprintf(fileID, 'Process variance (sigma_eta):\n');
fprintf(fileID, '%8.4f %8.4f\n', results.sigma_eta(1,:));
fprintf(fileID, '%8.4f %8.4f\n\n', results.sigma_eta(2,:));

fprintf(fileID, 'Transition matrix (G):\n');
fprintf(fileID, '%8.4f %8.4f\n', results.G(1,:));
fprintf(fileID, '%8.4f %8.4f\n\n', results.G(2,:));

fprintf(fileID, 'Error variance (sigma_eps):\n');
fprintf(fileID, '%8.4f %8.4f\n', results.sigma_eps(1,:));
fprintf(fileID, '%8.4f %8.4f\n', results.sigma_eps(2,:));

% Close the file
fclose(fileID);

%% Display confirmation
disp(['Results successfully saved to ' filename]);
disp('The file contains:');
disp('- Beta coefficients for all covariates');
disp('- RMSE values for both variables');
disp('- Log-Likelihood value');
disp('- All covariance parameters');