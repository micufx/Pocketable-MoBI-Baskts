clc, clear, close all;

%% Movement onset comparison (grand average)

% This code compares the time reference (eye-wrist intersection) and the
% grand average detected onset of the movement across participants.
% Furthermore, a binomial test is used to determine whether the proportion
% of participants showing significant movement in each body part was
% significantly above chance level.

% Miguel Contreras-Altamirano, 2025


%% EEG data preparation

mainpath = 'L:\Downloads\eeglab2023.0\'; % eeglab folder
path = 'L:\Downloads\basketball_RP\NCP_Basketball\MediaPipe\';
outpath = 'L:\Downloads\basketball_RP\Oldenburg_University\Thesis\data_hoops\';
files = dir( fullfile( path,'\*.xdf')); % listing data sets

% Add EEGLAB properly
if exist('eeglab','file') ~= 2
    addpath(mainpath);
end

num_conditions = 3; % (Conditions and overall: 1=hit 2=miss 3=all)

% Permutation parameters
bin_size = 500; % Bin size in milliseconds
num_permutations = 5000; % Number of permutations


%% Loading data

for cond=3 : num_conditions

    % Loading desired data
    if cond == 1 % 'hit'

        load([outpath , 'PLD_grand_avg_hit.mat'], 'averageTimeseriesMp', 'timestamps_mp');
        load([outpath , 'ACC_grand_avg_rev_hit','.mat']); % Loading accelerometer data

        % Import EEG processed data
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % Open eeglab
        EEG = pop_loadset('filename',['Grand_avg_hits','.set'],'filepath', outpath); % Loading set file


    elseif cond == 2 % 'miss'

        load([outpath , 'PLD_grand_avg_miss.mat'], 'averageTimeseriesMp', 'timestamps_mp');
        load([outpath , 'ACC_grand_avg_rev_miss','.mat']); % Loading accelerometer data

        % Import EEG processed data
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % Open eeglab
        EEG = pop_loadset('filename',['Grand_avg_misses','.set'],'filepath', outpath); % Loading set file
        eeglab redraw


    elseif cond == 3  % % 'none'

        load([outpath , 'PLD_grand_avg.mat'], 'averageTimeseriesMp', 'timestamps_mp');
        load([outpath , 'ACC_grand_avg_rev','.mat']); % Loading accelerometer data

        % Import EEG processed data
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % Open eeglab
        EEG = pop_loadset('filename',['Grand_avg_all','.set'],'filepath', outpath); % Loading set file
        eeglab redraw

    end

    %timeseries_mp = averageTimeseriesMp;


    frequency_sampling = input('At which frequency would you like the data? (1=15Hz / 2=250Hz): ');


    %% Reampling PLD to its originally 15 Hz

    if frequency_sampling == 1

        % Resampling instead
        %[OUTEEG] = pop_resample( INEEG, freq, fc, df);

        % Define original and target sampling rates
        original_sampling_rate = EEG.srate;  % EEG sampling rate (e.g., 250Hz)
        target_sampling_rate = 15;     % Target PLD sampling rate    %sampling_rate_mp

        % Calculate downsampling factor
        downsample_factor = round(original_sampling_rate / target_sampling_rate);

        % Downsample the time series data
        averageTimeseriesMp = averageTimeseriesMp(:, 1:downsample_factor:end);

        timeseries_mp = averageTimeseriesMp;


    elseif frequency_sampling == 2

        timeseries_mp = averageTimeseriesMp;

    end


    %% ERP Onset with Gaussian

    % Assuming you have EEG data in an EEGLAB structure
    ERP_bin = mean (EEG.data, 3);
    chan = find(strcmp({EEG.chanlocs.labels}, 'Cz'));
    timeEEG = [find(EEG.times == -200)]; % for topoplot

    % Step 1: Extract the data for the channel of interest
    latency = EEG.times;
    erp_data = squeeze(EEG.data(chan, :, :));  % Squeeze the data to remove singleton dimensions and transpose
    sortvar = zeros(1, size(erp_data, 2));  % One value per trial (876 trials in this case)

    % Step 3: Use erpimage
    figure('units', 'normalized', 'outerposition', [0 0 1 1]);
    %subplot(2, 1, 1);
    erpimage(erp_data, [], EEG.times, 'Grand Average ERP at Cz', 1, 1,...
        'yerplabel', {'Grand Average Motion Tracking and ERP [N=26]'},'erp', 'off', 'cbar', 'off','cbar_title', '\muV',...
        'vert', [grand_avgOnsetTime_rev], ...
        'topo', {chan, EEG.chanlocs, EEG.chaninfo},...
        'caxis', [-20 20],...
        'vert', grand_avgOnsetTime_rev,... %         'avg_type', 'Gaussian',...
        'img_trialax_label', {'Participants'}, 'img_trialax_ticks', [0 : 1 :size(erp_data,2)]);


    %% ERP Onset with Moving Average

    % Step 1: Define parameters
    clipping_range = [-20 20]; % Match the caxis range in erpimage

    % % Step 2: Apply smoothing
    % smooth_window = 20; % Adjust for slight smoothing if needed
    % smoothed_data = movmean(erp_data, smooth_window, 2); % Smooth across time

    smoothed_data = erp_data;

    % Step 3: Plot with imagesc
    figure('units', 'normalized', 'outerposition', [0 0 1 1]);
    %subtightplot(2, 1, 2);
    imagesc(latency, 1:size(smoothed_data, 2), smoothed_data'); % Transpose for correct orientation
    set(gca, 'YDir', 'normal'); % Ensure correct orientation

    % Step 4: Colormap and axis adjustments
    colormap('jet'); % Similar to 'erpimage' colormap
    c = colorbar('Ticks',[-20 -10 0 10 20]);  % Replace minValue and maxValue with your actual min and max
    c.Label.String = 'Amplitude [\muV]';
    c.Label.FontSize = 18;
    caxis(clipping_range); % Set color limits to match erpimage

    % Step 5: Add vertical lines and labels
    hold on;
    xline(0, 'r--', 'LineWidth', 2.5); % Onset line
    xline(grand_avgOnsetTime_rev, 'k:', 'LineWidth', 2.5); % Additional onset lines if needed
    xlabel('Time [ms]', 'FontSize', 18);
    ylabel('Participants', 'FontSize', 18);
    %title('Grand Average Motion Tracking and ERP [N=26]', 'FontSize', 20);
    %subtitle('Event Related Potential at [Cz]', 'FontSize', 19);

    % Optional: Adjust Y-axis tick labels
    yticks(1:size(smoothed_data, 2));
    yticklabels(1:size(smoothed_data, 2)); % Adjust as per participant indexing

    % % Step 4: Add the topoplot outside the matrix plot (above)
    % topoplot_axes = axes('Position', [0.56, 0.79, 0.1, 0.1]); % Adjust to position above the main plot
    % timeEEG = -200; % Choose the time point for topoplot (adjust as necessary)
    % topoplot(ERP_bin(:, find(latency == timeEEG)), EEG.chanlocs, 'maplimits', clipping_range, 'electrodes', 'off');
    % title([num2str(timeEEG), ' ms'], 'FontSize', 11);
    % set(topoplot_axes, 'Color', 'none'); % Optional: Make the topoplot background transparent
    %
    % % Step 4: Add the topoplot outside the matrix plot (above)
    % topoplot_axes = axes('Position', [0.50, 0.79, 0.1, 0.1]); % Adjust to position above the main plot
    % timeEEG = -500; % Choose the time point for topoplot (adjust as necessary)
    % topoplot(ERP_bin(:, find(latency == timeEEG)), EEG.chanlocs, 'maplimits', clipping_range, 'electrodes', 'off');
    % title([num2str(timeEEG), ' ms'], 'FontSize', 11);
    % set(topoplot_axes, 'Color', 'none'); % Optional: Make the topoplot background transparent

    % Save the Plot
    % saveas(gcf, [outpath, '\\group_analysis\\','ERP_onset_mov_grand_avg', '.jpg']); % Save the figure as a PNG image
    save_fig(gcf,[outpath, '\\group_analysis\\',], 'ERP_onset_mov_grand_avg', 'fontsize', 12);


    %% Calculate Acceleration Magnitude for Each Body Part

    % Assuming `averageTimeseriesMp` has dimensions [body_parts * 3 (xyz) * time]
    from = -2.5; % Start time in seconds
    to = 1;  % End time in seconds

    % Reshape and initialize variables
    num_body_parts = 33;
    num_frames = size(averageTimeseriesMp, 2);
    acceleration_magnitude = zeros(num_body_parts, num_frames);

    % Calculate the acceleration magnitude for each body part
    for i = 1:num_body_parts
        % Extract x, y, and z rows for the current body part
        x = averageTimeseriesMp((i-1)*3 + 1, :);
        y = averageTimeseriesMp((i-1)*3 + 2, :);
        z = averageTimeseriesMp((i-1)*3 + 3, :);  % --> Taking out z axis

        % Calculate magnitude
        acceleration_magnitude(i, :) = sqrt(x.^2 + y.^2 + z.^2);    %
    end


    if frequency_sampling == 1

        % RMS over time for acceleration magnitude
        sec = 0.264; % Time window length in seconds   (0.264 = 4 samples per window at 15Hz) 
        LeWin = target_sampling_rate * sec; % Define window length in samples
        idx_loop = 1:max(1, LeWin):size(acceleration_magnitude, 2); % Ensure valid step size
        rms_acceleration_t = zeros(size(acceleration_magnitude, 1), length(idx_loop)); % Pre-allocate matrix

        % Loop through and calculate RMS of acceleration magnitude in each time window
        row_count = 1; % Initialize counter for rows
        for idx = 1:LeWin:size(acceleration_magnitude, 2) - LeWin
            signal = acceleration_magnitude(:, idx:idx + (LeWin - 1)); % Segment of acceleration magnitude
            rms_acceleration_t(:, row_count) = std(signal, [], 2); % Calculate RMS (standard deviation)
            row_count = row_count + 1;
        end


    elseif frequency_sampling == 2

        % RMS over time for acceleration magnitude
        sec = 0.01; % Time window length in seconds     (0.01 = 2 samples per window at 250Hz) 
        LeWin = EEG.srate * sec; % Define window length in samples
        idx_loop = 1:LeWin:size(acceleration_magnitude, 2); % Index for loop to go through windows
        rms_acceleration_t = zeros(size(acceleration_magnitude, 1), length(idx_loop)); % Pre-allocate matrix


        % Loop through and calculate RMS of acceleration magnitude in each time window
        row_count = 1; % Initialize counter for rows
        for idx = 1:LeWin:size(acceleration_magnitude, 2) - LeWin
            signal = acceleration_magnitude(:, idx:idx + (LeWin - 1)); % Segment of acceleration magnitude
            rms_acceleration_t(:, row_count) = std(signal, [], 2); % Calculate RMS (standard deviation)
            row_count = row_count + 1;
        end


    end



    % Multiply RMS values by 1000 to convert units if necessary
    rms_acceleration_t = rms_acceleration_t * 1000;

    % Define body part labels
    body_parts = {
        'nose', 'left eye (inner)', 'left eye', 'left eye (outer)', 'right eye (inner)', ...
        'right eye', 'right eye (outer)', 'left ear', 'right ear', 'mouth (left)', ...
        'mouth (right)', 'left shoulder', 'right shoulder', 'left elbow', 'right elbow', ...
        'left wrist', 'right wrist', 'left pinky', 'right pinky', 'left index', 'right index', ...
        'left thumb', 'right thumb', 'left hip', 'right hip', 'left knee', 'right knee', ...
        'left ankle', 'right ankle', 'left heel', 'right heel', 'left foot index', 'right foot index'
        };

    %%
    % %% Pose Landmarks Artifacts - 3D Surface Plot with Adjusted Labels for Y Coordinates
    %
    % % RMS measures overall variability, which is helpful for identifying general movement artifacts.
    % time_axis = linspace(from * 1000, to * 1000, length(idx_loop)); % in milliseconds
    %
    % % We will only label every third row (corresponding to the y-coordinates)
    % label_indices = 0:1:length(body_parts); % Indices for the y-coordinates (every third row)
    %
    % % Define time points for onset lines
    % onset_times = [0, grand_avgOnsetTime_rev]; % Replace with your actual onset times
    %
    % % Plot the 3D surface with correctly aligned Y-axis labels
    % figure('units', 'normalized', 'outerposition', [0 0 1 1]);
    % [X, Y] = meshgrid(time_axis, 1:length(body_parts)); % Use body_parts length directly to match rows
    %
    % % Plot the surface
    % surf(X, Y, rms_acceleration_t, 'EdgeColor', 'none');
    % colormap("turbo");
    % c = colorbar;
    % c.Label.String = 'RMS of Acceleration Magnitude [mm/s^2]';
    % c.Label.FontSize = 11;
    % caxis([0 max(rms_acceleration_t(:))]);
    %
    % % Set axis limits and labels
    % xlim([min(time_axis) max(time_axis)]);
    % ylim([1 size(rms_acceleration_t, 1)]); % Ensure the Y-axis matches the data size
    %
    % % Adjust Y-axis labels
    % set(gca, 'YTick', 1:length(body_parts), 'YTickLabel', body_parts, 'YTickLabelRotation', 30,  'XTickLabelRotation', 30);
    %
    %
    % % Label axes
    % xlabel('Time [ms]', 'FontSize', 11);
    % ylabel('Body Landmarks', 'FontSize', 11);
    % zlabel('RMS', 'FontSize', 11);
    % title('Root Mean Square [RMS] of Acceleration Magnitude Over Time', 'FontSize', 12);
    % subtitle(['Windows of ', num2str(sec*1000), ' [ms]'], 'FontSize', 11.5);
    % view([110, 40]);
    %
    % % Recalculate and highlight top RMS body parts with correctly aligned labels
    % N = min(6, length(body_parts)); % Number of top body parts to highlight
    % [~, top_rms_indices] = maxk(mean(rms_acceleration_t, 2), N); % Get top body part indices by RMS
    % rms_threshold = min(max(rms_acceleration_t(label_indices(top_rms_indices), :), [], 2)); % Min of max RMS values for top body parts
    %
    %
    % % Draw 3D "walls" with restricted height at RMS threshold
    % hold on;
    % for i = 1:length(onset_times)
    %     % Define the color and style for each line
    %     if i == 1
    %         line_color = 'r';
    %         line_style = '--';
    %     else
    %         line_color = 'k';
    %         line_style = '--';
    %     end
    %
    %     % Draw box edges at each onset time along x, y, and restricted z
    %     plot3([onset_times(i), onset_times(i)], [1, 1], [0, rms_threshold], line_style, 'Color', line_color, 'LineWidth', 2); % Vertical edge
    %     plot3([onset_times(i), onset_times(i)], [1, size(rms_acceleration_t, 1)], [0, 0], line_style, 'Color', line_color, 'LineWidth', 2); % Bottom horizontal edge
    %     plot3([onset_times(i), onset_times(i)], [1, size(rms_acceleration_t, 1)], [rms_threshold, rms_threshold], line_style, 'Color', line_color, 'LineWidth', 2); % Top horizontal edge
    % end
    %
    % % Highlight top RMS body parts with labels
    % offset = 0.1; % Offset for label positioning
    % for i = 1:N
    %     plot3(time_axis, repmat(top_rms_indices(i), size(time_axis)), rms_acceleration_t(top_rms_indices(i), :), 'b', 'Linestyle', ':', 'LineWidth', 2);
    %     text(max(time_axis) + offset, top_rms_indices(i), max(rms_acceleration_t(top_rms_indices(i), :)), ...
    %         body_parts{top_rms_indices(i)}, 'Color', 'k', 'FontSize', 8, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    % end
    %
    % % Enable grid for better visualization
    % grid on;
    %
    % % Rotate the fig for better visualization
    % azimuth_angle = 3.349649635036496e+02;
    % elevation_angle = 81.093181818181820;
    %
    % view([azimuth_angle, elevation_angle]); % Replace with your desired values


    %% Plot Acceleration Magnitude as Coldmap 2D

    figure('units', 'normalized', 'outerposition', [0 0 1 1]);
    imagesc(EEG.times, 1:size(rms_acceleration_t, 1), rms_acceleration_t);
    colorbar;
    colormap("sky");
    set(gca, 'YTick', 1:length(body_parts), 'YTickLabel', body_parts); % Label body parts
    xlabel('Time [ms]',  'FontSize', 11);
    ylabel('Body Landmarks',  'FontSize', 11);
    title('Root Mean Square [RMS] of Acceleration Magnitude', 'FontSize', 12);
    subtitle(['Windows of ', num2str(sec*1000), ' [ms]'], 'FontSize', 11.5);
    c = colorbar;
    c.Label.String = 'RMS of Acceleration Magnitude [mm/s^2]';
    c.Label.FontSize = 11;
    xline(0, '--', 'Color', 'r', 'LineWidth', 2); % Add red dashed line at 0 ms
    xline(grand_avgOnsetTime_rev, ':', 'Color', 'k', 'LineWidth', 2);    % Add a red dashed line at 0 ms to indicate movement onset


    %% Plot Acceleration Magnitude as Heatmap 2D

    % % Plot with labels
    % fig_velocity = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
    % imagesc(EEG.times, 1:size(rms_acceleration_t, 1), rms_acceleration_t);                    % Plot RMS over time for MediaPipe data
    % colormap("turbo");
    % c = colorbar;
    % c.Label.String = 'RMS of Acceleration Magnitude [mm/s^2]';
    % c.Label.FontSize = 11;
    % set(gca, 'YTick', 1:1:33, 'YTickLabel', body_parts);  % Adjust for your landmark indices
    % xlabel('Time [ms]', 'FontSize', 11);
    % ylabel('Body Landmarks', 'FontSize', 11);
    % title('Root Mean Square [RMS] of Acceleration Magnitude Over Time', 'FontSize', 12);
    % subtitle(['Windows of ', num2str(sec*1000), ' [ms]'], 'FontSize', 11.5);
    %
    % xline(0, '--', 'Color', 'r', 'LineWidth', 2);    % Add a red dashed line at 0 ms to indicate movement onset
    % xline(grand_avgOnsetTime_rev, ':', 'Color', 'k', 'LineWidth', 2);    % Add a red dashed line at 0 ms to indicate movement onset
    %
    % %saveas(gcf, [outpath, '\\group_analysis\\','RMS_motion_2D_grand_avg', '.jpg']); % Save the figure as a PNG image


    %% Permutation Test for Motion Significance

    % Parameters
    bin_samples = bin_size / 10; % Convert to samples (each sample is 10 ms)
    time_bins = -2500:bin_size:1000; % Define time bins in ms
    clusters = {'Head', 'Upper Body', 'Lower Body'};
    num_clusters = length(clusters);

    % Define cluster indices
    head_parts = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
    upper_body_parts = [12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23];
    lower_body_parts = [24, 25, 26, 27, 28, 29, 30, 31, 32, 33];

    cluster_parts = {head_parts, upper_body_parts, lower_body_parts};

    % Initialize results
    p_values = zeros(num_clusters, length(time_bins) - 1);


    % Perform Permutation Test for Each Cluster and Each Time Bin

    for cluster_idx = 1:length(clusters)
        cluster_data = rms_acceleration_t(cluster_parts{cluster_idx}, :); % Extract data for current cluster

        for bin_idx = 1:length(time_bins) - 1
            % Define start and end sample for the current bin
            start_sample = (bin_idx - 1) * bin_samples + 1;
            end_sample = min(start_sample + bin_samples - 1, size(cluster_data, 2));

            % Calculate the observed mean for the current bin
            observed_mean = mean(cluster_data(:, start_sample:end_sample), 'all');

            % Initialize permutation means
            permuted_means = zeros(1, num_permutations);

            % Permutation test
            for perm = 1:num_permutations
                % Permute data
                permuted_data = cluster_data(:, randperm(size(cluster_data, 2)));
                permuted_means(perm) = mean(permuted_data(:, start_sample:end_sample), 'all');
            end

            % Calculate p-value for observed mean
            p_values(cluster_idx, bin_idx) = sum(permuted_means >= observed_mean) / num_permutations;
        end
    end


    % Apply FDR Correction

    adjusted_p_values = mafdr(p_values(:), 'BHFDR', true);
    adjusted_p_values = reshape(adjusted_p_values, size(p_values));


    %% Visualization of Significant Time Bins

    figure('units', 'normalized', 'outerposition', [0 0 1 1]);
    time_labels = time_bins(1:end-1) + bin_size / 2; % Midpoints of time bins

    % Define time bins from -2500 ms to 1000 ms
    bin_start_times = -2500:bin_size:1000;  % Start of each 100 ms bin
    bin_labels = arrayfun(@(x) sprintf('%d %d ms', x), bin_start_times, 'UniformOutput', false);  % Create labels

    for cluster_idx = 1:length(clusters)
        subplot(length(clusters), 1, cluster_idx);
        hold on;

        % Plot p-values
        plot(time_labels, adjusted_p_values(cluster_idx, :), '-o', 'LineWidth', 1.5);

        % Highlight significant bins
        significant_bins = adjusted_p_values(cluster_idx, :) < 0.05;
        scatter(time_labels(significant_bins), adjusted_p_values(cluster_idx, significant_bins), ...
            50, 'r', 'filled'); % Red dots for significant bins

        % Labels and formatting
        title(['Cluster: ', clusters{cluster_idx}], 'FontSize', 14, 'FontWeight', 'bold');
        xlabel('Time [ms]', 'FontSize', 12);
        ylabel('Adjusted p-Value', 'FontSize', 12);
        ylim([0 1]);
        yline(0.05, '--', 'FDR Threshold (α = 0.05)', 'FontSize', 10, 'Color', 'k', 'LabelHorizontalAlignment','left');
        xline(0, 'r--', 'LineWidth', 2.5); % Onset line

        xlim([-2500, 1000]);
        xticks(bin_start_times);  % Ensure all bins are represented
        xticklabels(bin_labels);
        %xtickangle(45);  % Rotate labels for readability

        grid on;
        hold off;
    end

    sgtitle('Permutation Test for Motion Significance', 'FontSize', 16, 'FontWeight', 'bold');


    % Save the Plot
    %saveas(gcf, [outpath, '\\group_analysis\\', 'Permutation_test_motion_clusters', '.jpg']);
    % save_fig(gcf,[outpath, '\\group_analysis\\',], 'Permutation_test_motion_clusters');



    if frequency_sampling == 1

        saveas(gcf, [outpath, '\\group_analysis\\', 'Permutation_test_motion_clusters_15Hz', '.jpg']);

    elseif frequency_sampling == 2

        saveas(gcf, [outpath, '\\group_analysis\\', 'Permutation_test_motion_clusters_250Hz', '.jpg']);

    end



    %% Combined plots

    % Plot RMS Background
    figure('units', 'normalized', 'outerposition', [0 0 1 1]);
    imagesc(EEG.times, 1:size(rms_acceleration_t, 1), rms_acceleration_t);
    colormap("turbo");
    c = colorbar;
    c.Label.String = 'RMS of Acceleration Magnitude [mm/s^2]';
    c.Label.FontSize = 11;
    set(gca, 'YTick', 1:1:33, 'YTickLabel', body_parts);
    xlabel('Time [ms]', 'FontSize', 11);
    ylabel('Body Landmarks', 'FontSize', 11, 'Position', [-2976.620246249664,16.560959874129882,1]);
    title('Root Mean Square [RMS] of Acceleration Magnitude Over Time', 'FontSize', 14);
    subtitle('Windows of 10 ms', 'FontSize', 11.5);

    % Add grid lines
    for c = [head_parts(end), upper_body_parts(end), lower_body_parts(end)]
        yline(c + 0.5, 'w-', 'LineWidth', 2);
    end


    hold on;
    % Draw vertical lines for time bins
    % for t = time_bins
    %     xline(t, 'w--', 'LineWidth', 0.1);
    % end

    % Add cluster labels on the left side of the plot
    text(-2900, mean(head_parts), 'Head', 'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'right', 'Rotation', 90);
    text(-2900, mean(upper_body_parts)-2, 'Upper Body', 'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'right', 'Rotation', 90);
    text(-2900, mean(lower_body_parts)-2, 'Lower Body', 'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'right', 'Rotation', 90);


    % Highlight Significant Bins with Stars
    for cluster_idx = 1:num_clusters
        for bin_idx = 1:length(time_bins) - 1
            if adjusted_p_values(cluster_idx, bin_idx) < 0.05
                % Get the mid-time of the bin
                bin_mid_time = (time_bins(bin_idx) + time_bins(bin_idx + 1)) / 2;

                % Determine y-axis position for the star (center of the cluster range)
                y_center = mean(cluster_parts{cluster_idx});

                % Plot star
                plot(bin_mid_time, y_center, 'w*', 'MarkerSize', 8, 'LineWidth', 1.5);
            end
        end
    end

    xline(0, '--', 'Color', 'r', 'LineWidth', 2);
    xline(grand_avgOnsetTime_rev, ':', 'Color', 'k', 'LineWidth', 2);    % Add a red dashed line at 0 ms to indicate movement onset
    hold off;


    % Save the Plot
    %saveas(gcf, [outpath, '\\group_analysis\\','RMS_motion_2D_grand_avg', '.jpg']); % Save the figure as a PNG image
    % save_fig(gcf,[outpath, '\\group_analysis\\',], 'RMS_motion_2D_grand_avg');




    if frequency_sampling == 1

        saveas(gcf, [outpath, '\\group_analysis\\','RMS_motion_2D_grand_avg_15Hz', '.jpg']); % Save the figure as a PNG image

    elseif frequency_sampling == 2

        saveas(gcf, [outpath, '\\group_analysis\\','RMS_motion_2D_grand_avg_250Hz', '.jpg']); % Save the figure as a PNG image

    end


    %% Combined plots 3D - Permutation

    % RMS measures overall variability, which is helpful for identifying general movement artifacts.
    time_axis = linspace(from * 1000, to * 1000, length(idx_loop)); % in milliseconds

    % We will only label every third row (corresponding to the y-coordinates)
    label_indices = 0:1:length(body_parts); % Indices for the y-coordinates (every third row)

    % Define time points for onset lines
    onset_times = [0, grand_avgOnsetTime_rev]; % Replace with your actual onset times

    % Plot the 3D surface with correctly aligned Y-axis labels
    figure('units', 'normalized', 'outerposition', [0 0 1 1]);
    [X, Y] = meshgrid(time_axis, 1:length(body_parts)); % Use body_parts length directly to match rows

    % Plot the surface
    surf(X, Y, rms_acceleration_t, 'EdgeColor', 'none');
    colormap("turbo");
    c = colorbar;
    c.Label.String = 'RMS of Acceleration Magnitude [mm/s^2]';
    c.Label.FontSize = 11;
    caxis([0 max(rms_acceleration_t(:))]);

    % Set axis limits and labels
    xlim([min(time_axis) max(time_axis)]);
    ylim([1 size(rms_acceleration_t, 1)]); % Ensure the Y-axis matches the data size

    % Adjust Y-axis labels
    set(gca, 'YTick', 1:length(body_parts), 'YTickLabel', body_parts, 'XTickLabelRotation', 30); %'YTickLabelRotation', 10,

    % Label axes
    xlabel('Time [ms]', 'FontSize', 11);
    ylabel('Body Landmarks', 'FontSize', 11, 'Position', [-3438.001500791994,11.190612155547742,-0.16010789176363]);
    zlabel('RMS', 'FontSize', 11);
    %title('Root Mean Square [RMS] of Acceleration Magnitude Over Time', 'FontSize', 12);
    %subtitle(['Windows of ', num2str(sec*1000), ' [ms]'], 'FontSize', 11.5);
    view([110, 40]);

    % Recalculate and highlight top RMS body parts with correctly aligned labels
    N = min(6, length(body_parts)); % Number of top body parts to highlight
    [top_rms_values, top_rms_indices] = maxk(mean(rms_acceleration_t, 2), N); % Get top body part indices by RMS
    rms_threshold = min(max(rms_acceleration_t(label_indices(top_rms_indices), :), [], 2)); % Average of max RMS values for top body parts

    % Draw 3D "walls" with restricted height at RMS threshold
    hold on;
    for i = 1:length(onset_times)

        % Define the color and style for each line
        if i == 1
            line_color = 'r';
            line_style = '--';
        else
            line_color = 'k';
            line_style = ':';
        end

        % Draw box edges at each onset time along x, y, and restricted z
        plot3([onset_times(i), onset_times(i)], [1, 1], [0, rms_threshold], line_style, 'Color', line_color, 'LineWidth', 2.5); % Vertical edge
        plot3([onset_times(i), onset_times(i)], [1, size(rms_acceleration_t, 1)], [0, 0], line_style, 'Color', line_color, 'LineWidth', 2.5); % Bottom horizontal edge
        plot3([onset_times(i), onset_times(i)], [1, size(rms_acceleration_t, 1)], [rms_threshold, rms_threshold], line_style, 'Color', line_color, 'LineWidth', 2.5); % Top horizontal edge
    end

    % Highlight top RMS body parts with labels
    offset = 0.1; % Offset for label positioning
    for i = 1:N
        plot3(time_axis, repmat(top_rms_indices(i), size(time_axis)), rms_acceleration_t(top_rms_indices(i), :), 'b', 'Linestyle', ':', 'LineWidth', 2);
        %text(max(time_axis) + offset, top_rms_indices(i), max(rms_acceleration_t(top_rms_indices(i), :)), ...
        %    body_parts{top_rms_indices(i)}, 'Color', 'k', 'FontSize', 8, 'HorizontalAlignment', 'center');
    end

    % Enable grid for better visualization
    grid on;

    % % Add grid lines
    % for c = [head_parts(end), upper_body_parts(end), lower_body_parts(end)]
    %     yline(c + 0.5, 'w-', 'LineWidth', 2);
    % end

    hold on;
    % % Draw vertical lines for time bins
    % for t = time_bins
    %     xline(t, 'w--', 'LineWidth', 0.1);
    % end

    % Add cluster labels on the left side of the plot
    text(-3200, mean(head_parts)+2, 'Head', 'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'right', 'Rotation', 90); %, 'Rotation', 90
    text(-3100, mean(upper_body_parts)+2, 'Upper Body', 'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'right', 'Rotation', 90);
    text(-3100, mean(lower_body_parts)+1, 'Lower Body', 'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'right', 'Rotation', 90);

    % Determine maximum z value for positioning the stars on top
    max_rms_value = max(rms_acceleration_t(:));
    z_offset = 0.1; % Small offset to ensure the markers are clearly visible above the surface

    % Highlight Significant Bins with Stars on Top of the 3D Plot
    for cluster_idx = 1:num_clusters
        for bin_idx = 1:length(time_bins) - 1
            if adjusted_p_values(cluster_idx, bin_idx) < 0.05
                % Get the mid-time of the bin
                bin_mid_time = (time_bins(bin_idx) + time_bins(bin_idx + 1)) / 2;

                % Determine y-axis position for the star (center of the cluster range)
                y_center = mean(cluster_parts{cluster_idx});

                % Plot star at the top surface level
                plot3(bin_mid_time, y_center, max_rms_value + z_offset, ...
                    'Marker', "pentagram", 'Color', 'w', 'MarkerSize', 15, 'LineWidth', 1, 'MarkerEdgeColor', 'k', 'MarkerFaceColor','w'); % Place star slightly above the surface
            end
        end
    end

    % Rotate the fig for better visualization
    azimuth_angle = -20.695036496350380;
    elevation_angle = 82.462139689578750;
    view([azimuth_angle, elevation_angle]); % Replace with your desired values


    % Loop through significant bins and highlight them with transparent 3D planes
    for cluster_idx = 1:num_clusters
        for bin_idx = 1:length(time_bins) - 1
            if adjusted_p_values(cluster_idx, bin_idx) < 0.05
                % Get the time range of the bin
                bin_start_time = time_bins(bin_idx);
                bin_end_time = time_bins(bin_idx + 1);

                % Determine y-axis range for the cluster
                y_start = min(cluster_parts{cluster_idx});
                y_end = max(cluster_parts{cluster_idx});

                % Define z-axis range (RMS values) for the box
                z_start = 0;
                z_end = max_rms_value;

                % Create vertices for the 3D box
                vertices = [
                    bin_start_time, y_start, z_start; % Bottom-front-left
                    bin_start_time, y_end, z_start;   % Bottom-front-right
                    bin_end_time, y_end, z_start;     % Bottom-back-right
                    bin_end_time, y_start, z_start;   % Bottom-back-left
                    bin_start_time, y_start, z_end;   % Top-front-left
                    bin_start_time, y_end, z_end;     % Top-front-right
                    bin_end_time, y_end, z_end;       % Top-back-right
                    bin_end_time, y_start, z_end;     % Top-back-left
                    ];

                % Define faces of the box
                faces = [
                    1, 2, 6, 5; % Front
                    2, 3, 7, 6; % Right
                    3, 4, 8, 7; % Back
                    4, 1, 5, 8; % Left
                    5, 6, 7, 8; % Top
                    1, 2, 3, 4; % Bottom
                    ];

                % Add the 3D box to the plot
                patch('Vertices', vertices, 'Faces', faces, ...
                    'FaceColor', "yellow", 'FaceAlpha', 0.08, 'EdgeColor', 'k');
            end
        end
    end

    %saveas(gcf, [outpath, '\\group_analysis\\','RMS_motion_3D_grand_avg', '.jpg']); % Save the figure as a PNG image
    %save_fig(gcf,[outpath, '\\group_analysis\\',], 'RMS_motion_3D_grand_avg_Permutation', 'fontsize', 10);

    % Save a figure with 2-column width (180 mm) as TIFF
    % save_fig_pro(gcf, [outpath, '\\group_analysis\\',], 'RMS_motion_3D_grand_avg', 'fontsize', 8, 'width_mm', 180, 'figtype', 'tiff', 'dpi', 600);





    if frequency_sampling == 1

        save_fig(gcf,[outpath, '\\group_analysis\\',], 'RMS_motion_3D_grand_avg_Permutation_15Hz', 'fontsize', 10);

    elseif frequency_sampling == 2

        save_fig(gcf,[outpath, '\\group_analysis\\',], 'RMS_motion_3D_grand_avg_Permutation_250Hz', 'fontsize', 10);

    end



    %% Combined plots 3D - Binomial

    % RMS measures overall variability, which is helpful for identifying general movement artifacts.
    time_axis = linspace(from * 1000, to * 1000, length(idx_loop)); % in milliseconds

    % We will only label every third row (corresponding to the y-coordinates)
    label_indices = 0:1:length(body_parts); % Indices for the y-coordinates (every third row)

    % Define time points for onset lines
    onset_times = [0, grand_avgOnsetTime_rev]; % Replace with your actual onset times

    % Plot the 3D surface with correctly aligned Y-axis labels
    figure('units', 'normalized', 'outerposition', [0 0 1 1]);
    [X, Y] = meshgrid(time_axis, 1:length(body_parts)); % Use body_parts length directly to match rows

    % Plot the surface
    surf(X, Y, rms_acceleration_t, 'EdgeColor', 'none');
    colormap("turbo");
    c = colorbar;
    c.Label.String = 'RMS of Acceleration Magnitude [mm/s^2]';
    c.Label.FontSize = 11;
    caxis([0 max(rms_acceleration_t(:))]);

    % Set axis limits and labels
    xlim([min(time_axis) max(time_axis)]);
    ylim([1 size(rms_acceleration_t, 1)]); % Ensure the Y-axis matches the data size

    % Adjust Y-axis labels
    set(gca, 'YTick', 1:length(body_parts), 'YTickLabel', body_parts, 'XTickLabelRotation', 30); %'YTickLabelRotation', 10,

    % Label axes
    xlabel('Time [ms]', 'FontSize', 11);
    ylabel('Body Landmarks', 'FontSize', 11, 'Position', [-3438.001500791994,11.190612155547742,-0.16010789176363]);
    zlabel('RMS', 'FontSize', 11);
    %title('Root Mean Square [RMS] of Acceleration Magnitude Over Time', 'FontSize', 12);
    %subtitle(['Windows of ', num2str(sec*1000), ' [ms]'], 'FontSize', 11.5);
    view([110, 40]);

    % Recalculate and highlight top RMS body parts with correctly aligned labels
    N = min(6, length(body_parts)); % Number of top body parts to highlight
    [top_rms_values, top_rms_indices] = maxk(mean(rms_acceleration_t, 2), N); % Get top body part indices by RMS
    rms_threshold = min(max(rms_acceleration_t(label_indices(top_rms_indices), :), [], 2)); % Average of max RMS values for top body parts

    % Draw 3D "walls" with restricted height at RMS threshold
    hold on;
    for i = 1:length(onset_times)

        % Define the color and style for each line
        if i == 1
            line_color = 'r';
            line_style = '--';
        else
            line_color = 'k';
            line_style = ':';
        end

        % Draw box edges at each onset time along x, y, and restricted z
        plot3([onset_times(i), onset_times(i)], [1, 1], [0, rms_threshold], line_style, 'Color', line_color, 'LineWidth', 2.5); % Vertical edge
        %plot3([onset_times(i), onset_times(i)], [1, size(rms_acceleration_t, 1)], [0, 0], line_style, 'Color', line_color, 'LineWidth', 2.5); % Bottom horizontal edge
        plot3([onset_times(i), onset_times(i)], [1, size(rms_acceleration_t, 1)], [rms_threshold, rms_threshold], line_style, 'Color', line_color, 'LineWidth', 2.5); % Top horizontal edge
    end

    % % Highlight top RMS body parts with labels
    % offset = 0.1; % Offset for label positioning
    % for i = 1:N
    %     plot3(time_axis, repmat(top_rms_indices(i), size(time_axis)), rms_acceleration_t(top_rms_indices(i), :), 'b', 'Linestyle', ':', 'LineWidth', 2);
    %     %text(max(time_axis) + offset, top_rms_indices(i), max(rms_acceleration_t(top_rms_indices(i), :)), ...
    %     %    body_parts{top_rms_indices(i)}, 'Color', 'k', 'FontSize', 8, 'HorizontalAlignment', 'center');
    % end

    % Enable grid for better visualization
    grid on;

    % % Add grid lines
    % for c = [head_parts(end), upper_body_parts(end), lower_body_parts(end)]
    %     yline(c + 0.5, 'w-', 'LineWidth', 2);
    % end

    hold on;
    % % Draw vertical lines for time bins
    % for t = time_bins
    %     xline(t, 'w--', 'LineWidth', 0.1);
    % end

    % Add cluster labels on the left side of the plot
    text(-3200, mean(head_parts)+2, 'Head', 'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'right', 'Rotation', 90); %, 'Rotation', 90
    text(-3100, mean(upper_body_parts)+2, 'Upper Body', 'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'right', 'Rotation', 90);
    text(-3100, mean(lower_body_parts)+1, 'Lower Body', 'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'right', 'Rotation', 90);

    % % Determine maximum z value for positioning the stars on top
    % max_rms_value = max(rms_acceleration_t(:));
    % z_offset = 0.1; % Small offset to ensure the markers are clearly visible above the surface
    %
    % % Highlight Significant Bins with Stars on Top of the 3D Plot
    % for cluster_idx = 1:num_clusters
    %     for bin_idx = 1:length(time_bins) - 1
    %         if adjusted_p_values(cluster_idx, bin_idx) < 0.05
    %             % Get the mid-time of the bin
    %             bin_mid_time = (time_bins(bin_idx) + time_bins(bin_idx + 1)) / 2;
    %
    %             % Determine y-axis position for the star (center of the cluster range)
    %             y_center = mean(cluster_parts{cluster_idx});
    %
    %             % Plot star at the top surface level
    %             plot3(bin_mid_time, y_center, max_rms_value + z_offset, ...
    %                 'Marker', "pentagram", 'Color', 'w', 'MarkerSize', 15, 'LineWidth', 1, 'MarkerEdgeColor', 'k', 'MarkerFaceColor','w'); % Place star slightly above the surface
    %         end
    %     end
    % end

    % Rotate the fig for better visualization
    azimuth_angle = -20.695036496350380;
    elevation_angle = 82.462139689578750;
    view([azimuth_angle, elevation_angle]); % Replace with your desired values

    % % Loop through significant bins and highlight them with transparent 3D planes
    % for cluster_idx = 1:num_clusters
    %     for bin_idx = 1:length(time_bins) - 1
    %         if adjusted_p_values(cluster_idx, bin_idx) < 0.05
    %             % Get the time range of the bin
    %             bin_start_time = time_bins(bin_idx);
    %             bin_end_time = time_bins(bin_idx + 1);
    %
    %             % Determine y-axis range for the cluster
    %             y_start = min(cluster_parts{cluster_idx});
    %             y_end = max(cluster_parts{cluster_idx});
    %
    %             % Define z-axis range (RMS values) for the box
    %             z_start = 0;
    %             z_end = max_rms_value;
    %
    %             % Create vertices for the 3D box
    %             vertices = [
    %                 bin_start_time, y_start, z_start; % Bottom-front-left
    %                 bin_start_time, y_end, z_start;   % Bottom-front-right
    %                 bin_end_time, y_end, z_start;     % Bottom-back-right
    %                 bin_end_time, y_start, z_start;   % Bottom-back-left
    %                 bin_start_time, y_start, z_end;   % Top-front-left
    %                 bin_start_time, y_end, z_end;     % Top-front-right
    %                 bin_end_time, y_end, z_end;       % Top-back-right
    %                 bin_end_time, y_start, z_end;     % Top-back-left
    %                 ];
    %
    %             % Define faces of the box
    %             faces = [
    %                 1, 2, 6, 5; % Front
    %                 2, 3, 7, 6; % Right
    %                 3, 4, 8, 7; % Back
    %                 4, 1, 5, 8; % Left
    %                 5, 6, 7, 8; % Top
    %                 1, 2, 3, 4; % Bottom
    %                 ];
    %
    %             % Add the 3D box to the plot
    %             patch('Vertices', vertices, 'Faces', faces, ...
    %                 'FaceColor', "yellow", 'FaceAlpha', 0.08, 'EdgeColor', 'k');
    %         end
    %     end
    % end


    % Add Significant Movement Stars to the Plot

    % Define the path to the onset validation file
    onset_validation_file = fullfile(outpath, 'binomial_test_acceleration.xlsx');

    % Read the onset validation data
    onset_data = readtable(onset_validation_file, 'ReadVariableNames', true);

    % Identify significant body parts based on p-value threshold
    significant_parts = onset_data.pValue < 0.05;
    significant_body_parts = onset_data.parts(significant_parts);

    % Loop through the body parts and find their indices
    significant_indices = [];
    for i = 1:length(significant_body_parts)
        % Find the index of the significant body part in the body_parts list
        idx = find(strcmp(body_parts, significant_body_parts{i}));
        if ~isempty(idx)
            significant_indices = [significant_indices; idx];
        end
    end

    % Add stars for significant body parts at time 0
    hold on;
    for i = 1:length(significant_indices)
        idx = significant_indices(i);
        plot3(0, idx, max(rms_acceleration_t(:)) + 0.1, 'p', ...
            'Marker', "pentagram", 'Color', 'w', 'MarkerSize', 15, 'LineWidth', 1, 'MarkerEdgeColor', 'k', 'MarkerFaceColor','w');
    end

    %saveas(gcf, [outpath, '\\group_analysis\\','RMS_motion_3D_grand_avg_PRO', '.jpg']); % Save the figure as a PNG image
    %save_fig(gcf,[outpath, '\\group_analysis\\',], 'RMS_motion_3D_grand_avg_Binomial', 'fontsize', 10);



    if frequency_sampling == 1

        save_fig(gcf,[outpath, '\\group_analysis\\',], 'RMS_motion_3D_grand_avg_Binomial_15Hz', 'fontsize', 10);

    elseif frequency_sampling == 2

        save_fig(gcf,[outpath, '\\group_analysis\\',], 'RMS_motion_3D_grand_avg_Binomial_250Hz', 'fontsize', 10);

    end


    disp('Updated plot with significant body parts saved!');


    %% Combined plots 2D - Binomial

    % RMS measures overall variability, which is helpful for identifying general movement artifacts.
    time_axis = linspace(from * 1000, to * 1000, length(idx_loop)); % in milliseconds

    % We will only label every third row (corresponding to the y-coordinates)
    label_indices = 0:1:length(body_parts); % Indices for the y-coordinates (every third row)

    % Define time points for onset lines
    onset_times = [0, grand_avgOnsetTime_rev]; % Replace with your actual onset times

    % Plot the 2D surface with correctly aligned Y-axis labels
    figure('units', 'normalized', 'outerposition', [0 0 1 1]);
    imagesc(time_axis, 1:size(rms_acceleration_t, 1), rms_acceleration_t);
    colormap("turbo");
    c = colorbar;
    c.Label.String = 'RMS of Acceleration Magnitude [mm/s^2]';
    c.Label.FontSize = 11;
    caxis([0 max(rms_acceleration_t(:))]);
    set(gca, 'YTick', 1:1:33, 'YTickLabel', body_parts);
    xlabel('Time [ms]', 'FontSize', 11);
    ylabel('Body Landmarks', 'FontSize', 11, 'Position', [-2976.620246249664,16.560959874129882,1]);
    % title('Root Mean Square [RMS] of Acceleration Magnitude Over Time', 'FontSize', 14);
    % subtitle('Windows of 10 ms', 'FontSize', 11.5);

    % Set axis limits and labels
    xlim([min(time_axis) max(time_axis)]);
    ylim([1 size(rms_acceleration_t, 1)]); % Ensure the Y-axis matches the data size

    % % Add grid lines
    % for c = [head_parts(end), upper_body_parts(end), lower_body_parts(end)]
    %     yline(c + 0.5, 'w-', 'LineWidth', 2);
    % end

    hold on;

    % Add cluster labels on the left side of the plot
    text(-2900, mean(head_parts), 'Head', 'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'right', 'Rotation', 90);
    text(-2900, mean(upper_body_parts)-2, 'Upper Body', 'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'right', 'Rotation', 90);
    text(-2900, mean(lower_body_parts)-2, 'Lower Body', 'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'right', 'Rotation', 90);


    % Recalculate and highlight top RMS body parts with correctly aligned labels
    N = min(6, length(body_parts)); % Number of top body parts to highlight
    [top_rms_values, top_rms_indices] = maxk(mean(rms_acceleration_t, 2), N); % Get top body part indices by RMS
    rms_threshold = min(max(rms_acceleration_t(label_indices(top_rms_indices), :), [], 2)); % Average of max RMS values for top body parts

    % Draw 3D "walls" with restricted height at RMS threshold
    hold on;
    for i = 1:length(onset_times)

        % Define the color and style for each line
        if i == 1
            line_color = 'r';
            line_style = '--';
        else
            line_color = 'k';
            line_style = ':';
        end

        % Draw box edges at each onset time along x, y, and restricted z
        plot3([onset_times(i), onset_times(i)], [1, 1], [0, rms_threshold], line_style, 'Color', line_color, 'LineWidth', 2.5); % Vertical edge
        %plot3([onset_times(i), onset_times(i)], [1, size(rms_acceleration_t, 1)], [0, 0], line_style, 'Color', line_color, 'LineWidth', 2.5); % Bottom horizontal edge
        plot3([onset_times(i), onset_times(i)], [1, size(rms_acceleration_t, 1)], [rms_threshold, rms_threshold], line_style, 'Color', line_color, 'LineWidth', 2.5); % Top horizontal edge
    end

    % Add Significant Movement Stars to the Plot
    hold on;

    % Define the path to the onset validation file
    onset_validation_file = fullfile(outpath, 'binomial_test_acceleration.xlsx');

    % Read the onset validation data
    onset_data = readtable(onset_validation_file, 'ReadVariableNames', true);

    % Identify significant body parts based on p-value threshold
    significant_parts = onset_data.pValue < 0.05;
    significant_body_parts = onset_data.parts(significant_parts);

    % Loop through the body parts and find their indices
    significant_indices = [];
    for i = 1:length(significant_body_parts)
        % Find the index of the significant body part in the body_parts list
        idx = find(strcmp(body_parts, significant_body_parts{i}));
        if ~isempty(idx)
            significant_indices = [significant_indices; idx];
        end
    end

    % Add stars for significant body parts at time 0
    hold on;
    for i = 1:length(significant_indices)
        idx = significant_indices(i);
        plot3(0, idx, max(rms_acceleration_t(:)) + 0.1, 'p', ...
            'Marker', "pentagram", 'Color', 'w', 'MarkerSize', 15, 'LineWidth', 1, 'MarkerEdgeColor', 'k', 'MarkerFaceColor','w');
    end

    %saveas(gcf, [outpath, '\\group_analysis\\','RMS_motion_3D_grand_avg_PRO', '.jpg']); % Save the figure as a PNG image
    %save_fig(gcf,[outpath, '\\group_analysis\\',], 'RMS_motion_2D_grand_avg_Binomial', 'fontsize', 10);



    if frequency_sampling == 1

        save_fig(gcf,[outpath, '\\group_analysis\\',], 'RMS_motion_2D_grand_avg_Binomial_15Hz', 'fontsize', 10);

        acceleration_magnitude_15Hz = rms_acceleration_t;
        time_axis_15Hz = time_axis;

        save([outpath, 'Acceleration_magnitude_grand_avg_15Hz', '.mat'],'acceleration_magnitude_15Hz', 'time_axis_15Hz');

    elseif frequency_sampling == 2

        save_fig(gcf,[outpath, '\\group_analysis\\',], 'RMS_motion_2D_grand_avg_Binomial_250Hz', 'fontsize', 10);

        acceleration_magnitude_250Hz = rms_acceleration_t;
        time_axis_250Hz = time_axis;

        save([outpath, 'Acceleration_magnitude_grand_avg_250Hz', '.mat'],'acceleration_magnitude_250Hz', 'time_axis_250Hz');

    end

end




