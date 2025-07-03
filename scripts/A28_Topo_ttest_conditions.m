clc, clear, close all;

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

for sub = 1 : length(files)

    participant = extractBefore(files(sub).name, '.xdf');
    out_subfold = [outpath, participant, '\\'];
    load([outpath, 'Info_EEG.mat']); % Loading channels file

    % Import EEG processed data
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % Open eeglab
    EEG = pop_loadset('filename',['hoop_hit_RP_', participant, '.set'],'filepath', out_subfold); % Loading set file
    EEG_hit = EEG;
    clear EEG;

    % Import EEG processed data
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % Open eeglab
    EEG = pop_loadset('filename',['hoop_miss_RP_', participant, '.set'],'filepath', out_subfold); % Loading set file
    EEG_miss = EEG;


    %% Features

    % Define your bins here, as before
    binEdges = [-1500, -1400, -1300, -1200, -1100, -1000, -900, -800, -700, -600, -500, -400, -300, -200, -100, 0];
    nBins = length(binEdges) - 1; % Number of bins
    nEpochs_hits = size(EEG_hit.data, 3);
    nEpochs_misses = size(EEG_miss.data, 3);

    % Generate column names for each bin
    columnNamesMean = cell(1, nBins);
    for b = 1:nBins
        columnNamesMean{b} = ['Bin_' num2str(b) '_Mean'];
    end

    % Initialize the tables for hit and miss conditions
    hit_means = cell(length(EEG.chanlocs), 1);
    miss_means = cell(length(EEG.chanlocs), 1);

    % Loop through each channel and each condition
    for chan_idx = 1:length(EEG.chanlocs)

        hit_means{chan_idx} = zeros(nEpochs_hits, nBins); % Initialize the mean values for hits
        miss_means{chan_idx} = zeros(nEpochs_misses, nBins); % Initialize the mean values for misses

        % Loop over each bin
        for b = 1:nBins
            % Find the time indices for the current bin
            idxStart = find(EEG.times >= binEdges(b), 1, 'first');
            idxEnd = find(EEG.times < binEdges(b + 1), 1, 'last');

            % Calculate the mean for each trial in the current bin for hits
            hit_data = EEG_hit.data(chan_idx, idxStart:idxEnd, :);
            hit_means{chan_idx}(:, b) = squeeze(mean(hit_data, 2)); % Mean across time for each trial

            % Calculate the mean for each trial in the current bin for misses
            miss_data = EEG_miss.data(chan_idx, idxStart:idxEnd, :);
            miss_means{chan_idx}(:, b) = squeeze(mean(miss_data, 2)); % Mean across time for each trial
        end
    end

    % Now you have a cell array where each cell contains a 2D matrix of trials x bins for each channel
    % You can now run your t-tests on these matrices


    %% T-test per mean bin

    chan_label = {EEG.chanlocs.labels};

    % Loop through each channel and each condition
    for chan_idx = 1 : length(EEG.chanlocs)

        p_values = zeros(1, nBins); % Initialize array for p-values for each bin

        % Perform t-tests for each bin
        for b = 1:nBins


            % Extract observations for the current channel and bin
            hits_observations = hit_means{chan_idx}(:, b);
            misses_observations = miss_means{chan_idx}(:, b);

            % Check normality for hits
            [~, p_shapiro_hits] = lillietest(hits_observations);
            normality_p_values_hits(chan_idx, b) = p_shapiro_hits;

            % Check normality for misses
            [~, p_shapiro_misses] = lillietest(misses_observations);
            normality_p_values_misses(chan_idx, b) = p_shapiro_misses;

            % Check homogeneity of variances between hits and misses
            [p_levene, stats] = vartestn([hits_observations; misses_observations],...
                [ones(size(hits_observations)); 2*ones(size(misses_observations))], ...
                'TestType', 'LeveneAbsolute', ...
                'Display', 'off');
            levenes_p_values(chan_idx, b) = p_levene;


            % Perform the t-test if normality and homogeneity assumptions are not violated
            if p_shapiro_hits > 0.05 && p_shapiro_misses > 0.05 && p_levene > 0.05 && nBins<1

                % Both groups are normally distributed with equal variances
                [h, p, ci, stats] = ttest2(hits_observations, misses_observations); % Parametric Independent Samples T-Test
                p_values(b) = p;

                % Store the p-values for this channel in the matrix
                p_values_matrix(chan_idx, :) = p_values;

                test_labels_matrix(chan_idx, b) = "T-test";
                disp(['Parametric test used for channel [', chan_label{chan_idx},'] bin [', num2str(b), ']: [T-test]']);

            else

                % Use a non-parametric test if assumptions are violated
                [p, h] = ranksum(hits_observations, misses_observations); % Non-Parametric Independent Samples Mann-Whitney U test
                p_values(b) = p;

                % Store the p-values for this channel in the matrix
                p_values_matrix(chan_idx, :) = p_values;

                test_labels_matrix(chan_idx, b) = "Mann-Whitney U test";
                disp(['Non-Parametric test used for channel [', chan_label{chan_idx},'] bin [', num2str(b), ']: [Mann-Whitney U test]']);

            end


        end

        % Now, p_values contains the p-value for each bin comparison between hits and misses for one channel

        % clear p_values

    end


    % Coorection for multiple comparisons --> Reduce the likelihood of type I errors (false positives)

    % FDR correction using Benjamini-Hochberg procedure
    % Flatten the matrix of p-values into a vector for FDR correction
    p_values_vector = reshape(p_values_matrix, [], 1);

    % Apply FDR correction
    adjusted_p_values_vector = mafdr(p_values_vector, 'BHFDR', true);

    % Reshape the adjusted p-values back into the original matrix form
    adjusted_p_values_matrix = reshape(adjusted_p_values_vector, size(p_values_matrix));

    % Replace the original p-values with the adjusted p-values in the matrix
    p_values_matrix = adjusted_p_values_matrix;


    %% TOPOGRAPHY

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

        topoplot(p_values_matrix(:,itopo), EEG.chanlocs, 'electrodes', 'off', 'maplimits', [low high], ...
            'whitebk', 'on', ...
            'shading', 'interp', ...
            'emarker2', {sig_channels, 'o', 'm', 10, 1});

        %title([num2str(EEG.times(timeEEG)), ' [ms]'], 'FontSize', 10, 'Position', [0, 0, 0], 'VerticalAlignment', 'cap');
        colormap(smoothGradient);

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


    sgtitle(['Wilcoxon signed-rank test for RP [Hits vs Misses] / Sub. [', num2str(sub), ']'], 'Color',"k", 'Fontweight', 'bold'); % Super title


    % Now create the tables using the column names
    channel_names = {EEG.chanlocs.labels}; % Adjust this line to match your channels
    pValues_Table = array2table(p_values_matrix, 'VariableNames', columnNamesMean, 'RowNames', channel_names);
    testLabels_Table = array2table(test_labels_matrix, 'VariableNames', columnNamesMean, 'RowNames', chan_label);



    %% Saving number of hits and misses

    T.Hits{sub} = length(hits_observations);
    T.Misses{sub} = length(misses_observations);

    % Save it in .mat file
    save([outpath, 'Info_EEG.mat'],'T');
    writetable(T, [outpath, 'Info_EEG.xlsx']);



    %% Saving

    % saveas(gcf, [out_subfold, 'topo_stats_conditions_', participant, '.png']); % Save the figure as a PNG image
    % saveas(gcf, [outpath, '\\group_analysis\\','topo_stats_conditions_', participant, '.png']); % Save the figure as a PNG image


    save([out_subfold, 'topo_stats_conditions_', participant,'.mat'], 'pValues_Table');
    % save([out_subfold, 'topo_stats_conditions_labels_', participant,'.mat'], 'testLabels_Table', 'normality_p_values_hits',...
    %     'normality_p_values_misses', 'levenes_p_values', 'hits_observations', 'misses_observations');


    save_fig(gcf, out_subfold, ['topo_stats_conditions_', participant], ...
        'fontsize', 14, ...
        'figsize', [35, 20], ...
        'figtypes', {'.png'},...
        'dpi', 600);


    % clear EEG
    % clear p_values_matrix


end


%% Assumptions before testing

% For an Independent t-test (comparing two groups, like hits and misses):

% Normality: Both groups should come from populations that follow a normal
% distribution. This is less of a concern with larger sample sizes due to
% the central limit theorem.

% Homoscedasticity (Homogeneity of variances - Equal variances):
% The variances of the populations from which the samples are drawn should
% be equal. The Welch's t-test is an alternative that does not assume equal
% population variances.

% Independence: The scores of the two groups are
% independent of each other, meaning the participants in one group cannot
% be in the other group.

%%