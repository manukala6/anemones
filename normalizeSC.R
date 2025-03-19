# Script to transform RData output to CSV

load("iNEXT_output//do_par_200_named.Rdata")

result_df <- data.frame(
  id = names(do_par_named),
  T = sapply(do_par_named, function(x) x$DataInfo$T),
  U = sapply(do_par_named, function(x) x$DataInfo$U),
  S_obs = sapply(do_par_named, function(x) x$DataInfo$S.obs),
  Q1 = sapply(do_par_named, function(x) x$DataInfo$Q1),
  Q2 = sapply(do_par_named, function(x) x$DataInfo$Q2),
  SC = sapply(do_par_named, function(x) x$DataInfo$SC),
  SCs = I(lapply(do_par_named, function(x) x$iNextEst$SC))
)
SCs <- c(do_par_named$`0_17`$iNextEst$SC)
result_df$SCs <- sapply(result_df$SCs, function(x) paste(x, collapse = ";"))
write.csv(result_df, "200km_SC.csv", row.names=FALSE)
write.csv(result_df, "400km_SC.csv", row.names=FALSE)
write.csv(result_df, "600km_SC.csv", row.names=FALSE)
write.csv(result_df, "800km_SC.csv", row.names=FALSE)