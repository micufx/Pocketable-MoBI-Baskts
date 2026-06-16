clc; clear; close all;

%% Individual-level parameterization and testing of the Readiness Potential
%
% Independent backup script.
%
% This script mirrors the logic of A15_Topo_ttest_RP_avg, but runs it
% separately for each participant.
%
% For each participant, it:
%   1. Loads hoop_RP_sub_XX.set
%   2. Computes 100-ms mean-amplitude bins from -1500 to 0 ms
%   3. Tests all channels against zero using Wilcoxon signed-rank tests
%   4. Applies FDR correction across all channels x bins
%   5. Re-runs the same analysis for the predefined ROI only:
%      C3, Cz, C4, FC1, Fz, FC2
%   6. Applies FDR correction across ROI channels x bins
%   7. Replaces the ROI p-values in the full p-value matrix with the
%      ROI-corrected values, exactly as in the grand-average script
%   8. Saves statistics and a topography figure in each participant folder
%
% IMPORTANT:
% This is intended as an optional backup analysis. It does not need to be
% reported unless reviewers explicitly ask for individual-level onset/bin
% evidence.

%% Paths

mainpath = 'L:\Downloads\eeglab2023.0\'; 
outpath  = 'L:\Downloads\basketball_RP\Oldenburg_University\Thesis\data_hoops\';

% Add EEGLAB
if exist('eeglab','file') ~= 2
    addpath(mainpath);
end

% Start EEGLAB once
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

%% Settings

roi_channels = {'C3','Cz','C4','FC1','Fz','FC2'};

binEdges = [-1500, -1400, -1300, -1200, -1100, -1000, ...
            -900, -800, -700, -600, -500, -400, ...
            -300, -200, -100, 0];

nBins = length(binEdges) - 1;
p_threshold = 0.05;

% Column names for tables
columnNamesMean = cell(1, nBins);
for b = 1:nBins
    columnNamesMean{b} = ['Bin_' num2str(b) '_Mean'];
end

%% Find participant folders

subDirs = dir(fullfile(outpath, 'sub_*'));
subDirs = subDirs([subDirs.isdir]);

subNames = {subDirs.name};
isSub = ~cellfun(@isempty, regexp(subNames, '^sub_\d+$', 'once'));
subNames = sort(subNames(isSub));

if isempty(subNames)
    error('No participant folders named sub_XX were found in: %s', outpath);
end

%% Global summary across participants

ALL_individual_summary = table();

%% Loop over participants

for isub = 1:length(subNames)

    participant = subNames{isub};
    subFolder = fullfile(outpath, participant);

    setFile = ['hoop_RP_', participant, '.set'];
    setPath = fullfile(subFolder, setFile);

    fprintf('\n==============================================================\n');
    fprintf('Participant %d/%d: %s\n', isub, length(subNames), participant);
    fprintf('Loading: %s\n', setPath);
    fprintf('==============================================================\n');

    if ~exist(setPath, 'file')
        warning('File not found: %s. Skipping participant.', setPath);
        continue;
    end

    EEG = pop_loadset('filename', setFile, 'filepath', [subFolder filesep]);

    chan_label = {EEG.chanlocs.labels};
    nChans = length(EEG.chanlocs);
    nTrials = size(EEG.data, 3);

    %% ------------------------------------------------------------
    %% Feature extraction: all channels, 100-ms bins
    %% ------------------------------------------------------------

    all_means = cell(nChans, 1);

    for chan_idx = 1:nChans

        all_means{chan_idx} = zeros(nTrials, nBins);

        for b = 1:nBins

            idxStart = find(EEG.times >= binEdges(b), 1, 'first');
            idxEnd   = find(EEG.times <  binEdges(b + 1), 1, 'last');

            if isempty(idxStart) || isempty(idxEnd) || idxEnd < idxStart
                warning('Empty bin for %s, channel %s, bin %d.', ...
                    participant, chan_label{chan_idx}, b);
                all_means{chan_idx}(:, b) = NaN;
                continue;
            end

            bin_data = EEG.data(chan_idx, idxStart:idxEnd, :);
            all_means{chan_idx}(:, b) = squeeze(mean(bin_data, 2));

        end
    end

    %% ------------------------------------------------------------
    %% Wilcoxon signed-rank test per bin: all channels
    %% ------------------------------------------------------------

    p_values_matrix = nan(nChans, nBins);
    z_values_matrix = nan(nChans, nBins);
    signedrank_matrix = nan(nChans, nBins);
    test_labels_matrix = strings(nChans, nBins);
    normality_p_values = nan(nChans, nBins);

    mean_matrix = nan(nChans, nBins);
    se_matrix = nan(nChans, nBins);
    sd_matrix = nan(nChans, nBins);
    median_matrix = nan(nChans, nBins);
    percent_neg_matrix = nan(nChans, nBins);
    r_abs_matrix = nan(nChans, nBins);
    n_obs_matrix = nan(nChans, nBins);

    for chan_idx = 1:nChans

        for b = 1:nBins

            observations = all_means{chan_idx}(:, b);
            observations = observations(:);
            observations = observations(~isnan(observations));

            n_obs_matrix(chan_idx, b) = numel(observations);

            if numel(observations) < 5
                continue;
            end

            mean_matrix(chan_idx, b) = mean(observations);
            sd_matrix(chan_idx, b) = std(observations);
            se_matrix(chan_idx, b) = std(observations) / sqrt(numel(observations));
            median_matrix(chan_idx, b) = median(observations);
            percent_neg_matrix(chan_idx, b) = 100 * mean(observations < 0);

            % Normality test retained for documentation
            try
                [~, p_shapiro] = lillietest(observations);
                normality_p_values(chan_idx, b) = p_shapiro;
            catch
                normality_p_values(chan_idx, b) = NaN;
            end

            % As in your group script, always use Wilcoxon signed-rank test
            [p, ~, stats] = signrank(observations, 0);

            p_values_matrix(chan_idx, b) = p;

            if isfield(stats, 'zval')
                z_values_matrix(chan_idx, b) = stats.zval;
                r_abs_matrix(chan_idx, b) = abs(stats.zval) / sqrt(numel(observations));
            end

            if isfield(stats, 'signedrank')
                signedrank_matrix(chan_idx, b) = stats.signedrank;
            end

            test_labels_matrix(chan_idx, b) = "Wilcoxon signed-rank test";

            fprintf('Non-Parametric test used for channel [%s] bin [%d]: [Wilcoxon signed-rank test]\n', ...
                chan_label{chan_idx}, b);

        end
    end

    %% ------------------------------------------------------------
    %% FDR correction: all channels x bins
    %% ------------------------------------------------------------

    p_values_vector = reshape(p_values_matrix, [], 1);
    valid_p = ~isnan(p_values_vector);

    adjusted_p_values_vector = nan(size(p_values_vector));

    if exist('mafdr', 'file') == 2
        adjusted_p_values_vector(valid_p) = mafdr(p_values_vector(valid_p), 'BHFDR', true);
    else
        warning('mafdr not found. Using local Benjamini-Hochberg FDR correction.');
        adjusted_p_values_vector(valid_p) = local_bh_fdr(p_values_vector(valid_p));
    end

    adjusted_p_values_matrix = reshape(adjusted_p_values_vector, size(p_values_matrix));
    p_values_matrix = adjusted_p_values_matrix;

    %% ------------------------------------------------------------
    %% ROI analysis: same logic as group script
    %% ------------------------------------------------------------

    roi_indices = find(ismember({EEG.chanlocs.labels}, roi_channels));
    roi_found = chan_label(roi_indices);

    if isempty(roi_indices)
        warning('No ROI channels found for %s. Skipping ROI replacement.', participant);
        roi_indices = [];
    end

    all_means_ROI = all_means(roi_indices, :);

    p_values_matrix_ROI = nan(length(roi_indices), nBins);
    z_values_matrix_ROI = nan(length(roi_indices), nBins);
    signedrank_matrix_ROI = nan(length(roi_indices), nBins);
    normality_p_values_ROI = nan(length(roi_indices), nBins);
    r_abs_matrix_ROI = nan(length(roi_indices), nBins);

    mean_matrix_ROI = nan(length(roi_indices), nBins);
    se_matrix_ROI = nan(length(roi_indices), nBins);
    sd_matrix_ROI = nan(length(roi_indices), nBins);
    median_matrix_ROI = nan(length(roi_indices), nBins);
    percent_neg_matrix_ROI = nan(length(roi_indices), nBins);
    n_obs_matrix_ROI = nan(length(roi_indices), nBins);

    for roi_ch = 1:length(roi_indices)

        for b = 1:nBins

            observations = all_means_ROI{roi_ch}(:, b);
            observations = observations(:);
            observations = observations(~isnan(observations));

            n_obs_matrix_ROI(roi_ch, b) = numel(observations);

            if numel(observations) < 5
                continue;
            end

            mean_matrix_ROI(roi_ch, b) = mean(observations);
            sd_matrix_ROI(roi_ch, b) = std(observations);
            se_matrix_ROI(roi_ch, b) = std(observations) / sqrt(numel(observations));
            median_matrix_ROI(roi_ch, b) = median(observations);
            percent_neg_matrix_ROI(roi_ch, b) = 100 * mean(observations < 0);

            try
                [~, p_shapiro] = lillietest(observations);
                normality_p_values_ROI(roi_ch, b) = p_shapiro;
            catch
                normality_p_values_ROI(roi_ch, b) = NaN;
            end

            [p, ~, stats] = signrank(observations, 0);

            p_values_matrix_ROI(roi_ch, b) = p;

            if isfield(stats, 'zval')
                z_values_matrix_ROI(roi_ch, b) = stats.zval;
                r_abs_matrix_ROI(roi_ch, b) = abs(stats.zval) / sqrt(numel(observations));
            end

            if isfield(stats, 'signedrank')
                signedrank_matrix_ROI(roi_ch, b) = stats.signedrank;
            end

            fprintf('ROI test used for channel [%s] bin [%d]: [Wilcoxon signed-rank test]\n', ...
                roi_found{roi_ch}, b);

        end
    end

    %% FDR correction: ROI channels x bins only

    p_values_vector_ROI = reshape(p_values_matrix_ROI, [], 1);
    valid_roi_p = ~isnan(p_values_vector_ROI);

    adjusted_p_values_vector_ROI = nan(size(p_values_vector_ROI));

    if exist('mafdr', 'file') == 2
        adjusted_p_values_vector_ROI(valid_roi_p) = mafdr(p_values_vector_ROI(valid_roi_p), 'BHFDR', true);
    else
        adjusted_p_values_vector_ROI(valid_roi_p) = local_bh_fdr(p_values_vector_ROI(valid_roi_p));
    end

    adjusted_p_values_matrix_ROI = reshape(adjusted_p_values_vector_ROI, size(p_values_matrix_ROI));

    p_values_matrix_ROI = adjusted_p_values_matrix_ROI;

    %% Replace old values from ROI, exactly as in your group script

    p_values_matrix(roi_indices, :) = p_values_matrix_ROI;
    z_values_matrix(roi_indices, :) = z_values_matrix_ROI;
    signedrank_matrix(roi_indices, :) = signedrank_matrix_ROI;
    r_abs_matrix(roi_indices, :) = r_abs_matrix_ROI;

    %% ------------------------------------------------------------
    %% Create full-channel tables
    %% ------------------------------------------------------------

    pValues_Table = array2table(p_values_matrix, ...
        'VariableNames', columnNamesMean, ...
        'RowNames', chan_label);

    zValues_Table = array2table(z_values_matrix, ...
        'VariableNames', columnNamesMean, ...
        'RowNames', chan_label);

    rValues_Table = array2table(r_abs_matrix, ...
        'VariableNames', columnNamesMean, ...
        'RowNames', chan_label);

    meanValues_Table = array2table(mean_matrix, ...
        'VariableNames', columnNamesMean, ...
        'RowNames', chan_label);

    seValues_Table = array2table(se_matrix, ...
        'VariableNames', columnNamesMean, ...
        'RowNames', chan_label);

    testLabels_Table = array2table(test_labels_matrix, ...
        'VariableNames', columnNamesMean, ...
        'RowNames', chan_label);

    normality_Table = array2table(normality_p_values, ...
        'VariableNames', columnNamesMean, ...
        'RowNames', chan_label);

    %% ------------------------------------------------------------
    %% Create ROI long-format table
    %% ------------------------------------------------------------

    ROI_BinStats = table();

    for roi_ch = 1:length(roi_indices)

        for b = 1:nBins

            tmp = table();
            tmp.Participant = string(participant);
            tmp.ROI_Channel = string(roi_found{roi_ch});
            tmp.BinStart_ms = binEdges(b);
            tmp.BinEnd_ms = binEdges(b+1);
            tmp.N = n_obs_matrix_ROI(roi_ch, b);
            tmp.Mean_uV = mean_matrix_ROI(roi_ch, b);
            tmp.SD_uV = sd_matrix_ROI(roi_ch, b);
            tmp.SE_uV = se_matrix_ROI(roi_ch, b);
            tmp.Median_uV = median_matrix_ROI(roi_ch, b);
            tmp.Percent_Negative_Trials = percent_neg_matrix_ROI(roi_ch, b);
            tmp.Z = z_values_matrix_ROI(roi_ch, b);
            tmp.SignedRank = signedrank_matrix_ROI(roi_ch, b);
            tmp.P_FDR_ROI = p_values_matrix_ROI(roi_ch, b);
            tmp.r_abs = r_abs_matrix_ROI(roi_ch, b);
            tmp.Significant_ROI = p_values_matrix_ROI(roi_ch, b) <= p_threshold;
            tmp.Significant_Negative_ROI = ...
                p_values_matrix_ROI(roi_ch, b) <= p_threshold && mean_matrix_ROI(roi_ch, b) < 0;

            ROI_BinStats = [ROI_BinStats; tmp];

        end
    end

    %% ------------------------------------------------------------
    %% Participant summary
    %% ------------------------------------------------------------

    sig_negative_roi = (p_values_matrix_ROI <= p_threshold) & (mean_matrix_ROI < 0);
    sig_any_roi_per_bin = any(sig_negative_roi, 1);

    onset_first_any_roi_ms = first_sustained_onset(sig_any_roi_per_bin, binEdges, 1);
    onset_first_2bin_roi_ms = first_sustained_onset(sig_any_roi_per_bin, binEdges, 2);

    Summary = table();
    Summary.Participant = string(participant);
    Summary.NTrials = nTrials;
    Summary.ROI_Channels = string(strjoin(roi_found, ', '));
    Summary.N_Significant_Negative_ROI_ChannelBins = sum(sig_negative_roi(:));
    Summary.N_Bins_With_Any_Significant_Negative_ROI = sum(sig_any_roi_per_bin);
    Summary.Onset_First_AnyROI_SigNeg_Bin_ms = onset_first_any_roi_ms;
    Summary.Onset_First_Sustained_2Bin_AnyROI_SigNeg_ms = onset_first_2bin_roi_ms;
    Summary.Min_ROI_Mean_uV = min(mean_matrix_ROI(:), [], 'omitnan');
    Summary.Max_ROI_Mean_uV = max(mean_matrix_ROI(:), [], 'omitnan');
    Summary.Min_ROI_FDR_p = min(p_values_matrix_ROI(:), [], 'omitnan');

    ALL_individual_summary = [ALL_individual_summary; Summary];

    %% ------------------------------------------------------------
    %% Save statistics in participant folder
    %% ------------------------------------------------------------

    statsPrefix = ['topo_stats_RP_individual_', participant];

    save(fullfile(subFolder, [statsPrefix, '.mat']), ...
        'pValues_Table', ...
        'zValues_Table', ...
        'rValues_Table', ...
        'meanValues_Table', ...
        'seValues_Table', ...
        'testLabels_Table', ...
        'normality_Table', ...
        'ROI_BinStats', ...
        'Summary', ...
        'p_values_matrix', ...
        'z_values_matrix', ...
        'r_abs_matrix', ...
        'mean_matrix', ...
        'se_matrix', ...
        'p_values_matrix_ROI', ...
        'z_values_matrix_ROI', ...
        'r_abs_matrix_ROI', ...
        'mean_matrix_ROI', ...
        'se_matrix_ROI', ...
        'roi_channels', ...
        'roi_indices', ...
        'roi_found', ...
        'binEdges');

    writetable(pValues_Table, fullfile(subFolder, [statsPrefix, '_pValues.xlsx']), 'WriteRowNames', true);
    writetable(zValues_Table, fullfile(subFolder, [statsPrefix, '_zValues.xlsx']), 'WriteRowNames', true);
    writetable(rValues_Table, fullfile(subFolder, [statsPrefix, '_rValues.xlsx']), 'WriteRowNames', true);
    writetable(meanValues_Table, fullfile(subFolder, [statsPrefix, '_mean_uV.xlsx']), 'WriteRowNames', true);
    writetable(seValues_Table, fullfile(subFolder, [statsPrefix, '_SE_uV.xlsx']), 'WriteRowNames', true);
    writetable(testLabels_Table, fullfile(subFolder, [statsPrefix, '_labels.xlsx']), 'WriteRowNames', true);
    writetable(ROI_BinStats, fullfile(subFolder, [statsPrefix, '_ROI_BinStats.xlsx']));
    writetable(Summary, fullfile(subFolder, [statsPrefix, '_summary.xlsx']));

    %% ------------------------------------------------------------
    %% Topography figure: same style as A15_Topo_ttest_RP_avg
    %% ------------------------------------------------------------

    % Colors from your group script
    a = [247,251,255] / 255;
    bcol = [222,235,247] / 255;
    ccol = [198,219,239] / 255;
    dcol = [158,202,225] / 255;
    ecol = [107,174,214] / 255;
    fcol = [66,146,198] / 255;
    gcol = [33,113,181] / 255;

    customColors = [gcol; fcol; ecol; dcol; ccol; bcol; a];

    smoothGradient = interp1( ...
        linspace(0, 1, size(customColors, 1)), ...
        customColors, ...
        linspace(0, 1, 256), ...
        'pchip');

    fig = figure('units', 'normalized', 'outerposition', [0 0 1 1]);

    nRows = 3;
    nCols = 5;

    useSubtight = exist('subtightplot', 'file') == 2;

    sig_p_values = p_values_matrix <= p_threshold;

    for itopo = 1:nBins

        if useSubtight
            subplotTopo = subtightplot(nRows, nCols, itopo);
        else
            subplotTopo = subplot(nRows, nCols, itopo);
        end

        binRangeStr = sprintf('%d to %d ms', binEdges(itopo), binEdges(itopo + 1));

        % Find significant channels for the current bin
        sig_channels = find(sig_p_values(:, itopo));

        low = 0;
        high = 1;

        % Plot all-channel p-value topography, with ROI dots in black
        topoplot(p_values_matrix(:, itopo), EEG.chanlocs, ...
            'electrodes', 'off', ...
            'maplimits', [low high], ...
            'whitebk', 'off', ...
            'shading', 'interp', ...
            'emarker2', {roi_indices, 'o', 'k', 10, 2});

        % Find significant ROI channels for the current bin
        significant_roi_indices = intersect(sig_channels, roi_indices);

        % Overlay significant ROI channels in red
        if ~isempty(significant_roi_indices)
            hold on;
            topoplot(p_values_matrix(:, itopo), EEG.chanlocs, ...
                'electrodes', 'off', ...
                'maplimits', [low high], ...
                'whitebk', 'on', ...
                'shading', 'interp', ...
                'emarker2', {significant_roi_indices, 'o', 'r', 10, 2});
            hold off;
        end

        colormap(smoothGradient);

        titleHandle = title(binRangeStr, 'FontSize', 11, 'FontWeight', 'bold');
        titlePosition = get(titleHandle, 'position');
        set(titleHandle, 'position', [titlePosition(1), titlePosition(2)-1.35, titlePosition(3)]);

        if itopo == 1
            cb = colorbar('Ticks', [0 1]);
            cb.Label.String = 'p-Values';
            cb.Label.FontSize = 11;
            cb.Position = [0.9546875,0.728587319243604,0.003645833333333,0.136334146724982];
        end

    end

    sgtitle(['Statistical Comparison [Readiness Potential vs 0] / ', participant], ...
        'Color', 'k', ...
        'FontWeight', 'bold', ...
        'Interpreter', 'none');

    %% Save figure in participant folder

    figPrefix = ['topo_stats_RP_individual_', participant];

    saveas(fig, fullfile(subFolder, [figPrefix, '.jpg']));
    saveas(fig, fullfile(subFolder, [figPrefix, '.png']));

    try
        savefig(fig, fullfile(subFolder, [figPrefix, '.fig']));
    catch
        warning('Could not save .fig for %s.', participant);
    end

    if exist('save_fig', 'file') == 2
        try
            save_fig(fig, [subFolder filesep], figPrefix, 'fontsize', 12);
        catch
            warning('save_fig failed for %s. Standard saveas files were saved.', participant);
        end
    end

    close(fig);

    fprintf('Saved participant-level RP statistics and figure for %s in:\n%s\n', participant, subFolder);

end

%% Save global summary in data_hoops folder

if ~isempty(ALL_individual_summary)
    writetable(ALL_individual_summary, fullfile(outpath, 'ALL_topo_stats_RP_individual_summary.xlsx'));
    writetable(ALL_individual_summary, fullfile(outpath, 'ALL_topo_stats_RP_individual_summary.csv'));
    save(fullfile(outpath, 'ALL_topo_stats_RP_individual_summary.mat'), 'ALL_individual_summary');
end

disp('==============================================================');
disp('Finished individual-level RP topography analysis.');
disp('Participant-level figures and statistics were saved in each participant folder.');
disp('==============================================================');

%% Local helper functions

function onset_ms = first_sustained_onset(sigVec, binEdges, minConsecBins)
% Returns the first bin start where sigVec has at least minConsecBins
% consecutive true values. Returns NaN if no such sequence exists.

    onset_ms = NaN;

    sigVec = logical(sigVec(:)');

    d = diff([false, sigVec, false]);

    runStarts = find(d == 1);
    runEnds   = find(d == -1) - 1;
    runLengths = runEnds - runStarts + 1;

    validRuns = find(runLengths >= minConsecBins);

    if ~isempty(validRuns)
        firstRun = validRuns(1);
        onsetBin = runStarts(firstRun);
        onset_ms = binEdges(onsetBin);
    end
end

function p_fdr = local_bh_fdr(p)
% Benjamini-Hochberg FDR correction fallback if mafdr is unavailable.
% Returns adjusted p-values in the original order.

    p = p(:);
    [p_sorted, sortIdx] = sort(p);
    m = numel(p_sorted);

    adj_sorted = nan(size(p_sorted));

    for i = 1:m
        adj_sorted(i) = p_sorted(i) * m / i;
    end

    % Enforce monotonicity
    for i = m-1:-1:1
        adj_sorted(i) = min(adj_sorted(i), adj_sorted(i+1));
    end

    adj_sorted(adj_sorted > 1) = 1;

    p_fdr = nan(size(p));
    p_fdr(sortIdx) = adj_sorted;
end