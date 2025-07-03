clc, clear, close all;

%% Feature extraction of the Readiness Potential

% This code extract important features of the Readiness Potential (mean and
% SD) per conditions. 

% Miguel Contreras-Altamirano, 2025

%% EEG condition analysis

mainpath = 'C:\Users\micua\Desktop\eeglab2023.0\'; % eeglab folder
path = 'C:\Users\micua\OneDrive - Benemérita Universidad Autónoma de Puebla\NCP_Basketball\MediaPipe\';
outpath = 'C:\\Users\\micua\\OneDrive - Benemérita Universidad Autónoma de Puebla\\Oldenburg_University\\Thesis\\data_hoops\\';
files = dir(fullfile(path, '\*.xdf')); % listing data sets

nochans = {'AccX', 'AccY', 'AccZ', 'GyroX', 'GyroY', 'GyroZ', ...
    'QuatW', 'QuatX', 'QuatY', 'QuatZ'}; % channels to be ignored

conditions = {'hit', 'miss'};
num_conditions = 2; % (Conditions: 1=hit 2=miss)
channels = {'C3', 'Cz', 'C4', 'FC1', 'Fz', 'FC2'}; % Channels of interest
cz_index = find(strcmp(channels, 'Cz')); % Find the index of Cz channel

% Preallocate tables for means
means_Cz_hits = [];
means_Cz_miss = [];

%% Selecting participant

for sub = 1:length(files)

    participant = extractBefore(files(sub).name, '.xdf');
    out_subfold = [outpath, participant, '\\'];
    load([outpath, 'Info_EEG.mat']); % Loading channels file

    for ch = 1:length(channels)

        for cond = 1:num_conditions

            if cond == 1  % 'hit'
                % Import EEG processed data
                [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab; % Open eeglab
                EEG = pop_loadset('filename', ['hoop_hit_RP_', participant, '.set'], 'filepath', out_subfold); % Loading set file

            elseif cond == 2  % 'miss'
                % Import EEG processed data
                [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab; % Open eeglab
                EEG = pop_loadset('filename', ['hoop_miss_RP_', participant, '.set'], 'filepath', out_subfold); % Loading set file
            end

            % Define the bins from -1500 to 0 ms, excluding baseline
            binEdges = [-1600, -1500, -1400, -1300, -1200, -1100, -1000, ...
                -900, -800, -700, -600, -500, -400, -300, -200, -100, 0];
            nBins = length(binEdges) - 1; % Number of bins is now 15

            nChannels = size(EEG.data, 1);
            nEpochs = size(EEG.data, 3);

            % Initialize structures for means and standard deviations
            MEAN = zeros(nChannels, nBins, nEpochs);
            STD = zeros(nChannels, nBins, nEpochs);

            % Loop through each bin
            for b = 1:nBins
                % Find indices for the current bin
                idxStart = find(EEG.times >= binEdges(b), 1, 'first');
                idxEnd = find(EEG.times < binEdges(b + 1), 1, 'last');

                % Extract data for the current bin and calculate mean and std
                for channel = 1:nChannels
                    for epoch = 1:nEpochs
                        data = EEG.data(channel, idxStart:idxEnd, epoch);
                        MEAN(channel, b, epoch) = mean(data, 'all');
                        STD(channel, b, epoch) = std(data, 0, 'all');
                    end
                end
            end

            % Erase the baseline since it is not helpful for prediction
            Mean_feat = MEAN;
            Std_feat = STD;

            Mean_feat(:, 1, :) = []; % Getting rid off baseline bin
            Std_feat(:, 1, :) = []; % Getting rid off baseline bin

            % Channel of interest
            chan = find(strcmp({EEG.chanlocs.labels}, channels{ch}));

            Mean_feat = Mean_feat(chan, :, :);
            Std_feat = Std_feat(chan, :, :);

            % Assuming Mean_feat and Std_feat are [1 x bins(15) x epochs]
            [nChannels, nBins, nEpochs] = size(Mean_feat); % Adjusted for your dimensions

            % Preallocate arrays for features
            features = zeros(nEpochs, nBins * 2); % For 15 bins of mean and 15 bins of std, total 30 columns per epoch

            % Loop through each epoch to populate features array
            for epoch = 1:nEpochs
                mean_features_epoch = squeeze(Mean_feat(:, :, epoch));
                std_features_epoch = squeeze(Std_feat(:, :, epoch));

                % Combine mean and std features for this epoch into one row
                features(epoch, :) = [mean_features_epoch, std_features_epoch];
            end

            % Create condition and label arrays
            if cond == 1  % 'hit'
                shot_cond = ones(1, size(features, 1))'; % Example: 1 for 'hit', 0 for 'miss'
                shot_labels = repmat({'hit'}, size(features, 1), 1); % Adjust according to your condition variable

            elseif cond == 2  % 'miss'
                shot_cond = zeros(1, size(features, 1))'; % Example: 1 for 'hit', 0 for 'miss'
                shot_labels = repmat({'miss'}, size(features, 1), 1); % Adjust according to your condition variable

            end

            % Generate column names for Mean and Standard Deviation features
            columnNamesMean = arrayfun(@(x) ['Bin-' num2str(x) '-Mean'], 1:nBins, 'UniformOutput', false);
            columnNamesStd = arrayfun(@(x) ['Bin-' num2str(x) '-SD'], 1:nBins, 'UniformOutput', false);

            % Generate column names for each bin
            sub_label = cell(1, length(files));
            for sub_idx = 1:length(files)
                sub_label{sub_idx} = ['Sub_' num2str(sub_idx)];
            end

            % Combine the column names
            columnNames = [columnNamesMean, columnNamesStd];

            if cond == 1  % 'hit'
                % Create the final table
                hit_Table = array2table(features, 'VariableNames', columnNames);
                hit_Table.Condition = shot_cond;
                hit_Table.Label = shot_labels;
            elseif cond == 2  % 'miss'
                % Create the final table
                miss_Table = array2table(features, 'VariableNames', columnNames);
                miss_Table.Condition = shot_cond;
                miss_Table.Label = shot_labels;
            end

            % If Cz channel, add to participant mean tables
            if strcmp(channels{ch}, 'Cz')
                participant_mean = mean(squeeze(Mean_feat), 2); % Calculate mean across epochs
                if cond == 1  % 'hit'
                    means_Cz_hits = [means_Cz_hits; participant_mean']; % Append participant mean
                elseif cond == 2  % 'miss'
                    means_Cz_miss = [means_Cz_miss; participant_mean']; % Append participant mean
                end
            end

            clear EEG MEAN STD

        end % end of loop conditions

        % Now concatenate
        features_Table = vertcat(hit_Table, miss_Table);

        % Save it in .mat file
        save([out_subfold, participant, '_features_RP_', channels{ch}, '.mat'], 'features_Table');

    end % end of loop channels

    disp([participant, ' finalized!']);
end % end of loop subjects


means_Cz_hits = array2table(means_Cz_hits, 'VariableNames', columnNamesMean, 'RowNames', sub_label);
means_Cz_miss = array2table(means_Cz_miss, 'VariableNames', columnNamesMean, 'RowNames', sub_label);


%% Save Cz means tables

% Save it in .mat file
save([outpath, 'means_Cz_hits', '.mat'], 'means_Cz_hits');
save([outpath, 'means_Cz_miss', '.mat'], 'means_Cz_miss');
