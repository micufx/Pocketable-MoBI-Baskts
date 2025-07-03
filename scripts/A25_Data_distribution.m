clc, clear, close all;

%% Data distribution analysis

% This code creates a plot comparing the distribution of the RP compared
% betweeen conditions across time.

% Miguel Contreras-Altamirano, 2025


%% EEG condition analysis

mainpath = 'C:\Users\micua\Desktop\eeglab2023.0\'; % eeglab folder
path = 'C:\Users\micua\OneDrive - Benemérita Universidad Autónoma de Puebla\NCP_Basketball\MediaPipe\';
outpath = 'C:\\Users\\micua\\OneDrive - Benemérita Universidad Autónoma de Puebla\\Oldenburg_University\\Thesis\\data_hoops\\';
files = dir( fullfile( path,'\*.xdf')); % listing data sets

%% Loading data 
% Load Grand Average EEG data for hits and misses
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab; % Open eeglab
EEG_hits = pop_loadset('filename', ['Grand_avg_hits.set'], 'filepath', outpath); % Grand average hits
eeglab redraw;

EEG_misses = pop_loadset('filename', ['Grand_avg_misses.set'], 'filepath', outpath); % Grand average misses
eeglab redraw;

%% Extracting mean and SE

% Define bins and Cz channel
binEdges = -1500:100:0; % 100 ms bins from -1500 ms to 0 ms
nBins = length(binEdges) - 1;
chanIdx = find(strcmp({EEG_hits.chanlocs.labels}, 'Cz')); % Find Cz channel

% Preallocate arrays for bin-wise mean amplitudes and SEs
mean_hits = zeros(1, nBins);
se_hits = zeros(1, nBins);
mean_misses = zeros(1, nBins);
se_misses = zeros(1, nBins);

% Calculate mean amplitudes and SEs for hits and misses in each bin
for b = 1:nBins
    % Get indices for the current bin
    idxStart = find(EEG_hits.times >= binEdges(b), 1, 'first');
    idxEnd = find(EEG_hits.times < binEdges(b + 1), 1, 'last');
    
    % Hits
    data_hits = squeeze(EEG_hits.data(chanIdx, idxStart:idxEnd, :)); % Extract data for this bin
    grand_mean_hits(b) = mean(data_hits(:)); % Mean across time and participants
    se_hits(b) = std(mean(data_hits, 1), 0, 2) / sqrt(size(data_hits, 2)); % SE across participants
    
    % Misses
    data_misses = squeeze(EEG_misses.data(chanIdx, idxStart:idxEnd, :)); % Extract data for this bin
    grand_mean_misses(b) = mean(data_misses(:)); % Mean across time and participants
    se_misses(b) = std(mean(data_misses, 1), 0, 2) / sqrt(size(data_misses, 2)); % SE across participants
end

% Define bin labels
bin_labels = arrayfun(@(x, y) sprintf('%d:%d', x, y), binEdges(1:end-1), binEdges(2:end), 'UniformOutput', false);


%% Plot distribution comparison (Mean comparison across participants)

% Create figure
figure('units','normalized','outerposition', [0 0 1 1]);
hold on;

% Define the number of bins
nBins = numel(bin_labels);

% Calculate the width for each bar group
groupWidth = min(0.8, nBins/(nBins + 1.5));

% Plot bars and error bars for each bin
for i = 1:nBins
    % Set the positions for hits and misses bars in each bin
    positions_hits = i - groupWidth / 4;
    positions_misses = i + groupWidth / 4;
    
    % Plot bars for hits
    bar(positions_hits, grand_mean_hits(i), groupWidth / 4, 'FaceColor', [0 .7 .7]);
    
    % Plot bars for misses
    bar(positions_misses, grand_mean_misses(i), groupWidth / 4, 'FaceColor', 'r');
    
    % Error bars for hits
    errorbar(positions_hits, grand_mean_hits(i), se_hits(i), 'k', 'linestyle', 'none');
    
    % Error bars for misses
    errorbar(positions_misses, grand_mean_misses(i), se_misses(i), 'k', 'linestyle', 'none');
end

% Customizing the plot
set(gca, 'xtick', 1:nBins, 'xticklabel', bin_labels, 'XTickLabelRotation', 30, 'FontSize', 11);
xlabel('Time [ms]', 'FontSize', 12);
ylabel('Amplitude [µV]', 'FontSize', 12);
%title('Grand Average Mean Amplitude Over Time', 'FontSize', 12);
%subtitle('Readiness Potential [Cz]', 'FontSize', 12);
legend({'Hits', 'Misses'}, 'Location', 'Best', 'FontSize', 10, 'Position', [0.163177083659296,0.187675611350757,0.048437499348074,0.040314135064629]);
grid on;

hold off;


%% Saving figures
saveas(gcf, [outpath, '\\group_analysis\\','box_mean_comparison', '.jpg']); % Save the figure as a PNG image
save_fig(gcf,[outpath, '\\group_analysis\\',], 'box_mean_comparison', 'fontsize', 12);

%%
