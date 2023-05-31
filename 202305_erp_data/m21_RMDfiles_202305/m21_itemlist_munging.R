

library(readr)
library(dplyr)
m21_n250_frq_nwords_impvalue <- read_csv("Documents/GIT/m21_analyses_202306_aov/m21_n250_frq_nwords_impvalue.csv")

itemlist_nwords <- m21_n250_frq_nwords_impvalue |> select(c("STIM", "logbf.binary", "logbf.binary.2")) |> 
