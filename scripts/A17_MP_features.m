clc, clear, close all;

%% Feature extraction of the human pose

% This code extract important features of the human pose (X, Y and Z 
% coordinates) per conditions. 

% Miguel Contreras-Altamirano, 2025

%% EEG data loading

mainpath = 'C:\Users\micua\Desktop\eeglab2023.0\'; % eeglab folder
path = 'C:\Users\micua\OneDrive - Benemérita Universidad Autónoma de Puebla\NCP_Basketball\MediaPipe\';
outpath = 'C:\\Users\\micua\\OneDrive - Benemérita Universidad Autónoma de Puebla\\Oldenburg_University\\Thesis\\data_hoops\\';
files = dir(fullfile(path, '\*.xdf')); % listing data sets

num_conditions = 2; % (Conditions: 1=hit 2=miss)

% Define an array of landmark times to loop through
Landmarks = [-2.5 : 0.1 : 1];  % Time of landmarks to analyze (in seconds)

% Multiply by 1000 to convert to milliseconds, and round to avoid precision issues
Landmarks = round(Landmarks * 1000) / 1000;


%% Loop through each participant and landmark time

for sub = 1:length(files)

    participant = extractBefore(files(sub).name, '.xdf');
    out_subfold = [outpath, participant, '\\'];

    % Loop through each landmark time
    for lm_idx = 1:length(Landmarks)

        Landmark = Landmarks(lm_idx); % Current landmark time

        for cond = 1:num_conditions

            % Loading desired data
            if cond == 1 % 'hit'
                % Load .mat file
                load([out_subfold, 'hoop_motion_hit_', participant, '.mat']);

            elseif cond == 2 % 'miss'
                % Load .mat file
                load([out_subfold, 'hoop_motion_miss_', participant, '.mat']);

            elseif cond == 3  % 'none'
                % Load .mat file
                load([out_subfold, 'hoop_motion_', participant, '.mat']);
            end

            % Initialize the table with appropriate variable names
            varNames = {};
            bodyParts = {'Nose', 'Left-Eye-Inner', 'Left-Eye', 'Left-Eye-Outer', 'Right-Eye-Inner', ...
                'Right-Eye', 'Right-Eye-Outer', 'Left-Ear', 'Right-Ear', 'Mouth-Left', ...
                'Mouth-Right', 'Left-Shoulder', 'Right-Shoulder', 'Left-Elbow', 'Right-Elbow', ...
                'Left-Wrist', 'Right-Wrist', 'Left-Pinky', 'Right-Pinky', 'Left-Index', ...
                'Right-Index', 'Left-Thumb', 'Right-Thumb', 'Left-Hip', 'Right-Hip', ...
                'Left-Knee', 'Right-Knee', 'Left-Ankle', 'Right-Ankle', 'Left-Heel', ...
                'Right-Heel', 'Left-Foot-Index', 'Right-Foot-Index'};

            % Generate variable names for the table
            for i = 1:length(bodyParts)
                varNames{end+1} = ['X-', bodyParts{i}];
                varNames{end+1} = ['Y-', bodyParts{i}];
                varNames{end+1} = ['Z-', bodyParts{i}];
            end

            % Prepare an empty matrix to hold the feature data
            numTrials = length(landmarksPerTrial);
            featureData = zeros(numTrials, length(varNames));

            % Select the frame index you are interested in
            frameIndex = find(timestamps_mp == Landmark * 1000);

            % Populate the feature data from landmarksPerTrial
            for trialIdx = 1:numTrials
                % Extract the specific frame data from the current trial's landmark data
                landmarkData = landmarksPerTrial{trialIdx}; % Get the data for the current trial
                selectedFrameData = landmarkData(:, frameIndex); % Select the frame

                % Now reshape the data to be 3 (XYZ) x 33 (body parts)
                reshapedData = reshape(selectedFrameData, [3, 33])';

                % Flatten the reshaped data to be a single row
                featureData(trialIdx, :) = reshapedData(:)';
            end

            % Create the feature table for hit or miss
            if cond == 1  % 'hit'
                featuresPLD_hit = array2table(featureData, 'VariableNames', varNames);

            elseif cond == 2  % 'miss'
                featuresPLD_miss = array2table(featureData, 'VariableNames', varNames);
            end

            % Create condition and label arrays
            if cond == 1  % 'hit'
                shot_cond = ones(1, size(featuresPLD_hit, 1))'; % 1 for 'hit'
                shot_labels = repmat({'hit'}, size(featuresPLD_hit, 1), 1);

            elseif cond == 2  % 'miss'
                shot_cond = zeros(1, size(featuresPLD_miss, 1))'; % 0 for 'miss'
                shot_labels = repmat({'miss'}, size(featuresPLD_miss, 1), 1);
            end

            if cond == 1  % 'hit'
                featuresPLD_hit.Condition = shot_cond;
                featuresPLD_hit.Label = shot_labels;

            elseif cond == 2  % 'miss'
                featuresPLD_miss.Condition = shot_cond;
                featuresPLD_miss.Label = shot_labels;
            end
        end

        % Now concatenate hit and miss tables
        features_PLD = vertcat(featuresPLD_hit, featuresPLD_miss);

        % Assign trial numbers as row names
        trialNumbers = arrayfun(@(x) ['Trial_', num2str(x)], 1:size(features_PLD, 1), 'UniformOutput', false);
        features_PLD.Properties.RowNames = trialNumbers;

        % Save it in .mat file with the current landmark time in the name
        %save([out_subfold, participant, '_features_PLD_', num2str(Landmark * 1000), '_ms', '.mat'], 'features_PLD');

        %clear features_PLD
   
    end

        disp([participant, ' finalized!']);
end

%%
