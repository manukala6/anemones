install.packages("readr")
library(readr)
install.packages("dplyr")
library(dplyr)

setwd("/fs/ess/PAS1032/CB/2024/anemone_maps/test")

csv_files <- list.files(path = "/fs/ess/PAS1032/CB/2024/anemone_maps/test", pattern = "*.csv", full.names = TRUE)

print(csv_files)

large_list2 <- list()

for (csv_file in csv_files) { 
  
  data <- read_csv("/fs/ess/PAS1032/CB/2024/anemone_maps/test/0_0.csv", col_names = FALSE)
  header <- data[1, 1] 
  values <- as.integer(pull(data[-1, ], 1))
  large_list2[[as.character(header)]] <- values 
}
