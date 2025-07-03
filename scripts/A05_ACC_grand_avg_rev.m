clc, clear, close all;

%% Onset detection with wrist sensor 

% This code calculates the grand average movement onset across
% participants per condition.

% Miguel Contreras-Altamirano, 2025

%% Paths and Files

mainpath = 'C:\Users\micua\Desktop\eeglab2023.0\'; % eeglab folder
path = 'C:\Users\micua\OneDrive - Benemérita Universidad Autónoma de Puebla\NCP_Basketball\MediaPipe\';
outpath = 'C:\\Users\\micua\\OneDrive - Benemérita Universidad Autónoma de Puebla\\Oldenburg_University\\Thesis\\data_hoops\\';
files = dir(fullfile(path,'\*.xdf')); % listing data sets

num_conditions = 3; % (Conditions and overall: 1=hit 2=miss 3=all)


for cond=1 : num_conditions

    %% Plotting setup

    from = -2.5; % sec
    to = 1; % sec

    legendEntries = cell(1, length(files) + 1); % Initialize cell array for legend entries (+1 for the average)
    allTimeseries = []; % Initialize matrix to store all timeseries data
    maxLength = 0; % Variable to store the length of the longest timeseries


    %% Loop through participants

    for sub = 1:length(files)
        
        participant = extractBefore(files(sub).name, '.xdf');
        out_subfold = [outpath, participant, '\\'];

        if cond == 1 % 'hit'

            ACC_file = [out_subfold, 'ACC_rev_hit_', participant, '.mat'];

        elseif cond == 2 % 'miss'

            ACC_file = [out_subfold, 'ACC_rev_miss_', participant, '.mat'];

        elseif cond == 3  % % 'none'

            ACC_file = [out_subfold, 'ACC_rev_', participant, '.mat'];

        end



        % Check if the ACC file exists
        if isfile(ACC_file)
            load(ACC_file, 'avgAccMagnitude_rev', 'epochTimes_rev', 'sampling_rate_acc', ...
                'epochs_accMagnitude_rev', 'baselineStd', 'upper_bound_rev', 'lower_bound_rev', 'avgOnsetTime_rev', 'RC_onsets'); % Load data

            % Check if the required variables are in the loaded file
            if exist('avgAccMagnitude_rev', 'var') && exist('epochTimes_rev', 'var')
                %subjects = plot(avgAccMagnitude_across_rev, epochTimes_rev, 'Color', colors(sub, :), 'LineWidth', 1.5);
                %legendEntries{sub} = ['Sub. ', num2str(sub)]; % Add entry for legend

                % Ensure timeseries_acc_mag is a column vector
                if isrow(avgAccMagnitude_rev)
                    avgAccMagnitude_rev = avgAccMagnitude_rev';
                end

                % Update maxLength if the current timeseries is longer
                if length(avgAccMagnitude_rev) > maxLength
                    maxLength = length(avgAccMagnitude_rev);
                end

                % Store the timeseries data for later processing
                allTimeseries{sub} = avgAccMagnitude_rev;
                allOnsets{sub} = avgOnsetTime_rev;
                peak_acc{sub} = max(avgAccMagnitude_rev);  % Directly find the max peaks

            else
                fprintf('Data for participant %d is missing or incomplete.\n', sub);
            end
        else
            fprintf('No ACC data file found for participant %d.\n', sub);
        end
    end

    % Concatenate timeseries
    for i = 1:length(allTimeseries)
        % Check if the current timeseries is not empty
        if ~isempty(allTimeseries{i})
            currentLength = length(allTimeseries{i});
            concatTimeseries(1:currentLength, i) = allTimeseries{i};
        end
        % If allTimeseries{i} is empty, the corresponding column in concatTimeseries
        % will remain NaNs as initialized.
    end

    % Calculate the average acceleration across all participants
    avgAccMagnitude_across_rev = mean(concatTimeseries, 2);


    % % Ensure that timestamps_acc_mag has the same length as the padded timeseries
    % if length(timestamps_acc_mag) ~= maxLength
    %     % Assuming timestamps_acc_mag is linearly spaced, we can extend it to match maxLength
    %     timestamps_acc_mag = linspace(timestamps_acc_mag(1), timestamps_acc_mag(end), maxLength);
    % end

    % mx_peak_acc_rev = max(mean(peak_acc{1:end}));


    %% Reverse Computation Algorithm

    % % Define the number of data points and trials based on your description
    % dataPoints = size(concatTimeseries, 1);
    % trials_avg = size(concatTimeseries, 2);
    % 
    % % Define epoch times for illustration purposes (if not already defined)
    % timestamps_acc_mag_rev = linspace(-2500, 1000, dataPoints); % Adjust this according to your data
    % start_BP = find(timestamps_acc_mag_rev == -2000);
    % artificial_onset = find(timestamps_acc_mag_rev == 0);
    % 
    % % Identify indices for the baseline period
    % baselineIndices = timestamps_acc_mag_rev >= -2500 & timestamps_acc_mag_rev <= -2000;
    % 
    % 
    % % Calculate the baseline mean and standard deviation for each trial
    % baselineMean = mean(concatTimeseries(baselineIndices, :), 1);
    % baselineStd = std(concatTimeseries(baselineIndices, :), 0, 1);
    % 
    % % Define a threshold for movement onset, for example, mean + 3 * standard deviations
    % threshold = baselineMean + 1 * baselineStd; % Above 1SD detection(mean + N * std)
    % 
    % % Initialize a vector to store the movement onset index for each trial
    % movementOnsets = NaN(1, trials_avg);
    % 
    % % Detect the movement onset for each trial using reverse computation
    % for trial_avg = 1:trials_avg
    %     % Reverse computation: start from time 0 and move backwards
    %     for t = find(timestamps_acc_mag_rev(start_BP:artificial_onset) <= 0, 1, 'last'):-1:1
    %         if concatTimeseries(t, trial_avg) > threshold(trial_avg)
    %             % Store the index just before the threshold is crossed
    %             movementOnsets(trial_avg) = t + 1;
    %             break; % Stop once the onset is found
    %         end
    %     end
    % end
    % 
    % % Check if any onsets were detected
    % if all(isnan(movementOnsets))
    %     disp('No onsets were detected.');
    % end



    %% Plotting

    % Constants for plotting
    colors = lines(length(concatTimeseries));   % Use hsv, jet or any other colormap
    % Mix with white to lighten the colors
    lightenFactor = 0.5;  % Adjust this to make the color lighter (closer to 1 makes it lighter)
    colors = colors + lightenFactor * (1 - colors);


    % Plot each trial as a semi-transparent line
    acc_fig_rev = figure('units','normalized','outerposition', [0 0 1 1]); hold on;
    for trial_avg = 1:size(concatTimeseries, 2)   % here subjects become 'trials'
        trials_avg = plot(epochTimes_rev, concatTimeseries(:, trial_avg), 'Color', colors(trial_avg, :), 'LineWidth', 1);
    end


    % Plot the average acceleration
    acc_line = plot(epochTimes_rev, avgAccMagnitude_across_rev, 'LineStyle', '-', ...
        'Marker', 'o', 'MarkerIndices', 1:10:length(avgAccMagnitude_across_rev),'LineWidth', 2.5, 'Color', 'k');


    % Assuming you have the figure already open and have plotted the trials

    % Highlight the baseline period
    baselineStart_avg = -2500; % adjust to your baseline start time
    baselineEnd_avg = -2000; % adjust to your baseline end time

    % Get the current y-axis limits
    ylimits = [0 180];

    % Fill between the baseline period with a light blue color and some transparency
    fill([baselineStart_avg, baselineStart_avg, baselineEnd_avg, baselineEnd_avg], [ylimits(1), ylimits(2), ylimits(2), ylimits(1)], [0.4660 0.6740 0.1880], 'FaceAlpha', 0.2, 'EdgeColor', 'none');  %[0 0.4470 0.7410]
    % Add a label to BL
    text(-2150, 10, 'Baseline', 'Color', 'k', 'FontSize', 10, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom','FontWeight', 'bold');


    % Calculate the average onset time
    % validOnsetIndices = ~isnan(movementOnsets);
    % grand_avgOnsetTime_rev = mean(epochTimes_rev(movementOnsets(validOnsetIndices)));
    basketballOnsets= [allOnsets{:}];
    grand_avgOnsetTime_rev = mean([allOnsets{:}]);


    % Plot a vertical line at the average onset time
    line([0, 0], ylim, 'Color', 'red', 'LineStyle', '--', 'LineWidth', 2.5);

    % Add a label to the line basketball onset
    text(0, 98, 'Movement onset', 'Color', 'r', 'FontSize', 10, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', 'Rotation', 90, 'FontWeight', 'bold');

    % Plot a vertical line at the average onset time
    line([grand_avgOnsetTime_rev, grand_avgOnsetTime_rev], ylim, 'Color', 'k', 'LineStyle', ':', 'LineWidth', 2);
    
    % Add a label to the line movement onset
    text(grand_avgOnsetTime_rev, 98, 'Set-point onset', 'Color', 'k', 'FontSize', 10, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', 'Rotation', 90, 'FontWeight', 'bold');


    % Displaying label condition

    if cond == 1 % 'hit'

        cond_label = 'Hits';

    elseif cond == 2 % 'miss'

        cond_label = 'Misses';

    elseif cond == 3  % % 'none'

        cond_label = 'Participants';

    end


    xlabel('Time [ms]', FontSize=15);
    ylabel('Acceleration Magnitude [m/s^2]', FontSize=15);
    %title('Onset Detection Based On Wrist Acceleration', FontSize=16);
    %subtitle('Grand Average [Reverse Computation Algorithm]', FontSize=16);
    legend([trials_avg, acc_line], {cond_label, 'Grand Mean'}, 'FontSize', 12, 'Location', 'northwest');
    ylim([0 100])
    xlim([from*1000 to*1000]);
    grid on;



    %% Saving

    if cond == 1 % 'hit'

        % Save it in .mat file
        save([outpath, 'ACC_grand_avg_rev_hit', '.mat'],'avgAccMagnitude_across_rev', 'epochTimes_rev', 'grand_avgOnsetTime_rev',...
            'concatTimeseries', 'basketballOnsets');


        % Save the figure as a PNG image
        %saveas(acc_fig_rev, [outpath, 'Grand_avg_ACC_rev_hit', '.jpg']);
        saveas(acc_fig_rev, [outpath, '\\group_analysis\\','Grand_avg_ACC_rev_hit', '.jpg']);


    elseif cond == 2 % 'miss'

        % Save it in .mat file
        save([outpath, 'ACC_grand_avg_rev_miss', '.mat'],'avgAccMagnitude_across_rev', 'epochTimes_rev', 'grand_avgOnsetTime_rev',...
            'concatTimeseries', 'basketballOnsets');

        % Save the figure as a PNG image
        %saveas(acc_fig_rev, [outpath, 'Grand_avg_ACC_rev_miss', '.jpg']);
        saveas(acc_fig_rev, [outpath, '\\group_analysis\\','Grand_avg_ACC_rev_miss', '.jpg']);



    elseif cond == 3  % % 'none'


        % Save it in .mat file
        save([outpath, 'ACC_grand_avg_rev', '.mat'],'avgAccMagnitude_across_rev', 'epochTimes_rev', 'grand_avgOnsetTime_rev',...
            'concatTimeseries', 'basketballOnsets');

        % Save the figure as a PNG image
        %saveas(acc_fig_rev, [outpath, 'Grand_avg_ACC_rev', '.jpg']);
        saveas(acc_fig_rev, [outpath, '\\group_analysis\\','Grand_avg_ACC_rev', '.jpg']);
        save_fig(acc_fig_rev,[outpath, '\\group_analysis\\',], 'Grand_avg_ACC_rev', 'fontsize', 12);



    end

    % clear avgAccMagnitude_across_rev
    % clear epochTimes_rev
    % clear grand_avgOnsetTime_rev
    % clear concatTimeseries
    % clear basketballOnsets
    % clear concatTimeseries

end


%% Reverse Computation Algorithm
% 
% The reverse computation algorithm, in the context of onset detection for
% movement or signal processing, refers to starting at a known event point
% (like a stimulus or action) and moving backward in time to find when a
% particular change of interest first occurs. This method is often used
% when the exact timing of the onset is not known, but the occurrence of an
% event is.
% 
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