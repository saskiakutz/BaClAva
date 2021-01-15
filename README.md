# Project name: Bayesian software

## Motivation:

Bayesian software **need a proper name!** is a software tool for clustering data from single-molecule localisation
microscopy (SMLM) with a Bayesian model. This tool offers the option to simulate SMLM-like localisations, do the
clustering of the localisation with a Bayesian model, and post-process single and multiple experiments. Hence, the user
will get non-user-biased clustering results in a reasonable amount of time.

## Table of content:

- [Installation](#Installation)
- [Usage](#Usage)
  - [Module 1: Simulation tool](##Module-1:-Simulation-tool)
  - [Module 2: Bayesian calculations](##Module-2:-Bayesian-calculations)
  - [Module 3: Bayesian postprocessing](##Module-3:-Bayesian-postprocessing)
- [Literature](#Literature)
- [Acknowledgement](#Acknowledgment)
- [Licencing](#Licencing)

# Installation:

# Usage:

The software offers three analysis modules. With the first module allows to simulated datasets. By uploading
localisation tables of these simulations or SMLM experiments, the second module calculates their cluster memberships and
Bayesian scores for the parameters' chosen range of the parameters. The calculations for the cluster plots and
additional cluster parameters take place in the third module. Each module can be used independently of the other two.

## Module 1: Simulation tool

The first module of the Bayesian software, the simulation tool, enables the user to simulate simple Gaussian-like
clusters. Upon starting the simulation tool, the user can adjust various simulation parameters, the number of datasets,
and the storage directory. The user can only start the simulation process after choosing a proper directory.

## Module 2: Bayesian calculations

In the second module, the clustering of either simulated or experimental data happens. The input data needs to be a
localisation table. For experimental data, this table can come from any localisation application ( e.g. SMAP or ?)  as
long as the table contains the 2D coordinates and a standard deviation of the localisations. Import files should be a
text or CSV file.

In the GUI, the user can choose their preferred clustering algorithm and other parameters. The radius and threshold
sequences are an essential part because they determine the Bayesian engine's parameter space. Note here that it has been
shown that Ripley's K based clustering and DBSCAN clustering are more sensitive to the parameter selection compared to
ToMATo. by displaying the top of a selected dataset, the GUI helps the user with the selection of the correct columns
for the analysis.

On Unix systems (any Linux or OS distribution) with multiple cores, the processing time can improve by parallelising the
clustering calculations. Note here that this option is not available on Windows machines.

## Module 3: Bayesian postprocessing

In the third module of this software for Bayesian clustering, various clustering parameters, e.i. the area of the
clusters or their density, are calculated for the best cluster parameter set. The GUI displays a scatter plot of the
clustered localisations and histograms for the different cluster parameters. This application can analyse a whole folder
of datasets with the same experimental conditions, therefore offers histograms summarising this condition. The software
can automatically store the data for these plots, but the user must tell the software whether it should automatically
create and store the corresponding scatterplots and histograms. Nonetheless, the GUI displays the plotted data which the
user can adjust by hand and store individually.

# Literature:

- Rubin-Delanchy, P., Burn, G., Griffié, J. et al. Bayesian cluster identification in single-molecule localization
  microscopy data. Nat Methods 12, 1072–1076 (2015). https://doi.org/10.1038/nmeth.3612
- Jeremy A Pike, Abdullah O Khan, Chiara Pallini, Steven G Thomas, Markus Mund, Jonas Ries, Natalie S Poulter, Iain B
  Styles, Topological data analysis quantifies biological nano-structure from single molecule localization microscopy,
  Bioinformatics, Volume 36, Issue 5, March 2020, Pages 1614–1621, https://doi.org/10.1093/bioinformatics/btz788

# Licencing:

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This project is licensed under the MIT License - see the LICENSE.md file for details
