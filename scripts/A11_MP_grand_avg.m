clc, clear, close all;

%% Grand average motion

% This code creates a grand average motion across all peaople of all trials

% Miguel Contreras-Altamirano, 2025

%% EEG data loading

mainpath = 'C:\Users\micua\Desktop\eeglab2023.0\'; % eeglab folder
path = 'C:\Users\micua\OneDrive - Benemérita Universidad Autónoma de Puebla\NCP_Basketball\MediaPipe\';
outpath = 'C:\\Users\\micua\\OneDrive - Benemérita Universidad Autónoma de Puebla\\Oldenburg_University\\Thesis\\data_hoops\\';
files = dir( fullfile( path,'\*.xdf')); % listing data sets

num_conditions = 3; % (Conditions and overall: 1=hit 2=miss 3=all)


%% PLD average

allTimeseriesMp = []; % Matrix to store all time series data
allTimestampsEEG = []; % Matrix to store all timestamp data

% % List of participants to exclude

for cond=1 : num_conditions

    % Loop through each participant
    for sub = 1:length(files)

        % if ismember(sub, excludeParticipants)
        %     % Skip this iteration if sub is in the exclude list
        %     continue;
        % end

        participant = extractBefore(files(sub).name, '.xdf');
        out_subfold = [outpath, participant, '\\'];


        % Loading desired data
        if cond == 1 % 'hit'

            load([out_subfold, 'hoop_motion_hit_', participant, '.mat']); % Loading events file


            % Check if timeseries_mp and timestamps_mp exist in the loaded data
            if exist('timeseries_mp', 'var') && exist('timestamps_mp', 'var')
                % Check if the dimensions match
                if isempty(allTimeseriesMp) || (size(allTimeseriesMp, 2) == size(timeseries_mp, 2))
                    allTimeseriesMp = cat(3, allTimeseriesMp, timeseries_mp);
                    %allTimestampsMp = [allTimestampsMp; timestamps_mp]; % Assuming timestamps are the same for all participants
                else
                    fprintf('Data dimensions do not match for participant %s.\n', participant);
                end
            else
                fprintf('timeseries_mp or timestamps_mp not found for participant %s.\n', participant);
            end


        elseif cond == 2  % 'miss'

            load([out_subfold, 'hoop_motion_miss_', participant, '.mat']); % Loading events file

            % Check if timeseries_mp and timestamps_mp exist in the loaded data
            if exist('timeseries_mp', 'var') && exist('timestamps_mp', 'var')
                % Check if the dimensions match
                if isempty(allTimeseriesMp) || (size(allTimeseriesMp, 2) == size(timeseries_mp, 2))
                    allTimeseriesMp = cat(3, allTimeseriesMp, timeseries_mp);
                    %allTimestampsMp = [allTimestampsMp; timestamps_mp]; % Assuming timestamps are the same for all participants
                else
                    fprintf('Data dimensions do not match for participant %s.\n', participant);
                end
            else
                fprintf('timeseries_mp or timestamps_mp not found for participant %s.\n', participant);
            end


        elseif cond == 3  % 'none'

            load([out_subfold, 'hoop_motion_', participant, '.mat']); % Loading events file

            % Check if timeseries_mp and timestamps_mp exist in the loaded data
            if exist('timeseries_mp', 'var') && exist('timestamps_mp', 'var')
                % Check if the dimensions match
                if isempty(allTimeseriesMp) || (size(allTimeseriesMp, 2) == size(timeseries_mp, 2))
                    allTimeseriesMp = cat(3, allTimeseriesMp, timeseries_mp);
                    %allTimestampsMp = [allTimestampsMp; timestamps_mp]; % Assuming timestamps are the same for all participants
                else
                    fprintf('Data dimensions do not match for participant %s.\n', participant);
                end
            else
                fprintf('timeseries_mp or timestamps_mp not found for participant %s.\n', participant);
            end

        end

    end


    % Calculate the average across participants
    averageTimeseriesMp = mean(allTimeseriesMp, 3, 'omitnan');


    % Saving final average data

    if cond == 1 % 'hit'


        % Save it in .mat file
        save([outpath , 'PLD_grand_avg_hit.mat'], 'averageTimeseriesMp', 'timestamps_mp');


    elseif cond == 2 % 'miss'


        % Save it in .mat file
        save([outpath , 'PLD_grand_avg_miss.mat'], 'averageTimeseriesMp', 'timestamps_mp');


    elseif cond == 3  % % 'none'


        % Save it in .mat file
        save([outpath , 'PLD_grand_avg.mat'], 'averageTimeseriesMp', 'timestamps_mp');


    end


    disp(['Condition ', num2str(cond), ' finalized!']);


    clear averageTimeseriesMp
    clear timestamps_mp


end





%%