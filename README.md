# Human motion capture & mobile EEG 

This project presents a novel, low-cost, and portable solution for simultaneously recording brain activity (EEG) and human body movement in real-world settings. By leveraging smartphones and a mobile EEG system, we aimed to investigate the feasibility of capturing the Readiness Potential (RP), a pre-movement brain signal, during a complex motor task: basketball free-throw shooting.

The results demonstrate the successful identification of the RP in a natural setting, highlighting the potential of this approach for studying brain-behavior relationships in various domains, including sports science, clinical neuroscience, and human-computer interaction. This research contributes to the advancement of mobile brain/body imaging (MoBI) by offering a practical and accessible method for capturing neural and behavioral data in everyday life contexts. By combining mobile EEG with real-time pose detection and readily available smartphones, this research offers a practical solution for studying brain-behavior relationships in naturalistic environments. 
 
This project involves analyzing motion and EEG data collected during basketball free-throw shooting. The scripts in this repository are designed to process and analyze the data stored in the `data` directory using MATLAB.

## Directory Structure

- `data/raw`: Contains all the raw `.xdf` files and `.mat` event files.
- `scripts/`: Contains MATLAB scripts for data processing and analysis.

## Usage

Each script in the `scripts` directory accesses files from the `data` directory. Ensure that the `data` directory is properly populated with the necessary files before running any scripts.

## Requirements

- MATLAB
- fieldtrip toolbox (fieldtrip-20230215)
- EEGLAB toolbox (2023.0)
- xdfimport extension for eeglab
- dipfit extension for eeglab

**NOTE:**: The `fieldtrip` and `eeglab` directories have to be located on the top level directory to be added to the MATLAB path automatically.

## Running the Scripts

1. Open MATLAB.
2. Navigate to the `scripts` directory.
3. Run the desired script.

Example:
```matlab
cd('path/to/scripts');
run('example_script.m');
```

## License

This project is licensed under the MIT License.
