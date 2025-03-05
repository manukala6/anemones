## run iNEXT on each tile 

library(foreach)
library(doParallel)
library(iNEXT)
library(purrr)
library(stringr)

cl <- makeCluster(2)
registerDoParallel(cl)

# Adjust the input path here:

data_files <- list.files(
  path = "/fs/ess/PAS1032/CB/2024/anemone_maps/Incidence_freq_tiles_August/800km",
  pattern = ".csv",
  full.names = TRUE
)


do_par_800 <- foreach(i=data_files, .packages="iNEXT") %dopar% {
  raw_df <- read.csv(i, header = FALSE)
  raw_inc_freq <- as.list(raw_df[[1]])
  inc_freq <- as.numeric(raw_inc_freq)
  out <- iNEXT(inc_freq, q = c(0, 1, 2), datatype = "incidence_freq", endpoint = NULL)
}

save(do_par_800, file = "/fs/ess/PAS1032/CB/2024/anemone_maps/do_par_800.Rdata" )

load(file = "do_par_800.Rdata")

# first get a list of bare tile names, so the path doesn't mess us up, and strip the .csv suffix at the same time.

tile_names <- data_files |> 
  map_chr(basename) |> 
  map_chr(\(x) str_replace(x, ".csv", ""))

# assign a name attribute to each element in the do_par list object:

names(do_par_800) <- tile_names

# As a sanity check, do

# names(do_par_200)

# Now we assign a tile_name to the site field in each element of the do_par list object.

# For each different tile, modify the range in the for-loop (here 1:363) to as many elements 
# as are in the do_par list (which is equal to the length of the tile_names vector).

for(i in 1:363) {
  assign(do_par_800[[i]]$DataInfo$site, tile_names[i])
}

# This is the do_par object we pass on to the filtering step (not implemented in this script).

# As a sanity check, do:

# do_par[[1]]$DataInfo

# and you should see the new site name.

# specify name of output directory. This directory must first be created in Unix, e.g here I used
# $ mkdir inext_output_2_files
# (c.f. input path above in the list.files command)

out_path <- "/fs/ess/PAS1032/CB/2024/anemone_maps/800_output/"

# Now loop through the tile names and iNEXT outputs (do_par list elements) using the assign function, 
# and clean up the temporary variables as we go.

# Adjust the range from 1:2 to the range of the actual tiles you're processing, say 1:363.

for(i in 1:363) {
  assign("tmp", do_par_800[[i]])
  assign("name", str_c(tile_names[i], ".Rdata"))
  assign("out_name", str_c(out_path, name))
  save(tmp, file = out_name)
  rm(tmp, name, out_name)
}

### #Filter iNEXT output: remove gridcells with too poor samples
#keep gridcells with SRobs > 2 & T > 3 & U > Q1

# Step 1: Define the directory and load the list of files to keep
directory <- "/fs/ess/PAS1032/CB/2024/anemone_maps/SCpercentile_csvs/800/Incidence_frequency_filt_800km"
keep_list_file <- "/fs/ess/PAS1032/CB/2024/anemone_maps/SCpercentile_csvs/800/800_list"  # Text file with file names to keep, one per line (no .csv extensions)

# Step 2: Read the list of files to keep
files_to_keep <- readLines(keep_list_file)  # Reads the file as a character vector

# Step 3: Get the list of all .csv files in the directory
all_files <- list.files(path = directory, pattern = "\\.csv$", full.names = TRUE)

# Step 4: Extract the file names without extensions from the full paths
file_names <- sub("\\.csv$", "", basename(all_files))

# Step 5: Identify files NOT in the `files_to_keep` list
files_to_remove <- all_files[!file_names %in% files_to_keep]

# Step 6: Remove the unwanted files
file.remove(files_to_remove)

# Debugging: Optional print statements
cat("Files removed:\n", files_to_remove, "\n")


## estimate diversities standardized at given SC values

library(iNEXT)
library(foreach)
library(doParallel)

# Read the SC values file
d <- read.csv("/fs/ess/PAS1032/CB/2024/anemone_maps/SCpercentile_csvs/800/800SC_percentiles.csv")

# List the .csv files in the directory
data.files <- list.files(
  path = "/fs/ess/PAS1032/CB/2024/anemone_maps/SCpercentile_csvs/800/Incidence_frequency_filt_800km",
  pattern = "\\.csv$",
  full.names = TRUE
)

# Extract file names without extensions
defi <- sub(".*/", "", data.files)
defi <- sub("\\.csv$", "", defi)

# Ensure SC values match tile IDs
if (!"tile_id" %in% colnames(d)) {
  stop("The column `tile_id` is missing in the SC values file.")
}

# Define output directory and ensure it exists
output_dir <- "/fs/ess/PAS1032/CB/2024/anemone_maps/SCpercentile_csvs/800/output/"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}


for (j in seq_along(data.files)) {
  # Extract SC values for the current tile
  tile_name <- defi[j]
  SCvalue <- d[d$tile_id == tile_name, c("SC1", "SC2", "SC3", "SC4", "SC5", "SC6", "SC7")]
  
  # Handle missing SC values
  if (nrow(SCvalue) == 0 || any(is.na(SCvalue))) {
    stop(paste("SC values missing or invalid for tile:", tile_name))
  }
  
  # Load the tile's .csv file
  raw_data <- read.csv(data.files[j], header = FALSE)
  raw_inc_freq <- as.list(raw_data[[1]])
  inc_freq <- as.numeric(raw_inc_freq)
  
  # Check for invalid `inc_freq`
  if (length(inc_freq) == 0 || any(is.na(inc_freq))) {
    stop(paste("Invalid or missing data in inc_freq for tile:", tile_name))
  }
  
  # Set up parallel processing
  cl <- makeCluster(detectCores() - 2)
  registerDoParallel(cl)
  
  # Compute iNEXT for each SC value
  OUT <- foreach(k = seq_along(SCvalue), .packages = "iNEXT", .export = c("inc_freq")) %dopar% {
    tryCatch({
      sc_level <- SCvalue[1, k]
      estimateD(inc_freq, datatype = "incidence_freq", base = "coverage", level = sc_level)
    }, error = function(e) {
      paste("Error in SC level:", sc_level, "-", e$message)
    })
  }
  
  stopCluster(cl)
  
  # Save output for the current tile
  names(OUT) <- paste0("SC", seq_along(SCvalue))
  output_file <- file.path(output_dir, paste0("estimateD_", tile_name, ".RData"))
  save(OUT, file = output_file)
}

### combine all iNEXT outputs for posthoc analysis

# Load necessary libraries
library(dplyr)

# Define directories
inext_dir <- "/fs/ess/PAS1032/CB/2024/anemone_maps/combining_outputs/combining_outputs_800/original_800_output"
sc_dir <- "/fs/ess/PAS1032/CB/2024/anemone_maps/combining_outputs/combining_outputs_800/SC_output"
output_file <- "/fs/ess/PAS1032/CB/2024/anemone_maps/combining_outputs/combining_outputs_800/summary.csv"

# List all .Rdata files
inext_files <- list.files(path = inext_dir, pattern = "\\.Rdata$", full.names = TRUE)
sc_files <- list.files(path = sc_dir, pattern = "\\.RData$", full.names = TRUE)

# Initialize output matrix
output_matrix <- matrix(ncol = 29, nrow = 0)


# Process iNEXT files
### for (i in 1:length(inext_files)) {}
for (i in 1:8) {
  load(inext_files[i]) # Loads `list_element`
  
  # Extract tile ID from file name
  tile_id <- sub("\\.Rdata$", "", basename(inext_files[i]))
  
  # Extract iNEXT metrics
  T <- list_element[[1]]$DataInfo$T
  U <- list_element[[1]]$DataInfo$U
  obs.D0 <- list_element[[1]]$iNextEst[list_element[[1]]$iNextEst$method == "observed", "qD"][1]
  obs.D1 <- list_element[[1]]$iNextEst[list_element[[1]]$iNextEst$method == "observed", "qD"][2]
  obs.D2 <- list_element[[1]]$iNextEst[list_element[[1]]$iNextEst$method == "observed", "qD"][3]
  Q1 <- list_element[[1]]$DataInfo$Q1
  Q2 <- list_element[[1]]$DataInfo$Q2
  
  # Create vector of these values
  
  row_1_thru_8 <- c(tile_id, T, U, obs.D0, obs.D1, obs.D2, Q1, Q2)
  
  # Process corresponding SC file
  
  load(sc_files[i]) # Loads 'OUT'
  
  # create empty vector
  qD_values <- numeric()
  
  for(j in 1:7) {
    qD_values <- c(qD_values, OUT[[j]]$qD)
  }
  
  # Create complete row vector
  
  new_row <- c(row_1_thru_8, qD_values)
  
  # Append this row to output_matrix
  
  output_matrix <- rbind(output_matrix, new_row)
}

# remove rownames
rownames(output_matrix) <- NULL

# Define output columns
out_col <- c("id", "T", "U", "obs.D0", "obs.D1", "obs.D2", "Q1", "Q2",
             "SC1.D0", "SC1.D1", "SC1.D2", "SC2.D0", "SC2.D1", "SC2.D2",
             "SC3.D0", "SC3.D1", "SC3.D2", "SC4.D0", "SC4.D1", "SC4.D2",
             "SC5.D0", "SC5.D1", "SC5.D2", "SC6.D0", "SC6.D1", "SC6.D2",
             "SC7.D0", "SC7.D1", "SC7.D2")

# Coerce matrix to data frame

output_df <- data.frame(output_matrix)

colnames(output_df) <- out_col

write.csv(df, file = output_file, row.names = FALSE, na = "")


