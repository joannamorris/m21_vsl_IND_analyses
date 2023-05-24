library(readr)

# read in data from both reading_type groups
n250_200_sem <- read_csv("m21_mea_200300_200_sem.csv")
n250_200_ort <- read_csv("m21_mea_200300_200_ort.csv")


# bind the two data frames
library(dplyr)
n250_erp<- bind_rows("semantic" = n250_200_sem, "orthographic" = n250_200_ort, .id = "reading_type")

# read in frequency data
stmfrq <- read_csv("m21_stmfrq_AB_BA.csv")
stmfrq$STIM <- toupper(stmfrq$STIM)
stmfrq$Base <- toupper(stmfrq$Base)

#join dataframes
n250_frq <- left_join(n250_erp, stmfrq, by="STIM")
n250_frq <- n250_frq |> select(!mlabel)



# separate fillers, words, and nonwords
n250_words <- n250_frq |> filter(binlabel1 == "CW")
n250_words <- n250_words|> select(!c(binlabel3, Stim.Type, NW.Type, Sublist, CB.Cond))

n250_nwords <- n250_frq |> filter(binlabel1 == "NW")
n250_nwords <- n250_nwords|> select(!c(SF, LogSF, BG_Mean, BG_Freq_By_Pos))

n250_fill <- n250_frq |> filter(binlabel1 == "FILL")
n250_fill <- n250_fill|> select(!c(binlabel3, affix, Sublist, CB.Cond))


#Separate electrode labels into multiple factors based on *anteriority* and *laterality*. `tidyr::separate` makes separating columns simple by allowing you to pass an integer index of split position, including negatively indexed from the end of the string.

library(tidyr)

#Separate electrode labels for words
n250_words <- n250_words |> 
  separate(chlabel, into = c('anteriority', 'laterality'), sep = -1, convert = TRUE)
n250_words <- n250_words |>                               
  mutate(laterality = replace(laterality, laterality == "Z", 0))  # Replacing "Z" value with 0
n250_words_subset <-  filter(n250_words, laterality == 0 & anteriority!= "O" |        
                                 laterality == 3 | laterality == 4) #Extract 5 x 3 matrix for analysis (F3 to P4)


#Separate electrode labels for non-words
n250_nwords <- n250_nwords |> 
  separate(chlabel, into = c('anteriority', 'laterality'), sep = -1, convert = TRUE)
n250_nwords <- n250_nwords |>                               
  mutate(laterality = replace(laterality, laterality == "Z", 0))  # Replacing "Z" value with 0
n250_nwords_subset <-  filter(n250_nwords, laterality == 0 & anteriority!= "O" |        
                               laterality == 3 | laterality == 4) #Extract 5 x 3 matrix for analysis (F3 to P4)

