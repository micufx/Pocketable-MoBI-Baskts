clc, clear, close all;

%% Paths and Files

mainpath = 'C:\Users\micua\Desktop\eeglab2023.0\'; % eeglab folder
path = 'C:\Users\micua\OneDrive - Benemérita Universidad Autónoma de Puebla\NCP_Basketball\MediaPipe\';
outpath = 'C:\\Users\\micua\\OneDrive - Benemérita Universidad Autónoma de Puebla\\Oldenburg_University\\Thesis\\data_hoops\\';
files = dir(fullfile(path,'\*.xdf')); % listing data sets


%% Plotting setup

% Assuming you have variable names like features_C3, features_Cz, etc., in your workspace
channel_names = {'FC1', 'Fz', 'FC2', 'C3', 'Cz', 'C4'};

num_bins = 15; % The number of bins
num_channels = length(channel_names);
t_values = zeros(num_channels, num_bins);
p_values = zeros(num_channels, num_bins);

numParticipants = length(files);
numSubplots = numParticipants + 1; % One for each participant, plus one for the average

numSubplotsPerFigure = 16;  % Number of subplots per figure (4x4 grid)
numFigures = ceil(length(files) / numSubplotsPerFigure);


figures = cell(1, numFigures);

for f = 1:numFigures
    figures{f} = figure;

    % Set up the figure with a larger size
    set(figures{f},'units','normalized','outerposition', [0 0 1 1]); % fig = figure('Units', 'pixels', 'Renderer', 'painters'); [100, 100, 800, 600]

end


hold on;


%% Loop through participants and plot

for sub = 1:numParticipants

    % Determine which figure and subplot index to use
    figureIndex = ceil(sub / numSubplotsPerFigure);
    subplotIndex = sub - (figureIndex - 1) * numSubplotsPerFigure;

    % Make the correct figure current
    currentFigure = figures{figureIndex};
    figure(currentFigure); % Correctly set the current figure for plotting

    participant = extractBefore(files(sub).name, '.xdf');
    out_subfold = [outpath, participant, '\\'];



    % Create subplot for this participant
    subplot(4, 4, subplotIndex);

    hold on;

    % Loop through each channel
    for chan_idx = 1:num_channels
        % Load the features for the current channel
        load([out_subfold, participant, '_features_RP_', channel_names{chan_idx}, '.mat']); % Loading features
        means = features_Table(:, 1:num_bins); % Assuming the mean bins are the first 15 columns
        condition = features_Table(:, end-1); % Condition column (hits=1, misses=0) before the label

        % Loop through each bin and perform t-tests
        for bin_idx = 1:num_bins
            hit_values = means(condition.Condition == 1, bin_idx);
            miss_values = means(condition.Condition == 0, bin_idx);

            % Check normality for hits
            [~, p_shapiro_hits] = lillietest(hit_values{:,:});
            normality_p_values_hits(chan_idx, bin_idx) = p_shapiro_hits;

            % Check normality for misses
            [~, p_shapiro_misses] = lillietest(miss_values{:,:});
            normality_p_values_misses(chan_idx, bin_idx) = p_shapiro_misses;

            % Check homogeneity of variances between hits and misses
            [p_levene, stats] = vartestn([ hit_values{:,:}; miss_values{:,:}],...
                [ones(size( hit_values)); 2*ones(size(miss_values))], ...
                'TestType', 'LeveneAbsolute', ...
                'Display', 'off');
            levenes_p_values(chan_idx, bin_idx) = p_levene;


            % Perform the t-test if normality and homogeneity assumptions are not violated
            if p_shapiro_hits > 0.05 && p_shapiro_misses > 0.05 && p_levene > 0.05 && num_bins<1

                [h,p,ci,stats] = ttest2(hit_values{:,:}, miss_values{:,:});
                t_values(chan_idx, bin_idx) = stats.tstat;
                p_values(chan_idx, bin_idx) = p;

                disp(['Parametric test used / Participant [', num2str(sub), ']: [T-test]']);

            else

                % Use a non-parametric test if assumptions are violated
                [p, h, stats] = ranksum(hit_values{:,:}, miss_values{:,:}); % Non-Parametric Independent Samples Mann-Whitney U test
                t_values(chan_idx, bin_idx) = stats.zval;
                p_values(chan_idx, bin_idx) = p;

                disp(['Non-Parametric test used / Participant [', num2str(sub), ']: [Wilcoxon signed-rank test]']);

            end

        end

    end

    % Significant values
    % Threshold for significance
    p_threshold = 0.05;   % FDR level

    % Correction for multiple comparisons

    % % Bonferroni correction
    % numComparisons = num_bins * num_channels;  % Total number of comparisons
    % corrected_p_threshold = p_threshold / numComparisons;  % Adjusted p-value threshold

    % FDR correction using Benjamini-Hochberg procedure
    % Assuming p_values is your matrix of p-values
    p_values_vector = p_values(:); % Reshape the matrix into a vector
    p_fdr_vector = mafdr(p_values_vector, 'BHFDR', true);
    p_fdr_matrix = reshape(p_fdr_vector, size(p_values));  % Reshape corrected p-values back to the original matrix form



    % Create Meshgrid for plotting
    [BinsGrid, ElectrodesGrid] = meshgrid(1:num_bins, 1:num_channels);

    % Plotting using surf
    surf(BinsGrid, ElectrodesGrid, p_fdr_matrix);
    shading interp; % Optional: to smooth the color transitions

    % Customizing the Plot
    %title('Readiness Potential', 'FontSize', 12);
    title(['Sub. [', num2str(sub), ']'], 'FontSize', 11.5);
    xlabel('Bins', 'FontSize', 11);
    ylabel('Electrodes', 'FontSize', 11);
    zlabel('p-Values', 'FontSize', 11);
    zlim([0 1]);
    colormap('parula');
    view(-135, 45); % Adjust the view angle for better visualization
    grid("on");

    % Set the y-ticks to correspond to each electrode
    yticks(1:length(channel_names));

    % Set the y-tick labels to be the names of the electrodes
    yticklabels(channel_names);
    ytickangle(30); % Option 2: Dedicated function for rotation

    if sub == 1
        % Colorbar
        c = colorbar('peer', gca);
        %c.TickLabels = {'0', '', '', '', '',  '', '', '','1'};
        c.Label.String = 'p-Values';
        c.Label.FontSize = 11;
        c.Position = [0.952205882352941,0.246200607902736,0.002626050420168,0.538702379047929]; % Set the colorbar position
        c.Limits = [0 1];

    elseif sub==25
        % Colorbar
        c = colorbar('peer', gca);
        %c.TickLabels = {'0', '', '', '', '', '', '', '','1'};
        c.Label.String = 'p-Values';
        c.Label.FontSize = 11;
        c.Position = [0.952205882352941,0.246200607902736,0.002626050420168,0.538702379047929]; % Set the colorbar position
        c.Limits = [0 1];
    end



    % Find indices of significant p-values after FDR correction
    [significantElectrodes, significantBins] = find(p_fdr_matrix < p_threshold);

    % Coordinates for the significant p-values after FDR correction
    significantZ = p_fdr_matrix(p_fdr_matrix < p_threshold);

    % Hold the current plot to add markers
    hold on;

    % Add markers on the significant p-values after FDR correction
    scatter3(significantBins, significantElectrodes, significantZ, 'o', 'filled', 'MarkerEdgeColor', [0 .5 .5], 'MarkerFaceColor', [0 .7 .7]);

    % Refresh the plot
    drawnow;

    % Hold the plot to add more elements
    hold on;

    % Get the limits of the current axes for x and y
    xlims = xlim;
    ylims = ylim;

    % Create a grid for the significance plane
    [X, Y] = meshgrid(xlims(1):xlims(2), ylims(1):ylims(2));

    % Plot the line at p_threshold
    Z = p_threshold * ones(size(X));
    surf(X, Y, Z, 'FaceColor', "#D95319", 'FaceAlpha', 0.3, 'EdgeColor', 'none');

    % Release the hold on the plot
    hold off;



    if sub==length(files)
        clear means
        clear condition
        clear hit_values
        clear miss_values
        clear p_values
        clear t_values
        clear BinsGrid
        clear ElectrodesGrid

        % Create subplot for average
        subplot(4, 4, subplotIndex+1);

        hold on;

        % Loop through each channel
        for chan_idx = 1:num_channels
            % Load the features for the current channel
            load([outpath, 'features_RP_avg_', channel_names{chan_idx}, '.mat']); % Loading features
            means = features_Table_avg(:, 1:num_bins); % Assuming the mean bins are the first 15 columns
            condition = features_Table_avg(:, end-1); % Condition column (hits=1, misses=0) before the label

            % Loop through each bin and perform t-tests
            for bin_idx = 1:num_bins
                hit_values = means(condition.Condition == 1, bin_idx);
                miss_values = means(condition.Condition == 0, bin_idx);

                % Check normality for hits
                [~, p_shapiro_hits] = lillietest(hit_values{:,:});
                normality_p_values_hits(chan_idx, bin_idx) = p_shapiro_hits;

                % Check normality for misses
                [~, p_shapiro_misses] = lillietest(miss_values{:,:});
                normality_p_values_misses(chan_idx, bin_idx) = p_shapiro_misses;

                % Check homogeneity of variances between hits and misses
                [p_levene, stats] = vartestn([ hit_values{:,:}; miss_values{:,:}],...
                    [ones(size( hit_values)); 2*ones(size(miss_values))], ...
                    'TestType', 'LeveneAbsolute', ...
                    'Display', 'off');
                levenes_p_values(chan_idx, bin_idx) = p_levene;


                % Perform the t-test if normality and homogeneity assumptions are not violated
                if p_shapiro_hits > 0.05 && p_shapiro_misses > 0.05 && p_levene > 0.05 && num_bins<1

                    [h,p,ci,stats] = ttest2(hit_values{:,:}, miss_values{:,:});
                    t_values(chan_idx, bin_idx) = stats.tstat;
                    p_values(chan_idx, bin_idx) = p;

                    disp(['Parametric test used: [T-test]']);

                else

                    % Use a non-parametric test if assumptions are violated
                    [p, h, stats] = ranksum(hit_values{:,:}, miss_values{:,:}); % Non-Parametric Independent Samples Mann-Whitney U test
                    t_values(chan_idx, bin_idx) = stats.zval;
                    p_values(chan_idx, bin_idx) = p;

                    disp(['Non-Parametric test used: [Wilcoxon signed-rank test]']);

                end
            end
        end

        % Significant values
        % Threshold for significance
        p_threshold = 0.05;   % FDR level

        % Correction for pmultiple comparisons

        % % Bonferroni correction
        % numComparisons = num_bins * num_channels;  % Total number of comparisons
        % corrected_p_threshold = p_threshold / numComparisons;  % Adjusted p-value threshold

        % FDR correction using Benjamini-Hochberg procedure
        % Assuming p_values is your matrix of p-values
        p_values_vector = p_values(:); % Reshape the matrix into a vector
        p_fdr_vector = mafdr(p_values_vector, 'BHFDR', true);
        p_fdr_matrix = reshape(p_fdr_vector, size(p_values));  % Reshape corrected p-values back to the original matrix form

        % Create Meshgrid for plotting
        [BinsGrid, ElectrodesGrid] = meshgrid(1:num_bins, 1:num_channels);

        % Plotting using surf
        surf(BinsGrid, ElectrodesGrid, p_fdr_matrix);
        shading interp; % Optional: to smooth the color transitions

        % Customizing the Plot
        %title('Readiness Potential', 'FontSize', 12);
        title(['Grand average'], 'FontSize', 11.5);
        xlabel('Bins', 'FontSize', 11);
        ylabel('Electrodes', 'FontSize', 11);
        zlabel('p-Values', 'FontSize', 11);
        colormap('parula');
        view(-135, 45); % Adjust the view angle for better visualization
        grid("on");

        % Set the y-ticks to correspond to each electrode
        yticks(1:length(channel_names));

        % Set the y-tick labels to be the names of the electrodes
        yticklabels(channel_names);
        ytickangle(30); % Option 2: Dedicated function for rotation


        % Find indices of significant p-values after FDR correction
        [significantElectrodes, significantBins] = find(p_fdr_matrix < p_threshold);

        % Coordinates for the significant p-values after FDR correction
        significantZ = p_fdr_matrix(p_fdr_matrix < p_threshold);

        % Hold the current plot to add markers
        hold on;

        % Add markers on the significant p-values after FDR correction
        scatter3(significantBins, significantElectrodes, significantZ, 'o', 'filled', 'MarkerEdgeColor', [0 .5 .5], 'MarkerFaceColor', [0 .7 .7]);

        % Refresh the plot
        drawnow;

        % Hold the plot to add more elements
        hold on;

        % Get the limits of the current axes for x and y
        xlims = xlim;
        ylims = ylim;

        % Create a grid for the significance plane
        [X, Y] = meshgrid(xlims(1):xlims(2), ylims(1):ylims(2));

        % The threshold value after FDR correction might not be the same as before
        % So, we take the most conservative p-value (the highest one that is still significant)
        fdr_threshold = max(p_fdr_matrix(p_fdr_matrix <= p_threshold));

        % Plot the line at p_threshold
        Z = p_threshold * ones(size(X));
        surf(X, Y, Z, 'FaceColor', "#D95319", 'FaceAlpha', 0.3, 'EdgeColor', 'none');

        % Release the hold on the plot
        hold off;


    end

    % Adjust subplot spacing if needed
    sgtitle('Wilcoxon signed-rank test for RP [Hits vs Misses]'); % Super title

end


%% Save figures

for f = 1:numFigures
    
    figure(figures{f});  % Ensure you're making each figure current before saving

    save_fig(figures{f},[outpath, '\\group_analysis\\',], ['3D_ttest_all_conditions', '_', num2str(f),],...
        'fontsize', 8, ...
        'figsize', [35, 20], ...
        'figtypes', {'.png'},...
        'dpi', 600);
end

% for f = 1:numFigures
%     % Ensure you're making each figure current before saving
%     figure(figures{f});
%     saveas(figures{f}, [outpath, '\\group_analysis\\', 'ttest_all_conditions', '_', num2str(f), '.png']);
%     saveas(figures{f}, [outpath, 'ttest_all_conditions', '_', num2str(f), '.png']);
%
% end

%%


