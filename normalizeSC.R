load("iNEXT_output//do_par_200_named.Rdata")

result_df <- data.frame(
  id = names(do_par_named),
  SC = sapply(do_par_named, function(x) x$DataInfo$SC)
)

write.csv(result_df, "200km_SC.csv", row.names=FALSE)
