clc, clear, close all;

%% Convert source data to BIDS

% This code plots a matrix of Root Mean Square (RMS) of EEG channels over
% time and SD topoplot to visualize bad EEG channels with strong artifacts.

% Miguel Contreras-Altamirano, 2025


%% EEG data preparation

mainpath = 'C:\Users\micua\Desktop\eeglab2023.0\'; % eeglab folder
path = 'C:\Users\micua\OneDrive - Benemérita Universidad Autónoma de Puebla\NCP_Basketball\MediaPipe\';
outpath = 'C:\\Users\\micua\\OneDrive - Benemérita Universidad Autónoma de Puebla\\Oldenburg_University\\Thesis\\data_hoops\\';
files = dir( fullfile( path,'\*.xdf')); % listing data sets

nochans = {'AccX','AccY','AccZ','GyroX','GyroY','GyroZ', ... % channels to be ignored
    'QuatW','QuatX','QuatY','QuatZ'};

conditions = {'miss', 'hit'};

HPF = 2;             % high paass filter
LPF = 30;            % low paass filter
thresh = 5;          % standard deviation threshold
from = -2.5;         % sec
to = 0.2;            % sec (from -500ms to -300ms would be the real onset based on wrist acceleration)


%% Bad channels over time

numParticipants = length(files);
numSubplots = numParticipants + 1; % One for each participant, plus one for the average
num_events = 120; % 120 trials
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



%% Loop through participants and plot

for sub = 1:numParticipants

    % Determine which figure and subplot index to use
    figureIndex = ceil(sub / numSubplotsPerFigure);
    subplotIndex = sub - (figureIndex - 1) * numSubplotsPerFigure;


    % Selecting participant
    %sub = input('Participant to analize: ');
    participant = extractBefore(files(sub).name, '.xdf');
    out_subfold = [outpath, participant, '\\'];


    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % Open eeglab

    % Import, channel locs, events, reref
    EEG = pop_loadxdf([path, files(sub).name], 'streamtype', 'EEG', 'exclude_markerstreams', {}); % Loading xdf file
    EEG = pop_chanedit(EEG, 'lookup',[mainpath, 'plugins/dipfit/standard_BEM/elec/standard_1005.elc']); % Channel info
    EEG = pop_select(EEG, 'nochannel', nochans); % Select relevant channels
    eeglab redraw % Updating GUI


    % Select the right figure for this subplot
    figure(figures{figureIndex});


    nchan_ori = EEG.nbchan; % original number of channels

    % Channel artefacts topography
    %EEG = pop_rejchan(EEG);                 % Bad chans detection;
    rms = std(EEG.data');                    % Standard deviation across channels to identify bad ones
    thres = mean(mean(rms)+1.5*std(rms));    % Define threshold for bad channel marking
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

    % Create subplot for this participant
    ax1  = subplot(4, 4, subplotIndex);
    imagesc(rms_t);                                                                         % create colormap for channel stds over time
    colorbar;
    colormap(ax1, turbo);
    xlabel(['Time [', num2str(sec), 's windows]']);
    ylabel('Electrodes');
    title('Root Mean Square (RMS)');
    subtitle(['[', participant, ']'], 'Interpret', 'none');

    % rms_ti = rms_t > thres;                                                                 % color code if value is > thresh or not
    % ax2 = subplot(1, 1, 1);
    % imagesc(rms_ti);
    % colorbar;
    % colormap(ax2, turbo);
    % xlabel(['Time [', num2str(sec), 's windows]']);
    % ylabel('Channels');
    % title(['Threshold: ', num2str(thres)], 'Interpret', 'none');


    sgt = sgtitle('Electrode artifacts over time', 'Interpreter', 'none'); % title for whole plot

end


%% Save figures

for f = 1:numFigures
    % Ensure you're making each figure current before saving
    figure(figures{f});
    saveas(figures{f}, [outpath, '\\group_analysis\\', 'Electrode_artifacts_participants', '_', num2str(f), '.jpg']);

end



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
