%% Results Saving Script for Univariate Pickups D-STEAM Model
clc;
warning off;

%% Load the results if not already loaded
if ~exist('pick_selected_model', 'var')
    load('pick_selected_model_results.mat');
end

%% Extract and prepare all results
results = struct();

% 1. Extract beta coefficients
results.beta = pick_selected_model.stem_par.beta;
num_covariates = length(results.beta);

% Get covariate names (from your model setup)
covar_names = {'Constant', 'Temp', 'Precip', 'Visibility', 'UVIndex', 'Weekend'};

% 2. Extract RMSE from validation
results.RMSE = sqrt(mean(pick_selected_model.stem_validation_result{1,1}.cv_mse_s));

% 3. Extract Log-Likelihood
results.logL = pick_selected_model.stem_EM_result.logL;

% 4. Extract covariance parameters
results.v_p = pick_selected_model.stem_par.v_p;         % Spatial variance
results.theta_p = pick_selected_model.stem_par.theta_p; % Spatial range
results.sigma_eta = pick_selected_model.stem_par.sigma_eta; % Process variance
results.G = pick_selected_model.stem_par.G;             % Transition matrix
results.sigma_eps = pick_selected_model.stem_par.sigma_eps; % Error variance

%% Create and write to text file
filename = 'univariate_pickups_model_results.txt';
fileID = fopen(filename, 'w');

% Write header
fprintf(fileID, 'UNIVARIATE D-STEAM MODEL RESULTS (PICKUPS)\n');
fprintf(fileID, '==========================================\n\n');
fprintf(fileID, 'Model estimation date: %s\n\n', datetime);

% 1. Write beta coefficients
fprintf(fileID, 'BETA COEFFICIENTS:\n');
fprintf(fileID, '------------------\n');
for i = 1:num_covariates
    fprintf(fileID, '%-12s: %8.4f\n', covar_names{i}, results.beta(i));
end

% 2. Write performance metrics
fprintf(fileID, '\nMODEL PERFORMANCE:\n');
fprintf(fileID, '-----------------\n');
fprintf(fileID, 'RMSE         : %8.4f\n', results.RMSE);
fprintf(fileID, 'Log-Likelihood: %8.4f\n\n', results.logL);

% 3. Write covariance parameters
fprintf(fileID, 'COVARIANCE PARAMETERS:\n');
fprintf(fileID, '----------------------\n');
fprintf(fileID, 'Spatial variance (v_p)      : %8.4f\n', results.v_p);
fprintf(fileID, 'Spatial range (theta_p)     : %8.4f\n', results.theta_p);
fprintf(fileID, 'Process variance (sigma_eta): %8.4f\n', results.sigma_eta);
fprintf(fileID, 'Transition matrix (G)       : %8.4f\n', results.G);
fprintf(fileID, 'Error variance (sigma_eps)  : %8.4f\n', results.sigma_eps);

% 4. Write EM algorithm information (corrected access method)
fprintf(fileID, '\nESTIMATION DETAILS:\n');
fprintf(fileID, '------------------\n');
if isfield(pick_selected_model.stem_EM_result, 'n_iter')
    fprintf(fileID, 'EM iterations      : %d\n', pick_selected_model.stem_EM_result.n_iter);
else
    fprintf(fileID, 'EM iterations      : Information not available\n');
end

if isfield(pick_selected_model.stem_EM_result, 'convergence')
    fprintf(fileID, 'Convergence reached: %d\n', pick_selected_model.stem_EM_result.convergence);
else
    fprintf(fileID, 'Convergence reached: Information not available\n');
end

if isfield(pick_selected_model.stem_EM_result, 'exit_tol')
    fprintf(fileID, 'Final tolerance    : %8.4e\n', pick_selected_model.stem_EM_result.exit_tol);
else
    fprintf(fileID, 'Final tolerance    : Information not available\n');
end

% Close the file
fclose(fileID);

%% Display confirmation
disp(['Results successfully saved to ' filename]);
disp('The file contains:');
disp('- Beta coefficients for all covariates');
disp('- RMSE value from validation');
disp('- Log-Likelihood value');
disp('- All covariance parameters');
disp('- Estimation details');

%% Optional: Save to CSV for easier analysis
% Create table of beta coefficients
beta_table = table(covar_names', results.beta, ...
                  'VariableNames', {'Covariate', 'Coefficient'});

% Write to CSV
writetable(beta_table, 'univariate_pickups_coefficients.csv');
disp('Beta coefficients also saved to univariate_pickups_coefficients.csv');