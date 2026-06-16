clc, clear, close all;

%% EEG preprocessing (Readiness Potential)

% This code processes EEG data. The artifact information obtained is
% retrieved and use as parameters to reject and clean up EEG data.
% Afterwards, the RP is calculated using only the pre-movement period (from
% -2.5 to 0 sec).

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

nochans = {'AccX','AccY','AccZ','GyroX','GyroY','GyroZ', ... % channels to be ignored
    'QuatW','QuatX','QuatY','QuatZ'};

conditions = {'hit_ACC', 'miss_ACC'};

from = -2.5;         % sec
to = 1.004;          % sec (.004 because of 250Hz sampling rate)


%% Selecting participant

for sub = 1 : 1%length(files)

    participant = extractBefore(files(sub).name, '.xdf');
    out_subfold = [outpath, participant, '\\'];
    load([out_subfold, 'events_all_', participant,'.mat']); % Loading events file
    load([outpath, 'Info_EEG.mat']); % Loading channels file


    %% EEG pre-proccesing

    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

    % Import prepared data
    EEG = pop_loadset('filename',['ica_', participant, '.set'],'filepath', out_subfold); % Loading set file
    eeglab redraw % Updating GUI


    HPF = 0.2;           % high paass filter
    LPF = 10;            % low paass filter


    % Pre-procces
    EEG = pop_eegfiltnew(EEG, 'locutoff', HPF); % High_pass
    EEG = pop_eegfiltnew(EEG, 'hicutoff', LPF); % Low_pass
    EEG = pop_epoch( EEG, conditions, [from  to], 'epochinfo', 'yes'); % Epoching
    EEG = pop_rmbase( EEG, [from*1000 (from*1000)+500] ,[]); % Baseline correction
    EEG = eeg_checkset(EEG);

    % ICA artefact rejection:
    % Bad components previosly calculated from pre-movement activity
    EEG = pop_subcomp( EEG, [T.Bad_components{sub}], 0); % Rejecting flag components
    EEG = eeg_checkset(EEG);

    % Bad trials rejection
    % Bad epochs previosly detected from pre-movement activity
    EEG = pop_rejepoch(EEG, [T.Bad_trials{sub}], 0); % Use the logical array to reject marked epochs
    EEG = eeg_checkset(EEG);

    % Interpolation
    if length(EEG.chanlocs) < 32
        EEG.chaninfo.removedchans(1:10) = []; % 1 to 10 are channels from accelerometer data
        EEG = pop_interp(EEG, [EEG.chaninfo.removedchans], 'spherical');
    end

    % Re-reference (TP9/10):
    id1 = find(strcmpi({EEG.chanlocs.labels}, 'TP9'));
    id2 = find(strcmpi({EEG.chanlocs.labels}, 'TP10'));
    EEG = pop_reref(EEG, [id1 id2]);
    % EEG = pop_reref( EEG, []); % or re-fer to common average


    % No condition
    EEG.setname = ['processed_hoop_', participant];
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG);
    eeglab redraw % Updating GUI
    EEG = pop_saveset( ALLEEG(2), 'filename', ['hoop_RP_', participant, '.set'],'filepath', out_subfold); % Saving file all
    total_good_trials {sub} = size(ALLEEG(2).data, 3);

    % Hit condition
    EEG = pop_selectevent( ALLEEG(2), 'type', conditions{1},'deleteevents','on','deleteepochs','on','invertepochs','off');
    EEG.setname = ['processed_hoop_hit_', participant];
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG);
    eeglab redraw % Updating GUI
    EEG = pop_saveset( ALLEEG(3), 'filename', ['hoop_hit_RP_', participant, '.set'],'filepath', out_subfold); % Saving file hit

    % Miss condition
    EEG = pop_selectevent( ALLEEG(2), 'type', conditions{2},'deleteevents','on','deleteepochs','on','invertepochs','off');
    EEG.setname = ['processed_hoop_miss_', participant];
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG);
    eeglab redraw % Updating GUI
    EEG = pop_saveset( ALLEEG(4), 'filename', ['hoop_miss_RP_', participant, '.set'],'filepath', out_subfold); % Saving file miss


    % Inspecting data sets per condition
    % ERP conditions
    idx1 = find(EEG.times == -2500); % Start of baseline
    idx2 = find(EEG.times == 0); % Start of movement according to accelerometer onset detection method

    ERP_hits = mean ( ALLEEG(3).data(:, idx1:idx2, :), 3);
    ERP_misses = mean ( ALLEEG(4).data(:, idx1:idx2, :), 3);

    figure('units','normalized','outerposition', [0 0 1 1]);
    subplot(2, 1, 1);
    timtopo(ERP_hits, EEG.chanlocs, 'limits', [-2500 0], 'plottimes',  [-2500 -2000 -1500 -1000 -800 -700 -600 -500 -400 -300 -200 -100 -40], 'title', 'Readines Potential [Hits]');
    subplot(2, 1, 2);
    timtopo(ERP_misses, EEG.chanlocs, 'limits', [-2500 0], 'plottimes',  [-2500 -2000 -1500 -1000 -800 -700 -600 -500 -400 -300 -200 -100 -40], 'title', 'Readines Potential [Misses]');
    % pop_timtopo( ALLEEG(4), [-2500 -500], [NaN], 'Readines Potential');
    sgtitle(['Sub. [', num2str(sub), ']'], 'Color',"#A2142F", 'Fontweight', 'bold'); % Super title

    saveas(gcf, [out_subfold, 'ERPs_comparison_RP_', participant, '.jpg']); % Save the figure as a PNG image
    % saveas(gcf, [outpath, '\\group_analysis\\','ERPs_comparison_RP_', participant, '.jpg']); % Save the figure as a PNG image


    disp([participant, ' finalized!']);
    disp(['Good trials: ', num2str(total_good_trials {sub})]);


end


T.Num_good_trials = total_good_trials';

% Save it in .mat file
save([outpath, 'Info_EEG.mat'],'T', 'total_good_trials');


%%
