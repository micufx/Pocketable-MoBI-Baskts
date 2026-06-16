clc, clear, close all;

%% Interpolation demo

% Loading xdf files
mainpath = 'L:\Downloads\eeglab2023.0\'; % eeglab folder
path = 'L:\Downloads\basketball_RP\NCP_Basketball\MediaPipe\';
outpath = 'L:\Downloads\basketball_RP\Oldenburg_University\Thesis\data_hoops\';
files = dir( fullfile( path,'\*.xdf')); % listing data sets

% Add EEGLAB properly
if exist('eeglab','file') ~= 2
    addpath(mainpath);
end

nochans = {'AccX','AccY','AccZ','GyroX','GyroY','GyroZ', ... % channels to be ignored
    'QuatW','QuatX','QuatY','QuatZ'};

%% Selecting participant

for sub=16 %length(files)

    participant = extractBefore(files(sub).name, '.xdf');
    out_subfold = [outpath, participant, '\\'];
    data = load_xdf([path, files(sub).name]); % Saving the data in a variable
    load([out_subfold, 'events_all_', participant,'.mat']); % Loading events file

    % Finding the number struct of MP and EEG
    for i = 1:length(data)
        currentName = data{1, i}.info.name;

        % Check if the current data is MP
        if contains(currentName, 'Pose', 'IgnoreCase', true)
            mp = i;
        end

        % Check if the current data is EEG
        if contains(currentName, 'Android_EEG', 'IgnoreCase', true)
            eeg = i;
        end

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

        % Check if the current data is EEG
        if contains(currentName, 'Android_EEG', 'IgnoreCase', true)
            eeg = i;
        end

    end


    % Assigning variables

    timeseries_mp = data{1, mp}.time_series; % MP time-series
    timeseries_eeg = data{1, eeg}.time_series; % EEG time-series

    timestamps_mp = data{1, mp}.time_stamps;  % MP timestamps
    timestamps_eeg = data{1, eeg} .time_stamps; % EEG timestamps

    timeseries_acc = data{1, acc}.time_series; % Sensor time-series
    timestamps_acc = data{1, acc}.time_stamps; % Sensor time-series


    % Inspecting data characteristics

    % EEG sampling rate
    srate_eeg = 1 / mean(diff(timestamps_eeg)); % calculates differences between adjacent elements of X and takes the mean divided by 1.
    timestamp_range_eeg = range(timestamps_eeg); %  returns the difference between the maximum and minimum values of sample data in X.

    % Length of the recording
    length_minutes_eeg = timestamp_range_eeg / 60; % in minutes
    duration_seconds_eeg = str2double(data{1, eeg}.info.last_timestamp) - str2double(data{1, eeg}.info.first_timestamp);  % in seconds

    % Double check based on data info (more accurate)
    sampling_rate_eeg = str2double(data{1, eeg}.info.sample_count) / duration_seconds_eeg; % in seconds


    % PLD sampling rate
    srate_mp = 1 / mean(diff(timestamps_mp)); % calculates differences between adjacent elements of X and takes the mean divided by 1.
    timestamp_range_mp = range(timestamps_mp); %  returns the difference between the maximum and minimum values of sample data in X.

    % Length of the recording
    length_minutes_mp = timestamp_range_mp / 60; % in minutes
    duration_seconds_mp = str2double(data{1, mp}.info.last_timestamp) - str2double(data{1, mp}.info.first_timestamp); %  in seconds

    % Double check based on data info (more accurate)
    sampling_rate_mp = str2double(data{1, mp}.info.sample_count) / duration_seconds_mp; % in seconds


    % ACC sampling rate
    timestamp_range_acc = range(timestamps_acc); %  returns the difference between the maximum and minimum values of sample data in X.

    % Length of the recording
    length_minutes_acc = timestamp_range_acc / 60; % in minutes
    duration_seconds_acc = str2double(data{1, acc}.info.last_timestamp) - str2double(data{1, acc}.info.first_timestamp); %  in seconds

    % Double check based on data info (more accurate)
    sampling_rate_acc = str2double(data{1, acc}.info.sample_count) / duration_seconds_acc; % in seconds


    % Display the results
    disp(['Sampling rate EEG: ', num2str(sampling_rate_eeg), ' samples per second']);
    disp(['EEG recording: ', num2str(length_minutes_eeg), ' minutes']);

    disp(['Sampling rate PLD: ', num2str(sampling_rate_mp), ' samples per second']);
    disp(['PLD recording: ', num2str(length_minutes_mp), ' minutes']);

    disp(['Sampling rate ACC: ', num2str(sampling_rate_acc), ' samples per second']);
    disp(['ACC recording: ', num2str(length_minutes_acc), ' minutes']);


        %% Finding Cz channel

    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % Open eeglab

    % Import, channel locs, events, reref
    EEG = pop_loadxdf([path, files(sub).name], 'streamtype', 'EEG', 'exclude_markerstreams', {}); % Loading xdf file
    EEG = pop_chanedit(EEG, 'lookup',[mainpath, 'plugins/dipfit/standard_BEM/elec/standard_1005.elc']); % Channel info
    EEG = pop_select(EEG, 'nochannel', nochans); % Select relevant channels
    eeglab redraw % Updating GUI

    Cz_channel  = find(strcmp({EEG.chanlocs.labels}, 'Cz')); % Find Cz channel
    
    window_size = 2;


    
    %% Interpolation motion data to 250Hz for comparison

    % Original PLD data
    timeseries_mp_raw = timeseries_mp;
    timestamps_mp_raw = timestamps_mp;

    % Interpolation of PLD data
    timeseries_mp = interp1(timestamps_mp, timeseries_mp', timestamps_eeg, 'linear', 'extrap')';
    timestamps_mp = timestamps_eeg;


    % Original accelerometer data
    accMagnitude = sqrt(sum(timeseries_acc(1:3,:).^2, 1)); % Acceleration Magnitude
    timestamps_acc_raw = timestamps_acc;

    % Interpolation of PLD data
    timeseries_acc = interp1(timestamps_acc_raw, accMagnitude', timestamps_eeg, 'linear', 'extrap')';
    timestamps_acc = timestamps_eeg;


    % % Interpolation of EEG data
    % timeseries_eeg_interp = interp1(timestamps_eeg, timeseries_eeg', timestamps_mp_raw, 'linear', 'extrap')';
    % timestamps_eeg_interp = timestamps_mp_raw;

    % % Resampling instead
    % %[OUTEEG] = pop_resample( INEEG, freq, fc, df);
    %  timeseries_eeg_interp = pop_resample( EEG.data(Cz_channel,:) , 15);
    %  timestamps_eeg_interp = timestamps_mp_raw;

    %%  EEG downsampling to 15 Hz for comparison

    % Define original and target sampling rates
    original_sampling_rate = round(sampling_rate_eeg);  % Ensure integer sampling rate
    target_sampling_rate = round(15);  % Ensure integer target rate

    % % Compute integer ratio for resampling
    [p, q] = rat(target_sampling_rate / original_sampling_rate);  % Get integer approximation

    % Proper downsampling using resample with anti-aliasing filter
    timeseries_eeg_interp = resample(timeseries_eeg', p, q)';

    % Resampling
    %timeseries_eeg_interp = resample(timeseries_eeg(18,:), timestamps_eeg_interp, sampling_rate_eeg);
    
    % Generate new timestamps matching the new data length
    timestamps_eeg_interp = linspace(timestamps_eeg(1), timestamps_eeg(end), length(timeseries_eeg_interp));


     %% Interpolation settings and signals of interest

    % PLD
    WristIndices = 17; % Based on MediaPipe
    landmarks = timeseries_mp(:, :);
    WristY = landmarks(WristIndices * 3 - 1, :); % For interpolation demo proposes
    WristY_raw = timeseries_mp_raw(WristIndices * 3 - 1, :);  % Keep the original

    % Extract the data for the first block (PLD data)
    onsetTimes = [events_ACC.time];
    first_20_onsets = onsetTimes(1:3); % Get the first 3 onset times (shots) %3
    block_start = first_20_onsets(1) - 20; % Start at the first onset
    block_end = first_20_onsets(end); % End at the 20th onset

    block_indices = timestamps_mp >= block_start & timestamps_mp <= block_end;  %19520
    block_indices_raw = 1550:2510; % Visual search to match the same period of time of the first 5 shots  %2510

    % Renaming variables to analyze extracted desired signal of interest
    WristY_plot = WristY(block_indices);
    timestamps_mp_plot = timestamps_mp(block_indices);

    WristY_raw_plot = WristY_raw(block_indices_raw);
    timestamps_mp_raw_plot = timestamps_mp_raw(block_indices_raw);



    % Accelerometer
    % Extract the data for the first block (accelerometer)
    % block_indices = timestamps_acc >= block_start & timestamps_mp <= block_end;  %19520
    block_indices_raw = 4990:7600; % Visual search to match the same period of time of the first 3 shots %7600

    % Renaming variables to analyze extracted desired signal of interest
    accMagnitude_plot = accMagnitude(block_indices_raw);
    timestamps_acc_raw_plot = timestamps_acc_raw(block_indices_raw);

    timeseries_acc_plot = timeseries_acc(block_indices);
    timestamps_acc_plot = timestamps_acc(block_indices);



    % EEG
    % Extract the data for the first block (EEG interpolated)
    onsetTimes_mp = [events_MP.time];
    first_20_onsets_mp = onsetTimes_mp(1:3); % Get the first 5 onset times   %2
    block_start_mp = first_20_onsets_mp(1) - 20; % Start at the first onset
    block_end_mp = first_20_onsets_mp(end); % End at the 20th onset

    % Renaming variables to analyze extracted desired signal of interest  
    % block_indices = timestamps_acc >= block_start & timestamps_mp <= block_end;  %19520
    timestamps_eeg_plot = timestamps_eeg(block_indices);
    timeseries_eeg_plot = timeseries_eeg(Cz_channel, block_indices);

    block_indices_eeginterp = timestamps_eeg_interp >= block_start_mp & timestamps_eeg_interp <= block_end_mp;

    timestamps_eeg_interp_plot = timestamps_eeg_interp(block_indices_eeginterp);
    timeseries_eeg_interp_plot = timeseries_eeg_interp(Cz_channel, block_indices_eeginterp);


    %% Frequency of the original PLD data (for comparison)

    % PLD - Original
    [psd_pld, freq_pld] = pwelch(WristY_raw, sampling_rate_mp*window_size, sampling_rate_mp*window_size/2, [], sampling_rate_mp);


    %% Frequency of the original accelerometer data (for comparison)

    % ACC - Original
    [psd_acc, freq_acc] = pwelch(accMagnitude, sampling_rate_acc * window_size, sampling_rate_mp*window_size/2, [], sampling_rate_acc);


    %% Frequency of the interpolated PLD data (for comparison)

    % PLD - Interpolated
    [psd_pld_interp, freq_pld_interp] = pwelch(WristY, original_sampling_rate * window_size, sampling_rate_mp*window_size/2, [], original_sampling_rate);


    %% Frequency of the interpolated accelerometer data (for comparison)

    % ACC - Interpolated
    [psd_acc_interp, freq_acc_interp] = pwelch(timeseries_acc, original_sampling_rate * window_size, sampling_rate_mp*window_size/2, [], original_sampling_rate);


    %% Frequency of the original EEG data (for comparison)

    % EEG - Original
    [psd_eeg, freq_eeg] = pwelch(timeseries_eeg(Cz_channel, :), sampling_rate_eeg * window_size, sampling_rate_eeg*window_size/2, [], sampling_rate_eeg);


    %% Frequency of the interpolated EEG data (for comparison)

    % EEG - Downsampled (Interpolated)
    [psd_eeg_interp, freq_eeg_interp] = pwelch(timeseries_eeg_interp(Cz_channel, :), target_sampling_rate * window_size,  (target_sampling_rate*window_size)/2, [], target_sampling_rate);


    %% Interp demo figure

    % Time series plot for interpolation demo
    figure('units','normalized','outerposition', [0 0 1 1]);

    % EEG data interp demo figure
    subplot 331
    eeg_line = plot(timestamps_eeg_plot, timeseries_eeg_plot, 'Color', "k", 'LineWidth', 0.5); % Blue line for eye
    xlabel('Time [s]', 'FontSize', 12);
    ylabel('Amplitude [\muV]', 'FontSize', 12, 'Color', 'k', 'LineWidth', 1);
    title(['Sub. [', num2str(sub), '] / EEG raw data'], 'FontSize', 14);
    subtitle('250 [Hz]', 'FontSize', 14);
    ylim([min(timeseries_eeg_plot) max(timeseries_eeg_plot)]);
    legend('Cz', 'Location', 'northwest');  % Show the legend
    axis tight;
    grid on;  % Display the plot

    subplot 332
    eeg_line_interp = plot(timestamps_eeg_interp_plot, timeseries_eeg_interp_plot, 'Color', "#0072BD", 'LineWidth', 0.5); % Blue line for eye
    xlabel('Time [s]', 'FontSize', 12);
    ylabel('Amplitude [\muV]', 'FontSize', 12, 'Color', 'k', 'LineWidth', 1);
    title(['Sub. [', num2str(sub), '] / EEG downsampled data'], 'FontSize', 14);
    subtitle('15 [Hz]', 'FontSize', 14);
    ylim([min(timeseries_eeg_interp_plot) max(timeseries_eeg_interp_plot)]);
    legend('Cz', 'Location', 'northwest');  % Show the legend
    axis tight;
    grid on;  % Display the plot

    subplot 333
    % EEG PSD
    plot(freq_eeg, 10*log10(psd_eeg), 'k', 'LineWidth', 1.5); hold on;
    plot(freq_eeg_interp, 10*log10(psd_eeg_interp), 'b', 'LineWidth', 1.5);
    xlabel('Frequency (Hz)');
    ylabel('Power/Frequency (dB/Hz)');
    title(['Sub. [', num2str(sub), '] / EEG Power Spectral Density']);
    legend('Original', 'Interpolated');
    grid on; xlim([0 7.5]);

  

    % PLD data interp demo figure
    subplot 334
    wristLine_raw = plot(timestamps_mp_raw_plot, WristY_raw_plot, 'k', 'LineWidth', 1);
    xlabel('Time [s]', 'FontSize', 12);
    ylabel('Y-Coordinates [Packets]', 'FontSize', 12);
    title(['Sub. [', num2str(sub), '] / PLD raw data'], 'FontSize', 14);
    subtitle('15 [Hz]', 'FontSize', 14);
    %ylim([-1 max(WristY_raw)]);
    axis tight;
    grid on;
    set(gca, 'YDir', 'reverse'); % Reverse Y-axis as before
    legend('Wrist', 'Location', 'northwest');  % Show the legend

    subplot 335
    wristLine = plot(timestamps_mp_plot, WristY_plot, 'Color', "#0072BD", 'LineWidth', 1);
    xlabel('Time [s]', 'FontSize', 12);
    ylabel('Y-Coordinates [Packets]', 'FontSize', 12);
    title(['Sub. [', num2str(sub), '] / PLD interpolated data'], 'FontSize', 14);
    subtitle('250 [Hz]', 'FontSize', 14);
    ylim([-1 max(WristY_plot)]);
    axis tight;
    grid on;
    set(gca, 'YDir', 'reverse'); % Reverse Y-axis as before
    legend('Wrist', 'Location', 'northwest');  % Show the legend

    subplot 336
    % PLD PSD
    plot(freq_pld, 10*log10(psd_pld), 'k', 'LineWidth', 1.5); hold on;
    plot(freq_pld_interp, 10*log10(psd_pld_interp), 'b', 'LineWidth', 1.5);
    xlabel('Frequency (Hz)');
    ylabel('Power/Frequency (dB/Hz)');
    title(['Sub. [', num2str(sub), '] / PLD Power Spectral Density']);
    legend('Original', 'Interpolated');
    grid on; xlim([0 5]);


    % Accelerometer data interp demo figure
    subplot 337
    plot(timestamps_acc_raw_plot, accMagnitude_plot, 'k', 'LineWidth', 1);
    xlabel('Time [s]', 'FontSize', 12);
    ylabel('Acceleration Magnitude [m/s^2]', 'FontSize', 12);
    title(['Sub. [', num2str(sub), '] / Accelerometer raw data'], 'FontSize', 14);
    subtitle('60 [Hz]', 'FontSize', 14);
    ylim([min(accMagnitude_plot) max(accMagnitude_plot)]);
    axis tight;
    grid on;
    legend('Acc', 'Location', 'northwest');  % Show the legend

    subplot 338
    plot(timestamps_acc_plot, timeseries_acc_plot, 'Color', "#0072BD",'LineWidth', 1);
    xlabel('Time [s]', 'FontSize', 12);
    ylabel('Acceleration Magnitude [m/s^2]', 'FontSize', 12);
    title(['Sub. [', num2str(sub), '] / Accelerometer interpolated data'], 'FontSize', 14);
    subtitle('250 [Hz]', 'FontSize', 14);
    ylim([min(timeseries_acc_plot) max(timeseries_acc_plot)]);
    axis tight;
    grid on;
    legend('Acc', 'Location', 'northwest');  % Show the legend

    subplot 339
    % ACC PSD
    plot(freq_acc, 10*log10(psd_acc), 'k', 'LineWidth', 1.5); hold on;
    plot(freq_acc_interp, 10*log10(psd_acc_interp), 'b', 'LineWidth', 1.5);
    xlabel('Frequency (Hz)');
    ylabel('Power/Frequency (dB/Hz)');
    title(['Sub. [', num2str(sub), '] / ACC Power Spectral Density']);
    legend('Original', 'Interpolated');
    grid on; xlim([0 15]);


    % Adjust subplot spacing if needed
    sgtitle('Data Interpolation Comparison'); % Super title


    % save_fig(gcf, out_subfold, ['Data_interpolation_comparison_', participant], ...
    %     'fontsize', 11, ...
    %     'figsize', [35, 20], ...
    %     'figtypes', {'.png'},...
    %     'dpi', 600);

    % save([outpath, 'data_motion_EEG', '.mat'],'events_ACC', 'Cz_channel', 'timestamps_eeg', ...
    %     'WristY', 'WristY_timestamps', 'accMagnitude', 'timestamps_acc');



    %% Interp demo figure 2

    % Time series plot for interpolation demo
    figure('units','normalized','outerposition', [0 0 1 1]);


    % PLD data interp demo figure
    subplot 231
    wristLine_raw = plot(timestamps_mp_raw_plot, WristY_raw_plot, 'k', 'LineWidth', 1);
    xlabel('Time [s]', 'FontSize', 12);
    ylabel('Y-Coordinates [Packets]', 'FontSize', 12);
    title(['Sub. [', num2str(sub), '] / PLD raw data'], 'FontSize', 14);
    subtitle('15 [Hz]', 'FontSize', 14);
    %ylim([-1 max(WristY_raw)]);
    axis tight;
    grid on;
    set(gca, 'YDir', 'reverse'); % Reverse Y-axis as before
    legend('Wrist', 'Location', 'northwest');  % Show the legend

    subplot 232
    wristLine = plot(timestamps_mp_plot, WristY_plot, 'Color', "#0072BD", 'LineWidth', 1);
    xlabel('Time [s]', 'FontSize', 12);
    ylabel('Y-Coordinates [Packets]', 'FontSize', 12);
    title(['Sub. [', num2str(sub), '] / PLD interpolated data'], 'FontSize', 14);
    subtitle('250 [Hz]', 'FontSize', 14);
    ylim([-1 max(WristY_plot)]);
    axis tight;
    grid on;
    set(gca, 'YDir', 'reverse'); % Reverse Y-axis as before
    legend('Wrist', 'Location', 'northwest');  % Show the legend

    subplot 233
    % PLD PSD
    plot(freq_pld, 10*log10(psd_pld), 'k', 'LineWidth', 1.5); hold on;
    plot(freq_pld_interp, 10*log10(psd_pld_interp), 'b', 'LineWidth', 1.5);
    xlabel('Frequency (Hz)');
    ylabel('Power/Frequency (dB/Hz)');
    title(['Sub. [', num2str(sub), '] / PLD Power Spectral Density']);
    legend('Original', 'Interpolated');
    grid on; xlim([0 5]);


    % Accelerometer data interp demo figure
    subplot 234
    plot(timestamps_acc_raw_plot, accMagnitude_plot, 'k', 'LineWidth', 1);
    xlabel('Time [s]', 'FontSize', 12);
    ylabel('Acceleration Magnitude [m/s^2]', 'FontSize', 12);
    title(['Sub. [', num2str(sub), '] / Accelerometer raw data'], 'FontSize', 14);
    subtitle('60 [Hz]', 'FontSize', 14);
    ylim([min(accMagnitude_plot) max(accMagnitude_plot)]);
    axis tight;
    grid on;
    legend('Acc', 'Location', 'northwest');  % Show the legend

    subplot 235
    plot(timestamps_acc_plot, timeseries_acc_plot, 'Color', "#0072BD",'LineWidth', 1);
    xlabel('Time [s]', 'FontSize', 12);
    ylabel('Acceleration Magnitude [m/s^2]', 'FontSize', 12);
    title(['Sub. [', num2str(sub), '] / Accelerometer interpolated data'], 'FontSize', 14);
    subtitle('250 [Hz]', 'FontSize', 14);
    ylim([min(timeseries_acc_plot) max(timeseries_acc_plot)]);
    axis tight;
    grid on;
    legend('Acc', 'Location', 'northwest');  % Show the legend

    subplot 236
    % ACC PSD
    plot(freq_acc, 10*log10(psd_acc), 'k', 'LineWidth', 1.5); hold on;
    plot(freq_acc_interp, 10*log10(psd_acc_interp), 'b', 'LineWidth', 1.5);
    xlabel('Frequency (Hz)');
    ylabel('Power/Frequency (dB/Hz)');
    title(['Sub. [', num2str(sub), '] / ACC Power Spectral Density']);
    legend('Original', 'Interpolated');
    grid on; xlim([0 15]);


    % Adjust subplot spacing if needed
    sgtitle('Data Interpolation Comparison'); % Super title


    save_fig(gcf, out_subfold, ['Data_interpolation_comparison_', participant], ...
        'fontsize', 11, ...
        'figsize', [35, 20], ...
        'figtypes', {'.png'},...
        'dpi', 600);

    % save([outpath, 'data_motion_EEG', '.mat'],'events_ACC', 'Cz_channel', 'timestamps_eeg', ...
    %     'WristY', 'WristY_timestamps', 'accMagnitude', 'timestamps_acc');

end