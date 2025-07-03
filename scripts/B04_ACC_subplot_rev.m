clc, clear, close all;

%% Onset detection with wrist sensor (all participants plot)

% This code uses accelerometer data to detect the onset of the movement
% based on wrist acceleration, creates subplots of the detected onset for
% all participants. 

% Miguel Contreras-Altamirano, 2025


%% Paths and Files

mainpath = 'C:\'; % eeglab folder
path = 'C:\';
outpath = 'C:\';
files = dir(fullfile(path,'\*.xdf')); % listing data sets


num_conditions = 3; % (Conditions and overall: 1=hit 2=miss 3=all)

for cond=3 : num_conditions


    %% Plotting setup

    % Constants for plotting
    from = -2.5; % sec
    to = 1; % sec

    numParticipants = length(files);
    numSubplots = numParticipants + 1; % One for each participant, plus one for the average
    allTimeseries = []; % Initialize matrix to store all timeseries data
    maxLength = 0; % Variable to store the length of the longest timeseries


    numSubplotsPerFigure = 16;  % Number of subplots per figure (4x4 grid)
    numFigures = ceil(length(files) / numSubplotsPerFigure);


    figures = cell(1, numFigures);

    for f = 1:numFigures
        figures{f} = figure;

        % Set up the figure with a larger size
        set(figures{f},'units','normalized','outerposition', [0 0 1 1]); % fig = figure('Units', 'pixels', 'Renderer', 'painters'); [100, 100, 800, 600]

    end


    hold on;


    %% Loop through participants and plot

    for sub = 1:numParticipants

        % Determine which figure and subplot index to use
        figureIndex = ceil(sub / numSubplotsPerFigure);
        subplotIndex = sub - (figureIndex - 1) * numSubplotsPerFigure;

        % Make the correct figure current
        currentFigure = figures{figureIndex};
        figure(currentFigure); % Correctly set the current figure for plotting


        participant = extractBefore(files(sub).name, '.xdf');
        out_subfold = [outpath, participant, '\\'];


        if cond == 1 % 'hit'

            ACC_file = [out_subfold, 'ACC_rev_hit_', participant, '.mat'];
            load([outpath, 'ACC_grand_avg_rev_hit', '.mat']);

        elseif cond == 2 % 'miss'

            ACC_file = [out_subfold, 'ACC_rev_miss_', participant, '.mat'];
            load([outpath, 'ACC_grand_avg_rev_miss', '.mat']);


        elseif cond == 3  % % 'none'

            ACC_file = [out_subfold, 'ACC_rev_', participant, '.mat'];
            load([outpath, 'ACC_grand_avg_rev', '.mat']);

        end



        load(ACC_file, 'avgAccMagnitude_rev', 'epochTimes_rev', 'grand_avgOnsetTime_rev', 'sampling_rate_acc', ...
            'epochs_accMagnitude_rev', 'avgOnsetTime_rev', 'baselineStd', 'upper_bound_rev', 'lower_bound_rev');

        num_events = size(epochs_accMagnitude_rev, 2); % number of trials (total or per condition)



        % Create subplot for this participant
        subplot(4, 4, subplotIndex);

        hold on;

        % Constants for plotting
        colors = lines(num_events);   % Use hsv, jet or any other colormap
        % Mix with white to lighten the colors
        lightenFactor = 0.5;  % Adjust this to make the color lighter (closer to 1 makes it lighter)
        colors = colors + lightenFactor * (1 - colors);


        % Plot each trial as a semi-transparent line
        for trial_avg = 1:size(epochs_accMagnitude_rev, 2)
            trials_avg = plot(epochTimes_rev, epochs_accMagnitude_rev(:, trial_avg), 'Color', colors(trial_avg, :), 'LineWidth', 1);
        end


        % Plot the average acceleration
        acc_line = plot(epochTimes_rev, avgAccMagnitude_rev, 'LineStyle', '-', ...
            'Marker', 'o', 'MarkerIndices', 1:10:length(avgAccMagnitude_rev),'LineWidth', 2.5, 'Color', 'k');

        % Assuming you have the figure already open and have plotted the trials

        % Highlight the baseline period
        baselineStart = -2500; % adjust to your baseline start time
        baselineEnd = -2000; % adjust to your baseline end time

        % Get the current y-axis limits
        ylimits = [0 100];

        % Fill between the baseline period with a light blue color and some transparency
        fill([baselineStart, baselineStart, baselineEnd, baselineEnd], [ylimits(1), ylimits(2), ylimits(2), ylimits(1)], [0 0.4470 0.7410], 'FaceAlpha', 0.3, 'EdgeColor', 'none');

        % peak_acc = max(epochs_accMagnitude_rev);  % Directly find the max peaks
        % mx_peak_acc = max(peak_acc);

        % Plot a vertical line at the average onset time
        line([avgOnsetTime_rev, avgOnsetTime_rev], ylim, 'Color', 'k', 'LineStyle', ':', 'LineWidth', 2);

        % Plot a vertical line at the average onset time
        line([0, 0], ylim, 'Color', 'red', 'LineStyle', '--', 'LineWidth', 2.5);


        if cond == 1 % 'hit'

            cond_label = 'Hits';

        elseif cond == 2 % 'miss'

            cond_label = 'Misses';

        elseif cond == 3  % % 'none'

            cond_label = 'All trials';

        end


        xlabel('Time [ms]');
        ylabel('Acc. Mag. [m/s^2]');
        title(['Wrist Acceleration / [', cond_label, ']']);
        subtitle(['Sub. [', num2str(sub), '] / ', '[RC]']);
        legend([trials_avg, acc_line], {cond_label, 'Mean'}, 'Location', 'northwest');
        ylim(ylimits)
        xlim([from*1000 to*1000]);
        grid on;


        if sub==length(files)

            % Constants for plotting
            colors = lines(length(files));   % Use hsv, jet or any other colormap
            % Mix with white to lighten the colors
            lightenFactor = 0.5;  % Adjust this to make the color lighter (closer to 1 makes it lighter)
            colors = colors + lightenFactor * (1 - colors);

            % Create subplot for average
            subplot(4, 4, subplotIndex+1);

            hold on;

            % Plot each trial as a semi-transparent line
            for trial_avg = 1:size(concatTimeseries, 2)
                trials_avg = plot(epochTimes_rev, concatTimeseries(:, trial_avg), 'Color', colors(trial_avg, :), 'LineWidth', 1);
            end


            % Plot the average acceleration
            acc_line = plot(epochTimes_rev, avgAccMagnitude_across_rev, 'LineStyle', '-', ...
                'Marker', 'o', 'MarkerIndices', 1:10:length(avgAccMagnitude_across_rev),'LineWidth', 2.5, 'Color', 'k');


            % Assuming you have the figure already open and have plotted the trials

            % Highlight the baseline period
            baselineStart = -2500; % adjust to your baseline start time
            baselineEnd = -2000; % adjust to your baseline end time

            % Get the current y-axis limits
            ylimits = [0 100];

            % Fill between the baseline period with a light blue color and some transparency
            fill([baselineStart, baselineStart, baselineEnd, baselineEnd], [ylimits(1), ylimits(2), ylimits(2), ylimits(1)], [0 0.4470 0.7410], 'FaceAlpha', 0.3, 'EdgeColor', 'none');


            % Calculate the average onset time
            % validOnsetIndices = ~isnan(movementOnsets);
            % grand_avgOnsetTime_rev = mean(epochTimes_rev(movementOnsets(validOnsetIndices)));


            % Plot a vertical line at the average onset time
            line([0, 0], ylim, 'Color', 'red', 'LineStyle', '--', 'LineWidth', 2.5);

            % Plot a vertical line at the average onset time
            line([grand_avgOnsetTime_rev, grand_avgOnsetTime_rev], ylim, 'Color', 'k', 'LineStyle', ':', 'LineWidth', 2);


            if cond == 1
                all = 'All ';
            elseif cond == 2
                all = 'All ';
            elseif cond == 3
                all = '';
            end

            xlabel('Time [ms]');
            ylabel('Acc. Mag. [m/s^2]');
            title(['Wrist Acceleration / [', cond_label, ']']);
            subtitle('Grand Average / [RC]');
            legend([trials_avg, acc_line], {[all, cond_label], 'Grand Mean'}, 'Location', 'northwest');
            ylim(ylimits)
            xlim([from*1000 to*1000]);
            grid on;

        end


        % Adjust subplot spacing if needed
        sgtitle('Onset Detection [Reverse Computation Algorithm]'); % Super title


        clear avgAccMagnitude_rev
        clear epochTimes_rev
        clear grand_avgOnsetTime_rev
        clear sampling_rate_acc
        clear epochs_accMagnitude_rev
        clear baselineStd
        clear upper_bound_rev
        clear lower_bound_rev


    end


end


%% Save figures

% for f = 1:numFigures
%     % Ensure you're making each figure current before saving
%     figure(figures{f});
%     saveas(figures{f}, fullfile(outpath, sprintf(['ACC_matrix_rev_', cond_label, '_', '%d', '.jpg'], f)));
%     saveas(figures{f}, fullfile(outpath, 'group_analysis', sprintf(['ACC_matrix_rev_', cond_label, '_', '%d', '.jpg'], f)));
% end

%%
