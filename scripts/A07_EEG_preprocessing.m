clc, clear, close all;

%% EEG artifact identification

% This code processes EEG data. First, ICA weights of the previous staps
% are merged with raw data and the preprocessing is applied to the the
% segment of data referred to basketball shot period (from -2.5 to 1 sec),
% only to save artifact information.

% Miguel Contreras-Altamirano, 2025

%% EEG pre-processing

mainpath = 'C:\Users\micua\Desktop\eeglab2023.0\'; % eeglab folder
path = 'C:\Users\micua\OneDrive - Benemérita Universidad Autónoma de Puebla\NCP_Basketball\MediaPipe\'; % raw data
outpath = 'C:\\Users\\micua\\OneDrive - Benemérita Universidad Autónoma de Puebla\\Oldenburg_University\\Thesis\\data_hoops\\';
files = dir( fullfile( path,'\*.xdf')); % listing data sets
vp_path = 'C:\Users\micua\Desktop\eeglab2023.0\plugins\ICLabel\viewprops'; % IC label needs the folder of the plugin

nochans = {'AccX','AccY','AccZ','GyroX','GyroY','GyroZ', ... % channels to be ignored
    'QuatW','QuatX','QuatY','QuatZ'};

conditions = {'hit_ACC', 'miss_ACC'};

HPF = 0.2;           % high paass filter
LPF = 10;            % low paass filter
thresh = 3;          % standard deviation
from = -2.5;         % sec
to = 0;            % sec (from -500ms to -200ms would be the real onset based on wrist acceleration)

bad_ICA = [];
IC_labels = [];
bad_trials = [];
total_bad_trials = [];


%% Selecting participant

for sub = 1 : 1%length(files)

    participant = extractBefore(files(sub).name, '.xdf');
    out_subfold = [outpath, participant, '\\'];
    load([outpath, 'Info_EEG.mat']); % Loading channels file


    %% Preparation for BP

    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

    % Import prepared data
    EEG = pop_loadset('filename',['ica_', participant, '.set'],'filepath', out_subfold); % Loading set file
    eeglab redraw % Updating GUI

    % Pre-procces
    %EEG = pop_reref(EEG, []); % Re-reference: TP9/10??? -- CAR
    EEG = pop_eegfiltnew(EEG, 'locutoff', HPF); % High_pass
    EEG = pop_eegfiltnew(EEG, 'hicutoff', LPF); % Low_pass
    EEG = pop_epoch( EEG, conditions, [from  to], 'epochinfo', 'yes'); % Epoching
    EEG = eeg_checkset(EEG);
    EEG = pop_rmbase(EEG, [from*1000 (from*1000)+500] ,[]); % Baseline correction (most of papers of BP have a BL of 200 to 500 ms)


    % ICA correction and final artefact rejection:
    %pop_topoplot(EEG, 0, [1:size(EEG.icawinv,2)] ,'all-ica',[6 6] ,0,'electrodes','on'); % Plotting_components

    % EEG.badcomps = input('Enter component(s) to be removed []: '); % Input to remove components
    % EEG = pop_subcomp( EEG, [EEG.badcomps], 0); % Rejecting manual selected components
    EEG = pop_iclabel(EEG, 'default');
    EEG = pop_icflag(EEG, [NaN NaN;0.30 1;0.30 1;0.90 1;0.90 1;0.30 1;0.30 1]); % Any component with at least num% confidence of being an artifact or less than num% confidence if its brain
    % Brain, Muscle, Eye, Heart, Line Noise, Channel Noise, and Other
    bad_compons = find(EEG.reject.gcompreject); % popviewprops()
    
    % IC label components
    %fig = figure('units','normalized','outerposition', [0 0 1 1]);
    pop_viewprops( EEG, 0, [1:size(EEG.icawinv,2)], 'freqrange', [2 80], 'ICLabel'); % Probably one has to open it manually the first time to get the plugin installed 
               %pop_viewprops( EEG, typecomp, chanorcomp, spec_opt, erp_opt, scroll_event, classifier_name, fig)
    
    saveas(gcf , [out_subfold, 'All_ICA_', participant, '.jpg']); % Saving components
    % saveas(gcf, [outpath, '\\group_analysis\\','All_ICA_', participant, '.jpg']); % Save the figure as a PNG image

    for compy = 1 : length(bad_compons)

        fig_IC = pop_prop_extended(EEG, 0, bad_compons(compy));

        [lab_max, idx_label] = max(EEG.etc.ic_classification.ICLabel.classifications(bad_compons(compy), :));
        label_comp(compy)  = {EEG.etc.ic_classification.ICLabel.classes{idx_label}};

        %Save the figure as a PNG image
        %saveas(fig_IC , [out_subfold, 'Bad_compon_', num2str(bad_compons(compy)), '_', label_comp{compy}, '_', participant, '.png']);
        % saveas(fig_IC , [outpath, '\\group_analysis\\', 'Bad_compon_', num2str(bad_compons(compy)), '_', label_comp{compy}, '_', participant, '.png']); % Save the figure as a PNG image
        clear fig_IC

    end


    EEG = pop_subcomp( EEG, [bad_compons], 0); % Rejecting flag components
    EEG = eeg_checkset(EEG);
    [EEG, locthresh, globthresh, nrej]  = pop_jointprob(EEG, 1, [1:EEG.nbchan] , thresh, thresh, 0, 0, 0, [], 0); % Artefact rejection by SD (bad trials)

    %[EEG Indexes] = pop_eegthresh(EEG, 1, [1:EEG.nbchan], -80, 80, -2.5, -1, 1, 1);
    %[EEG Indexes] = pop_eegthresh( INEEG, typerej, elec_comp, lowthresh, upthresh, starttime, endtime, superpose, reject);
    

    bad_epochs = find(EEG.reject.rejjp); % bad trials
    %EEG = pop_rejkurt(EEG,1,[1:EEG.nbchan] ,3,3,0,1,0,[],0);


    % Interpolation
    if size(EEG.data, 1) < 32
        EEG.chaninfo.removedchans(1:10) = []; % 1 to 10 are channels from accelerometer data
        EEG = pop_interp(EEG, EEG.chaninfo.removedchans(), 'spherical');
    end


    % Re-reference (TP9/10):
    id1 = find(strcmpi({EEG.chanlocs.labels}, 'TP9'));
    id2 = find(strcmpi({EEG.chanlocs.labels}, 'TP10'));
    EEG = pop_reref(EEG, [id1 id2]);
    %EEG = pop_reref( EEG, []); % or re-fer to common average:


    EEG.bad_compons = bad_compons;
    EEG.label_comp = label_comp;
    EEG.bad_trials = bad_trials;
    EEG.num_bad_trials = nrej;

    % Set name
    EEG.setname = [participant, '_processed']; % Set 2
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG); % Saving data set
    eeglab redraw % Updating GUI

    % Saving .set file
    %EEG = pop_saveset( EEG, 'filename',['processed_', participant,'.set'],'filepath', out_subfold);

    % % Saving .mat file
    % save([out_subfold, 'processed_', participant,'.mat'], 'bad_compons', 'label_comp', 'bad_trials', 'nrej');

    bad_ICA{sub} = bad_compons;
    IC_labels{sub} = label_comp;
    bad_trials{sub} = bad_epochs;
    total_bad_trials {sub} = nrej;


    clear bad_compons;
    clear label_comp;
    clear bad_epochs;
    clear nrej;


    disp([participant, ' finalized!']);


end


%% Table info.

% % Assuming T is your table and it has enough rows to accommodate all entries
% % Also assuming T already exists; if not, you would need to initialize it first.
% 
% % Directly assign cell array content to the table
% T.Bad_components = bad_ICA'; % This assumes 'Bad_components' is the correct column name
% 
% % Add a new column for IC labels. Initialize with empty cells
% T.IC_labels = repmat({''}, height(T), 1);
% 
% % Loop through each participant's labels in IC_labels and assign them to the table
% for i = 2:length(IC_labels)
%     T.IC_labels{i} = strjoin(IC_labels{i}, ', '); % Join labels with a comma if it's a cell array of strings
% end
% 
% T.Bad_trials = bad_trials';
% T.Num_bad_trials = total_bad_trials';
% 
% 
% % Save it in .mat file
% save([outpath, 'Info_EEG.mat'],'T', 'bad_ICA', 'IC_labels', 'bad_trials', 'total_bad_trials');


%%

