clc, clear, close all;

%% Significant motion in human pose across time 

% This code creates a matrix of significant features of human pose across
% time per participants, using the data os only significant differences
% between conditions of those participants who presented it.

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

% Initialize matrices to store all significant data, participant numbers, and time labels
all_significant_data_matrix = [];
all_significant_r2values_matrix = [];
all_participant_numbers = [];
all_time_labels = [];


%% Loop through each landmark

for t = 1:length(Landmarks)
    currentLandmark = Landmarks(t);
    landmark_ms = currentLandmark * 1000;  % Convert to milliseconds

    fprintf('Processing landmark at %d ms\n', landmark_ms);  % Debug message

    % Initialize temporary matrices to store significant p-values and participant numbers for this landmark
    sig_pvalues_for_landmark = [];
    participants_for_landmark = [];
    sig_r2values_for_landmark = [];

    % Loop over participants to load p-value matrices and find significant p-values
    for sub = 1:numParticipants
        participant = extractBefore(files(sub).name, '.xdf');
        out_subfold = [outpath, participant, '\\'];

        % Load the participant's p-value data for the current landmark
        pvalueFile = fullfile(out_subfold, ['Biserial_corr_PLD_', participant, '_', num2str(landmark_ms), '_ms.mat']);

        if isfile(pvalueFile)
            load(pvalueFile);  % Loads 'Biserial_corr_PLD' structure

            % Save feature names on first loop iteration
            feature_names = Biserial_corr_PLD.Features;

            % Get p-values and find if any are below 0.05
            pvalues = Biserial_corr_PLD.P_Value;  % Assuming P_Value contains p-values for all features
            r2values = Biserial_corr_PLD.R_Squared;
            significant = pvalues < 0.05;

            if any(significant)
                % Append entire column (all features) of significant p-values for this participant
                sig_pvalues_for_landmark = [sig_pvalues_for_landmark, pvalues];  % Concatenate columns
                sig_r2values_for_landmark = [sig_r2values_for_landmark, r2values];  % Concatenate columns
                participants_for_landmark = [participants_for_landmark, sub];  % Keep track of participant number
                all_time_labels = [all_time_labels, landmark_ms]; % Store the time label
            end
        else
            fprintf('File not found for participant: %s at %d ms\n', participant, landmark_ms);
        end
    end

    % Add data from this landmark to the main matrices
    if ~isempty(sig_pvalues_for_landmark)
        all_significant_data_matrix = [all_significant_data_matrix, sig_pvalues_for_landmark];
        all_significant_r2values_matrix = [all_significant_r2values_matrix, sig_r2values_for_landmark];
        all_participant_numbers = [all_participant_numbers, participants_for_landmark];
    end
end

% Rounding numbers for labels
all_time_labels = round(all_time_labels);

% Add an extra row for NaN (for distinguishing visual comparison)
all_significant_r2values_matrix(numFeatures + 1, size(all_significant_r2values_matrix, 2) + 1) = NaN;

% Calculate the mean across features per participant
all_significant_r2values_matrix(numFeatures + 2, :) = mean(all_significant_r2values_matrix(1:numFeatures, :), 1, 'omitnan');

% Calculate the mean across participants per feature
all_significant_r2values_matrix(:, size(all_significant_r2values_matrix, 2) + 1) = mean(all_significant_r2values_matrix(:, 1:end-1), 2, 'omitnan');

% Add 'Mean' to the feature names
feature_names{numFeatures + 2} = 'Mean';


%% Plotting

% Define custom colors for significance levels
darkBlue = [33, 113, 181] / 255;    % Dark blue for p < 0.001
mediumBlue = [107, 174, 214] / 255; % Medium blue for p < 0.01
lightBlue = [198, 219, 239] / 255;  % Light blue for p < 0.05
whiteColor = [1, 1, 1];             % White for p >= 0.05

% Create a colormap with four levels, arranged from most to least significant
newColormap = [darkBlue; mediumBlue; lightBlue; whiteColor];

% Set the desired angle for x-axis labels
time_angle = 90; % Adjust this value to your preference

% Define body part clusters and their indices
clusters = {'Head', 'Upper Body', 'Lower Body'};
cluster_indices = [1, 30, 60, numFeatures + 2]; % Example indices for cluster boundaries (adjust as needed)

figure('units', 'normalized', 'outerposition', [0 0 1 1]);

% Transform p-values into indices for color mapping
colorMatrix = ones(size(all_significant_data_matrix)) * 4; % Default to white (non-significant)
colorMatrix(all_significant_data_matrix < 0.05) = 3;       % Light blue for p < 0.05
colorMatrix(all_significant_data_matrix < 0.01) = 2;       % Medium blue for p < 0.01
colorMatrix(all_significant_data_matrix < 0.001) = 1;      % Dark blue for p < 0.001


% Main image - p-Values subplot
subplot(1, 2, 1);
% Display the color-coded matrix
imagesc(colorMatrix);

% Apply the custom colormap and configure the colorbar
colormap(gca, newColormap); % Keep colormap order from dark blue to white
cb = colorbar;
set(cb, 'Ticks', [1, 1.75, 2.5, 3.25], 'TickLabels', {'p < 0.001***', 'p < 0.01**', 'p < 0.05*', 'p \geq 0.05'});
ylabel(cb, 'p-Values', 'FontWeight', 'bold', 'FontSize', 11);
caxis([1 4]);  % Ensure color scale matches the index range

% Title and axis labels
title('Pose Landmarks Differences [Hits vs Misses]', 'FontWeight', 'bold', 'Position', [13.086861300871885,-6.445155362512551,17.000000000000014], 'FontSize', 12);
%subtitle('Significant Differences [p < 0.05*, p < 0.01**, p < 0.001***]', 'FontSize', 12);
%xlabel('Participants', 'FontWeight', 'bold', 'FontSize', 11.5);
ylabel('X, Y and Z Coordinates [Packets]', 'FontWeight', 'bold', 'FontSize', 11.5, 'Position', [-7.254325399349304,49.89019669556038,1]);

% Set y-axis ticks for feature names
yticks(2:3:numFeatures + 2);
yticklabels(feature_names(2:3:end));

% Add cluster labels on the y-axis
hold on;
for i = 1:numel(clusters)
    % Calculate the center position for the cluster label
    cluster_center = mean(cluster_indices(i:i+1));
    % Add the cluster label text
    text(-5.5, cluster_center, clusters{i}, 'FontSize', 11.5, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', 'Rotation', 90);

    % Add the cluster label text
    text(-5.5, cluster_center, clusters{i}, 'FontSize', 11.5, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', 'Rotation', 90);
end

% % Set x-axis ticks for participant numbers at the bottom
% xticks(1:length(all_participant_numbers));
% xticklabels(arrayfun(@num2str, all_participant_numbers, 'UniformOutput', false));
% xtickangle(90);
% %set(gca, 'FontSize', 8); % Smaller font size for participant labels

% Set x-axis ticks for participant numbers at the bottom with "sub_" prefix
xticks(1:length(all_participant_numbers));
xticklabels(arrayfun(@(x) sprintf('sub-%d', x), all_participant_numbers, 'UniformOutput', false));
xtickangle(90);
set(gca, 'XAxisLocation', 'top'); % Move x-axis to the top

% Manually add time labels at the top, aligning with columns
for i = 1:length(all_time_labels)
    text(i, 104, sprintf('%d ms', all_time_labels(i)), 'HorizontalAlignment', 'center', 'Rotation', time_angle, 'FontSize', 8);
end

% % Combine participant numbers and time labels for x-axis ticks
% combined_labels = arrayfun(@(p, t) sprintf('sub-%d\nat %d ms', p, t), all_participant_numbers, all_time_labels, 'UniformOutput', false);
%
% % Set x-axis ticks for combined labels
% xticks(1:length(all_participant_numbers));
% xticklabels(combined_labels);
% xtickangle(50);

% Manually add rotated "Mean" label at the bottom of the last column
text(-3.5, 103, 'Participants at ', ...
    'HorizontalAlignment', 'center', 'FontSize', 11.5, 'FontWeight', 'bold');



% Root Mean Square subplot - R² values
subplot(1, 2, 2);
imagesc(all_significant_r2values_matrix);
c2 = colorbar; % Create the colorbar
ylabel(c2, 'R^2', 'FontWeight', 'bold', 'FontSize', 11); % Label for colorbar
title('Pose Landmarks Differences [Hits vs Misses]', 'FontWeight', 'bold', 'Position', [13.792743653813059,-6.77442365519547,17.000000000000014], 'FontSize', 12); % Shift title up
%subtitle('Explained Variance [RMS]', 'Position', [13.788571225079686,-4.557333778817259,16.000000000000014], 'FontSize', 12);
%xlabel('Participants', 'FontWeight', 'bold', 'FontSize', 11.5);
%ylabel('X, Y and Z Coordinates [Packets]', 'FontWeight', 'bold', 'FontSize', 11.5, 'Position', [-7.254325399349304,49.89019669556038,1]);
colormap(gca, 'jet'); % Apply jet colormap to the second subplot
caxis([0 1]);
yticks(2:3:numFeatures + 2);
yticklabels(feature_names(2:3:end));
clim([0, max(all_significant_r2values_matrix(:))]);

% Set x-axis ticks for participant numbers at the bottom with "sub_" prefix
xticks(1:length(all_participant_numbers));
xticklabels(arrayfun(@(x) sprintf('sub-%d', x), all_participant_numbers, 'UniformOutput', false));
xtickangle(90);
set(gca, 'XAxisLocation', 'top'); % Move x-axis to the top

% Manually add time labels at the top, aligning with columns
for i = 1:length(all_time_labels)
    text(i, 105, sprintf('%d ms', all_time_labels(i)), 'HorizontalAlignment', 'center', 'Rotation', time_angle, 'FontSize', 8);
end


% Manually add rotated "Mean" label at the bottom of the last column
text(-2.8, 106, 'Participants at ', ...
    'HorizontalAlignment', 'center', 'FontSize', 11.5, 'FontWeight', 'bold');

[r2_max_landmarks, top_landmarks_indices] = maxk(all_significant_r2values_matrix(:, end), 4);
[r2_max_time, top_time_indices] = maxk(all_significant_r2values_matrix(end, :), 3);

saveas(gcf, [outpath, '\\group_analysis\\', 'Evolution of Pose', '.jpg']);


%% R² values matrix

figure('units', 'normalized', 'outerposition', [0 0 1 1]);
subplot(1, 2, 1);
imagesc(all_significant_r2values_matrix);
c2 = colorbar; % Create the colorbar
ylabel(c2, 'R^2', 'FontWeight', 'bold', 'FontSize', 11); % Label for colorbar
%title('Pose Landmarks Differences [Hits vs Misses]', 'FontWeight', 'bold', 'Position', [13.792743653813059,-6.77442365519547,17.000000000000014], 'FontSize', 12); % Shift title up
%subtitle('Explained Variance [RMS]', 'Position', [13.788571225079686,-4.557333778817259,16.000000000000014], 'FontSize', 12);
%xlabel('Participants', 'FontWeight', 'bold', 'FontSize', 11.5);
ylabel('X, Y and Z Coordinates [Packets]', 'FontWeight', 'bold', 'FontSize', 11.5, 'Position', [-9.129325399349304,50.37233955270325,1]);
colormap(gca, 'jet'); % Apply jet colormap to the second subplot
caxis([0 1]);
yticks(2:3:numFeatures + 2);
yticklabels(feature_names(2:3:end));
clim([0, max(all_significant_r2values_matrix(:))]);

% Set x-axis ticks for participant numbers at the bottom with "sub_" prefix
xticks(1:length(all_participant_numbers));
xticklabels(arrayfun(@(x) sprintf('sub-%d', x), all_participant_numbers, 'UniformOutput', false));
xtickangle(90);
set(gca, 'XAxisLocation', 'top'); % Move x-axis to the top


% Add cluster labels on the y-axis
hold on;
for i = 1:numel(clusters)
    % Calculate the center position for the cluster label
    cluster_center = mean(cluster_indices(i:i+1));
    % Add the cluster label text
    text(-8, cluster_center, clusters{i}, 'FontSize', 11.5, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', 'Rotation', 90);

    % Add the cluster label text
    text(-8, cluster_center, clusters{i}, 'FontSize', 11.5, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', 'Rotation', 90);
end


% Manually add time labels at the top, aligning with columns
for i = 1:length(all_time_labels)
    text(i, 106, sprintf('%d ms', all_time_labels(i)), 'HorizontalAlignment', 'center', 'Rotation', time_angle, 'FontSize', 8);
end

% Add rotated "Mean" label at the bottom of the last column
mean_label_position_x = length(all_time_labels) + 2; % Position for the last column
mean_label_position_y = 106; % Adjust the vertical position slightly below the time labels
text(mean_label_position_x, mean_label_position_y, 'Mean', ...
    'HorizontalAlignment', 'center', 'Rotation', 90, ...
    'FontSize', 11.5);

% Manually add rotated "Mean" label at the bottom of the last column
text(-4, 107, 'Participants at ', ...
    'HorizontalAlignment', 'center', 'FontSize', 11.5, 'FontWeight', 'bold');

[r2_max_landmarks, top_landmarks_indices] = maxk(all_significant_r2values_matrix(:, end), 4);
[r2_max_time, top_time_indices] = maxk(all_significant_r2values_matrix(end, :), 3);

save_fig(gcf,[outpath, '\\group_analysis\\',], 'Evolution of Pose-Explainded variance','fontsize', 9);


%% P-values matrix

figure('units', 'normalized', 'outerposition', [0 0 1 1]);

% Transform p-values into indices for color mapping
colorMatrix = ones(size(all_significant_data_matrix)) * 4; % Default to white (non-significant)
colorMatrix(all_significant_data_matrix < 0.05) = 3;       % Light blue for p < 0.05
colorMatrix(all_significant_data_matrix < 0.01) = 2;       % Medium blue for p < 0.01
colorMatrix(all_significant_data_matrix < 0.001) = 1;      % Dark blue for p < 0.001


% Main image - p-Values subplot
subplot(1, 2, 1);
% Display the color-coded matrix
imagesc(colorMatrix);

% Apply the custom colormap and configure the colorbar
colormap(gca, newColormap); % Keep colormap order from dark blue to white
cb = colorbar;
set(cb, 'Ticks', [1, 1.75, 2.5, 3.25], 'TickLabels', {'p < 0.001***', 'p < 0.01**', 'p < 0.05*', 'p \geq 0.05'});
ylabel(cb, 'p-Values', 'FontWeight', 'bold', 'FontSize', 11);
caxis([1 4]);  % Ensure color scale matches the index range

% Title and axis labels
%title('Pose Landmarks Differences [Hits vs Misses]', 'FontWeight', 'bold', 'Position', [13.086861300871885,-6.445155362512551,17.000000000000014], 'FontSize', 12);
%subtitle('Significant Differences [p < 0.05*, p < 0.01**, p < 0.001***]', 'FontSize', 12);
%xlabel('Participants', 'FontWeight', 'bold', 'FontSize', 11.5);
ylabel('X, Y and Z Coordinates [Packets]', 'FontWeight', 'bold', 'FontSize', 11.5, 'Position', [-9.129325399349304,50.37233955270325,1]); %

% Set y-axis ticks for feature names
yticks(2:3:numFeatures + 2);
yticklabels(feature_names(2:3:end));

% Add cluster labels on the y-axis
hold on;
for i = 1:numel(clusters)
    % Calculate the center position for the cluster label
    cluster_center = mean(cluster_indices(i:i+1));
    % Add the cluster label text
    text(-8, cluster_center, clusters{i}, 'FontSize', 11.5, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', 'Rotation', 90);

    % Add the cluster label text
    text(-8, cluster_center, clusters{i}, 'FontSize', 11.5, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', 'Rotation', 90);
end

% % Set x-axis ticks for participant numbers at the bottom
% xticks(1:length(all_participant_numbers));
% xticklabels(arrayfun(@num2str, all_participant_numbers, 'UniformOutput', false));
% xtickangle(90);
% %set(gca, 'FontSize', 8); % Smaller font size for participant labels

% Set x-axis ticks for participant numbers at the bottom with "sub_" prefix
xticks(1:length(all_participant_numbers));
xticklabels(arrayfun(@(x) sprintf('sub-%d', x), all_participant_numbers, 'UniformOutput', false));
xtickangle(90);
set(gca, 'XAxisLocation', 'top'); % Move x-axis to the top

% Manually add time labels at the top, aligning with columns
for i = 1:length(all_time_labels)
    text(i, 104, sprintf('%d ms', all_time_labels(i)), 'HorizontalAlignment', 'center', 'Rotation', time_angle, 'FontSize', 8);
end

% % Combine participant numbers and time labels for x-axis ticks
% combined_labels = arrayfun(@(p, t) sprintf('sub-%d\nat %d ms', p, t), all_participant_numbers, all_time_labels, 'UniformOutput', false);
%
% % Set x-axis ticks for combined labels
% xticks(1:length(all_participant_numbers));
% xticklabels(combined_labels);
% xtickangle(50);

% Manually add rotated "Mean" label at the bottom of the last column
text(-3.5, 104, 'Participants at ', ...
    'HorizontalAlignment', 'center', 'FontSize', 11.5, 'FontWeight', 'bold');

save_fig(gcf,[outpath, '\\group_analysis\\',], 'Evolution of Pose','fontsize', 9);


%%