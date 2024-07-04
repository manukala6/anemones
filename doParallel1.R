install.packages("foreach")
install.packages("doParallel")
install.packages("iNEXT")

library(foreach)
library(doParallel)
library(iNEXT)

setwd("/fs/ess/PAS1032/CB/2024/anemone_maps")

cl <- makeCluster(2)
registerDoParallel(cl)

data_files <- list.files(
  path = "/fs/ess/PAS1032/CB/2024/anemone_maps/test",
  pattern = ".csv",
  full.names = TRUE
)

do_par <- foreach(i=data_files, .packages="iNEXT") %dopar% {
  raw_df <- read.csv(i, header = TRUE)
  raw_inc_freq <- as.list(raw_df[[1]])
  inc_freq <- as.numeric(raw_inc_freq)
  out <- iNEXT(inc_freq, q=c(0,1,2), se=T, datatype = "incidence_freq")
}


sink("test1.txt")

print(do_par)

sink()
