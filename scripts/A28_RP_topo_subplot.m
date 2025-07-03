clc; clear; close all;

%% Readiness Potential topographies

% This code detects the Readiness Potential onset of each participant and
% plot their respective topography together with the accuracy percentage of
% basketball free-throw shooting.

% Miguel Contreras-Altamirano, 2025


%% Paths and Files
mainpath = 'C:\'; % eeglab folder
path = 'C:\';
outpath = 'C:\';
files = dir(fullfile(path, '\*.xdf')); % listing data sets

load([outpath , 'Info_EEG.mat']); % Assuming T is loaded from this file

num_conditions = 3; % (Conditions and overall: 1=hit 2=miss 3=all)


%% Shooting accuracy (%)

for sub = 1 : length(files)

    participant = extractBefore(files(sub).name, '.xdf');
    out_subfold = [outpath, participant, '\\'];
    load([out_subfold, 'events_all_', participant,'.mat']); % Loading events file

    % Updating times and frames with clean data
    onsetTimes = [events_ACC.time];
    onsetFrames = [events_ACC.latency];

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

    % Shooting percentage accuracy
    shoot_per = (length(hitOnsets) * 100 ) / (length(onsetTimes));
    Hoop_accuracy(sub) = shoot_per;

end


% Table shooting percentage accuracy
% write actual tables
T.Accuracy = Hoop_accuracy';

% Save it in .mat file
save([outpath, 'Info_EEG.mat'],'T');
% writetable(T, [outpath, 'Info_EEG.xlsx']);


%% Ordering topoplots from lower to higher accuracy (%)


% Now that we have a numeric array, we can sort it
[~, sorted_indices] = sort(T.Accuracy , 'ascend'); % Sorting based on accuracy


for cond = 3:num_conditions

    %% Plotting setup
    % Constants for plotting
    from = -2.5; % sec
    to = 1; % sec

    numParticipants = length(files);
    numSubplots = numParticipants + 1; % One for each participant, plus one for the average
    numSubplotsPerFigure = 16; % Number of subplots per figure (4x4 grid)
    numFigures = ceil(numSubplots / numSubplotsPerFigure);

    figures = cell(1, numFigures);
    for f = 1:numFigures
        figures{f} = figure;
        set(figures{f}, 'units', 'normalized', 'outerposition', [0 0 1 1]);
        hold on;
    end

    %% Loop through participants and plot
    for i = 1:numParticipants

        sub = sorted_indices(i); % Get the sorted participant index

        % Determine which figure and subplot index to use
        figureIndex = ceil(i / numSubplotsPerFigure);
        subplotIndex = mod(i - 1, numSubplotsPerFigure) + 1;

        participant = extractBefore(files(sub).name, '.xdf');
        out_subfold = [outpath, participant, '\\'];

        if cond == 1 % 'hit'
            % Import EEG processed data
            [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab; % Open eeglab
            EEG = pop_loadset('filename', ['hoop_hit_RP_', participant, '.set'], 'filepath', out_subfold);
        elseif cond == 2 % 'miss'
            [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab; % Open eeglab
            EEG = pop_loadset('filename', ['hoop_miss_RP_', participant, '.set'], 'filepath', out_subfold);
        elseif cond == 3 % 'none'
            [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab; % Open eeglab
            EEG = pop_loadset('filename', ['hoop_RP_', participant, '.set'], 'filepath', out_subfold);
        end

        % Make the correct figure current
        currentFigure = figures{figureIndex};
        set(0, 'CurrentFigure', currentFigure);

        subtightplot(4, 4, subplotIndex);
        hold on;

        %% TOPOGRAPHY

        % Find the index of the Cz channel (assuming 'Cz' is the label)
        cz_idx = find(strcmp({EEG.chanlocs.labels}, 'Cz'));

        % Get the EEG data for the Cz channel, average across trials
        cz_data = mean(EEG.data(cz_idx, :, :), 3); % Average across trials for Cz channel

        % Find the index of 0 ms (movement onset) in EEG.times
        time_0ms = find(EEG.times == 0);

        % Focus only on the data **before** 0 ms (negative times)
        cz_data_before_0ms = cz_data(1:time_0ms-50); % A bit earlier from movement onset

        % Find the time point with the strongest negative amplitude before 0 ms
        [min_amplitude, timeEEG_idx] = min(cz_data_before_0ms); % Get the index of the minimum value for Cz before 0 ms

        % Plot topography at the time of the strongest negative value for Cz
        ERP_bin = mean(EEG.data(:, timeEEG_idx, :), 3); % Feature mean per bin for all channels
        topoplot(ERP_bin, EEG.chanlocs, 'electrodes', 'off', 'maplimits', [-20 20], 'whitebk', 'on', 'shading', 'interp');
        colormap(jet(250));
        axis('fill');


        % Now you can round the accuracy value and use it in the text
        text('Parent', gca, 'String', ['Shoot acc: ', num2str(round(T.Accuracy(sub))), ' %'], ...
            'Units', 'normalized', 'Position', [-0.333850404608068, 0.388888939108999, 0], ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
            'FontSize', 11, 'FontWeight', 'bold', 'Rotation', 90);


        % Adjust text position below the topoplot
        text('Parent', gca, 'String', ['Sub. [', num2str(sub), '] at ', num2str(EEG.times(timeEEG_idx)), ' [ms]'], ...
            'Units', 'normalized', 'Position', [0.5, -0.0000000000000000000001, 0], ... % Adjust the Y position here
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
            'FontSize', 11, 'FontWeight', 'bold');


        if i == 1
            c = colorbar('Ticks', [-20 -10 0 10 20]);
            c.Label.String = 'Amplitude [\muV]';
            c.Label.FontSize = 11;
            c.Position = [0.9546875, 0.728587319243604, 0.003645833333333, 0.136334146724982];
        end


    end

    %% Plot average for the last subplot in the last figure
    clear EEG;

    if i == numParticipants
        if cond == 1 % 'hit'
            [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab; % Open eeglab
            EEG = pop_loadset('filename', ['Grand_avg_hits', '.set'], 'filepath', outpath);
        elseif cond == 2 % 'miss'
            [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab; % Open eeglab
            EEG = pop_loadset('filename', ['Grand_avg_misses', '.set'], 'filepath', outpath);
        elseif cond == 3 % 'none'
            [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab; % Open eeglab
            EEG = pop_loadset('filename', ['Grand_avg_all', '.set'], 'filepath', outpath);
        end

        % Determine the correct figure and subplot for the grand average
        subplotIndex = mod(numParticipants, numSubplotsPerFigure) + 1;
        if subplotIndex == 1 && numParticipants > 1
            subplotIndex = numSubplotsPerFigure;
            figureIndex = numFigures;
        else
            figureIndex = ceil(numParticipants / numSubplotsPerFigure);
        end

        currentFigure = figures{figureIndex};
        set(0, 'CurrentFigure', currentFigure);

        subtightplot(4, 4, subplotIndex);
        hold on;

        low = -20;
        high = 20;

        timeEEG = find(EEG.times == -200);

        ERP_bin_avg = mean(EEG.data(:, timeEEG-5, :), 3); % Feature mean per bin
        topoplot(ERP_bin_avg, EEG.chanlocs, 'electrodes', 'off', 'maplimits', [low high], 'whitebk', 'on', 'shading', 'interp');
        colormap(jet(250));
        axis('fill');

        % Adjust text position below the topoplot
        text('Parent', gca, 'String', ['Grand Average at ', num2str(EEG.times(timeEEG)), ' [ms]'], ...
            'Units', 'normalized', 'Position', [0.5, -0.0000000000000000000000000001], ... % Adjust the Y position here
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
            'FontSize', 11, 'FontWeight', 'bold');

        text('Parent', gca, 'String', ['Mean acc: ', num2str(round(mean(T.Accuracy))), ' %'], ...
            'Units', 'normalized', 'Position', [-0.333850404608068, 0.388888939108999, 0], ... % Adjust the Y position here
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
            'FontSize', 11, 'FontWeight', 'bold', 'Rotation', 90);

        c = colorbar('Ticks', [-20 -10 0 10 20]);
        c.Label.String = 'Amplitude [\muV]';
        c.Label.FontSize = 11;
        c.Position = [0.9546875, 0.728587319243604, 0.003645833333333, 0.136334146724982];
    end

    % Adjust subplot spacing if needed
    for f = 1:numFigures
        set(0, 'CurrentFigure', figures{f});

        if cond == 1 % 'hit'
            sgtitle('Readiness Potential Across Participants [Hits]'); % Super title
        elseif cond == 2 % 'miss'
            sgtitle('Readiness Potential Across Participants [Misses]'); % Super title
        elseif cond == 3 % 'none'
            sgtitle('Readiness Potential Across Participants'); % Super title
        end
    end
end

%% Save figures

for f = 1:numFigures
    set(0, 'CurrentFigure', figures{f});
    saveas(figures{f}, fullfile(outpath, sprintf(['RP_percentage_', cond_label, '_%d.jpg'], f)));
    saveas(figures{f}, fullfile(outpath, 'group_analysis', sprintf(['RP_percentage_', cond_label, '_%d.jpg'], f)));
end

%%
