clc, clear, close all;

%% Parameterization and testing of the Readiness Potential

% This code performs non-parametric test Wilcoxon signed-rank test agains
% zero to check significant changes from baseline in the grand average RP.

% Miguel Contreras-Altamirano, 2025

%% EEG condition analysis

mainpath = 'C:\Users\micua\Desktop\eeglab2023.0\'; % eeglab folder
path = 'C:\Users\micua\OneDrive - Benemérita Universidad Autónoma de Puebla\NCP_Basketball\MediaPipe\';
outpath = 'C:\\Users\\micua\\OneDrive - Benemérita Universidad Autónoma de Puebla\\Oldenburg_University\\Thesis\\data_hoops\\';
files = dir( fullfile( path,'\*.xdf')); % listing data sets

nochans = {'AccX','AccY','AccZ','GyroX','GyroY','GyroZ', ... % channels to be ignored
    'QuatW','QuatX','QuatY','QuatZ'};

conditions = {'hit', 'miss'};
num_conditions = 2; % (Conditions: 1=hit 2=miss)

%% Loading data

% Import EEG processed data
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % Open eeglab
EEG = pop_loadset('filename',['Grand_avg_all', '.set'],'filepath', outpath); % Loading set file


%% Features

% Define your bins here, as before
binEdges = [-1500, -1400, -1300, -1200, -1100, -1000, -900, -800, -700, -600, -500, -400, -300, -200, -100, 0];
nBins = length(binEdges) - 1; % Number of bins
nEpochs_hits = size(EEG.data, 3);
nEpochs_misses = size(EEG.data, 3);

% Generate column names for each bin
columnNamesMean = cell(1, nBins);
for b = 1:nBins
    columnNamesMean{b} = ['Bin_' num2str(b) '_Mean'];
end

% Initialize the tables for hit and miss conditions
all_means = cell(length(EEG.chanlocs), 1);

% Loop through each channel and each condition
for chan_idx = 1:length(EEG.chanlocs)

    all_means{chan_idx} = zeros(nEpochs_hits, nBins); % Initialize the mean values (all conditions)

    % Loop over each bin
    for b = 1:nBins
        % Find the time indices for the current bin
        idxStart = find(EEG.times >= binEdges(b), 1, 'first');
        idxEnd = find(EEG.times < binEdges(b + 1), 1, 'last');

        % Calculate the mean for each trial in the current bin for all
        all_data = EEG.data(chan_idx, idxStart:idxEnd, :);
        all_means{chan_idx}(:, b) = squeeze(mean(all_data, 2)); % Mean across time for each trial

    end
end

% Now you have a cell array where each cell contains a 2D matrix of trials x bins for each channel
% You can now run your t-tests on these matrices


%% T-test per mean bin (All channels)

chan_label = {EEG.chanlocs.labels};

% Initialize matrices for p-values, z-values, and test labels
p_values_matrix = zeros(length(EEG.chanlocs), nBins);
z_values_matrix = zeros(length(EEG.chanlocs), nBins);
test_labels_matrix = strings(length(EEG.chanlocs), nBins);
normality_p_values = zeros(length(EEG.chanlocs), nBins);

% Loop through each channel and each condition
for chan_idx = 1 : length(EEG.chanlocs)

    p_values = zeros(1, nBins); % Initialize array for p-values for each bin
    z_values = zeros(1, nBins); % Initialize array for z-values for each bin

    % Perform t-tests for each bin
    for b = 1:nBins

        % Extract observations for the current channel and bin
        observations = all_means{chan_idx}(:, b);

        % Normality test
        [~, p_shapiro] = lillietest(observations);
        normality_p_values(chan_idx, b) = p_shapiro;

        % Perform the t-test or non-parametric test based on the normality result
        if p_shapiro > 0.05 && nBins < 1 % Impossible assumption, so it always performs non-parametric test to be on the safe side
            % Normality assumption not violated, use One-Sample T-Test
            [h, p, ci, stats] = ttest(observations, 0);  % Test against zero
            p_values(b) = p;

            % Store the p-values for this channel in the matrix
            p_values_matrix(chan_idx, :) = p_values;

            test_labels_matrix(chan_idx, b) = "T-test";
            disp(['Parametric test used for channel [', chan_label{chan_idx}, '] bin [', num2str(b), ']: [T-test]']);

        else

            % Normality assumption violated, use a non-parametric test
            [p, h, stats] = signrank(observations, 0);  % Wilcoxon signed-rank test
            p_values(b) = p;
            z_values(b) = stats.zval;

            % Store the p-values and z-values for this channel in the matrix
            p_values_matrix(chan_idx, :) = p_values;
            z_values_matrix(chan_idx, :) = z_values;

            test_labels_matrix(chan_idx, b) = "Wilcoxon signed-rank test";
            disp(['Non-Parametric test used for channel [', chan_label{chan_idx}, '] bin [', num2str(b), ']: [Wilcoxon signed-rank test]']);
        end

    end

    % Now, p_values contains the p-value for each bin comparison between hits and misses for one channel

    %clear p_values

end

%% Correcting for multiple comparisons (All channels)

% Coorection for multiple comparisons --> Reduce the likelihood of type I errors (false positives)

% FDR correction using Benjamini-Hochberg procedure
% Flatten the matrix of p-values into a vector for FDR correction
p_values_vector = reshape(p_values_matrix, [], 1);

% Apply FDR correction
[adjusted_p_values_vector] = mafdr(p_values_vector, 'BHFDR', true, 'Showplot', true);

% Reshape the adjusted p-values back into the original matrix form
adjusted_p_values_matrix = reshape(adjusted_p_values_vector, size(p_values_matrix));

% Replace the original p-values with the adjusted p-values in the matrix
p_values_matrix = adjusted_p_values_matrix;


%% Defining Region Of Interest (ROI) 

% Define your ROI channels here
roi_channels = {'C3','Cz','C4','FC1','Fz','FC2'};
roi_indices = find(ismember({EEG.chanlocs.labels}, roi_channels));
all_means_ROI = all_means(roi_indices, :); 


%% T-test per mean bin (ROI)

chan_label = {EEG.chanlocs.labels};

% Initialize matrices for p-values, z-values, and test labels
p_values_matrix_ROI = zeros(length(roi_indices), nBins);
z_values_matrix_ROI = zeros(length(roi_indices), nBins);
normality_p_values_ROI = zeros(length(roi_indices), nBins);

% Loop through each channel and each condition
for chan_idx = 1 : length(roi_indices)

    p_values_ROI = zeros(1, nBins); % Initialize array for p-values for each bin
    z_values_ROI = zeros(1, nBins); % Initialize array for z-values for each bin

    % Perform t-tests for each bin
    for b = 1:nBins

        % Extract observations for the current channel and bin
        observations = all_means_ROI{chan_idx}(:, b);

        % Normality test
        [~, p_shapiro] = lillietest(observations);
        normality_p_values_ROI(chan_idx, b) = p_shapiro;

        % Perform the t-test or non-parametric test based on the normality result
        if p_shapiro > 0.05 && nBins < 1 % Impossible assumption, so it always performs non-parametric test to be on the safe side
            % Normality assumption not violated, use One-Sample T-Test
            [h, p, ci, stats] = ttest(observations, 0);  % Test against zero
            p_values_ROI(b) = p;

            % Store the p-values for this channel in the matrix
            p_values_matrix_ROI(chan_idx, :) = p_values_ROI;

            disp(['Parametric test used for channel [', chan_label{chan_idx}, '] bin [', num2str(b), ']: [T-test]']);

        else

            % Normality assumption violated, use a non-parametric test
            [p, h, stats] = signrank(observations, 0);  % Wilcoxon signed-rank test
            p_values_ROI(b) = p;
            z_values_ROI(b) = stats.zval;

            % Store the p-values and z-values for this channel in the matrix
            p_values_matrix_ROI(chan_idx, :) = p_values_ROI;
            z_values_matrix_ROI(chan_idx, :) = z_values_ROI;

            disp(['Non-Parametric test used for channel [', chan_label{chan_idx}, '] bin [', num2str(b), ']: [Wilcoxon signed-rank test]']);
        end

    end

    % Now, p_values contains the p-value for each bin comparison between hits and misses for one channel

    clear p_values_ROI

end


%% Correcting for multiple comparisons (ROI)

% Coorection for multiple comparisons --> Reduce the likelihood of type I errors (false positives)

% FDR correction using Benjamini-Hochberg procedure
% Flatten the matrix of p-values into a vector for FDR correction
p_values_vector_ROI = reshape(p_values_matrix_ROI, [], 1);

% Apply FDR correction
[adjusted_p_values_vector_ROI] = mafdr(p_values_vector_ROI, 'BHFDR', true, 'Showplot', true);

% Reshape the adjusted p-values back into the original matrix form
adjusted_p_values_matrix_ROI = reshape(adjusted_p_values_vector_ROI, size(p_values_matrix_ROI));

% Replace the original p-values with the adjusted p-values in the matrix
p_values_matrix_ROI = adjusted_p_values_matrix_ROI;


%% Replacing old values from ROI

p_values_matrix (roi_indices, :) = p_values_matrix_ROI;
z_values_matrix (roi_indices, :) = z_values_matrix_ROI;


%% TOPOGRAPHY

% Define your ROI channels here
roi_channels = {'C3','Cz','C4','FC1','Fz','FC2'};
roi_indices = find(ismember({EEG.chanlocs.labels}, roi_channels));
idx_chan_Cz = find(strcmp({EEG.chanlocs.labels}, 'Cz'));

% Colors
a = [247,251,255]/ 255;
b = [222,235,247]/ 255;
c = [198,219,239]/ 255;
d = [158,202,225]/ 255;
e = [107,174,214]/ 255;
f = [66,146,198]/ 255;
g = [33,113,181]/ 255;

% Combine the colors into a matrix
customColors = [g;f;e;d;c;b;a];

% Interpolate to create a smooth gradient with 256 points
smoothGradient = interp1(linspace(0, 1, size(customColors, 1)), customColors, linspace(0, 1, 256), 'pchip');

fig = figure('units','normalized','outerposition', [0 0 1 1]); % for full screen

% Define a larger grid, for example 3 rows and 5 columns
nRows = 3;
nCols = 5;

% Significant values
p_threshold = 0.05;  % Threshold for significance
sig_p_values = [p_values_matrix <= p_threshold];

for itopo = 1 : nBins

    % Top row - 3 plots
    subplotTopo = subtightplot(nRows, nCols, itopo);  % Top left plot

    % Create the string for the bin range, e.g., '-2000 to -1900 ms'
    binRangeStr = sprintf('%d to %d ms', binEdges(itopo), binEdges(itopo+1));

    % Find significant channels for the current bin
    sig_channels = find(sig_p_values(:, itopo));

    % Plot topography
    low = 0; % min(p_values_matrix(:));
    high = 1; % max(p_values_matrix(:));

    % Plot the topography with ROI channels highlighted as hollow circles
    topoplot(p_values_matrix(:, itopo), EEG.chanlocs, ...
    'electrodes', 'off', ...
    'maplimits', [low high], ...
    'whitebk', 'off', ...
    'shading', 'interp', ...
    'emarker2', {roi_indices, 'o', 'k', 10, 2}); % Hollow circles for ROI'MarkFaceColor', [0.00,0.00,0.00]

    % Find significant ROI channels for the current bin
    significant_roi_indices = intersect(sig_channels, roi_indices); % Only significant channels within ROI

    % Overlay significant channels with red markers
    if ~isempty(significant_roi_indices)
        hold on;
        topoplot(p_values_matrix(:, itopo), EEG.chanlocs, 'electrodes', 'off', 'maplimits', [low high], ...
            'whitebk', 'on', ...
            'shading', 'interp', ...
            'emarker2', {significant_roi_indices, 'o', 'r', 10, 1}); % Red squares for significant channels within ROI
        hold off;
    end


    %title([num2str(EEG.times(timeEEG)), ' [ms]'], 'FontSize', 10, 'Position', [0, 0, 0], 'VerticalAlignment', 'cap');
    colormap(smoothGradient);
    %colormap(jet(250));

    % Assuming 'ax' is the handle to your subplot axes
    axesPosition = get(subplotTopo, 'Position');  % Get the position of the current axes
    normalizedBottom = axesPosition(2);  % Bottom of the axes in normalized units

    % Instead of using `text`, adjust the title position
    titleText = [binRangeStr];
    titleHandle = title(titleText, 'FontSize', 11, 'FontWeight', 'bold');
    titlePosition = get(titleHandle, 'position');
    set(titleHandle, 'position', [titlePosition(1), titlePosition(2)-1.35, titlePosition(3)]);  % Adjust Y-offset as needed

    if itopo == 1
        c = colorbar('Ticks',[0 1]);  % Replace minValue and maxValue with your actual min and max
        %c.TickLabels = {'-', '', '', '', '+'};
        c.Label.String = 'p-Values';
        c.Label.FontSize = 11;
        c.Position = [0.9546875,0.728587319243604,0.003645833333333,0.136334146724982]; % Set the colorbar position
    end

end


sgtitle(['Statistical Comparison [Readiness Potential vs 0] / Grand Average'], 'Color',"k", 'Fontweight', 'bold'); % Super title


%% Creating tables

% Now create the tables using the column names
channel_names = {EEG.chanlocs.labels}; % Adjust this line to match your channels
pValues_Table = array2table(p_values_matrix, 'VariableNames', columnNamesMean, 'RowNames', channel_names);
testLabels_Table = array2table(test_labels_matrix, 'VariableNames', columnNamesMean, 'RowNames', chan_label);


%% Saving

saveas(gcf, [outpath, '\\group_analysis\\','topo_stats_RP_grand_avg', '.jpg']); % Save the figure as a PNG image
save_fig(gcf,[outpath, '\\group_analysis\\',], 'topo_stats_RP_grand_avg', 'fontsize', 12);

save([outpath, 'topo_stats_RP_grand_avg', '.mat'], 'pValues_Table');
save([outpath, 'topo_stats_RP_grand_avg_labels','.mat'], 'testLabels_Table', 'normality_p_values');


%% Saving pvalues table into an excel
% writetable(pValues_Table, 'pValues_Table.xlsx', 'WriteRowNames',true);


%% Assumptions before testing

% For an Independent t-test (comparing two groups, like hits and misses):

% Normality: Both groups should come from populations that follow a normal
% distribution. This is less of a concern with larger sample sizes due to
% the central limit theorem.

% Independence: The scores of the two groups are
% independent of each other, meaning the participants in one group cannot
% be in the other group.



