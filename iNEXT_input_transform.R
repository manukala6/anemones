install.packages("readr")
library(readr)
install.packages("dplyr")
library(dplyr)
library(iNEXT)

setwd(getwd())
csv_folder <- paste0(getwd(), "/largelisttest")
out_folder <- paste0(getwd(), "/iNEXT_output")

csv_files <- list.files(
  path = (csv_folder),
  pattern = "*.csv", 
  full.names = TRUE
)

print(csv_files)

large_list2 <- list()

for (csv_file in csv_files) { 
  data <- read_csv(csv_file, col_names = FALSE)
  header <- data[1, 1] 
  values <- as.integer(pull(data[-1, ], 1))
  large_list2[[as.character(header)]] <- values
}

data.files	<- list.files(path=csv_folder, pattern=".csv", full.name=T)
print(data.files)

out.names	<- paste(out_folder, "iNEXT_", sub(".*/", "", data.files), sep="")

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
