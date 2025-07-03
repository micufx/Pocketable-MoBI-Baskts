clc, clear, close all;

%% Statistical information of the Readiness Potential

% This code saves in a table the statistical results and critical
% information of the parameterized Readiness Potential

% Miguel Contreras-Altamirano, 2025


%% EEG data loading

mainpath = 'C:\Users\micua\Desktop\eeglab2023.0\'; % eeglab folder
path = 'C:\Users\micua\OneDrive - Benemérita Universidad Autónoma de Puebla\NCP_Basketball\MediaPipe\';  % raw data
outpath = 'C:\\Users\\micua\\OneDrive - Benemérita Universidad Autónoma de Puebla\\Oldenburg_University\\Thesis\\data_hoops\\';
files = dir( fullfile( path,'\*.xdf')); % listing data sets

num_conditions = 3; % (Conditions and overall: 1=hit 2=miss 3=all)

%% Selecting participant

for sub = 1 : length(files)

    participant = extractBefore(files(sub).name, '.xdf');
    out_subfold = [outpath, participant, '\\'];
    data = load_xdf([path, files(sub).name]); % Saving the data in a variable
    load([outpath, 'Info_EEG.mat']); % Loading channels file


    for cond=1 : num_conditions

        %% Behavioral Data Relationship

        if cond == 1  % 'hit'
            % Import EEG processed data
            [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % Open eeglab
            EEG = pop_loadset('filename',['hoop_hit_RP_', participant, '.set'],'filepath', out_subfold); % Loading set file

            load([out_subfold, 'ACC_rev_hit_', participant,'.mat']); % Loading accelerometer data

        elseif cond == 2  % 'miss'
            % Import EEG processed data
            [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % Open eeglab
            EEG = pop_loadset('filename',['hoop_miss_RP_', participant, '.set'],'filepath', out_subfold); % Loading set file

            load([out_subfold, 'ACC_rev_miss_', participant,'.mat']); % Loading accelerometer data

        elseif cond == 3  % 'none'
            % Import EEG processed data
            [ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % Open eeglab
            EEG = pop_loadset('filename',['hoop_RP_', participant, '.set'],'filepath', out_subfold); % Loading set file

            load([out_subfold, 'ACC_rev_', participant,'.mat']); % Loading accelerometer data
        end


        % Readiness potential range
        start_BP = find(EEG.times== -1500); % RP onset
        end_BP = find(EEG.times== 0);

        % % If the onset does not equal any values of the EEG.times because
        % % of sampling rate
        % if isempty(end_BP)
        %     [val,idx] = min(abs(EEG.times-avgOnsetTime_rev));
        %     minVal = EEG.times(idx);
        %     end_BP = find(EEG.times== minVal);
        % end


        % Channel to visualize
        chan = find(strcmp({EEG.chanlocs.labels}, 'Cz'));

        % Mean and maximun amplitude of the RP
        ERP = mean(EEG.data(:, :, :), 3);  % Mean across the third dimension (trials)
        chan_interest_mean = mean(ERP(chan, start_BP:end_BP)); % Mean amplitude
        chan_interest_max = min(ERP(chan, start_BP:end_BP)); % Maximun RP amplitude (is the min because it's negative)

        % Standard error of the Mean
        RP_window_data = EEG.data(chan, start_BP:end_BP, :); % Extract the amplitude data for the RP window
        mean_RP_amplitudes = squeeze(mean(RP_window_data, 2)); % Calculate the mean amplitude over the RP window for each trial
        std_RP = std(mean_RP_amplitudes); % Calculate the standard deviation across trials
        n_trials = size(EEG.data, 3); % Calculate the number of trials
        SEM = std_RP / sqrt(n_trials); % Calculate the Standard Error of the Mean (SEM)


        if cond == 1
            mean_observations_hits{sub} = mean_RP_amplitudes;
        elseif cond==2
            mean_observations_misses{sub} = mean_RP_amplitudes;
        elseif cond == 3
            mean_observations{sub} = mean_RP_amplitudes;
        end


        if cond == 1
            mean_amp_hits {sub} = chan_interest_mean;
            max_amp_hits {sub} = chan_interest_max;
            SE_hits {sub} = SEM;

        elseif cond==2
            mean_amp_misses {sub} = chan_interest_mean;
            max_amp_misses {sub} = chan_interest_max;
            SE_misses {sub} = SEM;


        elseif cond == 3
            mean_amp {sub} = chan_interest_mean;
            max_amp {sub} = chan_interest_max;
            SE {sub} = SEM;

        end

    end


    clear EEG


end


%% Update table

% write actual tables
T.RP_mean_hits = mean_amp_hits';
T.RP_mean_misses = mean_amp_misses';
T.RP_mean_all = mean_amp';

T.RP_max_hits = max_amp_hits';
T.RP_max_misses = max_amp_misses';
T.RP_max_all = max_amp';

T.RP_SE_hits = SE_hits';
T.RP_SE_misses = SE_misses';
T.RP_SE = SE';


% % write actual tables
% T.RP_mean_hits(end) = mean_amp_hits{end};
% T.RP_mean_misses(end)  = mean_amp_misses{end};
% T.RP_mean_all(end)  = mean_amp{end};
% 
% T.RP_max_hits(end)  = max_amp_hits{end};
% T.RP_max_misses(end)  = max_amp_misses{end};
% T.RP_max_all(end)  = max_amp{end};
% 
% T.RP_SE_hits (end) = SE_hits{end};
% T.RP_SE_misses(end)  = SE_misses{end};
% T.RP_SE (end) = SE{end};

%% Converting data format if neccesary

% Convert the cell array to a numeric matrix

% T.Basketball_onset = cell2mat(T.Basketball_onset);
% T.Accuracy = cell2mat(T.Accuracy);
% T.Subject_ID = cell2mat(T.Subject_ID);

T.RP_max_all = cell2mat(T.RP_max_all);
T.RP_max_hits = cell2mat(T.RP_max_hits);
T.RP_max_misses = cell2mat(T.RP_max_misses);

T.RP_mean_all = cell2mat(T.RP_mean_all);
T.RP_mean_hits = cell2mat(T.RP_mean_hits);
T.RP_mean_misses = cell2mat(T.RP_mean_misses);

T.RP_SE_hits = cell2mat(T.RP_SE_hits);
T.RP_SE_misses = cell2mat(T.RP_SE_misses);
T.RP_SE = cell2mat(T.RP_SE);

%%

% %% Independent Samples Test [Hits vs Misses] in [Cz]
% 
% % Initialize the table to store your results
% results_conditions = table('Size', [0 10], 'VariableTypes', ...
%     {'string', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double'}, ...
%     'VariableNames', {'Participant', 'Mean_RP_Hits', 'Mean_RP_Misses', ...
%     'SE_Hits', 'SE_Misses', 'T_Value', 'df', 'P_Value', 'Cohens_d', 'Test_type'});
% 
% % Iterate over each participant
% for i =1:height(T)
% 
%     % Extract the individual observations for the current participant
%     hits_observations = mean_observations_hits{i};
%     misses_observations = mean_observations_misses{i};
% 
%     % Calculate means for hits and misses
%     mean_hits = mean(hits_observations);
%     mean_misses = mean(misses_observations);
% 
%     % Calculate the pooled standard deviation for Cohen's d
%     pooled_std = sqrt(((std(hits_observations)^2 * (length(hits_observations) - 1)) + ...
%         (std(misses_observations)^2 * (length(misses_observations) - 1))) / ...
%         (length(hits_observations) + length(misses_observations) - 2));
% 
% 
%     % Check normality for hits
%     [~, p_shapiro_hits] = lillietest(hits_observations);
%     normality_p_values_hits(i) = p_shapiro_hits;
% 
%     % Check normality for misses
%     [~, p_shapiro_misses] = lillietest(misses_observations);
%     normality_p_values_misses(i) = p_shapiro_misses;
% 
%     % Check homogeneity of variances between hits and misses
%     [p_levene, stats] = vartestn([hits_observations; misses_observations],...
%         [ones(size(hits_observations)); 2*ones(size(misses_observations))], ...
%         'TestType', 'LeveneAbsolute', ...
%         'Display', 'off');
%     levenes_p_values(i) = p_levene;
% 
% 
% 
%     % Perform the t-test if normality and homogeneity assumptions are not violated
%     if p_shapiro_hits > 0.05 && p_shapiro_misses > 0.05 && p_levene > 0.05 && i<1 % Somthing unreal so it doesn't do Parametric test
% 
%         % Both groups are normally distributed with equal variances
%         [h, p, ci, stats] = ttest2(hits_observations, misses_observations); % Parametric Independent Samples T-Test
%         type_test(i) = stats.tstat;
%         p_values(i) = p;
% 
%         test_labels_matrix(i) = "T-test";
%         disp(['Parametric test used for channel [Cz] / Participant [', num2str(i), ']: [T-test]']);
% 
%     else
% 
%         % Use a non-parametric test if assumptions are violated
%         [p,h,stats] = ranksum(hits_observations, misses_observations); % Non-Parametric Independent Samples Mann-Whitney U test
%         type_test(i) = stats.zval;
%         p_values(i) = p;
% 
%         test_labels_matrix(i) = "Mann-Whitney U test";
%         disp(['Non-Parametric test used for channel [Cz] / Participant [', num2str(i), ']: [Mann-Whitney U test]']);
% 
%     end
% 
% 
%     % Calculate Cohen's d for independent samples
%     cohens_d = (mean_hits - mean_misses) / pooled_std;
% 
%     % Calculate degrees of freedom
%     df = length(hits_observations) + length(misses_observations) - 2;
% 
%     % Add results to the table
%     results_conditions = [results_conditions; {T.Subject_ID(i, :), mean_hits, mean_misses, ...
%         T.RP_SE_hits(i), T.RP_SE_misses(i), type_test(i), df, p, cohens_d, test_labels_matrix{i}}];
% end
% 
% 
% % Coorection for multiple comparisons --> Reduce the likelihood of type I errors (false positives)
% 
% % Holm-Bonferroni correction to the p-values in the results table
% % adjusted_p_values_vector = holm_bonferroni(p_values_vector);   % --> More conservative
% 
% % Bonferroni correction
% % numComparisons = num_bins * num_channels;  % Total number of comparisons
% % corrected_p_threshold = p_threshold / numComparisons;  % Adjusted p-value threshold
% 
% % FDR correction using Benjamini-Hochberg procedure
% p_values = results_conditions.P_Value; % Extract p-values
% p_fdr_pvalues = mafdr(p_values, 'BHFDR', true);  % --> Less conservative
% 
% % Add corrected p-values to results table
% results_conditions.P_Value = p_fdr_pvalues; % Replace the corrected p_values
% 
% % Significant differences between conditions
% p_threshold = 0.05;
% sig_p_values_conditions = [results_conditions.P_Value <= p_threshold];


%% One-Sample Test [Readiness Potential vs 0] in [Cz]

% Initialize the table to store your results
results_RP = table('Size', [0 9], 'VariableTypes', ...
    {'string', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'Participant', 'Mean_RP', 'SE_RP', 'Z_Value', 'Signedrank', 'df', 'P_Value', 'Cohens_d', 'Test_type'});

% Iterate over each participant
for i = 1:height(T)

    % Extract the individual observations for the current participant
    observations = mean_observations{i}; % Use hits or misses or all observations based on what you want to test

    % Calculate mean and standard deviation for RP
    mean_rp = mean(observations);
    std_rp = std(observations);

    % Calculate the standard error
    se_rp = std_rp / sqrt(length(observations));

    % Normality test
    [~, p_shapiro] = lillietest(observations);
    normality_p_values(i) = p_shapiro;

    % Perform the t-test or non-parametric test based on the normality result
    if p_shapiro > 0.05 && i<0
        % Normality assumption not violated, use One-Sample T-Test
        [h, p, ci, stats] = ttest(observations, 0);  % Test against zero
        type_test(i) = stats.tstat;
        p_values(i) = p;

        test_labels_matrix(i) = "T-test";
        disp(['Parametric test used for channel [Cz] / Participant [', num2str(i), ']: [T-test]']);

    else

        % Normality assumption violated, use a non-parametric test
        [p, h, stats] = signrank(observations, 0);  % Wilcoxon signed-rank test
        zval(i) = stats.zval;
        signedrank(i) = stats.signedrank;
        p_values(i) = p;

        test_labels_matrix(i) = "Wilcoxon signed-rank test";
        disp(['Non-Parametric test used for channel [Cz] / Participant [', num2str(i), ']: [Wilcoxon signed-rank test]']);
    
    end


    % Calculate Cohen's d for effect size
    cohens_d = mean_rp / std_rp;

    % Calculate degrees of freedom
    df = length(observations) - 1;

    % Add results to the table
    results_RP = [results_RP; {T.Subject_ID(i, :), mean_rp, se_rp, ...
    zval(i), signedrank(i), df, p, cohens_d, test_labels_matrix{i}}];
end

% FDR correction using Benjamini-Hochberg procedure
p_values = results_RP.P_Value; % Extract p-values
p_fdr_pvalues = mafdr(p_values, 'BHFDR', true);  % --> Less conservative

% Add corrected p-values to results table
results_RP.P_Value = p_fdr_pvalues; % Replace the corrected p_values


%% Save significance

% Save the results of presence in the general table
p_threshold = 0.05;
sig_p_values_RP = [results_RP.P_Value <= p_threshold];

T.RP_presence = sig_p_values_RP;
results_RP.Presence = T.RP_presence;

% Save it in .mat file
save([outpath, 'Info_EEG.mat'],'T');
writetable(T, [outpath, 'Info_EEG.xlsx']);

% Save it in .mat file
save([outpath, 'results_conditions','.mat'], 'results_conditions', 'mean_observations', 'mean_observations_hits', 'mean_observations_misses');

% Save it in .mat file
save([outpath, 'results_RP','.mat'], 'results_RP');
%writetable(results_RP,  [outpath,'results_RP.xlsx']);

%% 