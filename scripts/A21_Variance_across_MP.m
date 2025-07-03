clc, clear, close all;

%% Explained variance of the Readiness Potential 

% This code calculates the explained variance of the human pose features 
% between conditions.

% Miguel Contreras-Altamirano, 2025


%% Settings data
mainpath = 'C:\Users\micua\Desktop\eeglab2023.0\'; % eeglab folder
path = 'C:\Users\micua\OneDrive - Benemérita Universidad Autónoma de Puebla\NCP_Basketball\MediaPipe\';
outpath = 'C:\\Users\\micua\\OneDrive - Benemérita Universidad Autónoma de Puebla\\Oldenburg_University\\Thesis\\data_hoops\\';
files = dir(fullfile(path, '\*.xdf')); % listing data sets

% Landmark times to analyze
Landmarks = -2.5:0.1:1; % Consecutive landmarks

numParticipants = length(files); % number of participants
numFeatures = 99; % number of features

% Preallocate matrices for R_Squared results
R_Squared_Matrices_PLD = cell(length(Landmarks), 1);
feature_names = {};  % This will be updated inside the loop

%% Loop through each landmark dynamically
for lm_idx = 1:length(Landmarks)
    % Get the current landmark time
    landmark = Landmarks(lm_idx);
    
    % Initialize a matrix to hold R_Squared values for this landmark across participants
    R_Squared_Matrices_PLD{lm_idx} = zeros(numFeatures, numParticipants);

    % Loop through participants and load data
    for sub = 1:numParticipants
        participant = extractBefore(files(sub).name, '.xdf');
        out_subfold = [outpath, participant, '\\'];
        
        % Load the .mat file based on the current landmark time
        load([out_subfold, 'Biserial_corr_PLD_', participant, '_', num2str(landmark * 1000), '_ms', '.mat']); % Loading covariance

        % Fill in the matrix with R_Squared values for this participant
        R_Squared_Matrices_PLD{lm_idx}(:, sub) = Biserial_corr_PLD.R_Squared;

        % Store feature names if not already done (we assume they are the same across landmarks)
        if isempty(feature_names)
            feature_names = Biserial_corr_PLD.Features;
        end
    end

    % Add an extra layer for NaN (distinguishing visual comparison)
    R_Squared_Matrices_PLD{lm_idx}(numFeatures + 1, size(R_Squared_Matrices_PLD{lm_idx}, 2) + 1) = NaN;

    % Calculate the mean across features per participant
    R_Squared_Matrices_PLD{lm_idx}(numFeatures + 2, :) = mean(R_Squared_Matrices_PLD{lm_idx}, 1, 'omitmissing');

    % Calculate the mean across participants per feature
    R_Squared_Matrices_PLD{lm_idx}(:, size(R_Squared_Matrices_PLD{lm_idx}, 2) + 1) = mean(R_Squared_Matrices_PLD{lm_idx}, 2, 'omitmissing');

    % Add 'Mean' to the feature names
    feature_names{numFeatures + 2} = 'Mean';
end

%% Visualizing features variance across participants for all landmarks

numFigures = ceil(length(Landmarks) / 2);  % Number of figures needed (2 heatmaps per figure)

for fig_idx = 1:numFigures
    figure('units', 'normalized', 'outerposition', [0 0 1 1]);

    % Get the two landmarks for this figure
    lm_1_idx = (fig_idx - 1) * 2 + 1;  % First landmark index
    lm_2_idx = lm_1_idx + 1;  % Second landmark index (may not exist if odd number of landmarks)

    % First plot for the first landmark in the pair
    subplot(1, 2, 1);  % First subplot for the figure
    imagesc(R_Squared_Matrices_PLD{lm_1_idx});
    cb = colorbar; % Create the colorbar
    ylabel(cb, 'R^2', 'FontWeight', 'bold', 'FontSize', 11); % Label for colorbar
    title(['Pose Landmarks Differences [Hits vs Misses]'], 'FontSize', 12);
    subtitle(['Explained Variance [RMS] / [Landmark at ', num2str(Landmarks(lm_1_idx) * 1000), ' ms]'], 'FontSize', 12);
    xlabel('Participants', 'FontWeight', 'bold', 'FontSize', 11.5);
    ylabel('Features', 'FontWeight', 'bold', 'FontSize', 11.5);
    axis tight; % Adjusts the axis limits to the data
    xticks(1:numParticipants + 2);  % Number of participants + 2 for mean and NaN row
    xticklabels([arrayfun(@num2str, 1:numParticipants, 'UniformOutput', false), ' ', 'Mean']); % Participant numbers
    yticks(2:3:numFeatures + 2);  % Sparse labeling (every 3 features), +2 for gap and mean
    yticklabels(feature_names(2:3:end));  % Adjust the step as needed
    colormap('jet');  % Sets the colormap to 'jet' for better visibility of variance
    clim([0, max(R_Squared_Matrices_PLD{lm_1_idx}(:))]);  % Scale the color axis
    xtickangle(90);  % Rotate x-axis labels

    % If there's a second landmark, plot it. Otherwise, leave the second subplot blank
    if lm_2_idx <= length(Landmarks)
        subplot(1, 2, 2);  % Second subplot for the figure
        imagesc(R_Squared_Matrices_PLD{lm_2_idx});
        cb = colorbar; % Create the colorbar
        ylabel(cb, 'R^2', 'FontWeight', 'bold', 'FontSize', 11); % Label for colorbar
        title(['Pose Landmarks Differences [Hits vs Misses]'], 'FontSize', 12);
        subtitle(['Explained Variance [RMS] / [Landmark at ', num2str(Landmarks(lm_2_idx) * 1000), ' ms]'], 'FontSize', 12);
        xlabel('Participants', 'FontWeight', 'bold', 'FontSize', 11.5);
        ylabel('Features', 'FontWeight', 'bold', 'FontSize', 11.5);
        axis tight; % Adjusts the axis limits to the data
        xticks(1:numParticipants + 2);  % Number of participants + 2 for mean and NaN row
        xticklabels([arrayfun(@num2str, 1:numParticipants, 'UniformOutput', false), ' ', 'Mean']); % Participant numbers
        yticks(2:3:numFeatures + 2);  % Sparse labeling (every 3 features), +2 for gap and mean
        yticklabels(feature_names(2:3:end));  % Adjust the step as needed
        colormap('jet');  % Sets the colormap to 'jet' for better visibility of variance
        clim([0, max(R_Squared_Matrices_PLD{lm_2_idx}(:))]);  % Scale the color axis
        xtickangle(90);  % Rotate x-axis labels
    end

    % Save the figure (adjust the file name to show the correct landmark ranges)
    saveas(gcf, [outpath, '\\group_analysis\\', 'Feat_variance_PLD_Landmarks_', num2str(Landmarks(lm_1_idx) * 1000), '_', ...
        num2str(Landmarks(min(lm_2_idx, length(Landmarks))) * 1000), '_ms.jpg']);

end
