clc, clear, close all;

%% Interpolation demo

% Loading xdf files
mainpath = 'C:\Users\micua\Desktop\eeglab2023.0\'; % eeglab folder
path = 'C:\Users\micua\OneDrive - Benemérita Universidad Autónoma de Puebla\NCP_Basketball\MediaPipe\'; % raw data
outpath = 'C:\\Users\\micua\\OneDrive - Benemérita Universidad Autónoma de Puebla\\Oldenburg_University\\Thesis\\data_hoops\\';
files = dir( fullfile( path,'\*.xdf')); % listing data sets

analysis_type = input('What do you want to compare? (Acceleration=1 / Movement=2): ');

%% Binomial test

% This code creates a movie of frame-by-frame motion and EEG combined data
% synchronously.

% Miguel Contreras-Altamirano, 2025

% MATLAB equivalent of the provided Python script

% Preparations --------------------------------------------------------------
files = dir( fullfile( path,'\*.xdf')); % listing data sets

my_subs = {'sub_01', 'sub_02', 'sub_03', 'sub_04', 'sub_05', 'sub_06', ...
    'sub_07', 'sub_08', 'sub_09', 'sub_10', 'sub_11', 'sub_12', ...
    'sub_13', 'sub_14', 'sub_15', 'sub_16', 'sub_17', 'sub_18', ...
    'sub_19', 'sub_20', 'sub_21', 'sub_22', 'sub_23', 'sub_24', ...
    'sub_25', 'sub_26'};

n_subs = length(my_subs);

% Initialize p-values array
my_pvalues = nan(n_subs, 33);

% Wilcoxon test against zero per body part per participant ------------------

for sub = 1:n_subs

    cd(outpath);

    participant = extractBefore(files(sub).name, '.xdf');
    out_subfold = [outpath, participant, '\\'];

    files_csv_name = dir( fullfile( out_subfold,'\*.csv'));

    % fprintf('\nSubject %s, file: %s\n', my_subs{sub}, files_csv{sub});
    curr_file = files_csv_name (analysis_type) ;

    sub_dat = readtable([out_subfold, curr_file.name]);
    sub_dat.Properties.VariableNames = {'Landmark', 'RMS'};
    body_parts = unique(sub_dat.Landmark);

    fprintf('Body parts: %s\n', strjoin(body_parts', ', '));

    for ind = 1:length(body_parts)
        part = body_parts{ind};
        body_dat = sub_dat(strcmp(sub_dat.Landmark, part), :);

        fprintf('Participant: %s, Body Part: %s, RMS Values: %s\n', participant, part, num2str(body_dat.RMS'));


        % Wilcoxon signed-rank test
        if length(body_dat.RMS) > 1

            [p_value, ~] = signrank(body_dat.RMS);
            fprintf('P-value for %s: %f\n', part, p_value);
        else
            p_value = NaN; % Not enough values for Wilcoxon test
        end

        my_pvalues(sub, ind) = p_value;



    end

    % Apply false discovery rate correction (Benjamini-Hochberg)
    my_pvalues(sub, :) = mafdr(my_pvalues(sub, :), 'BHFDR', true);
end

% Summarize in one data frame -----------------------------------------------

all_pvalues = array2table(my_pvalues, 'VariableNames', body_parts);
all_pvalues.subject = my_subs';

binary_decision = my_pvalues < 0.05;

% Binomial test -------------------------------------------------------------

my_alpha = 0.05;
chance_level = binoinv(1 - my_alpha, n_subs, 1/2) * (100 / 26);

bodypart_significances = zeros(33, 1);

for ind = 1:length(body_parts)
    successes = sum(binary_decision(:, ind));

    % Binomial test
    bin_test = binocdf(successes, n_subs, chance_level / 100, 'upper');
    bodypart_significances(ind) = bin_test;
end

% Summarize in data frame --------------------------------------------------

final_df = array2table(bodypart_significances, 'VariableNames', {'pValue'});
final_df.parts = body_parts;

% Export to Excel
if analysis_type == 1
    writetable(final_df, 'binomial_test_acceleration.xlsx', 'WriteVariableNames', true);

elseif analysis_type == 2

    writetable(final_df, 'binomial_test_movement.xlsx', 'WriteVariableNames', true);
end

