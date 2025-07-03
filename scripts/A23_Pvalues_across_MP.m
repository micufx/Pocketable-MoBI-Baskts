clc, clear, close all;

%% P-values of the human pose correlation

% This code calculates the p-values of the correlation of human pose 
% features between conditions.

% Miguel Contreras-Altamirano, 2025


%% Settings data
mainpath = 'C:\Users\micua\Desktop\eeglab2023.0\'; % eeglab folder
path = 'C:\Users\micua\OneDrive - Benemérita Universidad Autónoma de Puebla\NCP_Basketball\MediaPipe\';
outpath = 'C:\\Users\\micua\\OneDrive - Benemérita Universidad Autónoma de Puebla\\Oldenburg_University\\Thesis\\data_hoops\\';
files = dir(fullfile(path, '*.xdf')); % listing data sets

% Landmark times to analyze
Landmarks = -2.5:0.1:1; % Consecutive landmarks

numParticipants = length(files); % number of participants
numFeatures = 99; % number of features

% Colors
customColors = [33,113,181; 66,146,198; 107,174,214; 158,202,225; 198,219,239; 222,235,247; 247,251,255] / 255;
smoothGradient = interp1(linspace(0, 1, size(customColors, 1)), customColors, linspace(0, 1, 256), 'pchip');

%% Adjust to handle odd numbers of landmarks properly
numLandmarks = length(Landmarks);
numFigures = ceil(numLandmarks / 2);  % Number of figures needed (two heatmaps per figure)

%% Loop through each pair of consecutive landmarks and generate plots
for figIdx = 1:numFigures

    Landmark_1 = Landmarks((figIdx - 1) * 2 + 1);   % First landmark in the pair
    is_second_landmark = ((figIdx - 1) * 2 + 2) <= numLandmarks;
    
    % If there is a second landmark, assign it; otherwise, leave it empty
    if is_second_landmark
        Landmark_2 = Landmarks((figIdx - 1) * 2 + 2); % Second landmark in the pair
    else
        Landmark_2 = [];
    end

    pvalues_Matrix_PLD_1 = zeros(numFeatures, numParticipants);
    pvalues_Matrix_PLD_2 = zeros(numFeatures, numParticipants);

    %% Creating p_values matrix for PLD [first column]
    for sub = 1:numParticipants
        participant = extractBefore(files(sub).name, '.xdf');
        out_subfold = [outpath, participant, '\\'];

        load([out_subfold, 'Biserial_corr_PLD_', participant, '_', num2str(Landmark_1*1000), '_ms.mat']);
        pvalues_Matrix_PLD_1(:, sub) = Biserial_corr_PLD.P_Value;
        
        if sub == 1
            % Save feature names on first loop iteration
            feature_names = Biserial_corr_PLD.Features;
        end
    end

    %% Creating p_values matrix for PLD [second column] (only if there is a second landmark)
    if ~isempty(Landmark_2)
        for sub = 1:numParticipants
            participant = extractBefore(files(sub).name, '.xdf');
            out_subfold = [outpath, participant, '\\'];

            load([out_subfold, 'Biserial_corr_PLD_', participant, '_', num2str(Landmark_2*1000), '_ms.mat']);
            pvalues_Matrix_PLD_2(:, sub) = Biserial_corr_PLD.P_Value;
        end
    end

    %% Plotting the results
    figure('units', 'normalized', 'outerposition', [0 0 1 1]);

    % First plot for Landmark_1
    subplot(1, 2, 1);
    imagesc(pvalues_Matrix_PLD_1);
    cb = colorbar; % Create the colorbar
    ylabel(cb, 'p-Values', 'FontWeight', 'bold', 'FontSize', 11); % Label for colorbar
    title(['Pose Landmarks Differences [Hits vs Misses]'], 'FontSize', 12);
    subtitle(['Significant Differences [p < 0.05*] / [Landmark at ', num2str(Landmark_1*1000), ' ms]'], 'FontSize', 12);
    xlabel('Participants', 'FontWeight', 'bold', 'FontSize', 11.5);
    ylabel('Features', 'FontWeight', 'bold', 'FontSize', 11.5);
    axis tight;
    xticks(1:numParticipants + 2);
    xticklabels([arrayfun(@num2str, 1:numParticipants, 'UniformOutput', false), ' ', 'Mean']);
    yticks(2:3:numFeatures + 2);
    yticklabels(feature_names(2:3:end));
    colormap(smoothGradient);
    clim([0, max(pvalues_Matrix_PLD_1(:))]);
    xtickangle(90);

    % Overlay markers for significant features
    [featureIdx_PLD, participantIdx_PLD] = find(pvalues_Matrix_PLD_1 < 0.05);
    hold on;
    scatter(participantIdx_PLD, featureIdx_PLD, 'filled', 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'r');
    hold off;

    % Second plot for Landmark_2, only if it exists
    if ~isempty(Landmark_2)
        subplot(1, 2, 2);
        imagesc(pvalues_Matrix_PLD_2);
        cb = colorbar; % Create the colorbar
        ylabel(cb, 'p-Values', 'FontWeight', 'bold', 'FontSize', 11); % Label for colorbar
        title(['Pose Landmarks Differences [Hits vs Misses]'], 'FontSize', 12);
        subtitle(['Significant Differences [p < 0.05*] / [Landmark at ', num2str(Landmark_2*1000), ' ms]'], 'FontSize', 12);
        xlabel('Participants', 'FontWeight', 'bold', 'FontSize', 11.5);
        ylabel('Features', 'FontWeight', 'bold', 'FontSize', 11.5);
        axis tight;
        xticks(1:numParticipants + 2);
        xticklabels([arrayfun(@num2str, 1:numParticipants, 'UniformOutput', false), ' ', 'Mean']);
        yticks(2:3:numFeatures + 2);
        yticklabels(feature_names(2:3:end));
        colormap(smoothGradient);
        clim([0, max(pvalues_Matrix_PLD_2(:))]);
        xtickangle(90);

        % Overlay markers for significant features
        [featureIdx_PLD, participantIdx_PLD] = find(pvalues_Matrix_PLD_2 < 0.05);
        hold on;
        scatter(participantIdx_PLD, featureIdx_PLD, 'filled', 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'r');
        hold off;
    end

    %% Save the figure
    if ~isempty(Landmark_2)
        saveas(gcf, [outpath, '\\group_analysis\\', 'Feat_significance_PLD_', num2str(Landmark_1*1000), '_', num2str(Landmark_2*1000), '_ms', '.jpg']);
    else
        saveas(gcf, [outpath, '\\group_analysis\\', 'Feat_significance_PLD_', num2str(Landmark_1*1000), '_ms', '.jpg']);
    end

end

%% Generating Tables for Significant Features

% Initialize table for storing significant features
sig_features_PLD_1 = cell(numParticipants, 1);
sig_features_PLD_2 = cell(numParticipants, 1);

% Loop through participants and store significant features for both landmarks
for sub = 1:numParticipants
    % Landmark 1
    significantIdx_PLD_1 = find(pvalues_Matrix_PLD_1(:, sub) < 0.05);
    sig_features_PLD_1{sub} = significantIdx_PLD_1;
    
    % Landmark 2 (if exists)
    if ~isempty(Landmark_2)
        significantIdx_PLD_2 = find(pvalues_Matrix_PLD_2(:, sub) < 0.05);
        sig_features_PLD_2{sub} = significantIdx_PLD_2;
    end
end

% Convert to table for Landmark 1
sig_feat_name_PLD_1 = ['Sig_Feat_PLD_', num2str(Landmark_1*1000), '_ms'];
featureTable_PLD_1 = cell2table(sig_features_PLD_1, 'VariableNames', {sig_feat_name_PLD_1});

% Convert to table for Landmark 2 (if exists)
if ~isempty(Landmark_2)
    sig_feat_name_PLD_2 = ['Sig_Feat_PLD_', num2str(Landmark_2*1000), '_ms'];
    featureTable_PLD_2 = cell2table(sig_features_PLD_2, 'VariableNames', {sig_feat_name_PLD_2});
end

%% Combine Tables and Save
if ~isempty(Landmark_2)
    sig_features_combined = horzcat(featureTable_PLD_1, featureTable_PLD_2);
else
    sig_features_combined = featureTable_PLD_1;
end

participantIDs = arrayfun(@(x) sprintf('sub_%02d', x), 1:numParticipants, 'UniformOutput', false)';
sig_features_combined.ParticipantID = participantIDs;
sig_features_combined = movevars(sig_features_combined, 'ParticipantID', 'Before', sig_features_combined.Properties.VariableNames{1});


%% Save the combined table
save([outpath, 'sig_bin_feat_motion.mat'], 'sig_features_combined');
