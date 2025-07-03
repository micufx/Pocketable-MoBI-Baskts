clc, clear, close all;

%% EEG data preparation

% This code prepares EEG data for preprocessing.Removes bad channels and
% applies ICA decomposition.

% Miguel Contreras-Altamirano, 2025

%% EEG data preparation

mainpath = 'C:\Users\micua\Desktop\eeglab2023.0\'; % eeglab folder
path = 'C:\Users\micua\OneDrive - Benemérita Universidad Autónoma de Puebla\NCP_Basketball\MediaPipe\'; % raw data
outpath = 'C:\\Users\\micua\\OneDrive - Benemérita Universidad Autónoma de Puebla\\Oldenburg_University\\Thesis\\data_hoops\\';
files = dir( fullfile( path,'\*.xdf')); % listing data sets

nochans = {'AccX','AccY','AccZ','GyroX','GyroY','GyroZ', ... % channels to be ignored
    'QuatW','QuatX','QuatY','QuatZ'};

conditions = {'hit_ACC', 'miss_ACC'};

HPF = 2;             % high paass filter
LPF = 30;            % low paass filter
thresh = 5;          % standard deviation threshold
from = -2.5;         % sec
to = 0;              % sec (from -500ms to -200ms would be the real onset based on wrist acceleration)

ID = [];             % participant ID
badchans = [];       % bad channels
No_bad_chans = [];   % number of bad channels


%% Selecting participant

for sub = 1 : length(files)

    participant = extractBefore(files(sub).name, '.xdf');
    out_subfold = [outpath, participant, '\\'];
    load([out_subfold, 'events_all_', participant,'.mat']); % Loading events file

    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % Open eeglab

    % Import, channel locs, events, reref
    EEG = pop_loadxdf([path, files(sub).name], 'streamtype', 'EEG', 'exclude_markerstreams', {}); % Loading xdf file
    EEG = pop_chanedit(EEG, 'lookup',[mainpath, 'plugins/dipfit/standard_BEM/elec/standard_1005.elc']); % Channel info
    EEG.event = all_events; % Add events to EEG structure
    EEG = eeg_checkset(EEG, 'eventconsistency'); % Event consistency
    EEG = pop_select(EEG, 'nochannel', nochans); % Select relevant channels
    eeglab redraw % Updating GUI
    % EEG = pop_saveset( EEG, 'filename', [participant, '.set'],'filepath', out_subfold); % Saving light file


    %% ICA Based Artefact Attenuation

    nchan_ori = EEG.nbchan; % original number of channels

    % Channel artefacts topography
    %EEG = pop_rejchan(EEG);                 % Bad chans detection;
    rms = std(EEG.data');                    % Standard deviation across channels to identify bad ones
    thres = mean(rms) + 1*std(rms);          % Define threshold for bad channel marking
    ind = find(rms > thres);

    % RMS over time (image plot) for each subject
    sec = 30;
    LeWin = EEG.srate*sec;                                                                  % define window length
    timeVec = 0 : 1/EEG.srate : sec-1/EEG.srate;                                            % define time vector
    idx_loop = 1:LeWin:size(EEG.data,2);                                                    % check how loop index will look like
    rms_t = zeros(EEG.nbchan, length(idx_loop));                                            % pre-allocate matrix of rms over time
    row_count = 1;                                                                          % set counter

    for idx = 1: LeWin: size(EEG.data,2)-LeWin

        signal = EEG.data(:,idx:idx+(LeWin-1));                                             % get short extract from data
        rms_t(:, row_count) = std(signal, [],2);                                            % calc standard deviation across channels
        row_count = row_count +1;                                                           % update counter

    end


    % Set up the figure with a larger size
    fig_bad_chan = figure('units','normalized','outerposition', [0 0 1 1]); % fig = figure('Units', 'pixels', 'Renderer', 'painters'); [100, 100, 800, 600]

    subtightplot(2, 2, [1, 3]);
    topoplot(rms, EEG.chanlocs, 'electrodes', 'numpoint', 'chaninfo', EEG.chaninfo, 'whitebk', 'on', 'shading', 'interp');

    subplot(2, 2, 4);
    plot(rms, 'k', 'LineWidth', 1);    % plot lines of channel stds with threshold
    hold on;
    plot(repmat(thres, 1, 32), 'r', 'LineStyle','--', 'LineWidth', 2);
    title(['Outliers: ', mat2str(ind)], 'Interpreter', 'none');
    subtitle('Threshold: [Mean RMS + 1 SD)]');
    xlabel('Electrodes');
    ylabel('RMS');
    grid on;
    axis tight;

    ax1 = subplot(2, 2, 2);                                                                 % create colormap for channel stds over time
    imagesc(rms_t);
    colorbar;
    colormap(ax1, turbo);
    xlabel('Time [sec]');
    ylabel('Electrodes');
    title('Root Mean Square [RMS]');
    subtitle(['Windows of ', num2str(sec), ' [sec]']);

    % rms_ti = rms_t > thres;                                                                 % color code if value is > thresh or not
    % ax2 = subplot(1, 1, 1);
    % imagesc(rms_ti);
    % colorbar;
    % colormap(ax2, turbo);
    % xlabel(['Time [', num2str(sec), 's windows]']);
    % ylabel('Channels');
    % title(['Threshold: ', num2str(thres)], 'Interpret', 'none');

    sgt = sgtitle(['Electrode artefacts: [', participant, ']'], 'Interpreter', 'none'); % title for whole plot

    % Selecting bad channels
    EEG.badchans = ind; % input('Enter bad channel numbers here :');
    EEG.badchans = sort(EEG.badchans);
    no_bad_chans = length(EEG.badchans);

    if ~isempty(EEG.badchans)
        EEG = pop_select(EEG, 'rmchannel', EEG.badchans);
    end

    disp(['Original number of channels: ', num2str(nchan_ori), '. Number of bad channels: ', ...    % inform about new number of channels
        num2str(length(EEG.badchans)), '.'])


    if ~isempty(EEG.badchans)                                                  % if bad channels are marked
        bad_chans{sub} = EEG.badchans;                                         % save them in EEG.badchans
        disp('Saved bad channels in cell array.')
    else
        disp('No bad channels, nothing to save.')                              % otherwise inform about this
    end

    % Preprocces for ICA: filt, bad chans, epoch, rej, ica

    % Filter for ICA only
    EEG_ica = pop_eegfiltnew(EEG, 'locutoff', HPF); % High_pass
    EEG_ica = pop_eegfiltnew(EEG_ica, 'hicutoff', LPF); % Low_pass

    % Epoch for ICA
    EEG_ica = pop_epoch(EEG_ica, conditions, [from to], ...
        'newname', 'all-ica epochs', 'epochinfo', 'yes');
    %EEG_ica = eeg_regepochs(EEG_ica); % 1 sec consecutive epochs
    EEG_ica = pop_jointprob(EEG_ica, 1, [1:EEG.nbchan] , thresh, thresh, 0, 1, 0, [], 0); % Artefact rejection by sd
    EEG_ica = pop_runica(EEG_ica, 'icatype', 'runica', 'extended',1,'interrupt','on');

    % Storing weights into original EEG data set
    EEG.icaact = EEG_ica.icaact;
    EEG.icawinv = EEG_ica.icawinv;
    EEG.icasphere = EEG_ica.icasphere;
    EEG.icaweights = EEG_ica.icaweights;
    EEG.icachansind = EEG_ica.icachansind;
    EEG.setname = [EEG.setname, '_ica']; % Set 1
    clear EEG_ica;
    eeglab redraw % Updating GUI

    ID{sub} = participant; % Assigning ID's
    No_bad_chans{sub} = no_bad_chans; 

    
    % Saving file
    EEG = pop_saveset( EEG, 'filename', ['ica_', participant, '.set'],'filepath', out_subfold);


    % Save the figure as a PNG image
    saveas(fig_bad_chan, [out_subfold, 'Bad_chan_', participant, '.jpg']);
    % saveas(fig_bad_chan, [outpath, '\\group_analysis\\','Bad_chan_', participant, '.jpg']); % Save the figure as a PNG image

    
    disp([participant, ' finalized!']);
    
    
end


%% Table info.

% write actual tables
T = table(ID', bad_chans', No_bad_chans');
T.Properties.VariableNames = {'Subject_ID', 'Bad_channels', 'Num_Bad_channels'};


% Save it in .mat file
save([outpath, 'Info_EEG.mat'],'T', 'ID', 'bad_chans', 'No_bad_chans');



%% RMS description

% In EEG preprocessing, rms_t typically represents the Root Mean Square
% (RMS) values calculated over time. This gives you an idea of the
% variability or the power of the signal within each time window for each
% channel. When you create an image (via imagesc in MATLAB) of the rms_t
% values, you can visually inspect the channels across time and identify
% any that consistently show higher or lower values, which might suggest
% noise or artifacts.

% The rms_ti, on the other hand, is a logical array that results from
% applying a threshold to rms_t. It's essentially a binary mask where
% values above the threshold are marked (often with 1) and values below the
% threshold are not marked (with 0). When you create an image of rms_ti, it
% should ideally highlight the windows of time where a channel's signal
% exceeds the normal range, indicating potential bad channels or artifacts.
% If the entire rms_ti array is zero, it suggests that no values exceeded
% the threshold; this could mean that the threshold is set too high or that
% the data is exceptionally clean (which is less likely in raw EEG data).

% rms_t is calculated over 30-second windows of the full dataset, so rms_ti
% would identify bad channels for those specific windows throughout the
% recording.







