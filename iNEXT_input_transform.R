install.packages("readr")
library(readr)
install.packages("dplyr")
library(dplyr)

setwd("/fs/ess/PAS1032/CB/2024/anemone_maps/test")

csv_files <- list.files(path = "/fs/ess/PAS1032/CB/2024/anemone_maps/test", pattern = "*.csv", full.names = TRUE)

print(csv_files)

large_list2 <- list()

for (csv_file in csv_files) { 
  
  data <- read_csv("/fs/ess/PAS1032/CB/2024/anemone_maps/test/10_1.csv", col_names = FALSE)
  header <- data[1, 1] 
  values <- as.integer(pull(data[-1, ], 1))
  large_list2[[as.character(header)]] <- values 
}

data.files	<- list.files(path="/fs/ess/PAS1032/CB/2024/anemone_maps/test", pattern=".csv", full.name=T)
print(data.files)

#out.names	<- paste("/fs/ess/PAS1032/CB/2024/anemone_maps/iNEXT_output", "iNEXT_", sub(".*/", "", data.files), sep="")
out.names <- list(test1="test1.Rdata", test2="test2.Rdata")

for(j in 1:length(data.files)){
  #load(data.files[j])
  #cl	<- makeCluster(detectCores()-2)
  #registerDoParallel(cl)
  OUT	<- foreach(i=1:length(large_list2), .packages="iNEXT") %dopar% {
    res	<- iNEXT(large_list2[[i]], q=c(0,1,2), se=T, datatype="incidence_freq", endpoint=NULL)
  }
  #stopCluster(cl)
  names(OUT)	<- names(large_list2)
  save(OUT, file=out.names[j])
}
