%% Subsequent analyses for bivariate_model_results
clc;  

%% Load the results from the saved file
load('bivariate_model_results.mat');

%% Access the beta coefficients
beta = bivariate_model.stem_par.beta;

%% Get the covariate names (corrected access method)
% First check available properties/methods of stem_data
disp('Available properties of stem_data:');
disp(fieldnames(bivariate_model.stem_data));

% Try to access variable names through the correct path
if isprop(bivariate_model.stem_data, 'X_beta_name')
    covar_names = bivariate_model.stem_data.X_beta_name;
elseif isprop(bivariate_model.stem_data, 'stem_varset') && ...
       isprop(bivariate_model.stem_data.stem_varset, 'X_beta_name')
    covar_names = bivariate_model.stem_data.stem_varset.X_beta_name;
else
    % If we can't find the names automatically, use manual names
    covar_names = {'Constant', 'Temp', 'FeelsLike', 'Precip', 'Windspeed', ...
                  'CloudCover', 'Visibility', 'UVIndex', 'NonWorkingDays', ...
                  'Weekend', 'Holidays', 'Humidity'};
    warning('Could not automatically retrieve covariate names - using default names');
end

% Handle case where covar_names is a cell array of cell arrays
if iscell(covar_names) && numel(covar_names) >= 1
    if iscell(covar_names{1})
        covar_names_pickups = covar_names{1};
        covar_names_duration = covar_names{2};
    else
        covar_names_pickups = covar_names;
        covar_names_duration = covar_names;
    end
else
    covar_names_pickups = covar_names;
    covar_names_duration = covar_names;
end

%% Determine the number of covariates
num_covariates = size(beta, 1) / 2;  % Half for Pickups and half for Duration

%% Separate the coefficients for Pickups and Duration
beta_pickups = beta(1:num_covariates);  % Coefficients for Pickups
beta_duration = beta(num_covariates + 1:end);  % Coefficients for Duration

%% Get RMSE values from validation results
RMSE_pickups = sqrt(mean(bivariate_model.stem_validation_result{1, 1}.cv_mse_s));
RMSE_duration = sqrt(mean(bivariate_model.stem_validation_result{1, 2}.cv_mse_s));

%% Get Log-Likelihood value
log_likelihood = bivariate_model.stem_EM_result.logL;

%% Create and open a text file for writing
fileID = fopen('bivariate_model_results.txt', 'w');

%% Write header information
fprintf(fileID, 'BIVARIATE MODEL RESULTS\n');
fprintf(fileID, '=======================\n\n');

%% Write beta coefficients for Pickups
fprintf(fileID, 'BETA COEFFICIENTS FOR PICKUPS:\n');
fprintf(fileID, '--------------------------------\n');
for i = 1:num_covariates
    if i <= length(covar_names_pickups)
        fprintf(fileID, '%s: %.4f\n', covar_names_pickups{i}, beta_pickups(i));
    else
        fprintf(fileID, 'Covariate_%d: %.4f\n', i, beta_pickups(i));
    end
end
fprintf(fileID, '\n');

%% Write beta coefficients for Duration
fprintf(fileID, 'BETA COEFFICIENTS FOR DURATION:\n');
fprintf(fileID, '---------------------------------\n');
for i = 1:num_covariates
    if i <= length(covar_names_duration)
        fprintf(fileID, '%s: %.4f\n', covar_names_duration{i}, beta_duration(i));
    else
        fprintf(fileID, 'Covariate_%d: %.4f\n', i, beta_duration(i));
    end
end
fprintf(fileID, '\n');

%% Write performance metrics
fprintf(fileID, 'MODEL PERFORMANCE METRICS:\n');
fprintf(fileID, '--------------------------\n');
fprintf(fileID, 'RMSE Pickups: %.4f\n', RMSE_pickups);
fprintf(fileID, 'RMSE Duration: %.4f\n', RMSE_duration);
fprintf(fileID, 'Log-Likelihood: %.4f\n', log_likelihood);

%% Close the file
fclose(fileID);

%% Display confirmation message
disp('Results successfully saved to bivariate_model_results.txt');