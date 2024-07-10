library(iNEXT)
library(foreach)
library(doParallel)

# Data files
data_files <- list.files(
  path = "inext_input",
  pattern = ".csv",
  full.names = TRUE
)

# Read in one CSV and see what happens
raw_df <- read.csv(data_files[1], header = TRUE)
raw_inc_freq <- as.list(raw_df[[1]])
inc_freq <- as.numeric(raw_inc_freq)
out <- iNEXT(inc_freq, q = 0, datatype = "incidence_freq", size = 160000)
