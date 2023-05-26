library(readr)

# read in data from both reading_type groups
n250sem <- read_csv("m21_mea_200300_200_sem.csv", show_col_types = FALSE)
n250ort <- read_csv("m21_mea_200300_200_ort.csv", show_col_types = FALSE)


# bind the two data frames
library(dplyr)
n250 <- bind_rows("semantic" = n250sem, "orthographic" = n250ort, .id = "reading_type")

# read in frequency data
stmfrq <- read_csv("m21_stmfrq_AB_BA.csv")
stmfrq$STIM <- toupper(stmfrq$STIM)
stmfrq$Base <- toupper(stmfrq$Base)

# join dataframes
n250 <- left_join(n250, stmfrq, by="STIM")
n250 <- n250 |> select(!mlabel)
n250 <- n250 |> rename(SubjID = ERPset)

# read in pca data
pca <- read_csv("m21_spell_vocab_raw_z_pca.csv")

# join dataframes
n250 <- left_join(n250, pca, by = "SubjID")

# separate fillers, words, and nonwords
n250_wrds <- n250 |> filter(stimtype == "CW")
n250_wrds <- n250_wrds|> select(!c(complexity, Stim.Type, NW.Type, Sublist, CB.Cond, reading_type, Lexicality))

n250_nwrds <- n250 |> filter(stimtype == "NW")
n250_nwrds <- n250_nwrds|> select(!c(SF, LogSF, BG_Mean, BG_Freq_By_Pos, reading_type, Lexicality))

n250_fill <- n250 |> filter(stimtype == "FILL")
n250_fill <- n250_fill|> select(!c(complexity, affix, Sublist, CB.Cond, reading_type, Lexicality))


#Separate electrode labels into multiple factors based on *anteriority* and *laterality*. `tidyr::separate` makes separating columns simple by allowing you to pass an integer index of split position, including negatively indexed from the end of the string.

library(tidyr)

#Separate electrode labels for words
n250_wrds <- n250_wrds |> 
  separate(chlabel, into = c('anteriority', 'laterality'), sep = -1, convert = TRUE)
n250_wrds <- n250_wrds |>                               
  mutate(laterality = replace(laterality, laterality == "Z", 0))  # Replacing "Z" value with 0
n250_wrds <-  filter(n250_wrds, laterality == 0 & anteriority!= "O" |        
                                 laterality == 3 | laterality == 4) #Extract 5 x 3 matrix for analysis (F3 to P4)


#Separate electrode labels for non-words
n250_nwrds <- n250_nwrds |> 
  separate(chlabel, into = c('anteriority', 'laterality'), sep = -1, convert = TRUE)
n250_nwrds <- n250_nwrds |>                               
  mutate(laterality = replace(laterality, laterality == "Z", 0))  # Replacing "Z" value with 0
n250_nwrds <-  filter(n250_nwrds, laterality == 0 & anteriority!= "O" |        
                               laterality == 3 | laterality == 4) #Extract 5 x 3 matrix for analysis (F3 to P4)


# Format Words

n250_wrds$anteriority <- case_match(n250_wrds$anteriority,
                                                "F" ~ "Frontal",
                                                "C" ~ "Central",
                                                "P" ~ "Parietal")
  
n250_wrds$laterality <- case_match(n250_wrds$laterality,
                                            "0" ~ "Midline",
                                            "3" ~ "Left",
                                            "4" ~ "Right")

n250_wrds$familysize_binary <- case_match(n250_wrds$familysize_binary,
                                           "S" ~ "Small",
                                           "L" ~ "Large")

# Format Nonwords

n250_nwrds$anteriority <- case_match(n250_nwrds$anteriority,
                                            "F" ~ "Frontal",
                                            "C" ~ "Central",
                                            "P" ~ "Parietal")

n250_nwrds$laterality <- case_match(n250_nwrds$laterality,
                                           "0" ~ "Midline",
                                           "3" ~ "Left",
                                           "4" ~ "Right")

n250_nwrds$familysize_binary <- case_match(n250_nwrds$familysize_binary,
                                          "S" ~ "Small",
                                          "L" ~ "Large")

n250_nwrds$complexity <- case_match(n250_nwrds$complexity,
                                           "COMP" ~ "Complex",
                                           "SIMP" ~ "Simple")

# write function to replace missing values with the mean 

impute.mean <- function(x) replace(x, is.na(x), mean(x, na.rm = TRUE))  # If the missing values are NA
impute.mean2 <- function(x) replace(x, x == 0, mean(x, na.rm = TRUE))   # If the missing values are 0


# impute means words
n250_wrds_imp <- n250_wrds |> 
  group_by(SubjID)|>
  mutate(value_imp = impute.mean2(value), .after = value)

# impute means non-words
n250_nwrds_imp <- n250_nwrds |> 
  group_by(SubjID)|>
  mutate(value_imp = impute.mean2(value), .after = value)


# write resulting files to disc

write_csv(n250_wrds_imp, "m21_n250_frq_words_impvalue.csv")
write_csv(n250_nwrds_imp, "m21_n250_frq_nwords_impvalue.csv")
