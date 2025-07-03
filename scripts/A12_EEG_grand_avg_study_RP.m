clc, clear, close all;

%% Motion capture combined with mobile EEG

% This code creates a grand average Readiness Potential.

% Miguel Contreras-Altamirano, 2025


%% EEG data loading

mainpath = 'C:\Users\micua\Desktop\eeglab2023.0\'; % eeglab folder
path = 'C:\Users\micua\OneDrive - Benemérita Universidad Autónoma de Puebla\NCP_Basketball\MediaPipe\';
outpath = 'C:\\Users\\micua\\OneDrive - Benemérita Universidad Autónoma de Puebla\\Oldenburg_University\\Thesis\\data_hoops\\';
files = dir( fullfile( path,'\*.xdf')); % listing data sets

num_conditions = 3; % (Conditions and overall: 1=hit 2=miss 3=all)


%% Study eeglab (loading sets for all trials)

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % Open eeglab

% Loop through each participant
for sub = 1:length(files)

    participant = extractBefore(files(sub).name, '.xdf');
    out_subfold = [outpath, participant, '\\'];

    % Import EEG processed data
    EEG = pop_loadset('filename',['hoop_RP_', participant , '.set'],'filepath', [outpath, '\\', participant, '\\']);
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, sub);

end

eeglab redraw % Updating GUI


%% Order channels to the same standard

% Assuming ALLEEG is your structure containing all EEG datasets
standardChannelOrder = {ALLEEG(1).chanlocs.labels}; % Use the first dataset as the standard order

% Loop through all datasets in ALLEEG (starting from the 2nd one)
for i = 2:length(ALLEEG)

    currentChannelOrder = {ALLEEG(i).chanlocs.labels}; % Get current order from the i-th dataset

    % Find the indices of the current channels to match the standard order
    [~, reorderIndices] = ismember(standardChannelOrder, currentChannelOrder);

    % Check if all channels were found
    if any(reorderIndices == 0)
        warning('Some channels in the standard order are not found in dataset %d.', i);
        % Handle missing channels as needed, for example, skip reordering for this dataset
        continue;
    end

    % Reorder the data for the i-th EEG dataset
    ALLEEG(i).data = ALLEEG(i).data(reorderIndices, :, :); % Assuming EEG.data is channels x time x epochs

    % Update EEG.chanlocs to reflect the new channel order
    ALLEEG(i).chanlocs = ALLEEG(i).chanlocs(reorderIndices);
end


% Storing all trial infor in a matrix for further plotting

% Initialize grand average EEG variables
all_trials_data = []; % [channels x time_points x all_trials]

% Loop through each EEG dataset in ALLEEG to extract and concatenate data
for sub = 1:length(ALLEEG)
    % Access the current participant's EEG data
    EEG_matrix = ALLEEG(sub);

    % Concatenate trials along the third dimension
    all_trials_data = cat(3, all_trials_data, EEG_matrix.data);
end

save([outpath, 'Study_ERP_image.mat'], 'all_trials_data');



%% Averaging epochs across to get ERPs

channels = size(ALLEEG(1).data, 1);
frames = size(ALLEEG(1).data, 2);
participants = length(ALLEEG);  % Total number of datasets in ALLEEG

% Initialize the matrix for the combined average ERP
averageAllERP = zeros(channels, frames, participants);

% Loop through each dataset in ALLEEG
for i = 1:participants
    % Calculate the average across epochs for each participant's dataset
    averageAllERP(:, :, i) = mean(ALLEEG(i).data, 3);
end

% averageAllERP now contains the grand average ERP per participant

% All
newEEGall = eeg_emptyset();
newEEGall.data = averageAllERP;
newEEGall.chanlocs = ALLEEG(1).chanlocs;
newEEGall.times = ALLEEG(1).times;
newEEGall.srate = ALLEEG(1).srate;
newEEGall.xmin = ALLEEG(1).xmin;
newEEGall.xmax = ALLEEG(1).xmax;
newEEGall.trials = participants;
newEEGall.pnts = frames;
newEEGall.nbchan = channels;


% Saving .set file
EEG = newEEGall;
EEG.setname = 'Grand_avg_all';
EEG = pop_saveset( EEG, 'filename',['Grand_avg_all','.set'],'filepath', outpath);

clear EEG
clear ALLEEG
clear all_trials_data
clear EEG_matrix

%% Study eeglab (loading sets by conditions)

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % Open eeglab


% Loop through each participant
for sub_eeg_hit = 1:length(files)

    participant = extractBefore(files(sub_eeg_hit).name, '.xdf');
    out_subfold = [outpath, participant, '\\'];

    % Import EEG processed data
    EEG = pop_loadset('filename',['hoop_hit_RP_', participant , '.set'],'filepath', [outpath, '\\', participant, '\\']);
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, sub_eeg_hit);

end

eeglab redraw % Updating GUI


idx = length(files) + 1;

% Loop through each participant
for sub_eeg_miss = 1:length(files)

    participant = extractBefore(files(sub_eeg_miss).name, '.xdf');
    out_subfold = [outpath, participant, '\\'];


    % Import EEG processed data
    EEG = pop_loadset('filename',['hoop_miss_RP_', participant , '.set'],'filepath', [outpath, '\\', participant, '\\']);
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, idx);

    idx = idx + 1;

end


eeglab redraw % Updating GUI


%% Order channels to the same standard

% Assuming ALLEEG is your structure containing all EEG datasets
standardChannelOrder = {ALLEEG(1).chanlocs.labels}; % Use the first dataset as the standard order

% Loop through all datasets in ALLEEG (starting from the 2nd one)
for i = 2:length(ALLEEG)

    currentChannelOrder = {ALLEEG(i).chanlocs.labels}; % Get current order from the i-th dataset

    % Find the indices of the current channels to match the standard order
    [~, reorderIndices] = ismember(standardChannelOrder, currentChannelOrder);

    % Check if all channels were found
    if any(reorderIndices == 0)
        warning('Some channels in the standard order are not found in dataset %d.', i);
        % Handle missing channels as needed, for example, skip reordering for this dataset
        continue;
    end

    % Reorder the data for the i-th EEG dataset
    ALLEEG(i).data = ALLEEG(i).data(reorderIndices, :, :); % Assuming EEG.data is channels x time x epochs

    % Update EEG.chanlocs to reflect the new channel order
    ALLEEG(i).chanlocs = ALLEEG(i).chanlocs(reorderIndices);
end

% Note: After this operation, all datasets in ALLEEG should have their channels
% in the order specified by the first dataset's channel order.

% [STUDY ALLEEG] = std_editset( STUDY, ALLEEG, 'name','Grand_average','task','hits_vs_misses','commands',{{'index',1,'subject','01','session',[],'condition','hit'},{'index',2,'subject','02','condition','hit'},{'index',3,'subject','03','condition','hit'},{'index',4,'subject','04','condition','hit'},{'index',5,'subject','05','condition','hit'},{'index',6,'subject','06','condition','hit'},{'index',7,'subject','07','condition','hit'},{'index',8,'subject','08','condition','hit'},{'index',9,'subject','09','condition','hit'},{'index',10,'subject','10','condition','hit'},{'index',11,'subject','11','condition','hit'},{'index',12,'subject','12','condition','hit'},{'index',13,'subject','13','condition','hit'},{'index',14,'subject','14','condition','hit'},{'index',15,'subject','15','condition','hit'},{'index',16,'subject','16','condition','hit'},{'index',17,'subject','17','condition','hit'},{'index',18,'subject','18','condition','hit'},{'index',19,'subject','19','condition','hit'},{'index',20,'subject','20','condition','hit'},{'index',21,'subject','21','condition','hit'},{'index',22,'subject','22','condition','hit'},{'index',23,'subject','23','condition','hit'},{'index',24,'subject','24','condition','hit'},{'index',25,'subject','25','condition','hit'},{'index',26,'subject','26','condition','hit'},{'index',27,'subject','27','condition','hit'},{'index',28,'subject','1','condition','miss'},{'index',29,'subject','2','condition','miss'},{'index',30,'subject','3','condition','miss'},{'index',1,'condition','''hit','condition','''hit'''},{'index',2,'condition','''hit'''},{'index',3,'condition','''hit'''},{'index',4,'condition','''hit'''},{'index',5,'condition','''hit'''},{'index',6,'condition','''hit'''},{'index',7,'condition','''hit'''},{'index',8,'condition','''hit'''},{'index',9,'condition','''hit'''},{'index',10,'condition','''hit'''},{'index',11,'condition','''hit'''},{'index',12,'condition','''hit'''},{'index',13,'condition','''hit'''},{'index',14,'condition','''hit'''},{'index',15,'condition','''hit'''},{'index',16,'condition','''hit'''},{'index',17,'condition','''hit'''},{'index',18,'condition','''hit'''},{'index',19,'condition','''hit'''},{'index',20,'condition','''hit'''},{'index',21,'condition','''hit'''},{'index',22,'condition','''hit'''},{'index',23,'condition','''hit'''},{'index',24,'condition','''hit'''},{'index',25,'condition','''hit'''},{'index',26,'condition','''hit'''},{'index',27,'condition','''hit'''},{'index',28,'condition','''miss'''},{'index',29,'condition','''miss'''},{'index',30,'condition','''miss'''},{'index',31,'condition','''miss'''},{'index',32,'condition','''miss'''},{'index',34,'condition','''miss'''},{'index',33,'condition','''miss'''},{'index',35,'condition','''miss'''},{'index',36,'condition','''miss'''},{'index',37,'condition','''miss'''},{'index',38,'condition','''miss'''},{'index',39,'condition','''miss'''},{'index',40,'condition','''miss'''},{'index',28,'subject','01'},{'index',29,'subject','02'},{'index',30,'subject','03'},{'index',31,'subject','04'},{'index',32,'subject','05'},{'index',33,'subject','06'},{'index',34,'subject','07'},{'index',35,'subject','08'},{'index',36,'subject','09'},{'index',37,'subject','10'},{'index',38,'subject','11'},{'index',39,'subject','12'},{'index',40,'subject','13'},{'index',41,'subject','14'},{'index',42,'subject','15'},{'index',43,'subject','16'},{'index',44,'subject','17'},{'index',45,'subject','18'},{'index',46,'subject','19'},{'index',47,'subject','20'},{'index',48,'subject','21'},{'index',49,'subject','22'},{'index',50,'subject','23'},{'index',51,'subject','24'},{'index',52,'subject','25'},{'index',53,'subject','26'},{'index',54,'subject','27'},{'index',41,'condition','''miss'''},{'index',42,'condition','''miss'''},{'index',43,'condition','''miss'''},{'index',44,'condition','''miss'''},{'index',45,'condition','''miss'''},{'index',46,'condition','''miss'''},{'index',47,'condition','''miss'''},{'index',48,'condition','''miss'''},{'index',49,'condition','''miss'''},{'index',50,'condition','''miss'''},{'index',51,'condition','''miss'''},{'index',52,'condition','''miss'''},{'index',53,'condition','''miss'''},{'index',54,'condition','''miss'''}},'updatedat','on','rmclust','on' );
% [STUDY ALLEEG] = std_checkset(STUDY, ALLEEG);
%
% CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];
% [STUDY, ALLEEG] = std_precomp(STUDY, ALLEEG, {},'savetrials','on','interp','on','recompute','on','erp','on','erpparams',{'rmbase',[-2500 -2000] },'spec','on','specparams',{'specmode','fft','logtrials','off'},'erpim','on','erpimparams',{'nlines',10,'smoothing',10});


% Storing all hits trials infor in a matrix for further plotting

% Initialize grand average EEG variables
all_trials_data = []; % [channels x time_points x all_trials]

% Loop through each EEG dataset in ALLEEG to extract and concatenate data
for sub = 1: length(ALLEEG)/2 % First half are hits data
    % Access the current participant's EEG data
    EEG_matrix = ALLEEG(sub);

    % Concatenate trials along the third dimension
    all_trials_data = cat(3, all_trials_data, EEG_matrix.data);
end

save([outpath, 'Study_ERP_image_hit.mat'], 'all_trials_data');


clear all_trials_data
clear EEG_matrix


% Storing all miss trials infor in a matrix for further plotting

% Initialize grand average EEG variables
all_trials_data = []; % [channels x time_points x all_trials]

% Loop through each EEG dataset in ALLEEG to extract and concatenate data
for sub = 1 + length(ALLEEG)/2  : length(ALLEEG)
    % Access the current participant's EEG data
    EEG_matrix = ALLEEG(sub);

    % Concatenate trials along the third dimension
    all_trials_data = cat(3, all_trials_data, EEG_matrix.data);
end

save([outpath, 'Study_ERP_image_miss.mat'], 'all_trials_data');


%% Averaging epochs across to get ERPs

channels = size(ALLEEG(1).data, 1);
frames = size(ALLEEG(1).data, 2);
participants = length(ALLEEG) / 2;  % First half of the structure are'hits' and the other half are 'misses'

averageHitERP = zeros(channels, frames, participants);
averageMissERP = zeros(channels, frames, participants);
averageAllERP = zeros(channels, frames, participants);

% Loop through participants
for i = 1:participants

    % Extract 'hit' and 'miss' ERPs for each participant
    hitEEG = mean(ALLEEG(i).data, 3);
    missEEG = mean(ALLEEG(i + participants).data, 3);

    % Store the average ERPs
    averageHitERP(:, :, i) = hitEEG;
    averageMissERP(:, :, i) = missEEG;

end

% Hits
newEEGhits = eeg_emptyset();
newEEGhits.data = averageHitERP;
newEEGhits.chanlocs = ALLEEG(1).chanlocs;
newEEGhits.times = ALLEEG(1).times;
newEEGhits.srate = ALLEEG(1).srate;
newEEGhits.xmin = ALLEEG(1).xmin;
newEEGhits.xmax = ALLEEG(1).xmax;
newEEGhits.trials = participants;
newEEGhits.pnts = frames;
newEEGhits.nbchan = channels;

% Misses
newEEGmisses = eeg_emptyset();
newEEGmisses.data = averageMissERP;
newEEGmisses.chanlocs = ALLEEG(1).chanlocs;
newEEGmisses.times = ALLEEG(1).times;
newEEGmisses.srate = ALLEEG(1).srate;
newEEGmisses.xmin = ALLEEG(1).xmin;
newEEGmisses.xmax = ALLEEG(1).xmax;
newEEGmisses.trials = participants;
newEEGmisses.pnts = frames;
newEEGmisses.nbchan = channels;


%% Saving final average data (.set file)

% Saving .set file
EEG = newEEGhits;
EEG.setname = 'Grand_avg_hits';
EEG = pop_saveset( EEG, 'filename',['Grand_avg_hits','.set'],'filepath', outpath);
clear EEG

% Saving .set file
EEG = newEEGmisses;
EEG.setname = 'Grand_avg_misses';
EEG = pop_saveset( EEG, 'filename',['Grand_avg_misses','.set'],'filepath', outpath);
clear EEG

disp('Grand ERP average created!');

%%


