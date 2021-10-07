
# setwd("C:/Users/USMG687637/Documents/050_projects/baseball")

print("loaded here")
library(here)

value = data.frame(Sys.time())

write.csv(value, here(paste0("data/", value, ".csv")))
