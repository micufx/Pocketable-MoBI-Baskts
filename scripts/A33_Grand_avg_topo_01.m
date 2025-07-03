clc, clear, close all;

%% Motion capture combined with mobile EEG (grand average plot)

% This code creates a grand average plot of frame-by-frame motion and EEG
% combined data synchronously.

% Miguel Contreras-Altamirano, 2025

%% EEG data loading

mainpath = 'C:\Users\micua\Desktop\eeglab2023.0\'; % eeglab folder
path = 'C:\Users\micua\OneDrive - Benemérita Universidad Autónoma de Puebla\NCP_Basketball\MediaPipe\';
outpath = 'C:\\Users\\micua\\OneDrive - Benemérita Universidad Autónoma de Puebla\\Oldenburg_University\\Thesis\\data_hoops\\';
files = dir( fullfile( path,'\*.xdf')); % listing data sets


num_conditions = 3; % (Conditions and overall: 1=hit 2=miss 3=all)


%% Selecting participant


for cond=3 : num_conditions


    % Loading desired data
    if cond == 1 % 'hit'
        load([outpath, 'ACC_grand_avg_rev_hit', '.mat']); % Loading accelerometer data
        % load([outpath, 'ACC_grand_avg_dev_hit', '.mat']); % Loading accelerometer data
        % load([outpath, 'ACC_grand_avg_sd_hit', '.mat']); % Loading accelerometer data
        load([outpath , 'PLD_grand_avg_hit.mat'], 'averageTimeseriesMp', 'timestamps_mp');

        % Import EEG processed data
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % Open eeglab
        EEG = pop_loadset('filename',['Grand_avg_hits','.set'],'filepath', outpath); % Loading set file
        eeglab redraw

    elseif cond == 2 % 'miss'
        load([outpath, 'ACC_grand_avg_rev_miss', '.mat']); % Loading accelerometer data
        % load([outpath, 'ACC_grand_avg_dev_miss', '.mat']); % Loading accelerometer data
        % load([outpath, 'ACC_grand_avg_sd_miss', '.mat']); % Loading accelerometer data
        load([outpath , 'PLD_grand_avg_miss.mat'], 'averageTimeseriesMp', 'timestamps_mp');

        % Import EEG processed data
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % Open eeglab
        EEG = pop_loadset('filename',['Grand_avg_misses','.set'],'filepath', outpath); % Loading set file
        eeglab redraw

    elseif cond == 3  % % 'none'
        load([outpath, 'ACC_grand_avg_rev', '.mat']); % Loading accelerometer data
        % load([outpath, 'ACC_grand_avg_dev', '.mat']); % Loading accelerometer data
        % load([outpath, 'ACC_grand_avg_sd', '.mat']); % Loading accelerometer data
        load([outpath , 'PLD_grand_avg.mat'], 'averageTimeseriesMp', 'timestamps_mp');

        % Import EEG processed data
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % Open eeglab
        EEG = pop_loadset('filename',['Grand_avg_all','.set'],'filepath', outpath); % Loading set file
        eeglab redraw
    end

    % Renaming variables for simplicity
    timeseries_acc_mag = avgAccMagnitude_across_rev; % from Reverse Computation Algorithm method
    timestamps_acc_mag = epochTimes_rev; % from Reverse Computation Algorithm method
    timeseries_mp = averageTimeseriesMp; % Average motion

    % Channel to visualize
    chan = find(strcmp({EEG.chanlocs.labels}, 'Cz'));

    % Calculate the mean and standard deviation of the mean
    ERP = mean(EEG.data(:, :, :), 3);  % Mean across the third dimension (trials)
    erp_std = std(EEG.data(:, :, :), 0, 3); % This is a single value --> Standard deviation across trials
    n_trials = size(EEG.data, 3);
    standard_error = erp_std / sqrt(n_trials); % Standard error of the Mean
    erp_pre_SD = standard_error(chan, :);


    % Settings for ERP
    % Calculate Global Field Power (GFP)
    GFP = std(ERP, [], 1); % GFP is the standard deviation across all electrodes at each time point

    % Scale or offset GFP if necessary for better visibility
    scaleFactor = 1; % Adjust this factor based on your data range
    offsetFactor = 4; % Adjust this offset to position GFP below or above your ERP
    GFP = GFP * scaleFactor + offsetFactor;


    % Create a colormap with as many colors as there are electrodes
    numElectrodes = size(EEG.data, 1);
    colors = lines(numElectrodes);   % Use hsv, jet or any other colormap
    % Mix with white to lighten the colors
    lightenFactor = 0.5;  % Adjust this to make the color lighter (closer to 1 makes it lighter)
    colors = colors + lightenFactor * (1 - colors);

    BP_acc = find(EEG.times < grand_avgOnsetTime_rev);
    BP_acc = BP_acc(end);
    % Find the index of the most negative point (peak) in the ERP data
    [~, peakIdx] = min(ERP(chan, 1 : BP_acc));  % Directly find the minimum for negative peaks
    peakTime = EEG.times(peakIdx);  % Time corresponding to the peak

    idx_bl = find(EEG.times == -2000);
    movement_onset = find(EEG.times == 0);

    % Define the time window around the peak
    timeWindowStart = -1500; % vgr., peakTime - 830 --> ms before the peak
    timeWindowEnd = 0; %vgr., peakTime + 50 --> ms after the peak

    % Ensure the time window is within the bounds of your data
    timeWindowStart = max(timeWindowStart, min(EEG.times));
    timeWindowEnd = min(timeWindowEnd, max(EEG.times));

    %% TOPOGRAPHY

    fig = figure('units','normalized','outerposition', [0 0 1 1]); % for full screen %figure('Units', 'pixels', 'Position', [100, 100, 1000, 800], 'Renderer', 'painters');
    %tiledlayout(6,6,'TileSpacing','Compact');

    % Define a larger grid, for example 3 rows and 5 columns
    nRows = 3;
    nCols = 5;

    % Define your bins here, as before
    binEdges = [-1000, -900, -800, -700, -600, -500, -400, -300, -200, -100, 0];
    nBins = length(binEdges) - 1; % Number of bins

    for itopo = 1 : nBins


        % Top row - 3 plots
        subplotTopo = subtightplot(nRows, nCols, itopo);  % Top left plot


        if itopo == 1
            timeEEG = [find(EEG.times == -1000) : find(EEG.times == -900)];
        elseif itopo == 2
            timeEEG = [find(EEG.times == -900) : find(EEG.times == -800)];
        elseif itopo == 3
            timeEEG = [find(EEG.times == -800) : find(EEG.times == -700)];
        elseif itopo == 4
            timeEEG = [find(EEG.times == -700) : find(EEG.times == -600)];
        elseif itopo == 5
            timeEEG = [find(EEG.times == -600) : find(EEG.times == -500)];
        elseif itopo == 6
            timeEEG = [find(EEG.times == -500) : find(EEG.times == -400)];
        elseif itopo == 7
            timeEEG = [find(EEG.times == -400) : find(EEG.times == -300)];
        elseif itopo == 8
            timeEEG = [find(EEG.times == -300) : find(EEG.times == -200)];
        elseif itopo == 9
            timeEEG = [find(EEG.times == -200) : find(EEG.times == -100)];
        elseif itopo == 10
            timeEEG = [find(EEG.times == -100) : find(EEG.times == 0)];
        end


        % Plot topography
        low = -20;
        high = 20;


        ERP_bin = mean(ERP(:, timeEEG), 2); % Feature mean per bin


        topoplot(ERP_bin, EEG.chanlocs, 'electrodes', 'off', 'maplimits', [low high], ...
            'whitebk', 'on', ...
            'shading', 'interp');
        %title([num2str(EEG.times(timeEEG)), ' [ms]'], 'FontSize', 10, 'Position', [0, 0, 0], 'VerticalAlignment', 'cap');
        colormap(jet(250));
        % Assuming 'ax' is the handle to your subplot axes

        axesPosition = get(subplotTopo, 'Position');  % Get the position of the current axes
        normalizedBottom = axesPosition(2);  % Bottom of the axes in normalized units


        % Create the string for the bin range, e.g., '-2000 to -1900 ms'
        binRangeStr = sprintf('%d to %d ms', binEdges(itopo), binEdges(itopo+1));

        % Instead of using `text`, adjust the title position
        titleText = [binRangeStr];
        titleHandle = title(titleText, 'FontSize', 11, 'FontWeight', 'bold');
        titlePosition = get(titleHandle, 'position');
        set(titleHandle, 'position', [titlePosition(1), titlePosition(2)-1.35, titlePosition(3)]);  % Adjust Y-offset as needed


        % % Position the text at the bottom center of each subplot
        % text('Parent', subplotTopo, 'String', [num2str(EEG.times(timeEEG(1))), ' to ', num2str(EEG.times(timeEEG(end))), ' ms'], ...
        %     'Units', 'normalized', ...
        %     'Position', [0.5, normalizedBottom - 0.6, 0], ... % You may need to adjust the 0.1 offset
        %     'HorizontalAlignment', 'center', ...
        %     'VerticalAlignment', 'top', ... % 'top' aligns the text at its top to the given Y position
        %     'FontSize', 11, 'FontWeight', 'bold');  % Adjust font size as needed

        if itopo == 1
            c = colorbar('Ticks',[-20 -10 0 10 20]);  % Replace minValue and maxValue with your actual min and max
            %c.TickLabels = {'-', '+'};
            c.Label.String = 'Amplitude [\muV]';
            c.Label.FontSize = 11;
            c.Position = [0.9546875,0.728587319243604,0.003645833333333,0.136334146724982]; % Set the colorbar position
        end

    end


    if cond == 1
        sgtitle('Grand Average ERP: Hits', 'Color',"#A2142F", 'Fontweight', 'bold'); % Super title
    elseif cond ==2
        sgtitle('Grand Average ERP: Misses', 'Color',"#A2142F", 'Fontweight', 'bold'); % Super title
    elseif cond == 3
        sgtitle('Grand Average ERP', 'Color',"#A2142F", 'Fontweight', 'bold'); % Super title
    end


    if cond == 1

        saveas(gcf, [outpath, '\\group_analysis\\', 'Motion_grand_avg_hit_alltopo', '.jpg']); % Save the figure as a PNG image

        %save_fig(gcf,[outpath, '\\group_analysis\\',], 'Motion_grand_avg_hit');


    elseif cond ==2

        saveas(gcf, [outpath, '\\group_analysis\\','Motion_grand_avg_miss_alltopo', '.jpg']); % Save the figure as a PNG image

        %save_fig(gcf,[outpath, '\\group_analysis\\',], 'Motion_grand_avg_miss');


    elseif cond == 3

        saveas(gcf, [outpath, '\\group_analysis\\','Motion_grand_avg_alltopo', '.jpg']); % Save the figure as a PNG image

        save_fig(gcf,[outpath, '\\group_analysis\\',], 'Motion_grand_avg_alltopo',...
        'fontsize', 8, ...
        'figsize', [35, 20], ...
        'figtypes', {'.png'},...
        'dpi', 600);

    end


    disp(['Condition ', num2str(cond), ' finalized!']);


end


