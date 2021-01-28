# Project name: Bayesian software

## About Bayesian software:

Bayesian software **need a proper name!** is a software tool with a grafic user interface for clustering data from
single-molecule localisation microscopy (SMLM) with a Bayesian model based on the code published in Rubin-Delaunchy et
al. [[1]](#1). This tool offers the option to simulate SMLM-like localisations, do the clustering of the localisation
with a Bayesian model, and post-process single and multiple experiments. Hence, the user will get non-user-biased
clustering results in a reasonable amount of time.

## Table of content:

- [Installation](#Installation)
- [Software overview](#Software-overview)
  - [Module 1: Simulation tool](#Module-1-Simulation-tool)
  - [Module 2: Bayesian calculations](#Module-2-Bayesian-calculations)
  - [Module 3: Bayesian postprocessing](#Module-3-Bayesian-postprocessing)
  - [Data format](#Data-format)
- [Literature](#Literature)
- [Acknowledgement](#Acknowledgment)
- [Licencing](#Licencing)

# Installation:

**This part needs to be written soon**

# Software overview:

The software offers three analysis modules. With the first module allows to simulated datasets. By uploading
localisation tables of these simulations or SMLM experiments, the second module calculates their cluster memberships and
Bayesian scores for the parameters' chosen range of the parameters. The calculations for the cluster plots and
additional cluster parameters take place in the third module. Each module can be used independently.

## Module 1: Simulation tool

The first module of the Bayesian software, the simulation tool, enables the user to simulate simple Gaussian-like
clusters. Upon starting the simulation tool, the user can adjust various simulation parameters, the number of datasets,
and the storage directory. The user can only start the simulation process after choosing a proper directory. The tool
simulates the final localisations assuming that each molecule only appears ones and can be well localised. For each
simulation, the final localisation table with the 2D coordinates ('x', 'y'), the localisation's standard deviation ('
sd') and its label ('clusterID') are stored as a dataset ('data') in a hdf5 file.

## Module 2: Bayesian calculations

The clustering of either simulated or experimental data happens in the second module. The input data for this module
needs to be a localisation table. For experimental data and simulation run in other programs, this table can come from
any localisation application ( e.g. SMAP or ?)  as long as the table contains the 2D coordinates and the localisations'
standard deviations. The software can read in data from CSV and text files, but the program copies the data to a hdf5
file for further use.

In the GUI, the user can choose their preferred clustering algorithm (Ripley's K based clustering, DBSCAN,
ToMATo [[2]](#2)) and other parameters. The radius and threshold sequences, and their step width are essential because
they determine the Bayesian engine's parameter space. Note here that it has been shown that Ripley's K based clustering
and DBSCAN clustering are more sensitive to the parameter selection compared to ToMATo [[2]](#2). Instead of choosing
single datasets for the analysis, the user chooses an entire folder of datasets by picking a random dataset within this
folder. The GUI then helps the user select the correct columns for the analysis by displaying the selected dataset's
top. The program loops through the given radius and threshold sequences after the user presses the start button. For
each set of parameters, the program clusters the localisations and assigns to each localisation a (cluster) label. Then,
the software scores each calculated cluster result against a Gaussian model. The scores ('r_vs_thresh') and labels are
stored in the hdf5 file along with the dataset information.

On Unix systems (any Linux or OS distribution) with multiple cores, the processing time can improve by parallelising the
clustering calculations. Note here that this option is not available on Windows machines right now.

## Module 3: Bayesian postprocessing

In the third module of this software for Bayesian clustering, various clustering parameters, e.i. the area of the
clusters or their density, are calculated for the best cluster parameter set. This application can analyse a whole
folder of datasets with the same experimental conditions, therefore offers histograms summarising this condition. The
GUI displays a scatter plot clustered localisations of a random dataset in the folder and histograms for the different
cluster parameters. The software automatically stores the data for these plots in the hdf5 file. However, the user must
tell the software whether it should automatically create and store the corresponding scatterplots and histograms as png,
eps and pdf files. Since the GUI displays the plotted data, the user can adjust and store them themself.

## Data format

The Bayesian software uses the hdf5 file format to manage and store the datasets and the data gathered during the
Bayesian analysis. Each dataset has all its information stored in a single file, keeping the number of storage file to a
minimum. It is possible to access the data in the hdf5 file with any standard hdf5 library available. The following part
will explain the file structure for users interested in accessing the file with ofter software tools.

The localisation table is stored in 'data', and the column names are stored as its attribute 'colnames'. The labels for
the different parameter combinations are stored in the 'label'-group. The scores of the Bayesian analysis are stored in
a matrix called 'r_vs_thresh'. The columns are the radius sequence, and the rows are the threshold sequence. In the hdf5
file, these names are stored as attributes to the 'r_vs_thresh' dataset. The parameter set of the best cluster result
within the chosen parameter space is another attribute to this dataset called 'best'.

Since the selected parameters for simulations and the Bayesian analysis are the same for the entire folder, the software
stores the information stored in two separate files 'sim_parameters.txt' and 'run_config.txt', respectively.

The final histograms are stored in a separate folder named 'postprocessing'.

# Acknowledgement

**I need to write this part soon**

# Literature:

<a id='1'>[1]<a/>
Rubin-Delanchy, P., Burn, G., Griffié, J. et al. Bayesian cluster identification in single-molecule localization
microscopy data. Nat Methods 12, 1072–1076 (2015). https://doi.org/10.1038/nmeth.3612

<a id='2'>[2]<a/>
Jeremy A Pike, Abdullah O Khan, Chiara Pallini, Steven G Thomas, Markus Mund, Jonas Ries, Natalie S Poulter, Iain B
Styles, Topological data analysis quantifies biological nano-structure from single molecule localization microscopy,
Bioinformatics, Volume 36, Issue 5, March 2020, Pages 1614–1621, https://doi.org/10.1093/bioinformatics/btz788

# Licencing:

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This project is licensed under the MIT License - see the LICENSE.md file for details
