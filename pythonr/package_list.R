# Title     : Package list
# Objective : loading all relevant packages
# Created by: Saskia Kutz

if (!require(pacman, quietly = TRUE))
  install.packages("pacman")

pacman::p_load_gh("saskiakutz/RSMLM")
pacman::p_load(
  "ggpubr",
  "igraph",
  "RSMLM",
  "tictoc",
  "geometry",
  "doParallel",
  "data.table",
  "plyr",
  "ggforce",
  "tidyverse",
  "rhdf5",
  "grid"
)

# if RSMLM cannot be installed via pacman, run the following part:

# if (!require(devtools))
#   install.packages("devtools")
# if (!require(RSMLM))
#   pacman::p_load("devtools")

