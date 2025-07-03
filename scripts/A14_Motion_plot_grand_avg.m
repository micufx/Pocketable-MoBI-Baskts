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


    % Set up the figure with a larger size
    % Get the screen size of all monitors
    % screensize = get(groot, 'MonitorPositions');
    %
    % % If there's more than one monitor, you might want to select which one to use
    % % For example, to use the second monitor:
    % if size(screensize, 1) > 1
    %     % Assuming the second monitor is the desired one
    %     desiredMonitor = 2;
    % else
    %     desiredMonitor = 1; % Default to the primary monitor if there's only one
    % end
    % Get the position of the desired monitor
    % monitorPosition = screensize(desiredMonitor, :);
    % Create a figure that fills the screen of the desired monitor
    %fig = figure('units', 'normalized', 'outerposition', [0, 0, 1, 1], 'Position', monitorPosition);



    fig = figure('units','normalized','outerposition', [0 0 1 1]); % for full screen %figure('Units', 'pixels', 'Position', [100, 100, 1000, 800], 'Renderer', 'painters');
    %tiledlayout(6,6,'TileSpacing','Compact');


    %% TOPOGRAPHY

    % Define a larger grid, for example 3 rows and 5 columns
    nRows = 3;
    nCols = 6;


    for itopo = 1 : 6


        % Top row - 3 plots
        subplotTopo = subtightplot(nRows, nCols, itopo);  % Top left plot


        if itopo == 1
            timeEEG = [find(EEG.times == -2500) : find(EEG.times == -2000)]; % End of baseline
        elseif itopo == 2
            timeEEG = [find(EEG.times == -2000) : find(EEG.times == -1500)]; % Steady period
        elseif itopo == 3
            timeEEG = [find(EEG.times == -1500) : find(EEG.times == -1000)]; % Beginning of ERP (BP2)
        elseif itopo == 4
            timeEEG = [find(EEG.times == -1000) : find(EEG.times == -500)];  % Middle of ERP (BP2)
        elseif itopo == 5
            timeEEG = [find(EEG.times == -500) : find(EEG.times == -200)]; % Peak of ERP (BP1)
        elseif itopo == 6
            timeEEG = [find(EEG.times == -200) : find(EEG.times == 0)];  % Highest Peak ERP (BP1)
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

        % Position the text at the bottom center of each subplot
        text('Parent', subplotTopo, 'String', [num2str(EEG.times(timeEEG(1))), ' to ', num2str(EEG.times(timeEEG(end))), ' ms'], ...
            'Units', 'normalized', ...
            'Position', [0.5, normalizedBottom - 0.6, 0], ... % You may need to adjust the 0.1 offset
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'top', ... % 'top' aligns the text at its top to the given Y position
            'FontSize', 11, 'FontWeight', 'bold');  % Adjust font size as needed

        if itopo == 1
            c = colorbar('Ticks',[-20 -10 0 10 20]);  % Replace minValue and maxValue with your actual min and max
            %c.TickLabels = {'-', '+'};
            c.Label.String = 'Amplitude [\muV]';
            c.Label.FontSize = 11;
            c.Position = [0.9546875,0.728587319243604,0.003645833333333,0.136334146724982]; % Set the colorbar position
        end

    end



    %% ERP

    % Middle row - 1 plot spanning all columns
    subplotERP = subtightplot_2(nRows, nCols, [7, 8, 9, 10, 11, 12]);

    % Define your y-limits
    yLimits = [-40, 30];
    ylim(yLimits);

    % Assigning y-limits to the data for better visualization
    EEG.data_masked = ERP; % Just for visualization porpouses (is like zooming in)
    EEG.data_masked(EEG.data_masked < yLimits(1) | EEG.data_masked > yLimits(2)) = NaN;
    GFP(GFP < yLimits(1) | GFP > yLimits(2)) = NaN;
    % timeseries_acc_mag(timeseries_acc_mag < yLimits(1) | timeseries_acc_mag > yLimits(2)) = NaN;


    % Plot the background channels only once, before the loop
    hold(subplotERP, 'on');
    for ch = 1:numElectrodes
        if ch ~= chan
            other_chan = plot(subplotERP, EEG.times, EEG.data_masked(ch, :), 'Color', [0.8 0.8 0.8], 'LineWidth', 0.8);
        end
    end


    % Custom grid lines within the RP time window
    gridYTicks = yLimits(1):10:yLimits(2); % Y-axis grid points
    for gridTime = timeWindowStart:100:timeWindowEnd % Adjust the step for your time resolution
        line([gridTime, gridTime], yLimits, 'Color', [0.8 0.8 0.8], 'LineStyle', '--'); % Vertical grid lines
    end
    for gridY = gridYTicks
        line([timeWindowStart, timeWindowEnd], [gridY, gridY], 'Color', [0.8 0.8 0.8], 'LineStyle', '--'); % Horizontal grid lines
    end


    % Plot the main ERP and GFP lines once
    %gfpLine = plot(subplotERP, EEG.times, GFP, 'Color', "#77AC30", 'LineWidth', 2.5, 'LineStyle', '-.');
    hold on;
    erpLine = plot(subplotERP, EEG.times, EEG.data_masked(chan,:), 'Color', "#0072BD", 'LineWidth', 3);
    uistack(erpLine, 'top');  % Make sure the ERP is on top

    % Calculate the upper and lower bounds of the shaded area
    upperBound_avg_EEG = ERP(chan,:) + erp_pre_SD;
    lowerBound_avg_EEG = ERP(chan,:) - erp_pre_SD;

    % Create the shaded area representing the SD around the mean
    fill(subplotERP, [EEG.times fliplr(EEG.times)], ...
        [upperBound_avg_EEG fliplr(lowerBound_avg_EEG)], ...
        [0 0.4470 0.7410], 'FaceAlpha', 0.2, 'EdgeColor', 'none');


    % Highlight the baseline period
    baselineStart = -2500; % adjust to your baseline start time
    baselineEnd = -2000; % adjust to your baseline end time

    % Get the current y-axis limits
    ylimits = ylim;

    % Fill between the baseline period with a light blue color and some transparency
    %fill([baselineStart, baselineStart, baselineEnd, baselineEnd], [ylimits(1), ylimits(2), ylimits(2), ylimits(1)], [0.4660 0.6740 0.1880], 'FaceAlpha', 0.2, 'EdgeColor', 'none');

    % RP highlight transparency
    fill([baselineStart+1000, baselineStart+1000, baselineEnd+1000, baselineEnd+1000], [ylimits(1), ylimits(2), ylimits(2), ylimits(1)], [0.8500 0.3250 0.0980], 'FaceAlpha', 0.2, 'EdgeColor', 'none');

    % Fill between the baseline period with a light blue color and some transparency
    fill([baselineStart+2000, baselineStart+2000, baselineEnd+1800, baselineEnd+1800], [ylimits(1), ylimits(2), ylimits(2), ylimits(1)], [0.8500 0.3250 0.0980], 'FaceAlpha', 0.2, 'EdgeColor', 'none');



    % Customize ERP axes
    %title(subplotERP, 'Readiness potential', 'Color', "#0072BD", 'FontWeight', 'bold', 'FontSize', 12);
    %subtitle(subplotERP, ['Electrodes at ', num2str(EEG.times(1)), ' [ms]'], 'FontWeight', 'bold', 'FontSize', 10);
    ylabel(subplotERP, 'Amplitude [\muV]', 'FontSize', 11, 'Color', 'k');
    xlabel(subplotERP, 'Time [ms]', 'FontSize', 11);
    xlim(subplotERP, [EEG.times(1) EEG.times(end)]);
    ylim(subplotERP, yLimits);
    yticks(subplotERP, yLimits(1):10:yLimits(2));
    set(subplotERP, 'YDir', 'reverse');
    %grid(subplotERP, 'on');
    axis(subplotERP, 'tight');

    % % Create patch for the highlight shadow once (Peak RP shadow)
    % peakPatch = patch(subplotERP, 'XData', [timeWindowStart, timeWindowStart, timeWindowEnd, timeWindowEnd], ...
    %     'YData', [min(ylim), max(ylim), max(ylim), min(ylim)], ...
    %     'FaceColor', 	"#D95319", 'FaceAlpha', 0.2, 'Edgecolor', 'none');

    % Set y-axis limits and ticks for ERP/GFP data
    ylim(subplotERP, yLimits);
    yticks(subplotERP, yLimits(1):10:yLimits(2));


    % Determine the full range of ACC data for plotting
    accMax = 100;
    accMin = min(timeseries_acc_mag);

    % Create a second axes for the ACC data that shares the same x-axis as subplotERP
    ax2 = axes('Position', subplotERP.Position, 'XAxisLocation', 'top', 'YAxisLocation', 'right', ...
        'Color', 'none', 'XColor', 'none', 'YColor', 'k', 'Parent', fig);
    ylabel(ax2, 'Acceleration Magnitude [m/s^2]', 'FontSize', 11, 'Color', 'k');
    linkaxes([subplotERP ax2], 'x'); % Link the x-axes of both axes

    % Set the y-axis limits for the ACC data to show the full range
    set(ax2, 'YLim', [accMin, accMax]);


    % Plot ACC data on the second axes
    hold(ax2, 'on');
    accLine = plot(ax2, timestamps_acc_mag, timeseries_acc_mag, 'Color', "k", 'LineStyle', '-', ...
        'Marker', 'o', 'MarkerIndices', 1:10:length(timeseries_acc_mag),'LineWidth', 2.5);


    % % Create the shaded area representing the SD around the mean
    % fill([timestamps_acc_mag fliplr(timestamps_acc_mag)], ...
    %     [upperBound_grand_avg_dev' fliplr(lowerBound_grand_avg_dev')], ...
    %     'k', 'FaceAlpha', 0.2, 'EdgeColor', 'none');


    % Plot the Basketball onset
    accOnset_rev = line(ax2, [grand_avgOnsetTime_rev grand_avgOnsetTime_rev], [accMin, accMax], 'Color', 'k', 'LineStyle', ':', 'LineWidth', 2);

    % Add a label to the line movement onset
    %text(grand_avgOnsetTime_rev, accMax, 'MP', 'Color', 'k', 'FontSize', 10, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', 'Rotation', 90, 'FontWeight', 'bold');

    % Adding line of the movement onset
    currentPointLine_PLD_onset = line(subplotERP, [0, 0], yLimits, 'Color', 'r', 'LineWidth', 2, 'Linestyle', '--');

    % Add a label to the line basketball onset
    %text(0, accMax, 'ACC', 'Color', 'r', 'FontSize', 10, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', 'Rotation', 90, 'FontWeight', 'bold');


    % % Plot the onset marker off the Derivative Method
    % accOnset_dev = line(ax2, [onsetTime_acc_dev onsetTime_acc_dev], [accMin, accMax], 'Color', "#D95319", 'LineStyle', '--', 'LineWidth', 2.5);
    % % Add a label to the line
    % text(ax2, onsetTime_acc_dev, accMax-5, 'Der', 'Color', 'k', 'FontSize', 10, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', 'Rotation', 90, 'FontWeight','bold');
    %
    % % Plot the onset marker off the Standard Deviation
    % accOnset_sd = line(ax2, [onsetTime_acc onsetTime_acc], [accMin, accMax], 'Color', "#A2142F", 'LineStyle', '--', 'LineWidth', 2.5);
    % % Add a label to the line
    % text(ax2, onsetTime_acc, accMax-1, 'Std', 'Color', 'k', 'FontSize', 10, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', 'Rotation', 90, 'FontWeight','bold');


    % Initialize the vertical line outside of the loop
    %currentPointLine_1 = line(subplotERP, [EEG.times(idx_bl), EEG.times(idx_bl)], yLimits, 'Color', 'r', 'LineWidth', 2);
    %currentPointLine_2 = line(subplotERP, [EEG.times(peakIdx), EEG.times(peakIdx)], yLimits, 'Color', 'r', 'LineWidth', 2);


    % Add legend to the ERP plot
    legend(subplotERP, [erpLine, accLine, other_chan], {'Cz', 'ACC', 'Channels'}, 'Location', 'northwest');

    % % Reconfigure position to maximize the size of the axes subplot
    % set(ax2, 'Outerposition', [0.517754838709677,0.070666259144418,0.429978494623656,0.397983502727505]);
    % set(ax2, 'Innerposition', [0.573333333333333,0.114444444444444,0.331333333333334,0.324356554722917]);
    % set(ax2, 'Position', [0.573333333333333,0.114444444444444,0.331333333333334,0.324356554722917]);



    %% PLD

    % Determine the number of frames and landmarks
    numFrames = size(timeseries_mp, 2); % Number of frames
    numLandmarks = size(timeseries_mp, 1) / 3; % Number of landmarks (33 according to MediaPipe)

    landmarkLabels = {
        'Nose', 'Left eye (inner)', 'Eye', 'Left eye (outer)', 'Right eye (inner)',...
        'Eye', 'Right eye (outer)', 'Left ear', 'Right ear', ...
        'Mouth (left)', 'Mouth (right)', 'Left shoulder', 'Right shoulder', 'Left elbow',...
        'Right elbow', 'Wrist', 'Wrist', 'Left pinky', 'Right pinky', ...
        'Left index', 'Right index', 'Left thumb', 'Right thumb', 'Left hip', 'Right hip',...
        'Left knee', 'Right knee', 'Left ankle', 'Right ankle', ...
        'Left heel', 'Right heel', 'Left foot index', 'Right foot index'
        };

    % Define a single color for all body clusters (gray)
    uniformClusterColor = [0.5, 0.5, 0.5]; % Gray color for all body clusters
    pointColors = repmat(uniformClusterColor, numLandmarks, 1); % Apply the same color to all landmarks

    % Highlight the right wrist (17th landmark)
    rightWristIndex = 17; % Index of the right wrist
    pointColors(rightWristIndex, :) = [0, 0, 0]; % Set the color to black for the right wrist

    clusters = {
        [1, 2], [1, 3], [1, 4], [1, 5], [1, 6], [1, 7], [1, 8], [1, 9], [1, 10], [1, 11],... % Face to Nose connections
        [1, 12], [1, 13],... % Shoulders to Nose connections
        [10, 11],... % Mouth (left to right)
        [12, 14],... % Left shoulder to left elbow
        [13, 15],... % Right shoulder to right elbow
        [14, 16],... % Left elbow to left wrist
        [15, 17],... % Right elbow to right wrist
        [16, 18], [16, 20], [16, 22],... % Left wrist to left fingers
        [17, 19], [17, 21], [17, 23],... % Right wrist to right fingers
        [12, 24],... % Left shoulder to left hip
        [13, 25],... % Right shoulder to right hip
        [24, 25],... % Left hip to right hip
        [24, 26],... % Left hip to left knee
        [25, 27],... % Right hip to right knee
        [26, 28],... % Left knee to left ankle
        [27, 29],... % Right knee to right ankle
        [28, 30], [30, 32], [32, 28],... % Left ankle, heel, foot index (sole of the left foot)
        [29, 31], [31, 33], [33, 29]    % Right ankle, heel, foot index (sole of the right foot)
        };


    highlightIndices = [6, 17];  % Indices: right eye (outer) and right wrist
    highlightLabels = {'Eye', 'Wrist'};  % Labels for the highlights

    % Initialize highlightPatch and highlightLabel outside the loop
    highlightPatch = gobjects(length(highlightIndices), 1);  % For square detections

    % Define highlight colors for eye and wrist
    highlightColorEye = [1, 0, 0];  % Color for eye highlight
    highlightColorWrist = [1 0 1];  % Color for wrist highlight

    highlightSize_square = 0.05;  % Size of the square detection area
    highlightSize_circle = 0.08;  % Size of the circledetection area

    firstOnsetFrame = NaN;  % Initialize as NaN, will be updated with the frame number of the first onset
    EyeIndices = 6;  % Right eye (outer)
    WristIndices = 17;  % Right wrist


    for iPLD = 1 : 6
        % gap = [0.09 0.09];
        % marg_h = [0.05 0.05];
        % marg_w = [0.05 0.05];

        % Bottom row - 3 plots
        subplotPLD = subtightplot(nRows, nCols, 12 + iPLD);  % Bottom left plot



        % Finding basketball onset
        [~, closest_time] = min(abs(EEG.times - grand_avgOnsetTime_rev)); % Find the index of the closest time to avgOnsetTime_rev
        avgOnsetTime_rev = EEG.times(closest_time); % Redifining basketball onset according to available timestamps
        basketball_onset = find(EEG.times == avgOnsetTime_rev); % You can now use basketball_onset to get the closest time



        if iPLD == 1
            timePLD = idx_bl; % End of baseline
        elseif iPLD == 2
            timePLD = find(EEG.times == -1500); % Beginning of ERP
        elseif iPLD == 3
            timePLD = find(EEG.times == -1000); % Middle of ERP
        elseif iPLD == 4
            timePLD = find(EEG.times == -500); % After ERP peak (peakIdx)
        elseif iPLD == 5
            timePLD = movement_onset; % PLD onset (start of shooting)
        elseif iPLD == 6
            timePLD = basketball_onset; % After shooting
        end


        landmarks = timeseries_mp(:, timePLD);

        % Extract the Y-coordinates of the right eye and right wrist
        EyeY = landmarks(EyeIndices * 3 - 1);
        WristY = landmarks(WristIndices * 3 - 1);


        % Split the data into X, Y, and Z coordinates for each landmark
        x_coords = landmarks(1:3:end);
        y_coords = landmarks(2:3:end);
        z_coords = landmarks(3:3:end);

        % Create a 3D plot of the landmarks with updated colors
        s = scatter3(x_coords, y_coords, z_coords, 30, pointColors, 'filled', 'o', 'MarkerEdgeColor', 'k');
        s.SizeData = 20; % Set default size

        % Increase the size of the circle for the right wrist
        hold on;
        wristMarker = scatter3(x_coords(rightWristIndex), y_coords(rightWristIndex), z_coords(rightWristIndex), ...
        50, 'k', 'filled', 'o', 'MarkerEdgeColor', 'k', 'LineWidth',2); % Larger black circle for the right wrist

        % Ensure the wrist marker is on top
        uistack(wristMarker, 'top'); % Moves the wrist marker to the top of all plotted elements

        % Customize the plot appearance (e.g., title, labels, etc.)
        %title([num2str(EEG.times(timePLD)), ' [ms]'], 'FontWeight','bold', 'FontSize', 10);
        %subtitle([num2str(EEG.times(timePLD)), ' [ms]'], 'FontWeight','bold', 'FontSize', 10);
        xlabel('X', 'FontSize', 11, 'Color', 'k');
        ylabel('Y', 'FontSize', 11, 'Color', 'k');
        zlabel('Z', 'FontSize', 11, 'Color', 'k');

        % View with the desired orientation
        %view(0,-90); % view(3) %for 3D view(0, -90);
        view(0, -80);  % Side view from the left, with a slight elevation

        grid(subplotPLD, 'off');

        % Indices for left and right landmarks (adjusted for MATLAB's 1-based indexing)
        leftLandmarkIndices = [2, 3, 4, 8, 10, 12, 14, 16, 18, 19, 20, 24, 26, 28, 30, 32, 34];  % Left side landmarks
        rightLandmarkIndices = [5, 6, 7, 9, 11, 13, 15, 17, 21, 22, 23, 25, 27, 29, 31, 33];  % Right side landmarks

        % Define colors for left and right
        leftColor = [0.4660 0.6740 0.1880];  % Color for left part of the body
        rightColor = [0 0.4470 0.7410];  % Color for right part of the body

        % Connect body parts within clusters with lines
        for b_part = 1:length(clusters)
            cluster_points = clusters{b_part};
            for foton = 1:(length(cluster_points) - 1)
                idx1 = cluster_points(foton);
                idx2 = cluster_points(foton + 1);

                % Check if the indices are in the left or right sets
                if ismember(idx1, leftLandmarkIndices) || ismember(idx2, leftLandmarkIndices)
                    lineColor = leftColor;  % Assign left color (green) if any index is in left landmarks
                elseif ismember(idx1, rightLandmarkIndices) || ismember(idx2, rightLandmarkIndices)
                    lineColor = rightColor;  % Assign right color (blue) if any index is in right landmarks
                else
                    lineColor = [0, 0, 0];  % Default color (black) for lines connected to the nose or unspecified
                end

                line([x_coords(idx1), x_coords(idx2)],...
                    [y_coords(idx1), y_coords(idx2)],...
                    [z_coords(idx1), z_coords(idx2)], 'Color', lineColor, 'Linewidth', 3);
            end
        end


        % % Draw or update the circle detection around the wrist
        % for idx = 1:length(highlightIndices)
        %     foton = highlightIndices(idx);
        %
        %     % Define coordinates for the corners of the shape around the point
        %     if idx == 1  % Square for the eye
        %         squareX = x_coords(foton) + highlightSize_square * [-1.5, 1.5, 1.5, -1.5, -1.5];
        %         squareY = y_coords(foton) + highlightSize_square * [-1.5, -1.5, 1.5, 1.5, -1.5];
        %         squareZ = z_coords(foton) * ones(1, 5);  % Keep the square in the same plane
        %         highlightColor = highlightColorEye;  % Red for the eye
        %
        %         % Draw the square using patch
        %         %highlightPatch(idx) = patch(squareX, squareY, squareZ, 'FaceColor', 'none', 'EdgeColor', highlightColor, 'LineWidth', 2, 'Linestyle', '-.');
        %
        %     else  % Circle for the wrist
        %
        %         % Create a set of points that form a circle in 3D
        %         theta = linspace(0, 2*pi, 50); % Number of points can be adjusted for smoothness
        %         circleX = x_coords(foton) + highlightSize_circle* cos(theta);
        %         circleY = y_coords(foton) + highlightSize_circle* sin(theta);
        %         circleZ = z_coords(foton) * ones(size(circleX));  % Keep the circle in the same plane
        %         highlightColor = highlightColorWrist;
        %
        %         % Draw the circle using patch
        %         highlightPatch(idx) = patch(circleX, circleY, circleZ, 'FaceColor', 'none', 'EdgeColor', 'k', 'LineWidth', 2, 'Linestyle', '-');
        %
        %     end
        %
        % end


        % Add a horizontal line to 0ms (onset of the movement ACC)
        if timePLD == movement_onset
            % Get the range of x coordinates for the line
            xRange = xlim(subplotPLD);
            xExtendedRange = [xRange(1) - 0.2, xRange(2) + 0.2];  % Extend the range a bit on both sides

            % Plot the line indicating the onset
            line(xExtendedRange, [WristY, WristY], 'Color', 'r', 'LineWidth', 2, 'LineStyle', '--');
            %legend('Onset', 'Location', 'southeast', 'FontSize', 9);
        end


        % If the current frame is the onset frame, add a horizontal line
        if timePLD == basketball_onset
            % Get the range of x coordinates for the line
            xRange = xlim(subplotPLD);
            xExtendedRange = [xRange(1) - 0.2, xRange(2) + 0.2];  % Extend the range a bit on both sides

            % Plot the line indicating the onset
            line(xExtendedRange, [EyeY, EyeY], 'Color', 'k', 'LineWidth', 2, 'LineStyle', ':');
            %legend('Onset', 'Location', 'southeast', 'FontSize', 9);
        end


        % Set axis limits for consistent scaling
        axis('equal');


        axesPosition_PLD = get(subplotPLD, 'Position');  % Get the position of the current axes
        normalizedBottom_PLD = axesPosition_PLD(2);  % Bottom of the axes in normalized units

        % Position the text at the bottom center of each subplot
        text('Parent', subplotPLD, 'String', [num2str(EEG.times(timePLD)), ' ms'], ...
            'Units', 'normalized', ...
            'Position', [0.5, normalizedBottom_PLD - 0.1, 0], ... % You may need to adjust the 0.1 offset
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'top', ... % 'top' aligns the text at its top to the given Y position
            'FontSize', 11, 'FontWeight', 'bold');  % Adjust font size as needed


        % if iPLD == 1
        %
        %     Add legend outside the loop
        %     if exist('highlightPatch', 'var')
        %         legend(highlightPatch, highlightLabels, 'Location', 'southeast', 'FontSize', 10);
        %     end
        %
        %     %axis(subplotPLD, 'off'); % This turns off the axis lines, ticks, and background
        %     set(get(subplotPLD, 'XLabel'), 'Visible', 'on'); % Make the X-axis label visible
        %     set(get(subplotPLD, 'YLabel'), 'Visible', 'on'); % Make the Y-axis label visible
        %     set(get(subplotPLD, 'ZLabel'), 'Visible', 'on'); % Make the Z-axis label visible
        %
        %     % After plotting data and setting axis off
        %     xlabelHandle = get(subplotPLD, 'XLabel');
        %     ylabelHandle = get(subplotPLD, 'YLabel');
        %     zlabelHandle = get(subplotPLD, 'ZLabel');
        %
        %     % Adjust label positions
        %     % Note: you will need to adjust these values based on your specific plot and requirements
        %     set(xlabelHandle, 'Position', get(xlabelHandle, 'Position') + [0.001, 0, 0.001]);
        %     set(ylabelHandle, 'Position', get(ylabelHandle, 'Position') + [-0.1, -0.1, 0]);
        %     set(zlabelHandle, 'Position', get(zlabelHandle, 'Position') + [0, 0, 1]);
        %
        %     % Then manually add text objects at the desired label positions
        %     xlabelPos = get(get(subplotPLD, 'XLabel'), 'Position'); % Get current label position
        %     ylabelPos = get(get(subplotPLD, 'YLabel'), 'Position'); % Get current label position
        %     zlabelPos = get(get(subplotPLD, 'ZLabel'), 'Position'); % Get current label position
        %
        %     % Now, add the text objects
        %     text(xlabelPos(1), xlabelPos(2), xlabelPos(3), 'X', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'Color', 'k');
        %     text(ylabelPos(1), ylabelPos(2), ylabelPos(3), 'Y', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', 'Color', 'k');
        %     text(zlabelPos(1), zlabelPos(2), zlabelPos(3), 'Z', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', 'Color', 'k');
        % end

        % Make the axes lines transparent
        set(subplotPLD, 'XColor', 'none', 'YColor', 'none', 'ZColor', 'none');


    end



    if cond == 1
        sgtitle('Grand Average Motion: Hits', 'Color',"#A2142F", 'Fontweight', 'bold'); % Super title
    elseif cond ==2
        sgtitle('Grand Average Motion: Misses', 'Color',"#A2142F", 'Fontweight', 'bold'); % Super title
    elseif cond == 3
        sgtitle('Grand Average Motion', 'Color',"#A2142F", 'Fontweight', 'bold'); % Super title
    end


    if cond == 1

        saveas(gcf, [outpath, '\\group_analysis\\', 'Motion_grand_avg_hit', '.jpg']); % Save the figure as a PNG image

        %save_fig(gcf,[outpath, '\\group_analysis\\',], 'Motion_grand_avg_hit');


    elseif cond ==2

        saveas(gcf, [outpath, '\\group_analysis\\','Motion_grand_avg_miss', '.jpg']); % Save the figure as a PNG image

        %save_fig(gcf,[outpath, '\\group_analysis\\',], 'Motion_grand_avg_miss');


    elseif cond == 3

        saveas(gcf, [outpath, '\\group_analysis\\','Motion_grand_avg', '.jpg']); % Save the figure as a PNG image

        save_fig(gcf,[outpath, '\\group_analysis\\',], 'Motion_grand_avg',...
        'fontsize', 8, ...
        'figsize', [35, 20], ...
        'figtypes', {'.png', '.svg'},...
        'dpi', 600);

    end


    disp(['Condition ', num2str(cond), ' finalized!']);


end



%%

