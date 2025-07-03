clc, clear, close all;

%% Point-biserial correlation of the human pose

% This code applies point-biserial correlation to the human pose between
% conditions.

% The point-biserial correlation is a specific case of the Pearson
% correlation coefficient that measures the strength and direction of the
% association between a continuous variable and a binary (dichotomous)
% variable. In your context, this method can help determine if there's a
% significant relationship between the features extracted from your EEG
% data (like the standard deviation and mean of signals per trial) and the
% binary outcome of each trial (hit or miss).

% This script computes the point-biserial correlation between each of the
% 30 features and the binary condition for all trials. The results are
% stored in the correlationResults table, which includes the correlation
% coefficient (R_Value) and p-value (P_Value) for each feature.

% The point-biserial correlation is essentially Pearson's
% correlation when one variable is continuous (features in this case) and
% the other is binary (condition, 1 or 0), so using corr with 'Type',
% 'Pearson' is appropriate here. The magnitude of R_Value indicates the
% strength of the relationship between the feature and the condition, while
% the P_Value indicates the statistical significance of this relationship.

% Miguel Contreras-Altamirano, 2025

%% Settings data
mainpath = 'C:\Users\micua\Desktop\eeglab2023.0\'; % eeglab folder
path = 'C:\Users\micua\OneDrive - Benemérita Universidad Autónoma de Puebla\NCP_Basketball\MediaPipe\';
outpath = 'C:\\Users\\micua\\OneDrive - Benemérita Universidad Autónoma de Puebla\\Oldenburg_University\\Thesis\\data_hoops\\';
files = dir(fullfile(path, '\*.xdf')); % listing data sets

% Landmark times to analyze
Landmarks = -2.5:0.1:1; % Consecutive landmarks

%% Loop through participants and landmark times

for sub = 1:1%length(files)

    participant = extractBefore(files(sub).name, '.xdf');
    out_subfold = [outpath, participant, '\\'];

    for lm_idx = 1:length(Landmarks)

        Landmark = Landmarks(lm_idx); % Current landmark time

        % Load the motion features for the current participant and landmark
        load([out_subfold, participant, '_features_PLD_', num2str(Landmark*1000), '_ms', '.mat']); % Loading motion data

        % Extract the names of the feature columns (assuming the first 99 columns are features)
        num_features = 99; % Number of feature bins
        featureNames = features_PLD.Properties.VariableNames(1:num_features);

        % Preallocate arrays for the correlation coefficients and p-values
        r_values = zeros(length(featureNames), 1);
        p_values = zeros(length(featureNames), 1);
        r_squared_values = zeros(length(featureNames), 1);  % Preallocate R^2 array

        % Loop through each feature column to compute the point-biserial correlation with the condition
        for i = 1:length(featureNames)
            [r, p] = corr(features_PLD.(featureNames{i}), features_PLD.Condition, 'Type', 'Pearson');
            r_values(i) = r; % Store the correlation coefficient for each feature
            p_values(i) = p; % Store the p-value for each feature
            r_squared_values(i) = r^2; % Calculate and store R^2 value
        end

        % Significant differences in landmarks
        adjusted_p_values_vector = mafdr( p_values, 'BHFDR', true); % Adjust p-values for multiple comparisons
        significant_diff = adjusted_p_values_vector < 0.05;  % Find significant differences

        % Create a table to summarize the correlation results and p-values after multiple comparison correction
        Biserial_corr_PLD = table(featureNames', r_values, adjusted_p_values_vector, r_squared_values, ...
            'VariableNames', {'Features', 'R_Value', 'P_Value', 'R_Squared'});

        % % Visualization of R^2 values
        % figure('units','normalized','outerposition', [0 0 1 1]);
        % bar(r_squared_values); % Plotting R^2 values
        % title('Explained Variance [R^2] of PLD features', 'FontSize', 12);
        % subtitle(['Sub. [', num2str(sub), '] / ', '[Landmark at ', num2str(Landmark*1000), ' ms]'], 'FontSize', 11.5);
        % xlabel('Feature Index');
        % ylabel('R^2 Value');
        % xticks(1:length(featureNames));
        % xticklabels(featureNames);
        % xtickangle(90);  % Rotate labels for better readability


        %% Saving info
        % Save the correlation results in a .mat file
        save([out_subfold, 'Biserial_corr_PLD_', participant, '_', num2str(Landmark*1000), '_ms','.mat'], 'Biserial_corr_PLD');

        % Save the figure
        % saveas(gcf, [out_subfold, 'r2_feat_PLD_', participant, '_', num2str(Landmark*1000), '_ms','.jpg']);
        % saveas(gcf, [outpath, '\\group_analysis\\','r2_feat_PLD_', participant, '_', num2str(Landmark*1000), '_ms','.jpg']);

        % Display if significant differences are found
        if any(significant_diff > 0)
            disp(['Participant ', num2str(sub), ' showed significant differences in motion', ' at ', num2str(Landmark*1000), 'ms']);
        end

        clear Biserial_corr_PLD  % Clear the variable for the next loop

    end  % End of landmarks loop

    disp([participant, ' finalized!']);

end  % End of participants loop


% Biserial correlation

% This code calculates the point-biserial correlation coefficient (r) and
% the corresponding p-value (pValue) for both the standard deviation and
% mean features against the trial outcomes. The r value indicates the
% strength and direction of the association, while the pValue assesses the
% statistical significance of this association. A low p-value (typically <
% 0.05) suggests that the observed correlation is unlikely to have occurred
% by chance.

% Correlation Coefficient (r): This measures the strength and direction of
% a linear relationship between two variables. In the context of
% point-biserial correlation, it measures the relationship between a
% continuous variable (e.g., your features such as mean or standard
% deviation) and a binary categorical variable (e.g., hit or miss). The
% value of r ranges from -1 to 1, where: 1 indicates a perfect positive
% linear relationship, -1 indicates a perfect negative linear relationship,
% 0 indicates no linear relationship. P-value: This indicates the
% probability of observing the data or something more extreme if the null
% hypothesis is true. In this context, the null hypothesis typically states
% that there is no association between the continuous and binary variables.
% A small p-value (typically ≤ 0.05) indicates strong evidence against the
% null hypothesis, suggesting a significant association between the
% variables.

% Interpreting the Results High Positive r Value: Indicates that
% as the continuous feature increases, the likelihood of one category of
% the binary variable (e.g., hit) increases. High Negative r Value:
% Indicates that as the continuous feature increases, the likelihood of the
% opposite category of the binary variable (e.g., miss) increases. P-value
% ≤ 0.05: Suggests that the observed correlation is statistically
% significant, meaning there is a less than 5% chance that the observed
% association is due to random variation alone.

% When it comes to calculating explained variance (R^2), simply squaring
% the Pearson correlation coefficient (r) gives you a measure of how much
% variance in the dependent variable can be explained by the independent
% variable in a linear model. This is appropriate for linear relationships.
% If your features and conditions follow a linear model, squaring the
% correlation coefficient (r^2) indeed gives you the explained variance.

% Using the point-biserial correlation coefficient squared (R^2) can give
% estimate of the explained variance. It indicates how much of the
% variability in the binary outcome can be accounted for by the variance
% in the readiness potential amplitude, under the assumption of a linear
% relationship between these variables. This method can provide valuable
% insights into the strength and significance of the relationship between
% brain activity and performance.

