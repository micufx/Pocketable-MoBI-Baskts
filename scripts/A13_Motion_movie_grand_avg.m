clc, clear, close all;

%% Motion capture combined with mobile EEG (grand average movie)

% This code creates a grand average movie of frame-by-frame motion and EEG 
% combined data synchronously.

% Miguel Contreras-Altamirano, 2025

%% EEG data loading

mainpath = 'C:\Users\micua\Desktop\eeglab2023.0\'; % eeglab folder
path = 'C:\Users\micua\OneDrive - Benemérita Universidad Autónoma de Puebla\NCP_Basketball\MediaPipe\';
outpath = 'C:\\Users\\micua\\OneDrive - Benemérita Universidad Autónoma de Puebla\\Oldenburg_University\\Thesis\\data_hoops\\';
files = dir( fullfile( path,'\*.xdf')); % listing data sets

num_conditions = 3; % (Conditions and overall: 1=hit 2=miss 3=all)

% Ask the user if they want to create a video
create_video = input('Do you want to create a video for the analysis? (yes/no): ', 's');
create_video = lower(create_video);  % Normalize input
create_video_flag = strcmp(create_video, 'yes');  % Flag for video creation


%% Selecting participant

for cond=1 : num_conditions


    if cond == 1 % 'hit'

        load([outpath , 'ACC_grand_avg_rev_hit','.mat']); % Loading accelerometer data
        % load([outpath , 'ACC_grand_avg_dev_hit','.mat']); % Loading accelerometer data
        load([outpath , 'PLD_grand_avg_hit.mat'], 'averageTimeseriesMp', 'timestamps_mp');
        load([outpath , 'Study_ERP_image_hit','.mat']); % Loading accelerometer data

        % Import EEG processed data
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % Open eeglab
        EEG = pop_loadset('filename',['Grand_avg_hits','.set'],'filepath', outpath); % Loading set file
        eeglab redraw

    elseif cond == 2 % 'miss'

        load([outpath , 'ACC_grand_avg_rev_miss','.mat']); % Loading accelerometer data
        % load([outpath , 'ACC_grand_avg_dev_miss','.mat']); % Loading accelerometer data
        load([outpath , 'PLD_grand_avg_miss.mat'], 'averageTimeseriesMp', 'timestamps_mp');
        load([outpath , 'Study_ERP_image_miss','.mat']); % Loading accelerometer data

        % Import EEG processed data
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % Open eeglab
        EEG = pop_loadset('filename',['Grand_avg_misses','.set'],'filepath', outpath); % Loading set file
        eeglab redraw

    elseif cond == 3  % % 'none'

        load([outpath , 'ACC_grand_avg_rev','.mat']); % Loading accelerometer data
        % load([outpath , 'ACC_grand_avg_dev','.mat']); % Loading accelerometer data
        load([outpath , 'PLD_grand_avg.mat'], 'averageTimeseriesMp', 'timestamps_mp');
        load([outpath , 'Study_ERP_image','.mat']); % Loading accelerometer data

        % Import EEG processed data
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % Open eeglab
        EEG = pop_loadset('filename',['Grand_avg_all','.set'],'filepath', outpath); % Loading set file
        eeglab redraw

    end


    % Rewriting variables for simplicity
    timeseries_mp = averageTimeseriesMp;
    timeseries_acc_mag = avgAccMagnitude_across_rev;
    timestamps_acc_mag = epochTimes_rev;


    % Channel to visualize
    chan = find(strcmp({EEG.chanlocs.labels}, 'Cz'));


    % Calculate the mean and standard deviation of the mean
    ERP = mean(EEG.data(:, :, :), 3);  % Mean across the third dimension (trials)
    erp_std = std(EEG.data(:, :, :), 0, 3); % --> Standard deviation across trials
    n_trials = size(EEG.data, 3);
    standard_error = erp_std / sqrt(n_trials); % Standard error of the Mean
    erp_pre_SD = standard_error(chan, :);


    % Saving new information in variables (for ERP)
    timestamps_eeg = EEG.times;
    timeseries_eeg = ERP; % Re-writing variable names for analysis


    %% Motion visualization

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

    highlightSize_square = 0.04;  % Size of the square detection area
    highlightSize_circle = 0.04;  % Size of the circledetection area


    firstOnsetFrame = NaN;  % Initialize as NaN, will be updated with the frame number of the first onset
    movement_onset = find(EEG.times == 0);
    EyeIndices = 6;  % Right eye (outer)
    WristIndices = 17;  % Right wrist


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
    lightenFactor = 0.8;  % Adjust this to make the color lighter (closer to 1 makes it lighter)
    colors = colors + lightenFactor * (1 - colors);

    BP_acc = find(EEG.times < grand_avgOnsetTime_rev);
    BP_acc = BP_acc(end);
    % Find the index of the most negative point (peak) in the ERP data
    [~, peakIdx] = min(ERP(chan, 1 : BP_acc));  % Directly find the minimum for negative peaks
    peakTime = EEG.times(peakIdx);  % Time corresponding to the peak

    % Find the index of the highest point (peak) in the ERP data
    % [~, peakIdx] = max(abs(EEG.data(chan,1:BP)));  % Use 'abs' if you're interested in the highest magnitude regardless of sign
    % peakTime = EEG.times(peakIdx);  % Time corresponding to the peak

    % Define the time window around the peak
    timeWindowStart = -1500; % vgr., peakTime - 830 --> ms before the peak
    timeWindowEnd = 0; %vgr., peakTime + 50 --> ms after the peak

    % Ensure the time window is within the bounds of your data
    timeWindowStart = max(timeWindowStart, min(EEG.times));
    timeWindowEnd = min(timeWindowEnd, max(EEG.times));

    % % Find the global maximum and minimum across all channels
    % globalMax = max(max(EEG.data(:)));  % Max across all channels and all times
    % globalMin = min(min(EEG.data(:)));  % Min across all channels and all times

    % Define your y-limits
    yLimits = [-40, 30];
    ylim(yLimits);

    % Assigning y-limits to the data for better visualization
    EEG.data_masked = ERP; % Just for visualization porpouses (is like zooming in)
    EEG.data_masked(EEG.data_masked < yLimits(1) | EEG.data_masked > yLimits(2)) = NaN;
    GFP(GFP < yLimits(1) | GFP > yLimits(2)) = NaN;
    % timeseries_acc_mag(timeseries_acc_mag < yLimits(1) | timeseries_acc_mag > yLimits(2)) = NaN;

    % Set up the figure with a larger size
    %fig = figure('Units', 'pixels', 'Position', [100, 100, 1000, 800], 'Renderer', 'painters'); % fig = figure('Units', 'pixels', 'Renderer', 'painters'); [100, 100, 800, 600]
    fig = figure('units','normalized','outerposition', [0 0 1 1]);

    % Initialize subplots outside the loop
    subplotPLD = subplot(2, 3, [1, 4]);


    % Plot ERP Image (Top Center)
    subplotERPImage = subplot(2, 3, 3);

    % erp_data = squeeze(all_trials_data(chan, :, :));  % Squeeze the data to remove singleton dimensions and transpose
    % sortvar = zeros(1, size(erp_data, 2));  % One value per trial (876 trials in this case)
  
    % erpimage(erp_data, [], EEG.times, 'Cz', 1, 1,...
    % 'yerplabel', {'Grand Average ERP'},'erp', 'off', 'cbar', 'off','cbar_title', '\muV',...
    % 'vert', [grand_avgOnsetTime_rev], ...
    % 'topo', {chan, EEG.chanlocs, EEG.chaninfo},...
    % 'caxis', [-40 40], 'avg_type', 'Gaussian', 'vert', grand_avgOnsetTime_rev,...
    % 'img_trialax_label', {'All trials'}, 'img_trialax_ticks', [0 : 500 :size(erp_data,2)]);
      
    % % Step 2: Apply smoothing
    % smooth_window = 20; % Adjust for slight smoothing if needed
    % smoothed_data = movmean(erp_data, smooth_window, 2); % Smooth across time


    % Step 1: Extract the data for the channel of interest
    latency = EEG.times;
    erp_data = squeeze(EEG.data(chan, :, :));  % Squeeze the data to remove singleton dimensions and transpose
    sortvar = zeros(1, size(erp_data, 2));  % One value per trial (876 trials in this case)

    % % Step 3: Use erpimage
    % erpimage(erp_data, [], EEG.times, 'Cz', 1, 1,...
    %     'yerplabel', {'Grand Average ERP'},'erp', 'off', 'cbar', 'off','cbar_title', '\muV',...
    %     'vert', [grand_avgOnsetTime_rev], ...
    %     'topo', {chan, EEG.chanlocs, EEG.chaninfo},...
    %     'caxis', [-20 20],...
    %     'vert', grand_avgOnsetTime_rev,... %         'avg_type', 'Gaussian',...
    %     'img_trialax_label', {'Participants'}, 'img_trialax_ticks', [0 : 1 :size(erp_data,2)]);

    % Step 1: Define parameters
    clipping_range = [-20 20]; % Match the caxis range in erpimage

    % Step 2: Plot with imagesc
    imagesc(latency, 1:size(erp_data, 2), erp_data'); % Transpose for correct orientation
    set(gca, 'YDir', 'normal'); % Ensure correct orientation

    % Step 3: Colormap and axis adjustments
    colormap('jet'); % Similar to 'erpimage' colormap
    % c = colorbar('Ticks',[-20 -10 0 10 20]);  % Replace minValue and maxValue with your actual min and max
    % c.Label.String = 'Amplitude [\muV]';
    % c.Label.FontSize = 14;
    caxis(clipping_range); % Set color limits to match erpimage
    set(gca, 'FontSize', 13);

    % Step 4: Add vertical lines and labels
    hold on;
    xline(0, 'r--', 'LineWidth', 2.5); % Onset line
    xline(grand_avgOnsetTime_rev, 'k:', 'LineWidth', 2.5); % Additional onset lines if needed
    xlabel('Time [ms]', 'FontSize', 16);
    ylabel('Participants', 'FontSize', 16);
    title(EEG.chanlocs(chan).labels, 'FontSize', 17);   % title('Grand Average Motion Tracking and ERP [N=26]', 'FontSize', 20);
    %subtitle('Event Related Potential at [Cz]', 'FontSize', 19);

    % Optional: Adjust Y-axis tick labels
    yticks(1:size(erp_data, 2));
    yticklabels(1:size(erp_data, 2)); % Adjust as per participant indexing



    subplotTopo = subtightplot(2, 3, 2);
    c = colorbar('Ticks',[-20 -10 0 10 20]);
    %c.TickLabels = {'-', '+'};
    c.Label.String = 'Amplitude [\muV]';
    c.Label.FontSize = 16;
    c.Position = [0.383172034845905,0.609276063931848,0.004631856339674,0.247492481203008]; % Set the colorbar position

    subplotERP = subplot(2, 3, [5, 6]);


    % Initialize the vertical line outside of the loop
    currentPointLine = line(subplotERP, [EEG.times(1), EEG.times(1)], yLimits, 'Color', 'r', 'LineWidth', 2);
    %currentPointLine_PLD_onset = line(subplotERP, [0, 0], yLimits, 'Color', 'r', 'LineWidth', 2, 'Linestyle', '--');

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


    % Highlight the baseline period
    baselineStart = -2500; % adjust to your baseline start time
    baselineEnd = -2000; % adjust to your baseline end time

    % Get the current y-axis limits
    ylimits = ylim;

    % Fill between the baseline period with a light blue color and some transparency
    %fill([baselineStart, baselineStart, baselineEnd, baselineEnd], [ylimits(1), ylimits(2), ylimits(2), ylimits(1)], [0.4660 0.6740 0.1880], 'FaceAlpha', 0.2, 'EdgeColor', 'none');

    % RP highlight transparency
    fill([baselineStart+1500, baselineStart+1500, baselineEnd+2000, baselineEnd+2000], [ylimits(1), ylimits(2), ylimits(2), ylimits(1)], [0.8500 0.3250 0.0980], 'FaceAlpha', 0.2, 'EdgeColor', 'none');

    % Customize ERP axes
    title(subplotERP, 'Grand Average ERP', 'Color', "#0072BD", 'FontWeight', 'bold', 'FontSize', 16);
    subtitle(subplotERP, [num2str(EEG.times(1)), ' [ms]'], 'FontWeight', 'bold', 'FontSize', 16);
    ylabel(subplotERP, 'Amplitude [\muV]', 'FontSize', 16, 'Color', 'k');
    xlabel(subplotERP, 'Time [ms]', 'FontSize', 16);
    xlim(subplotERP, [EEG.times(1) EEG.times(end)]);
    ylim(subplotERP, yLimits);
    yticks(subplotERP, yLimits(1):10:yLimits(2));
    set(subplotERP, 'YDir', 'reverse');
    %grid(subplotERP, 'on');
    axis(subplotERP, 'tight');
    set(gca, 'FontSize', 16);

    % Create patch for the highlight shadow once
    % peakPatch = patch(subplotERP, 'XData', [timeWindowStart, timeWindowStart, timeWindowEnd, timeWindowEnd], ...
    %     'YData', [min(ylim), max(ylim), max(ylim), min(ylim)], ...
    %     'FaceColor', "#D95319", 'FaceAlpha', 0.2, 'Edgecolor', 'none');

    % Set y-axis limits and ticks for ERP/GFP data
    ylim(subplotERP, yLimits);
    yticks(subplotERP, yLimits(1):10:yLimits(2));



    % Calculate the upper and lower bounds of the shaded area of RP
    upperBound = ERP(chan,:) + erp_pre_SD;
    lowerBound = ERP(chan,:) - erp_pre_SD;

    % Create the shaded area representing the SD around the mean
    fill([EEG.times fliplr(EEG.times)], ...
        [upperBound fliplr(lowerBound)], ...
        [0 0.4470 0.7410], 'FaceAlpha', 0.2, 'EdgeColor', 'none');



    % Plot the main ERP and GFP lines once
    %gfpLine = plot(EEG.times, GFP, 'Color', "#77AC30", 'LineWidth', 2.5, 'LineStyle', '-.');
    erpLine = plot(EEG.times, EEG.data_masked(chan,:), 'Color', "#0072BD", 'LineWidth', 3);
    uistack(erpLine, 'top');  % Make sure the ERP is on top


    % Determine the full range of ACC data for plotting
    accMax = 100; %accMax = max(timeseries_acc_mag);
    accMin = min(timeseries_acc_mag);

    % Create a second axes for the ACC data that shares the same x-axis as subplotERP
    ax2 = axes('Position', subplotERP.Position, 'XAxisLocation', 'top', 'YAxisLocation', 'right', ...
        'Color', 'none', 'XColor', 'none', 'YColor', 'k', 'Parent', fig);
    set(gca, 'FontSize', 16);
    ylabel(ax2, 'Acceleration Magnitude [m/s^2]', 'FontSize', 16, 'Color', 'k');
    
    linkaxes([subplotERP ax2], 'x'); % Link the x-axes of both axes

    % Set the y-axis limits for the ACC data to show the full range
    set(ax2, 'YLim', [accMin, accMax]);


    % Plot ACC data on the second axes
    hold(ax2, 'on');
    accLine = plot(ax2, timestamps_acc_mag, timeseries_acc_mag, 'Color', "k", 'LineStyle', '-', ...
        'Marker', 'o', 'MarkerIndices', 1:10:length(timeseries_acc_mag),'LineWidth', 2.5);

    % % Create the shaded area representing the SD around the mean of accelerometer data
    % fill([timestamps_acc_mag fliplr(timestamps_acc_mag)], ...
    %     [upperBound_grand_avg_dev' fliplr(lowerBound_grand_avg_dev')], ...
    %     'k', 'FaceAlpha', 0.2, 'EdgeColor', 'none');

    % Plot the onset marker off the Reverse Computational Method (the
    % method that won in comparison with the others, also it goes according
    % literature and the SD method shows the same detection as well)


    % Plot the Basketball onset
    accOnset_rev = line(ax2, [grand_avgOnsetTime_rev grand_avgOnsetTime_rev], [accMin, accMax], 'Color', 'k', 'LineStyle', ':', 'LineWidth', 2);

    % Add a label to the line movement onset
    %text(grand_avgOnsetTime_rev, accMax, 'MP', 'Color', 'k', 'FontSize', 10, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', 'Rotation', 90, 'FontWeight', 'bold');

    % Adding line of the movement onset
    currentPointLine_PLD_onset = line(subplotERP, [0, 0], yLimits, 'Color', 'r', 'LineWidth', 2, 'Linestyle', '--');

    % Add a label to the line basketball onset
    %text(0, accMax, 'ACC', 'Color', 'r', 'FontSize', 10, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', 'Rotation', 90, 'FontWeight', 'bold');


    % Add legend to the ERP plot
    legend(subplotERP, [erpLine, accLine, other_chan], {EEG.chanlocs(chan).labels, 'ACC', 'Channels'}, 'Location', 'northwest','FontSize', 16);


    % Reconfigure position to maximize the size of the axes subplot
    set(ax2, 'Outerposition', [0.327909122695361,0.063478233815164,0.637599836568569,0.416601750567577]);
    set(ax2, 'Innerposition', [0.410797101449275,0.109304426377597,0.494139873340641,0.339530426712575]);
    set(ax2, 'Position', [0.410797101449275,0.109304426377597,0.494139873340641,0.339530426712575]);



    %Define manual axis limits based on the observed range of motion
    % xLimManual = [-0.1, 0.5]; % Replace with appropriate min and max values
    % yLimManual = [-0.8, 0.9]; % Replace with appropriate min and max values
    % zLimManual = [-0.2, 0.6]; % Replace with appropriate min and max values


    % Define the skip factor (e.g., plot every 5th time point)
    %skipFactor = 20; % Just to display faster if neccesary


    %% Settings for video - Video Generation Part
    if create_video_flag  % Only run this if the user chose to create a video

        % Settings for video
        if cond == 1 % hit
            videoFile = ['hoop_hit_grand_avg', '.mp4'];
        elseif cond == 2 % miss
            videoFile = ['hoop_miss_grand_avg', '.mp4'];
        elseif cond == 3 % none
            videoFile = ['hoop_grand_avg', '.mp4'];
        end

        % Set up video writer
        videoObj = VideoWriter(videoFile, 'MPEG-4');
        videoObj.FrameRate = 20;  % Adjust the frame rate as needed
        open(videoObj);


        % Loop through the frames to create the animation
        for i = 1 : numFrames %:skipFactor

            landmarks = timeseries_mp(:, i);

            % Extract the Y-coordinates of the right eye and right wrist
            EyeY = landmarks(EyeIndices * 3 - 1);
            WristY = landmarks(WristIndices * 3 - 1);

            % Onset detection logic: Mark the first frame where the wrist Y-coordinate equals or overpasses the Eye Y-coordinate
            if isnan(firstOnsetFrame) && i == movement_onset % Basketball onset reference point, frame of intersection at 0ms (EyeY >= WristY)
                firstOnsetFrame = i;
            end

            % Plot PLD movement transition
            subplotPLD = subplot(2, 3, [1, 4]);

            % Split the data into X, Y, and Z coordinates for each landmark
            x_coords = landmarks(1:3:end);
            y_coords = landmarks(2:3:end);
            z_coords = landmarks(3:3:end);

            % Create a 3D plot of the landmarks for each body part with unique colors
            s = scatter3(x_coords, y_coords, z_coords, 30, pointColors, 'filled', 'o','MarkerEdgeColor','flat', 'MarkerEdgeColor','k');
            s.SizeData = 55;

            % Increase the size of the circle for the right wrist
            hold on;
            wristMarker = scatter3(x_coords(rightWristIndex), y_coords(rightWristIndex), z_coords(rightWristIndex), ...
                300, 'k', 'filled', 'o', 'MarkerEdgeColor', 'k', 'LineWidth',2); % Larger black circle for the right wrist

            % Ensure the wrist marker is on top
            uistack(wristMarker, 'top'); % Moves the wrist marker to the top of all plotted elements

            % Customize the plot appearance (e.g., title, labels, etc.)
            title('Grand Average Motion Tracking', 'Color', "#FF0000", 'FontSize', 16);
            subtitle([num2str(EEG.times(i)), ' ms'], 'FontWeight','bold', 'FontSize', 16);
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
                        [z_coords(idx1), z_coords(idx2)], 'Color', lineColor, 'Linewidth', 4);
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


            % % Add legend outside the loop
            % if exist('highlightPatch', 'var')
            %     legend(highlightPatch, highlightLabels, 'Location', 'southeastoutside', 'FontSize', 10);
            % end


            % % If the current frame is the onset frame, add a horizontal line
            % if i == grand_avgOnsetTime_rev
            %     % Get the range of x coordinates for the line
            %     xRange = xlim(subplotPLD);
            %     xExtendedRange = [xRange(1) - 0.2, xRange(2) + 0.2];  % Extend the range a bit on both sides
            %
            %     % Plot the line indicating the onset
            %     line(xExtendedRange, [EyeY, EyeY], 'Color', 'k', 'LineWidth', 2, 'LineStyle', ':');
            %     legend('Onset', 'Location', 'southeast', 'FontSize', 10);
            % end
            %
            % % Add a horizontal line to 0ms (onset of the movement ACC)
            % if i == movement_onset
            %     % Get the range of x coordinates for the line
            %     xRange = xlim(subplotPLD);
            %     xExtendedRange = [xRange(1) - 0.2, xRange(2) + 0.2];  % Extend the range a bit on both sides
            %
            %     % Plot the line indicating the onset
            %     line(xExtendedRange, [WristY, WristY], 'Color', 'r', 'LineWidth', 2, 'LineStyle', '--');
            %     %legend('Onset', 'Location', 'southeast', 'FontSize', 9);
            % end


            % Set axis limits for consistent scaling
            axis('image');


            % %axis(subplotPLD, 'off'); % This turns off the axis lines, ticks, and background
            % set(get(subplotPLD, 'XLabel'), 'Visible', 'on'); % Make the X-axis label visible
            % set(get(subplotPLD, 'YLabel'), 'Visible', 'on'); % Make the Y-axis label visible
            % set(get(subplotPLD, 'ZLabel'), 'Visible', 'on'); % Make the Z-axis label visible
            %
            % % After plotting data and setting axis off
            % xlabelHandle = get(subplotPLD, 'XLabel');
            % ylabelHandle = get(subplotPLD, 'YLabel');
            % zlabelHandle = get(subplotPLD, 'ZLabel');
            %
            % % Adjust label positions
            % % Note: you will need to adjust these values based on your specific plot and requirements
            % set(xlabelHandle, 'Position', get(xlabelHandle, 'Position') + [0.3, 0, 0.3]);
            % set(ylabelHandle, 'Position', get(ylabelHandle, 'Position') + [-0.1, -0.1, 0]);
            % set(zlabelHandle, 'Position', get(zlabelHandle, 'Position') + [0, 0, 1]);
            %
            % % Then manually add text objects at the desired label positions
            % xlabelPos = get(get(subplotPLD, 'XLabel'), 'Position'); % Get current label position
            % ylabelPos = get(get(subplotPLD, 'YLabel'), 'Position'); % Get current label position
            % zlabelPos = get(get(subplotPLD, 'ZLabel'), 'Position'); % Get current label position
            %
            % % Now, add the text objects
            % text(xlabelPos(1), xlabelPos(2), xlabelPos(3), 'X', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'Color', 'k');
            % text(ylabelPos(1), ylabelPos(2), ylabelPos(3), 'Y', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', 'Color', 'k');
            % text(zlabelPos(1), zlabelPos(2), zlabelPos(3), 'Z', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', 'Color', 'k');

            % Make the axes lines transparent
            set(subplotPLD, 'XColor', 'none', 'YColor', 'none', 'ZColor', 'none');

            % After plotting the data for the current frame, set the manual axis limits
            % xlim(subplotPLD, xLimManual);
            % ylim(subplotPLD, yLimManual);
            % zlim(subplotPLD, zLimManual);

            % Plot topography
            % subtightplot(2, 2, 2);
            % pop_topoplot(EEG, 1, EEG.times(i), '', [], 0, 'electrodes', 'off', 'maplimits', [-20 20], ...
            %     'whitebk', 'on', ...
            %     'shading', 'interp');
            % ylabel('Amplitude [\muV]', 'FontSize', 10);
            % colormap(jet(250));


            subplotTopo = subtightplot(2, 3, 2);
            topoplot(ERP(:, i), EEG.chanlocs, 'electrodes', 'off', 'maplimits', [-20 20], ...
                'whitebk', 'on', ...
                'shading', 'interp');
            %title([num2str(EEG.times(i)), ' [ms]'], 'FontSize', 10, 'VerticalAlignment', 'baseline');
            colormap(jet(250));

            % Title adjusted
            axesPosition = get(subplotTopo, 'Position');  % Get the position of the current axes
            normalizedBottom = axesPosition(2);  % Bottom of the axes in normalized units

            % Position the text at the bottom center of each subplot
            text('Parent', subplotTopo, 'String', [num2str(EEG.times(i)), ' ms'], ...
                'Units', 'normalized', ...
                'Position', [0.5, normalizedBottom - 0.40, 0], ... % You may need to adjust the 0.1 offset
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'top', ... % 'top' aligns the text at its top to the given Y position
                'FontSize', 16, 'FontWeight', 'bold');  % Adjust font size as needed
            set(gca, 'FontSize', 16);


            % % Plot EEG waveform
            subtitle(subplotERP, [num2str(EEG.times(i)), ' ms'], 'FontWeight', 'bold', 'FontSize', 16);

            % Update the XData property of the vertical line to move it forward
            set(currentPointLine, 'XData', [EEG.times(i), EEG.times(i)]);


            if cond == 1
                sgtitle('Hits', 'Color', "#A2142F", 'FontSize', 16, 'Fontweight', 'bold'); % Super title
            elseif cond ==2
                sgtitle('Misses', 'Color', "#A2142F", 'FontSize', 16, 'Fontweight', 'bold'); % Super title
            elseif cond == 3
                %sgtitle('Grand Average Motion Tracking and ERP', 'Color', "#A2142F", 'Fontweight', 'bold'); % Super title
            end



            % Save the frame as an image in the RP peak
            if i == (find(EEG.times==-200))  % A couple of frames before Peak ERP index

                if cond == 1 % hit

                    saveas(gcf, [outpath, '\\group_analysis\\','Mind_grand_hoop_hit_BP', '.jpg']); % Save the figure as a PNG image
                    %save_fig(gcf,[outpath, '\\group_analysis\\',], 'Mind_grand_hoop_hit_BP');

                elseif cond == 2 % miss

                    saveas(gcf, [outpath, '\\group_analysis\\','Mind_grand_hoop_miss_BP', '.jpg']); % Save the figure as a PNG image
                    %save_fig(gcf,[outpath, '\\group_analysis\\',], 'Mind_grand_hoop_miss_BP');

                elseif cond == 3 % all

                    saveas(gcf, [outpath, '\\group_analysis\\','Mind_grand_hoop_BP', '.jpg']); % Save the figure as a PNG image
                    %save_fig(gcf,[outpath, '\\group_analysis\\',], 'Mind_grand_hoop_BP');

                end

            end


            % Save the frame as an image in the RP peak
            if i == (find(EEG.times==-2500))  % Basketball onset reference frame

                if cond == 1 % hit

                    saveas(gcf, [outpath, '\\group_analysis\\','Mind_grand_hoop_hit_0', '.jpg']); % Save the figure as a PNG image
                    %save_fig(gcf,[outpath, '\\group_analysis\\',], 'Mind_grand_hoop_hit_0');

                elseif cond == 2 % miss

                    saveas(gcf, [outpath, '\\group_analysis\\','Mind_grand_hoop_miss_0', '.jpg']); % Save the figure as a PNG image
                    %save_fig(gcf,[outpath, '\\group_analysis\\',], 'Mind_grand_hoop_miss_0');

                elseif cond == 3 % all

                    saveas(gcf, [outpath, '\\group_analysis\\','Mind_grand_hoop_0', '.jpg']); % Save the figure as a PNG image

                    % save_fig(gcf,[outpath, '\\group_analysis\\',], 'Mind_grand_hoop_0',...
                    %     'fontsize', 8, ...
                    %     'figsize', [35, 20], ...
                    %     'figtypes', {'.png', '.svg'},...
                    %     'dpi', 600);

                end

            end

            % % Save the frame as an image in the RP peak
            % if i == (find(EEG.times== round(grand_avgOnsetTime_rev) ))  % A couple of frames before Peak ERP index
            %
            %     if cond == 1 % hit
            %
            %         saveas(gcf, [outpath, '\\group_analysis\\','Mind_grand_hoop_hit_setpoint_', '.jpg']); % Save the figure as a PNG image
            %
            %     elseif cond == 2 % miss
            %
            %         saveas(gcf, [outpath, '\\group_analysis\\','Mind_grand_hoop_miss_setpoint_', '.jpg']); % Save the figure as a PNG image
            %
            %     elseif cond == 3 % all
            %         saveas(gcf, [outpath, '\\group_analysis\\','Mind_grand_hoop_setpoint_', '.jpg']); % Save the figure as a PNG image
            %
            %     end
            %
            % end


            % Capture frame
            frame = getframe(gcf);
            writeVideo(videoObj, frame);


            % Clear the figure to avoid overlap
            cla(subplotPLD);
            cla(subplotTopo);
            % cla(subplot(2, 2, 4));


        end

        % Close the video writer
        close(videoObj);

    end

    disp(['Condition ', num2str(cond), ' finalized!']);


end



%%

