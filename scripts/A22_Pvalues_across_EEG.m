clc, clear, close all;

%% P-values of the Readiness Potential correlation

% This code calculates the p-values of the correlation of RP features 
% between conditions.

% Miguel Contreras-Altamirano, 2025


%% Settings data

mainpath = 'C:\Users\micua\Desktop\eeglab2023.0\'; % eeglab folder
path = 'C:\Users\micua\OneDrive - Benemérita Universidad Autónoma de Puebla\NCP_Basketball\MediaPipe\';
outpath = 'C:\\Users\\micua\\OneDrive - Benemérita Universidad Autónoma de Puebla\\Oldenburg_University\\Thesis\\data_hoops\\';
files = dir(fullfile(path, '*.xdf')); % listing data sets

% Define channels for frontal and central regions
central_channels = {'C3', 'Cz', 'C4'};   
frontal_channels = {'FC1', 'Fz', 'FC2'};

% Initialize cell arrays for storing p-value matrices
pvalues_Matrix_RP_Central = cell(1, length(central_channels));
pvalues_Matrix_RP_Front = cell(1, length(frontal_channels));

% Combine both sets for processing in a loop
all_channels = [frontal_channels, central_channels];

% Bin edges for 100 ms bins from -1500 ms to 0 ms
binEdges = -1500:100:0;
numBins = length(binEdges) - 1;

% Generate bin labels
bin_labels = arrayfun(@(s, e) sprintf('[%d:%d ms]', s, e), binEdges(1:end-1), binEdges(2:end), 'UniformOutput', false);


%% Creating p-values matrix for RP (Readiness Potential) for all channels

for ch = 1:length(all_channels)

    numParticipants = length(files); % number of participants
    numFeatures = 15; % 30 features

    % Initialize a matrix to hold p-values for all features across all participants
    pvalues_Matrix = zeros(numFeatures, numParticipants);

    for sub = 1:numParticipants
        participant = extractBefore(files(sub).name, '.xdf');
        out_subfold = [outpath, participant, '\\'];
        load([out_subfold, 'Biserial_corr_RP_', all_channels{ch}, '_', participant, '.mat']); % Load RP data

        % Fill in the matrix with p-values for this participant
        pvalues_Matrix(:, sub) = Biserial_corr_RP.P_Value(1:numFeatures);

        % Save feature names for plotting
        feature_names = Biserial_corr_RP.Features;
    end

    % Store the matrix depending on whether it's frontal or central
    if ch <= length(frontal_channels)
        pvalues_Matrix_RP_Front{ch} = pvalues_Matrix;
    else
        pvalues_Matrix_RP_Central{ch - length(frontal_channels)} = pvalues_Matrix;
    end
end

% Colors for the plots
customColors = [33,113,181; 66,146,198; 107,174,214; 158,202,225; 198,219,239; 222,235,247; 247,251,255] / 255;
smoothGradient = interp1(linspace(0, 1, size(customColors, 1)), customColors, linspace(0, 1, 256), 'pchip');

%% Visualizing features variance across participants for Frontal and Central channels

figure('units', 'normalized', 'outerposition', [0 0 1 1]);

% Threshold for significant features
threshold_RP = 0.05;

% Plot Frontal Channels (Top Row)
for i = 1:3
    subplot(2, 3, i)
    imagesc(pvalues_Matrix_RP_Front{i});
    cb = colorbar; % Create the colorbar
    ylabel(cb, 'p-Values', 'FontWeight', 'bold', 'FontSize', 11); % Label for colorbar
    title(['Point bi-serial correlation of [', frontal_channels{i}, ']'], 'FontSize', 12);
    subtitle('[Hits vs Misses]', 'FontSize', 12);
    xlabel('Participants', 'FontWeight', 'bold', 'FontSize', 11.5);
    ylabel('Features', 'FontWeight', 'bold', 'FontSize', 11.5);
    xticks(1:numParticipants+2);
    xticklabels([arrayfun(@num2str, 1:numParticipants, 'UniformOutput', false), ' ', 'Mean']);
    yticks(1:numFeatures+2);
    yticklabels(feature_names);
    colormap(smoothGradient);
    clim([0, 1]); % Adjust color limit to [0, 1] for better comparison
    
    % Overlay the markers for significant features (p-values < 0.05)
    [featureIdx_PLD, participantIdx_PLD] = find(pvalues_Matrix_RP_Front{i} < threshold_RP);
    hold on; 
    scatter(participantIdx_PLD, featureIdx_PLD, 'filled', 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'r');
end

% Plot Central Channels (Bottom Row)
for i = 1:3
    subplot(2, 3, i + 3)
    imagesc(pvalues_Matrix_RP_Central{i});
    cb = colorbar; % Create the colorbar
    ylabel(cb, 'p-Values', 'FontWeight', 'bold', 'FontSize', 11); % Label for colorbar
    title(['Point bi-serial correlation of [', central_channels{i}, ']'], 'FontSize', 12);
    subtitle('[Hits vs Misses]', 'FontSize', 12);
    xlabel('Participants', 'FontWeight', 'bold', 'FontSize', 11.5);
    ylabel('Features', 'FontWeight', 'bold', 'FontSize', 11.5);
    xticks(1:numParticipants+2);
    xticklabels([arrayfun(@num2str, 1:numParticipants, 'UniformOutput', false), ' ', 'Mean']);
    yticks(1:numFeatures+2);
    yticklabels(feature_names);
    colormap(smoothGradient);
    clim([0, 1]); % Adjust color limit to [0, 1] for better comparison
    
    % Overlay the markers for significant features (p-values < 0.05)
    [featureIdx_PLD, participantIdx_PLD] = find(pvalues_Matrix_RP_Central{i} < threshold_RP);
    hold on; 
    scatter(participantIdx_PLD, featureIdx_PLD, 'filled', 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'r');
end


%% Visualizing features variance across participants for Frontal and Central channels

figure('units', 'normalized', 'outerposition', [0 0 1 1]);

% Threshold for significant features
threshold_RP = 0.05;

% Plot Frontal Channels (Top Row)
for i = 1:3
    subplot(2, 3, i)
    imagesc(pvalues_Matrix_RP_Front{i}');
    cb = colorbar; % Create the colorbar
    ylabel(cb, 'p-Values', 'FontWeight', 'bold', 'FontSize', 11); % Label for colorbar
    title(['ERP Comparison of ', frontal_channels{i}], 'FontSize', 12);
    subtitle('[Hits vs Misses]', 'FontSize', 12);
    xlabel('Mean features', 'FontWeight', 'bold', 'FontSize', 11.5);
    ylabel('Participants', 'FontWeight', 'bold', 'FontSize', 11.5);
    
    % Configure X and Y ticks
    xticks(1:numBins);
    xticklabels(bin_labels); % Bin labels on x-axis
    yticks(1:numParticipants);
    yticklabels(arrayfun(@(x) sprintf('sub-%02d', x), 1:numParticipants, 'UniformOutput', false)); % Participant labels on y-axis
    
    colormap(smoothGradient);
    clim([0, 1]); % Adjust color limit to [0, 1] for better comparison
end

% Plot Central Channels (Bottom Row)
for i = 1:3
    subplot(2, 3, i + 3)
    imagesc(pvalues_Matrix_RP_Central{i}');
    cb = colorbar; % Create the colorbar
    ylabel(cb, 'p-Values', 'FontWeight', 'bold', 'FontSize', 11); % Label for colorbar
    title(['ERP Comparison of ', central_channels{i}], 'FontSize', 12);
    subtitle('[Hits vs Misses]', 'FontSize', 12);
    xlabel('Mean features', 'FontWeight', 'bold', 'FontSize', 11.5);
    ylabel('Participants', 'FontWeight', 'bold', 'FontSize', 11.5);
    
    % Configure X and Y ticks
    xticks(1:numBins);
    xticklabels(bin_labels); % Bin labels on x-axis
    yticks(1:numParticipants);
    yticklabels(arrayfun(@(x) sprintf('sub-%02d', x), 1:numParticipants, 'UniformOutput', false)); % Participant labels on y-axis
    
    colormap(smoothGradient);
    clim([0, 1]); % Adjust color limit to [0, 1] for better comparison
end


%% Generating Tables for Significant Features

% Initialize cell arrays for tables
sig_features_frontal = cell(1, 3);
sig_features_central = cell(1, 3);

% Loop through frontal channels to generate tables
for i = 1:3
    significantFeat_RP = cell(numParticipants, 1);

    for sub = 1:numParticipants
        significantIdx_RP = find(pvalues_Matrix_RP_Front{i}(:, sub) < threshold_RP);
        significantFeat_RP{sub} = significantIdx_RP;
    end

    sig_feat_name_RP = ['Sig_Feat_RP_', frontal_channels{i}];
    sig_features_frontal{i} = cell2table(significantFeat_RP, 'VariableNames', {sig_feat_name_RP});
end

% Loop through central channels to generate tables
for i = 1:3
    significantFeat_RP = cell(numParticipants, 1);

    for sub = 1:numParticipants
        significantIdx_RP = find(pvalues_Matrix_RP_Central{i}(:, sub) < threshold_RP);
        significantFeat_RP{sub} = significantIdx_RP;
    end

    sig_feat_name_RP = ['Sig_Feat_RP_', central_channels{i}];
    sig_features_central{i} = cell2table(significantFeat_RP, 'VariableNames', {sig_feat_name_RP});
end

%% Saving

% Frontal Table
sig_features_frontal_combined = horzcat(sig_features_frontal{:});
participantIDs = arrayfun(@(x) sprintf('sub_%02d', x), 1:numParticipants, 'UniformOutput', false)';
sig_features_frontal_combined.ParticipantID = participantIDs;
sig_features_frontal_combined = movevars(sig_features_frontal_combined, 'ParticipantID', 'Before', sig_features_frontal_combined.Properties.VariableNames{1});
save([outpath, 'sig_bin_feat_fronto-central.mat'], 'sig_features_frontal_combined');

% Central Table
sig_features_central_combined = horzcat(sig_features_central{:});
sig_features_central_combined.ParticipantID = participantIDs;
sig_features_central_combined = movevars(sig_features_central_combined, 'ParticipantID', 'Before', sig_features_central_combined.Properties.VariableNames{1});
save([outpath, 'sig_bin_feat_central.mat'], 'sig_features_central_combined');

% Save plot
saveas(gcf, [outpath, '\\group_analysis\\', 'Feat_pvalues_fronto-central.jpg']);
