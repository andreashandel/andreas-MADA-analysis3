# Overview

Example of a data analysis. 



# Data 

The data comes from [this paper](https://datadryad.org/stash/dataset/doi:10.5061/dryad.51c59zw4v). 

The specific data file we use as starting point is `SympAct_Any_Pos.Rda`, which is in the `raw_data` folder.

The processed data is stored in the `processed_data` folder.



# Code

The file `processingscript.R` processes/cleans the raw data and stores the clean data in the `processed_data` folder. It should be run first.

The file `analysisscript.Rmd` performs an analysis on the cleaned data.

The results are shown as part of the Rmd/html file. No external files are created.



# Notes

Some of the tuning functions in the analysis code take a while to run.