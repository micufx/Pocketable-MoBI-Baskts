clc; clear; close all;

%% Convert source data to BIDS

% This code transforms the existing raw data sets into BIDS format.

% Miguel Contreras-Altamirano, 2025


%% Settings
% Get the full path of the current script
scriptPath = fileparts(mfilename('fullpath'));
proj_dir = fullfile(scriptPath, '..');
proj_dir = char(java.io.File(proj_dir).getCanonicalPath); % Convert to canonical absolute path

% Change to the parent directory of the script
cd(fullfile(proj_dir));

%% Load required paths and libraries
addpath(fullfile('.', dir('*eeglab*').name)); % eeglab folder
addpath(fullfile('.', dir('*fieldtrip*').name)); % add Fieldtrip
addpath(fullfile('.', 'utils')); % add utility functions
dir_data = fullfile('.','data'); % raw data path
dir_chanslocs = fullfile(proj_dir, dir('*eeglab*').name, 'plugins', dir('*eeglab*\plugins\*dipfit*').name, '/standard_BEM/elec/standard_1005.elc');
files = dir(fullfile(dir_data, 'raw\*.xdf')); % listing datasets

ft_defaults; % Fieldtrip defaults
% some about the version

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % Open eeglab

%% Set general BIDS conversion configuration

cfg = [];
cfg.InstitutionName = 'University of Oldenburg';
cfg.dataset_description.Name = 'EEG_Basketball';
cfg.dataset_description.BIDSVersion = '1.9';
cfg.method = 'convert'; % The original data is in a BIDS-compliant format and can be copied
cfg.bidsroot = './data/bids';  % write to the present working directory

%% Loop over datasets

for sub = 1: 1%length(files)

    participant = extractBefore(files(sub).name, '.xdf');  % get subject name
    data = load_xdf(fullfile(dir_data,'raw', files(sub).name)); % Saving the data in a variable
    load((fullfile(dir_data,'raw', ['events_all_', participant,'.mat']))); % Loading events file


    %% Extract EEG and motion data from XDF file
    for i = 1: length(data)

        currentName = data{1, i}.info.name;
        
         % Check if the current data is MP
        if contains(currentName, 'Pose', 'IgnoreCase', true)
            mp = data{1, i}; % Pose (motion) data
        end

        % Check if the current data is ACC
        if strcmp(currentName, 'Movella DOT B1')
            acc = data{1, i};
        end

        % Check if the current data is ACC
        if strcmp(currentName, 'Movella DOT B2')
            acc = data{1, i};
        end

        % Check if the current data is ACC
        if strcmp(currentName, 'Movella DOT B3')
            acc = data{1, i};
        end

        % Check if the current data is ACC
        if strcmp(currentName, 'Movella DOT B4')
            acc = data{1, i};
        end

        % Check if the current data is ACC
        if strcmp(currentName, 'Movella DOT B5')
            acc = data{1, i};
        end

    end

    %% Modality agnostic info

    % Generate dataset_description.json
    cfg.dataset_description.Name = 'Readiness Potential in Basketball';
    cfg.dataset_description.BIDSVersion = '1.9';
    cfg.dataset_description.Authors = {'Miguel Contreras-Altamirano', 'Stefan Debener'};
    cfg.dataset_description.License = 'Creative Commons';
    cfg.dataset_description.DatasetType = 'raw';

    %% EEG Data Conversion

    % Import EEG, add channel locations, and add events
    EEG = pop_loadxdf(fullfile(dir_data,'raw', files(sub).name), 'streamtype', 'EEG', 'exclude_markerstreams', {});
    EEG = pop_chanedit(EEG, 'lookup', dir_chanslocs); % Add channel info
    EEG.event = all_events; % Add events
    EEG = eeg_checkset(EEG, 'eventconsistency'); % Check event consistency

    % Channel labels and electrode info
    eeg_channel_labels = {EEG.chanlocs.labels};
    elec_file = dir_chanslocs;
    elec = ft_read_sens(elec_file); % Load electrode file
    cfg.elec = elec;
    
    % Define Fieldtrip EEG structure (eeglab2fieldtrip)
    data_eeg = eeglab2fieldtrip( EEG, 'raw', 'none');

    % BIDS-specific settings for EEG
    cfg.sub = extractAfter(participant, 'sub_');
    cfg.datatype = 'eeg';
    ft_checkdata(data_eeg);
    cfg.task = 'Freethrow';

    cfg.eeg.PowerLineFrequency = 50; % Power line frequency (50Hz for EU)
    cfg.eeg.EEGReference = 'TP9 TP10';  % Reference electrodes
    cfg.eeg.InstitutionName = 'University of Oldenburg';
    cfg.eeg.InstitutionAddress = 'Ammerlaender Heerstr. 114-118, 26129 Oldenburg, Germany';
    cfg.eeg.ManufacturersModelName = 'mbraintrain';
    cfg.eeg.SoftwareFilters = "n/a";

    % specify coordsys
    cfg.coordsystem.EEGCoordinateSystem = "CTF";
    cfg.coordsystem.EEGCoordinateUnits = "mm";
    

    % Generate README file
    README = sprintf('The experiment included 26 participants. \n- Miguel Contreras-Altamirano (February, 2025)');

    % Call data2bids for EEG
    data2bids(cfg, data_eeg);


    %% Motion Data (MediaPipe) Conversion

    % Prepare motion data structure
    mocap.trial{1} = [mp.time_series];
    mocap.time{1} = mp.time_stamps;
    mocap.label = {
        'nose_X', 'nose_Y', 'nose_Z', ...
        'left eye (inner)_X', 'left eye (inner)_Y', 'left eye (inner)_Z', ...
        'left eye_X', 'left eye_Y', 'left eye_Z', ...
        'left eye (outer)_X', 'left eye (outer)_Y', 'left eye (outer)_Z', ...
        'right eye (inner)_X', 'right eye (inner)_Y', 'right eye (inner)_Z', ...
        'right eye_X', 'right eye_Y', 'right eye_Z', ...
        'right eye (outer)_X', 'right eye (outer)_Y', 'right eye (outer)_Z', ...
        'left ear_X', 'left ear_Y', 'left ear_Z', ...
        'right ear_X', 'right ear_Y', 'right ear_Z', ...
        'mouth (left)_X', 'mouth (left)_Y', 'mouth (left)_Z', ...
        'mouth (right)_X', 'mouth (right)_Y', 'mouth (right)_Z', ...
        'left shoulder_X', 'left shoulder_Y', 'left shoulder_Z', ...
        'right shoulder_X', 'right shoulder_Y', 'right shoulder_Z', ...
        'left elbow_X', 'left elbow_Y', 'left elbow_Z', ...
        'right elbow_X', 'right elbow_Y', 'right elbow_Z', ...
        'left wrist_X', 'left wrist_Y', 'left wrist_Z', ...
        'right wrist_X', 'right wrist_Y', 'right wrist_Z', ...
        'left pinky_X', 'left pinky_Y', 'left pinky_Z', ...
        'right pinky_X', 'right pinky_Y', 'right pinky_Z', ...
        'left index_X', 'left index_Y', 'left index_Z', ...
        'right index_X', 'right index_Y', 'right index_Z', ...
        'left thumb_X', 'left thumb_Y', 'left thumb_Z', ...
        'right thumb_X', 'right thumb_Y', 'right thumb_Z', ...
        'left hip_X', 'left hip_Y', 'left hip_Z', ...
        'right hip_X', 'right hip_Y', 'right hip_Z', ...
        'left knee_X', 'left knee_Y', 'left knee_Z', ...
        'right knee_X', 'right knee_Y', 'right knee_Z', ...
        'left ankle_X', 'left ankle_Y', 'left ankle_Z', ...
        'right ankle_X', 'right ankle_Y', 'right ankle_Z', ...
        'left heel_X', 'left heel_Y', 'left heel_Z', ...
        'right heel_X', 'right heel_Y', 'right heel_Z', ...
        'left foot index_X', 'left foot index_Y', 'left foot index_Z', ...
        'right foot index_X', 'right foot index_Y', 'right foot index_Z'
        };

    % BIDS motion data settings
    cfg = [];
    cfg.sub = extractAfter(participant, 'sub_');
    cfg.datatype = 'motion';
    cfg.task = 'Freethrow';
    cfg.bidsroot = './data/bids';
    cfg.tracksys = 'MediaPipe';
    cfg.motion.TrackingSystemName = 'MediaPipe';
    cfg.motion.samplingrate = sampling_rate_mp;

    % specify channel details, this overrides the details in the original data structure
    cfg.channels = [];
    cfg.channels.name = mocap.label;
    cfg.channels.component = cellstr(repmat({'x','y','z'},1, length(mocap.label)/3));
    cfg.channels.type = cellstr(repmat('POS',length(mocap.label),1));
    cfg.channels.tracked_point = mocap.label;
    cfg.channels.units = cellstr(repmat('m',length(mocap.label),1));

    mocap = ft_datatype_raw(mocap);

    data2bids(cfg, mocap);


    %% Accelerometer Data Conversion

    % Prepare motion data structure
    mocap.trial{1} = [acc.time_series];
    mocap.time{1} = acc.time_stamps;
    mocap.label = {
        'acc_hand_X', 'acc_hand_Y', 'acc_hand_Z', ...
        'gyro_hand_X', 'gyro_hand_Y', 'gyro_hand_Z', ...
        };

    % BIDS motion data settings
    cfg = [];
    cfg.sub = extractAfter(participant, 'sub_');
    cfg.datatype = 'motion';
    cfg.task = 'Freethrow';
    cfg.bidsroot = './data/bids';
    cfg.tracksys = 'Movella DOT';
    cfg.motion.TrackingSystemName = 'Movella DOT';
    cfg.motion.samplingrate = sampling_rate_acc;

    % specify channel details, this overrides the details in the original data structure
    cfg.channels = [];
    cfg.channels.name = mocap.label;
    cfg.channels.component = cellstr(repmat({'acc_x','acc_y','acc_z', 'gyro_x','gyro_y','gyro_z'},1, length(mocap.label)/3));
    cfg.channels.type = cellstr(repmat({'ACCEL''GYRO'},length(mocap.label),1));
    cfg.channels.tracked_point = mocap.label;
    cfg.channels.units = cellstr(repmat('m s−2',length(mocap.label),1));

    mocap = ft_datatype_raw(mocap);

    data2bids(cfg, mocap);

end

