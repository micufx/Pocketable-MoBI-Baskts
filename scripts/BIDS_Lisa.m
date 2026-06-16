%% Convert source data to BIDS
clc; clear; close all;

%% Dynamic paths

% Get the full path of the current script
scriptPath = fileparts(mfilename('fullpath'));
proj_dir = fullfile(scriptPath, '..');
proj_dir = char(java.io.File(proj_dir).getCanonicalPath); % Convert to canonical absolute path

% Change to the parent directory of the script
cd(fullfile(proj_dir));

%% Load required paths and libraries
addpath(fullfile(proj_dir, dir('*eeglab*').name)); % eeglab folder
addpath(fullfile(proj_dir, dir('*fieldtrip*').name)); % add Fieldtrip
addpath(fullfile(proj_dir, 'utils')); % add utility functions
dir_data = fullfile(proj_dir,'data','raw_lisa'); % raw data path
dir_chanslocs = fullfile(proj_dir, dir('*eeglab*').name, 'plugins', dir('*eeglab*\plugins\*dipfit*').name, '/standard_BEM/elec/standard_1005.elc');
files = dir(fullfile(dir_data, '*.set')); % listing datasets

ft_defaults; % Fieldtrip defaults
% some about the version

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % Open eeglab

%% Set general BIDS conversion configuration

cfg = [];
cfg.InstitutionName = 'University of Oldenburg';
cfg.dataset_description.Name = 'EEG_Walking';
cfg.dataset_description.BIDSVersion = '1.9';
cfg.method = 'convert'; % The original data is in a BIDS-compliant format and can be copied
cfg.bidsroot = './data/bids_lisa';  % write to the present working directory


conditions = {
    'DualSpeakerNoBackground_acq-Lab'...
    'DualSpeakerSit_acq-BTL',...
    'DualSpeakerWalk_acq-BTL',...
    'DualSpeakerWithBackground_acq-Lab'...
    'SingleSpeakerNoBackground_acq-Lab',...
    'SingleSpeakerSit_acq-BTL',...
    'SingleSpeakerWalk_acq-BTL',...
    'SingleSpeakerWithBackground_acq',...
    };


% Every participants contains this set files:

% DualSpeakerNoBackground_acq-Lab_run-01
% DualSpeakerNoBackground_acq-Lab_run-02
%
% DualSpeakerSit_acq-BTL_run-01
%
% DualSpeakerWalk_acq-BTL_run-01
%
% DualSpeakerWithBackground_acq-Lab_run-01
% DualSpeakerWithBackground_acq-Lab_run-02
%
% SingleSpeakerNoBackground_acq-Lab_run-01
% SingleSpeakerNoBackground_acq-Lab_run-02
%
% SingleSpeakerSit_acq-BTL_run-01
%
% SingleSpeakerWalk_acq-BTL_run-01
%
% SingleSpeakerWithBackground_acq-Lab_run-01
% SingleSpeakerWithBackground_acq-Lab_run-02


%% Loop over datasets

for sub = 1: length(files)

    participant = extractBefore(files(sub).name, '_ses');  % get subject name
    run = extractAfter(files(sub).name, 'run-');
    run = extractBefore(run, '_eeg.set');

    %% Modality agnostic info

    % Generate dataset_description.json
    cfg.dataset_description.Name = 'Lisa Project';
    cfg.dataset_description.BIDSVersion = '1.9';
    cfg.dataset_description.Authors = {'Lisa', 'Stefan Debener'};
    cfg.dataset_description.License = 'Creative Commons';
    cfg.dataset_description.DatasetType = 'raw';

    %% EEG Data Conversion

    for cond=1 : length(conditions)

        % Import EEG, add channel locations, and add events
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % Open eeglab
        EEG = pop_loadset('filename', [participant, '_ses-01_task-', conditions{cond}, '_run-', run, '_eeg.set'],'filepath', files(sub).folder); % Loading set file

        % Channel labels and electrode info
        eeg_channel_labels = {EEG.chanlocs.labels};
        elec_file = dir_chanslocs;
        elec = ft_read_sens(elec_file); % Load electrode file
        cfg.elec = elec;

        % Define Fieldtrip EEG structure (eeglab2fieldtrip)
        data_eeg = eeglab2fieldtrip( EEG, 'raw', 'none');

        % BIDS-specific settings for EEG
        cfg.sub = extractAfter(participant, 'sub-');
        cfg.datatype = 'eeg';
        ft_checkdata(data_eeg);
        cfg.task = conditions{cond};

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
        README = sprintf('The experiment included 27 participants. \n- Lisita (December, 2024)');

        % Call data2bids for EEG
        data2bids(cfg, data_eeg);

    end


end

