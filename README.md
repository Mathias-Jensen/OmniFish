# OmniFish

This repository contains the design files, control code, experimental protocols, datasets, analysis scripts, and CFD simulations developed for **OmniFish** — a soft robotic fish platform designed to span the full Body–Caudal Fin (BCF) locomotion range.

OmniFish was developed as part of a research project investigating how different fish-inspired body shapes and caudal fin configurations influence swimming kinematics, locomotion performance, and hydrodynamic behavior.

## Repository Structure

```text
OmniFish/
│
├── cfd-simulation/                 # CFD simulations of analyzed fish-inspired bodies
│   ├── average/                    # Average body simulation files
│   ├── boxfish/                    # Boxfish-inspired body simulation files
│   ├── eel/                        # Eel-inspired body simulation files
│   ├── mackerel/                   # Mackerel-inspired body simulation files
│   ├── trout/                      # Trout-inspired body simulation files
│   └── tuna/                       # Tuna-inspired body simulation files
│
├── data-and-data-analysis/          # Experimental data and MATLAB analysis scripts
│   ├── data/                       # Raw and experimental datasets
│   ├── KinematicResults.csv        # Kinematic analysis results
│   ├── fin_results.csv             # Fin experiment results
│   ├── swimming_results.csv        # Swimming performance results
│   ├── pairwise_statistics.csv     # Pairwise statistical comparisons
│   ├── within_mode_frequency_statistics.csv
│   ├── drag_simulation.mlx         # Drag simulation analysis
│   ├── kinematic_anlysis.mlx       # Kinematic analysis workflow
│   ├── load_cell_calibration.mlx   # Load cell calibration
│   ├── locomotion_experiments.mlx  # Locomotion experiment analysis
│   ├── oscillating_fin_experiment.mlx
│   └── swim_fin_trim.mlx
│
├── design-files/                   # Mechanical design files for bodies, fins, robot, and setups
│   ├── bodies/                     # Fish-inspired body geometries
│   ├── caudal-fins/                # Caudal fin designs
│   ├── robot/                      # Robot components and assembly files
│   └── setups/                     # Experimental setup design files
│
├── experimental-protocols/          # Protocols for fabrication, testing, and experiments
│
├── fish-specimen-analysis/          # Analysis of biological fish specimens and reference geometries
│
├── robot-control-code/              # Code used to control the soft robotic fish
│
├── LICENSE                         # MIT License
└── README.md
```

## Project Overview

The goal of OmniFish is to provide a soft robotic platform for studying BCF swimming across a wide range of fish-like morphologies.

The repository includes:

* Design files for soft robotic fish bodies and caudal fins
* Robot assembly and experimental setup files
* Robot control code
* Experimental protocols
* Raw and processed experimental data
* MATLAB analysis workflows
* CFD simulations of six analyzed body geometries
* Fish specimen analysis used to inform the body designs

## CFD Simulations

The `cfd-simulation/` folder contains simulation files for six fish-inspired body geometries:

* Average body
* Boxfish
* Eel
* Mackerel
* Trout
* Tuna

These simulations were used to compare hydrodynamic behavior across different body shapes representative of the BCF locomotion range.

## Data and Analysis

The `data-and-data-analysis/` folder contains experimental datasets and MATLAB Live Scripts used for processing and analyzing the project results.

Included analysis files cover:

* Swimming kinematics
* Locomotion experiments
* Oscillating fin experiments
* Load cell calibration
* Drag simulation
* Fin trimming and swimming performance
* Statistical comparisons between modes and frequencies

## Design Files

The `design-files/` folder contains the physical design files for the OmniFish platform.

It is organized into:

* `bodies/` — fish-inspired body geometries
* `caudal-fins/` — caudal fin designs
* `robot/` — robot hardware and assembly components
* `setups/` — experimental setups and test fixtures

## Experimental Protocols

The `experimental-protocols/` folder contains procedures used during the project, including testing, calibration, and experimental workflows.

## Robot Control Code

The `robot-control-code/` folder contains the code used to actuate and control the OmniFish robot during experiments.

## Fish Specimen Analysis

The `fish-specimen-analysis/` folder contains files related to the biological reference data and specimen analysis used to inform the robotic body geometries.

## Software Requirements

Depending on the part of the repository being used, the following software may be required:

* MATLAB, for data analysis and `.mlx` live scripts
* Arduino IDE or compatible embedded development tools, for robot control code
* CFD software compatible with the included simulation files (OpenFoam)
* CAD software for viewing or modifying design files

## Example Workflow

1. Select or modify a fish-inspired body geometry from `design-files/bodies/`.
2. Select a caudal fin design from `design-files/caudal-fins/`.
3. Manufacture and assemble the robot using files in `design-files/robot/`.
4. Use the protocols in `experimental-protocols/` to run experiments.
5. Control the robot using code from `robot-control-code/`.
6. Analyze the collected data using scripts in `data-and-data-analysis/`.
7. Compare experimental results with CFD simulations in `cfd-simulation/`.

## License

This repository is licensed under the MIT License.
