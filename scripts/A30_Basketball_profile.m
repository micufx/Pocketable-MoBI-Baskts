clc, clear, close all;

%% Basketball profile of participants

% This code creates a basketball profile of each participant depending on
% the collected behavioral data (PANAS and VAS questionnaires).

% Positive and Negative Affect Schedule (PANAS; Watson et al., 1988) 
% Visual Analogue Scale (VAS; Hayes & Patterson, 1921)

% Miguel Contreras-Altamirano, 2025


%% EEG data loading

mainpath = 'C:\'; % eeglab folder
path = 'C:\';  % raw data
outpath = 'C:\';
files = dir( fullfile( path,'\*.xdf')); % listing data sets

num_conditions = 3; % (Conditions and overall: 1=hit 2=miss 3=all)


%% Loading table and formating data

% Load the data from the Excel file
filename = [outpath, 'Participants_bskt.csv']; % Replace with your actual file path
data = readtable(filename);

% Convert categorical data to numerical values if possible and normalize
data.Basketball_tournaments = double(categorical(data.Basketball_tournaments));
data.School_qualification = double(categorical(data.School_qualification));

% Select the columns you want to include in the radar plot
% Assuming these columns contain numeric data that can be compared directly
columns = {'Age', 'Handedness', 'Sex', 'School_qualification', 'Sleep_hours', 'Last_eating_hours'...
    'Basketball_club_membership_years','Exercise_frequency_hours_per_week', 'Basketball_experience_years', ...
    'Basketball_practice_hours_per_week', 'Last_contact_with_basketball_weeks', 'Basketball_tournaments', 'Own_performance_estimation', ...
    'Recent_exercise_frequency_hours_per_week'};

% Normalizing data
normalized_data = data(:, columns);

% Since there is no left-hand people, everyone has the same value
normalized_data.Handedness = double(categorical(data.Handedness));

% Since there is no left-hand people, everyone has the same value
normalized_data.Sex = double(categorical(data.Sex));


% % Normalizing the data for radar plot (this assumes all values are positive and you want to map them to a [0, 1] scale)
% for sub = 1:width(normalized_data)
%     col = normalized_data{:, sub};
%     normalized_data{:, sub} = (col - min(col)) / (max(col) - min(col));
% end


% Normalizing the data for radar plot (this assumes all values are positive and you want to map them to a [0, 1] scale)
for sub = 1:width(normalized_data)
    col = normalized_data{:, sub};
    if min(col) ~= max(col)
        normalized_data{:, sub} = (col - min(col)) / (max(col) - min(col));
    else
        normalized_data{:, sub} = col; % No normalization needed if all values are the same
    end
end

% Labels
labels = {'Age', 'Handedness', 'Sex', 'School', 'Sleep', 'Eating'...
    'Club','Exercise', 'Experience', ...
    'Practice', 'Familiarity', 'Tournaments', 'Own estimation', ...
    'Recent activity'};


% Define colors for each participant
colors = lines(height(normalized_data)); % Create a colormap with as many colors as there are participants


% %% Plotting participants profile

% % Loop through each participant and create a radar plot
% for sub = 1:height(normalized_data)
% 
%     participant = extractBefore(files(sub).name, '.xdf');
%     out_subfold = [outpath, participant, '\\'];
% 
%     fig = figure('units','normalized','outerposition', [0 0 1 1]);
%     participant_data = normalized_data(sub, :);
% 
%     % Create the radar plot
%     h = polarplot(linspace(0, 2*pi, length(columns)+1), [participant_data{1,:}, participant_data{1,1}], '-o', 'LineWidth', 2.5, 'Color', colors(sub,:), 'MarkerFaceColor', 'k');
% 
%     % Set the axis labels
%     ax = gca;
%     ax.ThetaTick = linspace(0, 360, length(columns)+1);
%     ax.ThetaTickLabels = [labels, labels(1)];
% 
%     % Set the title
%     title('Basketball Profile');
%     subtitle(['Sub. [', num2str(sub), ']']);
% 
%     % Enable grid and set the limits
%     ax.RGrid = 'on';
%     ax.RLim = [0 1]; % since the data is normalized
% 
% 
%     % % Save the figure if needed
%     % saveas(gcf, [out_subfold, 'Basketball_profile_', participant, '.jpg']); % Save the figure as a PNG image
%     % saveas(gcf, [outpath, '\\group_analysis\\','Basketball_profile_', participant, '.jpg']); % Save the figure as a PNG image
% 
% end
% 
% %% Grand Average Profile
% 
% % Calculate the mean across participants for each attribute
% average_profile = mean(normalized_data{:, :});
% 
% % Open a figure
% fig = figure('units','normalized','outerposition', [0 0 1 1]);
% 
% % Create the radar plot for the average profile
% h = polarplot(linspace(0, 2*pi, length(columns)+1), [average_profile, average_profile(1)], '-o', 'LineWidth', 2.5, 'Color', [0 .7 .7], 'MarkerFaceColor', 'r');
% 
% % Set the axis labels
% ax = gca;
% ax.ThetaTick = linspace(0, 360, length(columns)+1);
% ax.ThetaTickLabels = [labels, labels(1)];
% 
% % Set the title
% title('Basketball Profile');
% subtitle('[Average]');
% 
% % Enable grid and set the limits
% ax.RGrid = 'on';
% ax.RLim = [0 1]; % since the data is normalized
% 
% 
% % Save the figure if needed
% % 
% % saveas(gcf, [outpath, 'Average_Basketball_Profile.jpg']); % Save the figure as a PNG image
% % saveas(gcf, [outpath, '\\group_analysis\\','Average_Basketball_Profile.jpg']); % Save the figure as a PNG image


%% Subplot all participants

numParticipants = length(files);
numSubplots = numParticipants+1; % One for each participant, plus one for the average
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


for sub = 1:numParticipants

    % Determine which figure and subplot index to use
    figureIndex = ceil(sub / numSubplotsPerFigure);
    subplotIndex = sub - (figureIndex - 1) * numSubplotsPerFigure;

    % Make the correct figure current
    currentFigure = figures{figureIndex};
    figure(currentFigure); % Correctly set the current figure for plotting


    participant = extractBefore(files(sub).name, '.xdf');
    out_subfold = [outpath, participant, '\\'];

    participant_data = normalized_data(sub, :);

    % Create subplot for this participant
    subplot(4, 4, subplotIndex);

    % Create the radar plot
    h = polarplot(linspace(0, 2*pi, length(columns)+1), [participant_data{1,:}, participant_data{1,1}], '-o', 'LineWidth', 1.5, 'Color', colors(sub,:), 'MarkerFaceColor', 'k');

    % Set the axis labels
    ax = gca;
    ax.ThetaTick = linspace(0, 360, length(columns)+1);
    ax.ThetaTickLabels = [labels, labels(1)];

    % Set the title
    title(['Sub. [', num2str(sub), ']'], 'FontSize', 12);

    % Enable grid and set the limits
    ax.RGrid = 'on';
    ax.RLim = [0 1]; % since the data is normalized



    if sub==length(files)

        % Create subplot for average
        subplot(4, 4, subplotIndex+1);

        % Calculate the mean across participants for each attribute
        average_profile = mean(normalized_data{:, :});

        % Create the radar plot for the average profile
        h = polarplot(linspace(0, 2*pi, length(columns)+1), [average_profile, average_profile(1)], '-o', 'LineWidth', 2.5, 'Color', [0 .7 .7], 'MarkerFaceColor', 'r');

        % Set the axis labels
        ax = gca;
        ax.ThetaTick = linspace(0, 360, length(columns)+1);
        ax.ThetaTickLabels = [labels, labels(1)];

        % Set the title
        title('Average', 'FontSize', 12);

        % Enable grid and set the limits
        ax.RGrid = 'on';
        ax.RLim = [0 1]; % since the data is normalized

    end


    % Adjust subplot spacing if needed
    sgtitle('Basketball Profile of Participants'); % Super title

end

%% Save figures

for f = 1:numFigures
    % Ensure you're making each figure current before saving
    figure(figures{f});
    saveas(figures{f}, [outpath, '\\group_analysis\\', 'Basketball_profiles', '_', num2str(f), '.jpg']);

end

%%