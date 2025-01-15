library(foreach)
library(doParallel)
library(iNEXT)


cl <- makeCluster(2)
registerDoParallel(cl)

data_files <- list.files(
  path = "/fs/ess/PAS1032/CB/2024/anemone_maps/test",
  pattern = ".csv",
  full.names = TRUE
)

do_par <- foreach(i = seq_along(data_files), .packages = "iNEXT") %dopar% {
  file_name <- data_files[i]
  raw_df <- read.csv(file_name, header = TRUE)
  raw_inc_freq <- as.list(raw_df[[1]])
  inc_freq <- as.numeric(raw_inc_freq)
  out <- iNEXT(inc_freq, q = c(0, 1, 2), se = TRUE, datatype = "incidence_freq")
  
  # Create a unique filename for each output
  save_name <- paste0("do_par_", i, ".RData")
  save(out, file = save_name)

  return(save_name)
} 



