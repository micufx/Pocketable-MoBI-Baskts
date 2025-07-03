clc, clear, close all;

%% Onset detection with wrist sensor (movement onset)

% This code detects the movement onset based on the Reverse Copmputational
% Method algorythm using the previously time references detected by the
% human pose motion and with help of the motion sensor attached to the
% wrist of participants.

% Miguel Contreras-Altamirano, 2025


%% Loading data

mainpath = 'C:\Users\micua\Desktop\eeglab2023.0\'; % eeglab folder
path = 'C:\Users\micua\OneDrive - Benemérita Universidad Autónoma de Puebla\NCP_Basketball\MediaPipe\';
outpath = 'C:\\Users\\micua\\OneDrive - Benemérita Universidad Autónoma de Puebla\\Oldenburg_University\\Thesis\\data_hoops\\';
files = dir( fullfile( path,'\*.xdf')); % listing data sets

num_conditions = 3; % (Conditions and overall: 1=hit 2=miss 3=all)

for sub = 1 : length(files)

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
    timestamps_acc_marker = data{1, acc_marker}.time_stamps; % Sensor time-series

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


        load([out_subfold, 'events_MP_', participant,'.mat']); % Loading events file


        %% Defining conditions or general view

        % Divide PLD by conditions
        % Initialize empty vectors to store hit and miss onsets
        hitOnsets = [];
        missOnsets = [];
        hitFrames = [];
        missFrames = [];

        % Loop through the event markers

        for i = 1:length(events_MP)
            if strcmp(events_MP(i).type, 'hit_MP')
                % If the event marker is '1', it's a hit
                hitOnsets = [hitOnsets, onsetTimes(i)];
                hitFrames = [hitFrames, onsetFrames(i)];
            elseif strcmp(events_MP(i).type, 'miss_MP')
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


        % Interpolation
        timeseries_acc = interp1(timestamps_acc, timeseries_acc', timestamps_eeg, 'linear')';
        timestamps_acc = timestamps_eeg;

        % Find the time of those indexes in the ACC data
        markers_time_acc = onsetTimes;
        markers_sample_acc = onsetFrames;
        numEvents = length(markers_sample_acc);


        %% Plotting onsets

        % % Plot sensor data
        % fig = figure('units','normalized','outerposition', [0 0 1 1]);
        % plot(timestamps_acc, timeseries_acc(1,:), 'Color','#0072BD', 'LineWidth', 0.6);
        % 
        % hold on;
        % 
        % % Plot vertical dashed lines and color markers based on their labels
        % for i = 1: length(events_MP)
        % 
        %     % Plot vertical dashed lines
        %     line_handle = plot([events_MP(i).time, events_MP(i).time], get(gca, 'YLim'), '--', 'Color', 'k');
        % 
        %     % Plot vertical dashed lines
        %     % plot([events(i).time, events(i).time], get(gca, 'YLim'), '--', 'Color', 'k');
        % 
        %     % Color markers based on their labels
        %     if strcmpi(events_MP(i).type, 'miss_MP')
        %         scatter(events_MP(i).time, 0, 'k', 'v', 'filled');
        %     elseif strcmpi(events_MP(i).type, 'hit_MP')
        %         scatter(events_MP(i).time, 0, 'r', 'o', 'filled');
        %     end
        % end
        % 
        % xlabel('Time (s)');
        % ylabel('Accelerometer [m/s]');
        % legend('Onsets', 'Location', 'Best');
        % title('Shooting Speed');
        % grid on;
        % 
        % % Set x-axis limits to focus on the relevant portion of the data
        % xlim([min(timestamps_acc), max(timestamps_acc)])
        % 
        % % Set y-axis limits to better visualize the data
        % %ylim([min(timeseries_acc(1,:)), max(timeseries_acc(3,:))]);
        % ylim([0 100]); % % mx_peak_acc= 174.6862 for sub_01 which is the highest, therefore I set the same scale to compare with the others
        % 
        % hold off; % Release hold


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
        start_BP = find(epochTimes_rev == -2000);  % Baseline
        artificial_onset = find(epochTimes_rev == 0);  % Time reference

        %% Dynamic baseline correction

        % Initial baseline period (default)
        baseline_start_default = -2500;
        baseline_end_default = -2000;

        % Define a larger window for dynamic baseline search
        search_start = -2500;
        search_end = -1500;

        % Initial baseline check: check the standard deviation in the default baseline range
        default_baselineIndices = find(epochTimes_rev >= baseline_start_default & epochTimes_rev <= baseline_end_default);
        default_bl = mean(epochs_accMagnitude_rev(default_baselineIndices));
        default_baseline_std = std(epochs_accMagnitude_rev(default_baselineIndices, :), 0, 1);

        % Calculate a dynamic threshold based on the data itself
        % Use median or percentiles to avoid outliers influencing too much
        artifact_threshold = max(default_baseline_std) * 3;  % You can tweak the multiplier


        % Define a larger baseline period for searching (EXCLUDING default baseline)
        search_baselineIndices = find(epochTimes_rev >= search_start & epochTimes_rev <= search_end & ...
            (epochTimes_rev < baseline_start_default | epochTimes_rev > baseline_end_default));

        % Calculate the sliding standard deviation over the search period using a window
        window_size = 500;  % Window size in ms
        sliding_std = movstd(mean(epochs_accMagnitude_rev(search_baselineIndices, :), 2), window_size);

        % Identify the most stable section in the search window by looking for the minimum std
        [~, min_std_idx] = min(sliding_std);

        % Check if the default baseline is too noisy
        if default_bl > artifact_threshold
            disp('Artifacts detected in the default baseline, searching for a new steady period...');

            % Force selection of the minimum std window OUTSIDE the default range
            prob_bl_start = epochTimes_rev(search_baselineIndices(min_std_idx));
            prob_bl_end = prob_bl_start + window_size;

            % Ensure the new baseline is within valid search range
            if prob_bl_end > search_end
                prob_bl_end = search_end;
            end

            % Debugging step: Check if it's actually moving away from the default
            if prob_bl_start >= baseline_start_default && prob_bl_end <= baseline_end_default
                disp('New baseline overlaps with the default baseline. Forcing a shift.');
                prob_bl_start = -1500;  % Force new baseline if stuck in the default
                prob_bl_end = -1000;    % You can adjust these values as needed
            end

            disp(['New baseline set between ', num2str(prob_bl_start), ' ms and ', num2str(prob_bl_end), ' ms']);
        else
            % If no artifacts are detected, use the default baseline
            prob_bl_start = baseline_start_default;
            prob_bl_end = baseline_end_default;
            disp('Default baseline used, no significant artifacts detected.');
        end

        % Use the identified baseline for calculations
        baselineIndices = epochTimes_rev >= prob_bl_start & epochTimes_rev <= prob_bl_end;

        %% Reverse Computational Method

        % Calculate the baseline mean and standard deviation for each trial
        baselineMean = mean(epochs_accMagnitude_rev(baselineIndices, :), 1);
        baselineStd = std(epochs_accMagnitude_rev(baselineIndices, :), 0, 1);

        % Define a threshold for movement onset, e.g., mean + 1 * standard deviation
        threshold = baselineMean + 1 * baselineStd;

        % Initialize vectors to store movement onset latencies and timestamps
        movementOnsets = NaN(1, trials);  % Store the onset frame relative to the epoch
        movementOnsetTimestamps = NaN(1, trials);  % Store the corresponding onset timestamps
        movementOnsetLatencies = NaN(1, trials);  % Store the onset latencies relative to original time series

        for trial = 1:trials
            % Reverse computation: start from time 0 (artificial onset) and move backwards
            for t = find(epochTimes_rev(start_BP:artificial_onset) <= 0, 1, 'last'):-1:1
                if epochs_accMagnitude_rev(t, trial) > threshold(trial)
                    movementOnsets(trial) = t + 1;

                    % Calculate corresponding timestamp
                    event_reference_time = events_MP(trial).time;
                    movementOnsetTimestamps(trial) = event_reference_time + epochTimes_rev(movementOnsets(trial)) / 1000;

                    % Find closest latency
                    [~, onset_latency_index] = min(abs(timestamps_acc - movementOnsetTimestamps(trial)));
                    movementOnsetLatencies(trial) = onset_latency_index;
                    break;
                end
            end

            % If no onset was detected, replace NaN with the original event onset from events_MP
            if isnan(movementOnsets(trial))
                disp(['No movement onset detected for trial ', num2str(trial), '. Using events_MP onset.']);
                movementOnsets(trial) = find(epochTimes_rev == 0);  % You can set this to the appropriate index for time 0
                movementOnsetTimestamps(trial) = events_MP(trial).time;  % Use the time from events_MP
                movementOnsetLatencies(trial) = events_MP(trial).latency;  % Use the frame/latency from events_MP
            end

        end

        % Check if any onsets were detected
        if all(isnan(movementOnsetTimestamps))
            disp('No onsets were detected.');
        else
            disp(['Movement onsets for participant ', num2str(sub) ' successfully detected!']);
        end


        %% Creating events file

        % Storing Onset Timestamps and Latencies (Relative to Global Time)

        % Append the new onsets as separate events, as "hit_onset" or "miss_onset"
        events_ACC = struct('type', {}, 'latency', {}, 'urevent', {}, 'duration', {}, 'time', {}, 'block', {});

        for trial = 1:trials
            if ~isnan(movementOnsetTimestamps(trial))  % If an onset was detected
                if strcmpi(events_MP(trial).type, 'hit_MP')
                    new_event_type = 'hit_ACC';
                elseif strcmpi(events_MP(trial).type, 'miss_MP')
                    new_event_type = 'miss_ACC';
                else
                    new_event_type = [events_MP(trial).type, '_onset'];
                end

                % Append the detected onset as a new event
                new_event = struct(...
                    'type', new_event_type, ...
                    'latency', movementOnsetLatencies(trial), ...  % Latency relative to the original time series
                    'urevent', events_MP(trial).urevent, ...
                    'duration', events_MP(trial).duration, ...
                    'time', movementOnsetTimestamps(trial), ...  % Global timestamp of the detected onset
                    'block', events_MP(trial).block);

                events_ACC(end + 1) = new_event;
            end
        end

        % Combine original events and new onset events
        all_events = [events_MP, events_ACC];

        onsetTimes = [events_ACC.time];
        onsetFrames = [events_ACC.latency];


        %% Saving
        % 
        % % Save the combined events structure
        % save([out_subfold, 'events_all_', participant, '.mat'], 'all_events', 'events_MP', 'events_ACC',...
        %     'timeseries_mp', 'timestamps_mp', 'timeseries_eeg', 'timestamps_eeg', ...
        %     'sampling_rate_eeg', 'sampling_rate_mp', 'sampling_rate_acc');



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
    clear timeseries_mp
    clear timestamps_mp
    clear timeseries_eeg
    clear timestamps_eeg


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
