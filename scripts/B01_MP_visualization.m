clc, clear, close all;

%% Human pose visualization

% This code visualizes the numan pose dynamically for each participant with
% the aim of identify and corraborate detected false onsets

% Miguel Contreras-Altamirano, 2025


%% MediaPipe - Pose Landmark Detection (PLD)

% MediaPipe timestamps are in units of microseconds. However, the LSD send
% the data in seconds.

% Units:
% x and y : Landmark coordinates normalized between 0.0 and 1.0 by
% the image width ( x ) and height ( y ).
% z : The landmark depth, with the depth at the midpoint of the hips as
% the origin. The smaller the value, the closer the landmark is to the
% camera. The magnitude of z uses roughly the same scale as x .

% The pose landmarker model tracks 33 body landmark locations, representing
% the approximate location of body parts. The data is arranged by 99 rows,
% representing x,y and z coordinates of each body part in secuencial order,
% the columns represent the time series.

% The coordinate system is oriented with the positive Y-axis pointing
% downwards.

% Body points:
% 0 - nose
% 1 - left eye (inner)
% 2 - left eye
% 3 - left eye (outer)
% 4 - right eye (inner)
% 5 - right eye
% 6 - right eye (outer)
% 7 - left ear
% 8 - right ear
% 9 - mouth (left)
% 10 - mouth (right)
% 11 - left shoulder
% 12 - right shoulder
% 13 - left elbow
% 14 - right elbow
% 15 - left wrist
% 16 - right wrist
% 17 - left pinky
% 18 - right pinky
% 19 - left index
% 20 - right index
% 21 - left thumb
% 22 - right thumb
% 23 - left hip
% 24 - right hip
% 25 - left knee
% 26 - right knee
% 27 - left ankle
% 28 - right ankle
% 29 - left heel
% 30 - right heel
% 31 - left foot index
% 32 - right foot index

% Miguel Contreras-Altamirano, 2023


%% Loading xdf files

mainpath = 'C:\Users\micua\Desktop\eeglab2023.0\'; % eeglab folder
path = 'C:\Users\micua\OneDrive - Benemérita Universidad Autónoma de Puebla\NCP_Basketball\MediaPipe\';
outpath = 'C:\\Users\\micua\\OneDrive - Benemérita Universidad Autónoma de Puebla\\Oldenburg_University\\Thesis\\data_hoops\\';
files = dir( fullfile( path,'\*.xdf')); % listing data sets


%% Selecting participant

sub = input('Which participant do you want to check?: ');
participant = extractBefore(files(sub).name, '.xdf');
out_subfold = [outpath, participant, '\\'];
data = load_xdf([path, files(sub).name]); % Saving the data in a variable
load([out_subfold, 'events_', participant,'.mat']); % Loading events file


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
end

% Assigning variables 

timeseries_mp = data{1, mp}.time_series; % MP time-series
timeseries_eeg = data{1, eeg}.time_series; % EEG time-series

timestamps_mp = data{1, mp}.time_stamps;  % MP timestamps
timestamps_eeg = data{1, eeg} .time_stamps; % EEG timestamps


% Inspecting data characteristics

% EEG sampling rate
srate_eeg = 1 / mean(diff(timestamps_eeg)); % calculates differences between adjacent elements of X and takes the mean divided by 1.
timestamp_range_eeg = range(timestamps_eeg); %  returns the difference between the maximum and minimum values of sample data in X.
disp(['Sampling rate EEG: ', num2str(srate_eeg)]);

% Length of the recording 
length_minutes_eeg = timestamp_range_eeg / 60; % in minutes
duration_seconds_eeg = str2double(data{1, eeg}.info.last_timestamp) - str2double(data{1, eeg}.info.first_timestamp);  % in seconds

% Double check based on data info (more accurate)
sampling_rate_eeg = str2double(data{1, eeg}.info.sample_count) / duration_seconds_eeg; % in seconds


% PLD sampling rate
srate_mp = 1 / mean(diff(timestamps_mp)); % calculates differences between adjacent elements of X and takes the mean divided by 1.
timestamp_range_mp = range(timestamps_mp); %  returns the difference between the maximum and minimum values of sample data in X.
disp(['Sampling rate PLD: ', num2str(srate_mp)]);

% Length of the recording
length_minutes_mp = timestamp_range_mp / 60; % in minutes
duration_seconds_mp = str2double(data{1, mp}.info.last_timestamp) - str2double(data{1, mp}.info.first_timestamp); %  in seconds

% Double check based on data info (more accurate)
sampling_rate_mp = str2double(data{1, mp}.info.sample_count) / duration_seconds_mp; % in seconds


% Display the results
disp(['Sampling rate EEG: ', num2str(sampling_rate_eeg), ' samples per second']);
disp(['Sampling rate PLD: ', num2str(sampling_rate_mp), ' samples per second']);
disp(['PLD recording: ', num2str(length_minutes_mp), ' minutes']);
disp(['EEG recording: ', num2str(length_minutes_eeg), ' minutes']);


%% Pose Landmark Detection (PLD) visualization

% Determine the number of frames and landmarks
numFrames = size(timeseries_mp, 2); % Number of frames
numLandmarks = size(timeseries_mp, 1) / 3; % Number of landmarks (33 according to MediaPipe)

% Initialize the figure and set axis limits based on the data
figure;

landmarkLabels = {
    'nose', 'left eye (inner)', 'left eye', 'left eye (outer)', 'right eye (inner)',...
    'right eye', 'right eye (outer)', 'left ear', 'right ear', ...
    'mouth (left)', 'mouth (right)', 'left shoulder', 'right shoulder', 'left elbow',...
    'right elbow', 'left wrist', 'right wrist', 'left pinky', 'right pinky', ...
    'left index', 'right index', 'left thumb', 'right thumb', 'left hip', 'right hip',...
    'left knee', 'right knee', 'left ankle', 'right ankle', ...
    'left heel', 'right heel', 'left foot index', 'right foot index'
    };

% Define colors for each body point
pointColors = lines(numLandmarks);

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


% Loop through the frames to create the animation
for i = 10000: numFrames
    
    landmarks = timeseries_mp(:, i);

    % Split the data into X, Y, and Z coordinates for each landmark
    x_coords = landmarks(1:3:end);
    y_coords = landmarks(2:3:end);
    z_coords = landmarks(3:3:end);

    % Create a 3D plot of the landmarks for each body part with unique colors
    scatter3(x_coords, y_coords, z_coords, 30, pointColors, 'filled');

    % Customize the plot appearance (e.g., title, labels, etc.)
    title('Pose Landmark Detection');
    subtitle(['Frame: ', num2str(i), ' at ', num2str(timestamps_mp(i)), ' [s]']);
    xlabel('X-coordinate');
    ylabel('Y-coordinate');
    zlabel('Z-coordinate');

    % Set axis limits for consistent scaling
    axis equal;

    % View with the desired orientation
    view(0, -90); %view(3) %for 3D

    % Connect body parts within clusters with lines
    for b_part = 1:length(clusters)
        cluster_points = clusters{b_part};
        for foton = 1:(length(cluster_points) - 1)
            idx1 = cluster_points(foton);
            idx2 = cluster_points(foton + 1);
            line([x_coords(idx1), x_coords(idx2)],...
                [y_coords(idx1), y_coords(idx2)],...
                [z_coords(idx1), z_coords(idx2)], 'Color', pointColors(idx1, :));
        end
    end

    % Add labels for right eye and wrist
    for foton = [6, 17] % Indices for right eye and right wrist (0 in nose, therefore the order changes)
        text(x_coords(foton), y_coords(foton), z_coords(foton), landmarkLabels{foton},...
            'Color', pointColors(foton, :));
    end

    % Display the plot
    grid on;
    axis equal;

    % Pause briefly to create an animation effect (adjust the pause duration)
    pause(0.0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001); % Display it faster

    % Clear the current frame to update the plot
    clf;
end


