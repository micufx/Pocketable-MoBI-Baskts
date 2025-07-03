clc, clear, close all;

%% Explained variance of the Readiness Potential 

% This code calculates the explained variance of RP features between 
% conditions.

% Miguel Contreras-Altamirano, 2025


%% Settings data

mainpath = 'C:\Users\micua\Desktop\eeglab2023.0\'; % eeglab folder
path = 'C:\Users\micua\OneDrive - Benemérita Universidad Autónoma de Puebla\NCP_Basketball\MediaPipe\';
outpath = 'C:\\Users\\micua\\OneDrive - Benemérita Universidad Autónoma de Puebla\\Oldenburg_University\\Thesis\\data_hoops\\';
files = dir(fullfile(path, '\*.xdf')); % listing data sets

channels_RP_top = {'FC1', 'Fz', 'FC2'};   % Channels for top row (frontal)
channels_RP_bottom = {'C3', 'Cz', 'C4'};  % Channels for bottom row (central)

% Bin edges for 100 ms bins from -1500 ms to 0 ms
binEdges = -1500:100:0;

% Generate bin labels
bin_labels = arrayfun(@(s, e) sprintf('%d:%d', s, e), binEdges(1:end-1), binEdges(2:end), 'UniformOutput', false);

%% Process for both sets of channels

% Initialize cell arrays to hold matrices for both sets of channels
R_Squared_Matrices_RP_bottom = cell(1, length(channels_RP_bottom));
R_Squared_Matrices_RP_top = cell(1, length(channels_RP_top));

% This variable will hold bin numbers as feature names
bin_numbers = arrayfun(@(x) sprintf('%d', x), 1:15, 'UniformOutput', false);

% Process Readiness Potential for both sets of channels
for ch = 1:length(channels_RP_bottom)
    R_Squared_Matrices_RP_bottom{ch} = process_channels(files, channels_RP_bottom{ch}, outpath, 'RP', bin_numbers);
end

for ch = 1:length(channels_RP_top)
    R_Squared_Matrices_RP_top{ch} = process_channels(files, channels_RP_top{ch}, outpath, 'RP', bin_numbers);
end

%% Visualization of features variance across participants

% figure('units', 'normalized', 'outerposition', [0 0 1 1]);
% 
% % Plotting for top row (Frontal channels: FC1, Fz, FC2)
% for ch = 1:length(channels_RP_top)
%     subplot(2, 3, ch);
%     imagesc(R_Squared_Matrices_RP_top{ch});
%     cb = colorbar; % Create the colorbar
%     ylabel(cb, 'R^2', 'FontWeight', 'bold', 'FontSize', 11); % Label for colorbar
%     title(['ERP Comparison at ', channels_RP_top{ch}], 'FontSize', 12);
%     subtitle('[Hits vs Misses]', 'FontSize', 12);
%     xlabel('Participants', 'FontWeight', 'bold', 'FontSize', 11.5);
%     ylabel('Mean Bins of 100 ms', 'FontWeight', 'bold', 'FontSize', 11.5);
%     axis tight;
%     xticks(1:length(files) + 2);  % Number of participants + 2 for padding/mean
%     xticklabels([arrayfun(@num2str, 1:length(files), 'UniformOutput', false), ' ', 'Mean']);
%     yticks(1:length(bin_numbers) + 2);  % Number of bins + separator + mean row
%     yticklabels([bin_numbers, ' ', 'Mean']);  % Use bin numbers and add "Mean" for the last row
%     colormap('jet');
%     clim([0, max(R_Squared_Matrices_RP_top{ch}(:))]);
% end
% 
% % Plotting for bottom row (Central channels: C3, Cz, C4)
% for ch = 1:length(channels_RP_bottom)
%     subplot(2, 3, ch + 3);
%     imagesc(R_Squared_Matrices_RP_bottom{ch});
%     cb = colorbar; % Create the colorbar
%     ylabel(cb, 'R^2', 'FontWeight', 'bold', 'FontSize', 11); % Label for colorbar
%     title(['ERP Comparison at ', channels_RP_bottom{ch}], 'FontSize', 12);
%     subtitle('[Hits vs Misses]', 'FontSize', 12);
%     xlabel('Participants', 'FontWeight', 'bold', 'FontSize', 11.5);
%     ylabel('Mean Bins of 100 ms', 'FontWeight', 'bold', 'FontSize', 11.5);
%     axis tight;
%     xticks(1:length(files) + 2);  % Number of participants + 2 for padding/mean
%     xticklabels([arrayfun(@num2str, 1:length(files), 'UniformOutput', false), ' ', 'Mean']);
%     yticks(1:length(bin_numbers) + 2);  % Number of bins + separator + mean row
%     yticklabels([bin_numbers, ' ', 'Mean']);  % Use bin numbers and add "Mean" for the last row
%     colormap('jet');
%     clim([0, max(R_Squared_Matrices_RP_bottom{ch}(:))]);
% end

% Save the figure
%ROI = 'fronto-central';
% saveas(gcf, [outpath, '\\group_analysis\\', 'Feat_variance_', ROI, '.jpg']);


%% Visualization of features variance across participants

figure('units', 'normalized', 'outerposition', [0 0 1 1]);

% Set the desired angle for x-axis labels
xLabelAngle = 45; % Adjust this value to your preference

% Plotting for top row (Frontal channels: FC1, Fz, FC2)
for ch = 1:length(channels_RP_top)
    subplot(2, 3, ch);
    imagesc(R_Squared_Matrices_RP_top{ch}');
    cb = colorbar; % Create the colorbar
    ylabel(cb, 'R^2', 'FontWeight', 'bold', 'FontSize', 11); % Label for colorbar
    title([channels_RP_top{ch}], 'FontSize', 12); % 'ERP Comparison at ', 
    %subtitle('[Hits vs Misses]', 'FontSize', 12);
    xlabel('Time window mean [ms]', 'FontWeight', 'bold', 'FontSize', 11.5);
    ylabel('Participants', 'FontWeight', 'bold', 'FontSize', 11.5);
    axis tight;

    % Adjust X and Y ticks and labels
    xticks(1:length(bin_labels) + 2);
    xticklabels([bin_labels, ' ', 'Mean']); % Add empty layer and mean
    yticks(1:length(files) + 2);
    yticklabels([arrayfun(@(i) sprintf('%02d', i), 1:length(files), 'UniformOutput', false), ' ', 'Mean']); % Add empty layer and mean

    % Rotate x-axis labels
    xtickangle(xLabelAngle);

    colormap('jet');
    clim([0, max(R_Squared_Matrices_RP_top{ch}(:))]);
end

% Plotting for bottom row (Central channels: C3, Cz, C4)
for ch = 1:length(channels_RP_bottom)
    subplot(2, 3, ch + 3);
    imagesc(R_Squared_Matrices_RP_bottom{ch}');
    cb = colorbar; % Create the colorbar
    ylabel(cb, 'R^2', 'FontWeight', 'bold', 'FontSize', 11); % Label for colorbar
    title([channels_RP_bottom{ch}], 'FontSize', 12); % 'ERP Comparison at ', 
    %subtitle('[Hits vs Misses]', 'FontSize', 12);
    xlabel('Time window mean [ms]', 'FontWeight', 'bold', 'FontSize', 11.5);
    ylabel('Participants', 'FontWeight', 'bold', 'FontSize', 11.5);
    axis tight;

    % Adjust X and Y ticks and labels
    xticks(1:length(bin_labels) + 2);
    xticklabels([bin_labels, ' ', 'Mean']); % Add empty layer and mean
    yticks(1:length(files) + 2);
    yticklabels([arrayfun(@(i) sprintf('%02d', i), 1:length(files), 'UniformOutput', false), ' ', 'Mean']); % Add empty layer and mean

    % Rotate x-axis labels
    xtickangle(xLabelAngle);

    colormap('jet');
    clim([0, max(R_Squared_Matrices_RP_bottom{ch}(:))]);
end

% Save the figure
ROI = 'fronto-central';
saveas(gcf, [outpath, '\\group_analysis\\', 'Feat_variance_', ROI, '.png']);
%save_fig(gcf,[outpath, '\\group_analysis\\',], ['Feat_variance_', ROI]);



%% Visualization of features (single matrix Fz)

% figure('units', 'normalized', 'outerposition', [0 0 1 1]);
% 
% % Set the desired angle for x-axis labels
% xLabelAngle = 45; % Adjust this value to your preference
% 
% % Plotting for top row (Frontal channels: FC1, Fz, FC2)
% for ch = 1:length(channels_RP_top)
%     subplot(2, 3, [2, 5, 3, 6]);  % Center row spanning all columns
%     imagesc(R_Squared_Matrices_RP_top{2}');
%     cb = colorbar; % Create the colorbar
%     ylabel(cb, 'R^2', 'FontWeight', 'bold', 'FontSize', 11); % Label for colorbar
%     title(['ERP Comparison at ', channels_RP_top{2}], 'FontSize', 12);
%     subtitle('[Hits vs Misses]', 'FontSize', 12);
%     xlabel('Time window mean [ms]', 'FontWeight', 'bold', 'FontSize', 11.5);
%     ylabel('Participants', 'FontWeight', 'bold', 'FontSize', 11.5);
%     axis tight;
% 
%     % Adjust X and Y ticks and labels
%     xticks(1:length(bin_labels) + 2);
%     xticklabels([bin_labels, ' ', 'Mean']); % Add empty layer and mean
%     yticks(1:length(files) + 2);
%     yticklabels([arrayfun(@(i) sprintf('%02d', i), 1:length(files), 'UniformOutput', false), ' ', 'Mean']); % Add empty layer and mean
% 
%     % Rotate x-axis labels
%     xtickangle(xLabelAngle);
% 
%     colormap('jet');
%     clim([0, max(R_Squared_Matrices_RP_top{2}(:))]);
% end


% % Save the figure
% ROI = 'Fz';
% saveas(gcf, [outpath, '\\group_analysis\\', 'Feat_variance_', ROI, '.jpg']);
% save_fig(gcf,[outpath, '\\group_analysis\\',], ['Feat_variance_', ROI]);

%% Visualization of features (single matrix Cz)

% figure('units', 'normalized', 'outerposition', [0 0 1 1]);
% 
% % Set the desired angle for x-axis labels
% xLabelAngle = 45; % Adjust this value to your preference
% 
% % Plotting for bottom row (Central channels: C3, Cz, C4)
% for ch = 1:length(channels_RP_bottom)
%     subplot(2, 3, [2, 5, 3, 6]);
%     imagesc(R_Squared_Matrices_RP_bottom{2}');
%     cb = colorbar; % Create the colorbar
%     ylabel(cb, 'R^2', 'FontWeight', 'bold', 'FontSize', 11); % Label for colorbar
%     title(['ERP Comparison at ', channels_RP_bottom{2}], 'FontSize', 12);
%     subtitle('[Hits vs Misses]', 'FontSize', 12);
%     xlabel('Time window mean [ms]', 'FontWeight', 'bold', 'FontSize', 11.5);
%     ylabel('Participants', 'FontWeight', 'bold', 'FontSize', 11.5);
%     axis tight;
% 
%     % Adjust X and Y ticks and labels
%     xticks(1:length(bin_labels) + 2);
%     xticklabels([bin_labels, ' ', 'Mean']); % Add empty layer and mean
%     yticks(1:length(files) + 2);
%     yticklabels([arrayfun(@(i) sprintf('%02d', i), 1:length(files), 'UniformOutput', false), ' ', 'Mean']); % Add empty layer and mean
% 
%     % Rotate x-axis labels
%     xtickangle(xLabelAngle);
% 
%     colormap('jet');
%     clim([0, max(R_Squared_Matrices_RP_bottom{2}(:))]);
% end


% % Save the figure
% ROI = 'Cz';
% saveas(gcf, [outpath, '\\group_analysis\\', 'Feat_variance_', ROI, '.jpg']);
% save_fig(gcf,[outpath, '\\group_analysis\\',], ['Feat_variance_', ROI]);


%% Visualization of features (single matrix - Fz)

figure('units', 'normalized', 'outerposition', [0 0 1 1]);

% Set the desired angle for x-axis labels
xLabelAngle = 45; % Adjust this value to your preference

% Plotting for top row (Frontal channels: FC1, Fz, FC2)
for ch = 1:length(channels_RP_top)
    subtightplot(2, 3, 2);  % Center row spanning all columns
    imagesc(R_Squared_Matrices_RP_top{2}');
    cb = colorbar; % Create the colorbar
    ylabel(cb, 'R^2', 'FontWeight', 'bold', 'FontSize', 11); % Label for colorbar
    %title(['ERP Comparison at ', channels_RP_top{2}], 'FontSize', 12);
    %subtitle('[Hits vs Misses]', 'FontSize', 12);
    xlabel('Time window mean [ms]', 'FontWeight', 'bold', 'FontSize', 11.5);
    ylabel('Participants', 'FontWeight', 'bold', 'FontSize', 11.5);
    axis tight;

    % Adjust X and Y ticks and labels
    xticks(1:length(bin_labels) + 2);
    xticklabels([bin_labels, ' ', 'Mean']); % Add empty layer and mean
    yticks(1:length(files) + 2);
    yticklabels([arrayfun(@(i) sprintf('%02d', i), 1:length(files), 'UniformOutput', false), ' ', 'Mean']); % Add empty layer and mean

    % Rotate x-axis labels
    xtickangle(xLabelAngle);

    colormap('jet');
    clim([0, max(R_Squared_Matrices_RP_top{2}(:))]);
end


% Save the figure
ROI = 'Fz_tight';
saveas(gcf, [outpath, '\\group_analysis\\', 'Feat_variance_', ROI, '.jpg']);

save_fig(gcf,[outpath, '\\group_analysis\\'], ['Feat_variance_', ROI],...
    'fontsize', 10, ...
    'figsize', [35, 20], ...
    'figtypes', {'.png', '.svg'},...
    'dpi', 600);


%% Visualization of features (single matrix Fz)

% figure('units', 'normalized', 'outerposition', [0 0 1 1]);
% 
% % Set the desired angle for x-axis labels
% xLabelAngle = 45; % Adjust this value to your preference
% 
% % Plotting for bottom row (Central channels: C3, Cz, C4)
% for ch = 1:length(channels_RP_bottom)
%     subtightplot(2, 3, 2);
%     imagesc(R_Squared_Matrices_RP_bottom{2}');
%     cb = colorbar; % Create the colorbar
%     ylabel(cb, 'R^2', 'FontWeight', 'bold', 'FontSize', 11); % Label for colorbar
%     title(['ERP Comparison at ', channels_RP_bottom{2}], 'FontSize', 12);
%     subtitle('[Hits vs Misses]', 'FontSize', 12);
%     xlabel('Time window mean [ms]', 'FontWeight', 'bold', 'FontSize', 11.5);
%     ylabel('Participants', 'FontWeight', 'bold', 'FontSize', 11.5);
%     axis tight;
% 
%     % Adjust X and Y ticks and labels
%     xticks(1:length(bin_labels) + 2);
%     xticklabels([bin_labels, ' ', 'Mean']); % Add empty layer and mean
%     yticks(1:length(files) + 2);
%     yticklabels([arrayfun(@(i) sprintf('%02d', i), 1:length(files), 'UniformOutput', false), ' ', 'Mean']); % Add empty layer and mean
% 
%     % Rotate x-axis labels
%     xtickangle(xLabelAngle);
% 
%     colormap('jet');
%     clim([0, max(R_Squared_Matrices_RP_bottom{2}(:))]);
% end
% 
% 
% % Save the figure
% ROI = 'Cz_tight';
% saveas(gcf, [outpath, '\\group_analysis\\', 'Feat_variance_', ROI, '.jpg']);
% save_fig(gcf,[outpath, '\\group_analysis\\',], ['Feat_variance_', ROI], 'fontsize', 10);


%% Local function definition

function R_Squared_Matrix = process_channels(files, channel, outpath, condition, bin_numbers)
numParticipants = length(files); % Number of participants
numBins = length(bin_numbers); % Number of bins to retain

% Initialize a matrix to hold R_Squared values for all features across all participants
R_Squared_Matrix = nan(numBins + 2, numParticipants + 2); % +2 rows for white separator and mean, +1 column for mean across participants

for sub = 1:length(files)
    participant = extractBefore(files(sub).name, '.xdf');
    out_subfold = [outpath, participant, '\\'];
    load([out_subfold, 'Biserial_corr_', condition, '_', channel, '_', participant, '.mat']);

    % Retain only the mean features (first 15 bins)
    R_Squared_Matrix(1:numBins, sub) = Biserial_corr_RP.R_Squared(1:numBins);

    % Calculate the overall mean for this participant (mean across bins)
    R_Squared_Matrix(numBins + 2, sub) = mean(R_Squared_Matrix(1:numBins, sub), 'omitnan');
end

% Calculate the mean across participants for each bin
R_Squared_Matrix(1:numBins, end) = mean(R_Squared_Matrix(1:numBins, 1:end-1), 2, 'omitnan');

% Add an extra mean value in the bottom right cell (mean of all means)
R_Squared_Matrix(numBins + 2, end) = mean(R_Squared_Matrix(numBins + 2, 1:end-1), 'omitnan');

% Add NaN values in the separator row and column to render them as white
R_Squared_Matrix(numBins + 1, :) = NaN;
R_Squared_Matrix(:, numParticipants + 1) = NaN;
end
