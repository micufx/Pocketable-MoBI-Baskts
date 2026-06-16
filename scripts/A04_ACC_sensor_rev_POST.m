clc, clear, close all;

%% Onset detection with wrist sensor (movement onset - plotting)

% This code uses accelerometer data to detect the onset of the movement
% based on wrist acceleration, saving the onset of the movement of each
% trail of all participants. This second part is in charge to plot those
% detected movement onset timestamps after detection.

% Miguel Contreras-Altamirano, 2025

%% Loading data

mainpath = 'L:\Downloads\eeglab2023.0\'; % eeglab folder
path = 'L:\Downloads\basketball_RP\NCP_Basketball\MediaPipe\';
outpath = 'L:\Downloads\basketball_RP\Oldenburg_University\Thesis\data_hoops\';
files = dir( fullfile( path,'\*.xdf')); % listing data sets

% Add EEGLAB properly
if exist('eeglab','file') ~= 2
    addpath(mainpath);
end

num_conditions = 3; % (Conditions and overall: 1=hit 2=miss 3=all)

for sub = 1 : 1%length(files)

    participant = extractBefore(files(sub).name, '.xdf');
    out_subfold = [outpath, participant, '\\'];
    data = load_xdf([path, files(sub).name]); % Saving the data in a variable

    from = -2.5; % sec
    to = 1.004; % sec


    % Finding the number struct of MP and EEG
    for i = 1:length(data)
        currentName = data{1, i}.info.name;

        % Check if the current data is ACC
        if strcmp(currentName, 'Movella DOT B1')
            acc = i;
        end

        % Check if the current data is ACC
        if strcmp(currentName, 'Movella DOT B2')
            acc = i;
        end

        % Check if the current data is ACC
        if strcmp(currentName, 'Movella DOT B3')
            acc = i;
        end

        % Check if the current data is ACC
        if strcmp(currentName, 'Movella DOT B4')
            acc = i;
        end

        % Check if the current data is ACC
        if strcmp(currentName, 'Movella DOT B5')
            acc = i;
        end

        % Check if the current data is ACC
        if strcmp(currentName, 'Movella DOT B1 Marker')
            acc_marker = i;
        end

        % Check if the current data is ACC
        if strcmp(currentName, 'Movella DOT B2 Marker')
            acc_marker = i;
        end

        % Check if the current data is ACC
        if strcmp(currentName, 'Movella DOT B3 Marker')
            acc_marker = i;
        end

        % Check if the current data is ACC
        if strcmp(currentName, 'Movella DOT B4 Marker')
            acc_marker = i;
        end

        % Check if the current data is ACC
        if strcmp(currentName, 'Movella DOT B5 Marker')
            acc_marker = i;
        end

        % Check if the current data is EEG
        if contains(currentName, 'Android_EEG', 'IgnoreCase', true)
            eeg = i;
        end

    end


    % Assigning variables

    timeseries_acc = data{1, acc}.time_series; % Sensor time-series
    timestamps_acc = data{1, acc}.time_stamps; % Sensor zime-series

    timeseries_acc_marker = data{1, acc_marker}.time_series; % Sensor time-series
    timestamps_acc_marker = data{1, acc_marker}.time_stamps; % Sensor zime-series

    timeseries_eeg = data{1, eeg}.time_series; % EEG time-series
    timestamps_eeg = data{1, eeg} .time_stamps; % EEG timestamps


    %% Accelerometer data info

    % ACC sampling rate
    timestamp_range_acc = range(timestamps_acc); %  returns the difference between the maximum and minimum values of sample data in X.

    % Length of the recording
    length_minutes_acc = timestamp_range_acc / 60; % in minutes
    duration_seconds_acc = str2double(data{1, acc}.info.last_timestamp) - str2double(data{1, acc}.info.first_timestamp); %  in seconds

    % Double check based on data info (more accurate)
    sampling_rate_acc = str2double(data{1, acc}.info.sample_count) / duration_seconds_acc; % in seconds

    % Display the results
    disp(['Sampling rate ACC: ', num2str(sampling_rate_acc), ' samples per second']);
    disp(['ACC recording: ', num2str(length_minutes_acc), ' minutes']);


    for cond=3 : num_conditions


        load([out_subfold, 'events_all_', participant,'.mat']); % Loading events file


        if cond == 1 % 'hit'

            load([out_subfold, 'ACC_sd_hit_', participant,'.mat']); % Loading accelerometer data
            load([out_subfold, 'ACC_rev_hit_', participant,'.mat']); % Loading accelerometer data
            load([out_subfold, 'ACC_dev_hit_', participant,'.mat']); % Loading accelerometer data

        elseif cond == 2 % 'miss'

            load([out_subfold, 'ACC_sd_miss_', participant,'.mat']); % Loading accelerometer data
            load([out_subfold, 'ACC_rev_miss_', participant,'.mat']); % Loading accelerometer data
            load([out_subfold, 'ACC_dev_miss_', participant,'.mat']); % Loading accelerometer data

        elseif cond == 3  % % 'none'

            load([out_subfold, 'ACC_sd_', participant,'.mat']); % Loading accelerometer data
            load([out_subfold, 'ACC_rev_', participant,'.mat']); % Loading accelerometer data
            load([out_subfold, 'ACC_dev_', participant,'.mat']); % Loading accelerometer data

        end



        %% Defining conditions or general view

        % Redifining new onsets based on Accelerometer data
        onsetTimes = [events_ACC.time];
        onsetFrames = [events_ACC.latency];

        % Divide PLD by conditions
        % Initialize empty vectors to store hit and miss onsets
        hitOnsets = [];
        missOnsets = [];
        hitFrames = [];
        missFrames = [];

        % Loop through the event markers

        for i = 1:length(events_ACC)
            if strcmp(events_ACC(i).type, 'hit_ACC')
                % If the event marker is '1', it's a hit
                hitOnsets = [hitOnsets, onsetTimes(i)];
                hitFrames = [hitFrames, onsetFrames(i)];
            elseif strcmp(events_ACC(i).type, 'miss_ACC')
                % If the event marker is '2', it's a miss
                missOnsets = [missOnsets, onsetTimes(i)];
                missFrames = [missFrames, onsetFrames(i)];
            end
        end

        % Now you have two vectors: hitOnsets and missOnsets, with the times categorized



        if cond == 1 % hit
            onsetTimes = hitOnsets; % Overwrite variable to analize a specific condition
            onsetFrames = hitFrames;
        elseif cond == 2 % miss
            onsetTimes = missOnsets;
            onsetFrames = missFrames;
        elseif cond == 3 % none
            onsetTimes = onsetTimes;
            onsetFrames = onsetFrames;
        end


        %% Syncronizing onset times by Euclidean distance


        % % Interpolation
        % timeseries_acc = interp1(timestamps_acc, timeseries_acc', timestamps_eeg, 'linear')';
        % timestamps_acc = timestamps_eeg;
        %
        %
        % % Find the time of those indexes in the ACC data
        % markers_time_acc = onsetTimes;
        % markers_sample_acc = onsetFrames;
        % numEvents = length(markers_sample_acc);


        % Optional
        % Using interpolation to get the exact match for onset times
        idx_nearest_acc = interp1(timestamps_acc, 1:length(timestamps_acc), onsetTimes, 'nearest', 'extrap');

        % % % Find the index of the nearest timestamp for each onset time
        % idx_nearest_acc = arrayfun(@(onset) find(abs(timestamps_acc - onset) == min(abs(timestamps_acc - onset))), onsetTimes);

        % Find the time of those indexes in the ACC data
        markers_time_acc = timestamps_acc(idx_nearest_acc);
        markers_sample_acc = idx_nearest_acc;
        numEvents = length(markers_sample_acc);



        % Plot sensor data
        fig = figure('units','normalized','outerposition', [0 0 1 1]);
        plot(timestamps_acc, timeseries_acc(1,:), 'Color','#0072BD', 'LineWidth', 0.6);

        hold on;

        % Plot vertical dashed lines and color markers based on their labels
        for i = 1: length(events_ACC)

            % Plot vertical dashed lines
            line_handle = plot([events_ACC(i).time, events_ACC(i).time], get(gca, 'YLim'), '--', 'Color', 'k');

            % Plot vertical dashed lines
            % plot([events(i).time, events(i).time], get(gca, 'YLim'), '--', 'Color', 'k');

            % Color markers based on their labels
            if strcmpi(events_ACC(i).type, 'miss')
                scatter(events_ACC(i).time, 0, 'k', 'v', 'filled');
            elseif strcmpi(events_ACC(i).type, 'hit')
                scatter(events_ACC(i).time, 0, 'r', 'o', 'filled');
            end
        end

        xlabel('Time (s)');
        ylabel('Accelerometer [m/s]');
        legend('Onsets', 'Location', 'Best');
        title('Shooting Speed');
        grid on;

        % Set x-axis limits to focus on the relevant portion of the data
        xlim([min(timestamps_acc), max(timestamps_acc)])

        % Set y-axis limits to better visualize the data
        %ylim([min(timeseries_acc(1,:)), max(timeseries_acc(3,:))]);
        ylim([0 100]); % % mx_peak_acc= 174.6862 for sub_01 which is the highest, therefore I set the same scale to compare with the others

        hold off; % Release hold


        %% Epoching around onset

        % Constants
        epoch_start_sec = from; % seconds
        epoch_end_sec = to; % seconds

        % Convert epoch start and end to samples
        epoch_start_samples = round(epoch_start_sec * sampling_rate_acc);
        epoch_end_samples = round(epoch_end_sec * sampling_rate_acc);

        % Number of samples in the epoch
        num_samples_in_epoch = epoch_end_samples - epoch_start_samples + 1;

        % Initialize matrix to store epochs
        num_events = length(markers_sample_acc);
        num_channels = size(timeseries_acc, 1); % Number of channels (rows) in your accelerometer data
        epochs = nan(num_channels, num_samples_in_epoch, num_events); % Initialize with NaNs

        % Epoch the data
        for i = 1:num_events
            current_marker_sample = markers_sample_acc(i);

            % Calculate the start and end samples for the current epoch
            start_sample = current_marker_sample + epoch_start_samples;
            end_sample = current_marker_sample + epoch_end_samples;

            % Check if the start and end samples are within the range of the data
            if start_sample >= 1 && end_sample <= length(timeseries_acc)
                % Extract the epoch and store it in the matrix
                epochs(:, :, i) = timeseries_acc(:, start_sample:end_sample);
            end
        end


        % Apply median filter to each epoch
        % for i = 1:num_events
        %     epochs(:, i) = medfilt1(epochs(:, i), 5); % 5 is the window size, adjust as needed
        % end


        % Calculate the average across epochs
        average_epoch = mean(epochs, 3, 'omitnan');

        time_vector = linspace(from*1000, to*1000, num_samples_in_epoch);

        % % Plotting the average epoch
        % fig = figure('units','normalized','outerposition', [0 0 1 1]);
        % plot(time_vector, average_epoch(1:3,:), 'Color', '#0072BD', 'LineWidth', 2);
        % xlabel('Time (s)');
        % ylabel('Average Accelerometer [m/s]');
        % title('Average Accelerometer Data Across Epochs');
        % grid on;


        %% Acceleration magnitude averaged

        % Constants for epoching
        epoch_start_samples = round(from * sampling_rate_acc);
        epoch_end_samples = round(to * sampling_rate_acc);
        num_samples_in_epoch = epoch_end_samples - epoch_start_samples + 1;

        % Create an accurate epoch time vector based on actual timestamps
        epochs_accMagnitude_rev = nan(num_samples_in_epoch, numEvents);
        accMagnitude = sqrt(sum(timeseries_acc(1:3,:).^2, 1)); % Acceleration Magnitude

        epochTimes_rev = nan(num_samples_in_epoch, numEvents);  % To store accurate timestamps for each epoch

        % Epoch each event's data and store actual timestamps
        for i = 1:numEvents
            start_sample = markers_sample_acc(i) + epoch_start_samples;
            end_sample = markers_sample_acc(i) + epoch_end_samples;

            if start_sample >= 1 && end_sample <= length(accMagnitude)
                epochs_accMagnitude_rev(:, i) = accMagnitude(start_sample:end_sample);
                epochTimes_rev(:, i) = timestamps_acc(start_sample:end_sample); % Use actual timestamps for each event
            end
        end

        peak_acc = max(epochs_accMagnitude_rev);  % Directly find the max peaks
        mx_peak_acc = max(peak_acc); % Most participants have their peak at around 170, therefore teh scale its set to 175 for comparison



        %% Reverse Computation Algorithm with Global Latencies and Timestamps

        % Define the number of data points and trials based on your description
        dataPoints = size(epochs_accMagnitude_rev, 1);
        trials = size(epochs_accMagnitude_rev, 2);

        % Define epoch times (in ms) for illustration purposes (relative to time reference)
        epochTimes_rev = linspace(-2500, 1000, dataPoints); % Adjust this according to your data
        start_BP = find(epochTimes_rev == -2000);  % Baseline start
        artificial_onset = find(epochTimes_rev == 0);  % Time reference

        % Identify indices for the baseline period
        baselineIndices = epochTimes_rev >= -2500 & epochTimes_rev <= -2000;

        % Calculate the baseline mean and standard deviation for each trial
        baselineMean = mean(epochs_accMagnitude_rev(baselineIndices, :), 1);
        baselineStd = std(epochs_accMagnitude_rev(baselineIndices, :), 0, 1);

        % Define a threshold for movement onset, e.g., mean + 1 * standard deviation
        threshold = baselineMean + 1 * baselineStd;



        %% Plotting

        % Constants for plotting
        colors = lines(length(epochs_accMagnitude_rev));   % Use hsv, jet or any other colormap
        % Mix with white to lighten the colors
        lightenFactor = 0.5;  % Adjust this to make the color lighter (closer to 1 makes it lighter)
        colors = colors + lightenFactor * (1 - colors);

        % Plot each trial as a semi-transparent line
        acc_fig_rev = figure('units','normalized','outerposition', [0 0 1 1]); hold on;
        for trial = 1:size(epochs_accMagnitude_rev, 2)
            trials = plot(epochTimes_rev, epochs_accMagnitude_rev(:, trial), 'Color', colors(trial, :), 'LineWidth', 1);
        end

        % Calculate the average acceleration across all trials
        avgAccMagnitude_rev = mean(epochs_accMagnitude_rev, 2);

        % Plot the average acceleration
        acc_line = plot(epochTimes_rev, avgAccMagnitude_rev, 'LineStyle', '-', ...
            'Marker', 'o', 'MarkerIndices', 1:10:length(avgAccMagnitude_rev),'LineWidth', 2.5, 'Color', 'k');

        % Calculate the upper and lower bounds of the shaded area
        upper_bound_rev = avgAccMagnitude_rev + baselineStd;
        lower_bound_rev = avgAccMagnitude_rev - baselineStd;

        % Assuming you have the figure already open and have plotted the trials

        % Highlight the baseline period
        baselineStart = -2500; % adjust to your baseline start time
        baselineEnd = -2000; % adjust to your baseline end time

        % Get the current y-axis limits
        ylimits = [0 180];

        % Fill between the baseline period with a light blue color and some transparency
        fill([baselineStart, baselineStart, baselineEnd, baselineEnd], [ylimits(1), ylimits(2), ylimits(2), ylimits(1)], [0 0.4470 0.7410], 'FaceAlpha', 0.3, 'EdgeColor', 'none');


        % Plot a vertical line at the average movement onset time
        line([0, 0], ylim, 'Color', 'red', 'LineStyle', '--', 'LineWidth', 2.5);


        % Reversing basketball onset
        if avgOnsetTime_rev < 0
            avgOnsetTime_rev = avgOnsetTime_rev*-1;
        end


        % Plot a vertical line at the average basketball onset time
        line([avgOnsetTime_rev, avgOnsetTime_rev], ylim, 'Color', 'k', 'LineStyle', ':', 'LineWidth', 2);


        % % Calculate the average onset time
        % avgOnsetTime_movement = mean([new_events.time]) / -1000;
        %
        % % Plot a vertical line at the average onset time
        % line([avgOnsetTime_movement, avgOnsetTime_movement], ylim, 'Color', 'b', 'LineStyle', '--', 'LineWidth', 3);


        % Displaying label condition

        if cond == 1 % 'hit'

            cond_label = 'Hits';

        elseif cond == 2 % 'miss'

            cond_label = 'Misses';

        elseif cond == 3  % % 'none'

            cond_label = 'All trials';

        end

        xlabel('Time [ms]');
        ylabel('Acceleration Magnitude [m/s^2]');
        title('Onset Detection Based On Wrist Acceleration');
        subtitle(['Sub. [', num2str(sub), '] / ', '[Reverse Computation Algorithm]']);
        legend([trials, acc_line], {cond_label, 'Mean'}, 'Location', 'northwest');
        ylim(ylimits)
        xlim([from*1000 to*1000]);
        grid on;


        %% Saving

        if cond == 1 % 'hit'

            % Save it in .mat file
            save([out_subfold, 'ACC_rev_hit_', participant,'.mat'], 'avgAccMagnitude_rev', 'epochTimes_rev', 'sampling_rate_acc', ...
                'epochs_accMagnitude_rev', 'baselineStd', 'upper_bound_rev', 'lower_bound_rev', 'avgOnsetTime_rev', 'RC_onsets',...
                'timestamps_acc', 'timeseries_acc',...
                'markers_time_acc', 'markers_sample_acc');

            % Save the figure as a PNG image
            saveas(acc_fig_rev, [out_subfold, 'ACC_fig_rev_hit_', participant, '.jpg']);
            %saveas(acc_fig_rev, [outpath, '\\group_analysis\\','ACC_fig_rev_hit_', participant, '.jpg']); % Save the figure as a PNG image


        elseif cond == 2 % 'miss'

            % Save it in .mat file
            save([out_subfold, 'ACC_rev_miss_', participant,'.mat'], 'avgAccMagnitude_rev', 'epochTimes_rev', 'sampling_rate_acc', ...
                'epochs_accMagnitude_rev', 'baselineStd', 'upper_bound_rev', 'lower_bound_rev', 'avgOnsetTime_rev', 'RC_onsets',...
                'timestamps_acc', 'timeseries_acc',...
                'markers_time_acc', 'markers_sample_acc');

            % Save the figure as a PNG image
            saveas(acc_fig_rev, [out_subfold, 'ACC_fig_rev_miss_', participant, '.jpg']);
            %saveas(acc_fig_rev, [outpath, '\\group_analysis\\','ACC_fig_rev_miss_', participant, '.jpg']); % Save the figure as a PNG image


        elseif cond == 3  % % 'none'

            % Save it in .mat file
            save([out_subfold, 'ACC_rev_', participant,'.mat'], 'avgAccMagnitude_rev', 'epochTimes_rev', 'sampling_rate_acc', ...
                'epochs_accMagnitude_rev', 'baselineStd', 'upper_bound_rev', 'lower_bound_rev', 'avgOnsetTime_rev', 'RC_onsets',...
                'timestamps_acc', 'timeseries_acc',...
                'markers_time_acc', 'markers_sample_acc');

            % Save the figure as a PNG image
            saveas(acc_fig_rev, [out_subfold, 'ACC_fig_rev_', participant, '.jpg']);
            %saveas(acc_fig_rev, [outpath, '\\group_analysis\\','ACC_fig_rev_', participant, '.jpg']);

        end



        clear avgAccMagnitude_rev
        clear epochTimes_rev
        clear epochs_accMagnitude_rev
        clear baselineStd
        clear upper_bound_rev
        clear lower_bound_rev
        clear avgOnsetTime_rev
        clear RC_onsets
        clear hitOnsets
        clear missOnsets
        clear hitFrames
        clear missFrames
        clear onsetTimes
        clear onsetFrames



    end

    clear timeseries_acc
    clear timestamps_acc


end


%% Reverse Computation Algorithm

% The reverse computation algorithm, in the context of onset detection for
% movement or signal processing, refers to starting at a known event point
% (like a stimulus or action) and moving backward in time to find when a
% particular change of interest first occurs. This method is often used
% when the exact timing of the onset is not known, but the occurrence of an
% event is.

% Establish a Baseline: Determine a period when no change or event of
% interest is expected. Calculate the mean and standard deviation of the
% signal during this period.
%
% Set a Threshold: Define a threshold for what constitutes a significant
% change from the baseline. This could be, for example, the baseline mean
% plus a multiple of the standard deviations.
%
% Start from a Known Point: Begin at a time point known to be after the
% onset of the event. For movement, this could be the moment when the
% movement is clearly happening.
%
% Move Backward in Time: Step back through the signal, one time point at a
% time, checking to see if the signal is below the threshold, indicating no
% event or movement.
%
% Identify the Onset: The first time point where the signal crosses the
% threshold (from above to below) as you move backward is marked as the
% onset of the event. This is the point where the signal first starts to
% deviate from the baseline.
%
% Account for Consecutive Points: To avoid false positives due to noise,
% you may require several consecutive points below the threshold before
% confirming the onset.


%% Sync methods

% If exact timing relative to physiological events is crucial (e.g., for
% event-related potential studies in EEG), precision with minimal
% distortion is key, and nearest timestamp might be preferable. For
% broader analyses where smooth data is beneficial, interpolation might be
% suitable.


%%









