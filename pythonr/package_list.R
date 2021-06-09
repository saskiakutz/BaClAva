# Title     : Package list
# Objective : loading all relevant packages
# Created by: Saskia Kutz
# Created on: 2021-04-16

if (!require(pacman, quietly = TRUE))
  install.packages("pacman")
# if (!require(devtools))
#   install.packages("devtools")
# if (!require(RSMLM))
#   pacman::p_load("devtools")
#   install_github("lucabaronti/RSMLM")
pacman::p_load_gh("saskiakutz/RSMLM")
pacman::p_load(
  "pryr",
  "ggpubr",
  "splancs",
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

