import mne
from mne.io import read_raw_eeglab
from mne.viz import plot_compare_evokeds, plot_events
from pathlib import Path
import pandas as pd

# Set the directory containing your .set files
set_files_dir = Path(r'C:\Users\juliu\Desktop\oldenburg\mobile_basketball_eeg\data\clean_ica')  # Change this to your directory

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


# List all .set files in the directory
set_files = list(set_files_dir.glob('*.set'))

# Load each .set file into an MNE Raw object
raw_list = []
for set_file in set_files:
    print(f"Loading {set_file.name}...")
    # Read the .set file using MNE include events
    raw = read_raw_eeglab(set_file, preload=True, verbose='ERROR')
    
    # get events from the raw object
    events, event_id = mne.events_from_annotations(raw)

    # I wan tot epoch the data aroudn the events
    epochs_pre = mne.Epochs(raw, events, event_id, tmin=-1.0, tmax=0, baseline=None,  preload=True, verbose='ERROR', event_repeated='merge')
    epochs_post = mne.Epochs(raw, events, event_id, tmin=0, tmax=1.0,  baseline=None, preload=True, verbose='ERROR', event_repeated='merge')

    spectrum = epochs_pre["hit_ACC"].compute_psd()
    spectrum.plot_topomap()

    spectrum = epochs_post["hit_ACC"].compute_psd()
    spectrum.plot_topomap()
