import mne
from mne.io import read_raw_eeglab
import numpy as np
from pathlib import Path
import pandas as pd

# Set the directory containing your .set files
set_files_dir = Path(r'C:\Users\juliu\Desktop\oldenburg\mobile_basketball_eeg\data\clean_ica')  # Change this to your directory
DIR_PLOTS = Path(r'C:\Users\juliu\Desktop\oldenburg\mobile_basketball_eeg\plots')  # Change this to your directory

# load .mat file for EEG info
dir_info = Path(r'C:\Users\juliu\Desktop\oldenburg\mobile_basketball_eeg\data\raw')  # Change this to your directory
info_file = dir_info.joinpath('Info_EEG.csv')

info_eeg = pd.read_csv(info_file)
# Find all columns that start with 'Bad_channels_n', 'Bad_components_n', or 'Bad_trials_n'
bad_channels_cols = [col for col in info_eeg.columns if col.startswith('Bad_channels')]
bad_components_cols = [col for col in info_eeg.columns if col.startswith('Bad_components')]
bad_trials_cols = [col for col in info_eeg.columns if col.startswith('Bad_trials')]

# Merge the columns into a single list per row
info_eeg['Bad_channels_merged'] = info_eeg[bad_channels_cols].apply(lambda row: [item for item in row if pd.notnull(item)], axis=1)
info_eeg['Bad_components_merged'] = info_eeg[bad_components_cols].apply(lambda row: [item for item in row if pd.notnull(item)], axis=1)
info_eeg['Bad_trials_merged'] = info_eeg[bad_trials_cols].apply(lambda row: [item for item in row if pd.notnull(item)], axis=1)

# define ROI
roi = ['C3', 'Cz', 'C4', 'P3', 'Pz', 'P4']  # Define your region of interest (ROI) channels

# List all .set files in the directory
set_files = list(set_files_dir.glob('*.set'))

# Load each .set file into an MNE Raw object
raw_list = []
for set_file in set_files:
    participant = '_'.join(set_file.stem.split('_')[1:3])  # Assuming the filename starts with the participant ID
    print(f"Loading {set_file.name}...")
    # Read the .set file using MNE include events
    raw = read_raw_eeglab(set_file, preload=True, verbose='ERROR')
    
    # get events from the raw object
    events, event_id = mne.events_from_annotations(raw)

    # I wan tot epoch the data aroudn the events
    epochs = mne.Epochs(raw, events, event_id, tmin=-2.5, tmax=2.0, baseline=(-2.5,-2),  preload=True, verbose='ERROR', event_repeated='merge')

    # Artifact rejection (bad components)
    idx = info_eeg[info_eeg['Subject_ID'] == participant].index[0]
    bad_comps = info_eeg.iloc[idx]['Bad_components_merged']  # e.g., '[1,2,3]
    if bad_comps:
        ica = mne.preprocessing.read_ica_eeglab(set_file)
        # prep bad_comps for python, shift index by -1
        bad_comps = [int(comp) - 1 for comp in bad_comps]
        epochs = ica.apply(epochs, exclude=bad_comps)

    # Bad trials rejection
    bad_trials = info_eeg.iloc[idx]['Bad_trials_merged']
    if bad_trials:
        epochs.drop(bad_trials)

    # Re-reference to TP9/TP10 if present
    if 'TP9' in epochs.ch_names and 'TP10' in epochs.ch_names:
        epochs.set_eeg_reference(['TP9', 'TP10'])

    freqs = np.logspace(*np.log10([8, 32]), num=12)
    n_cycles = freqs / 2.0  # different number of cycle per frequency
    power, itc = epochs.compute_tfr(
        method="morlet",
        freqs=freqs,
        n_cycles=n_cycles,
        average=True,
        return_itc=True,
        decim=3,
        picks=roi
    )

    power.plot_joint(
    baseline=(-2.5, -2.0), mode="mean", tmin=-2.5, tmax=1.5, timefreqs=[(-1, 15), (0, 15), (1, 15)],
    title=f"{participant} - Power",
    )

    # store the plot
    plot_file = DIR_PLOTS.joinpath(f"{participant}_power_plot.png")