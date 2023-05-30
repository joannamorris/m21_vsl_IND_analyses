library(readr)

# read in data from both reading_type groups
n250sem <- read_csv("m21_mea_200300_200_sem.csv", show_col_types = FALSE)
n250ort <- read_csv("m21_mea_200300_200_ort.csv", show_col_types = FALSE)


# bind the two data frames
library(dplyr)
n250 <- bind_rows("semantic" = n250sem, "orthographic" = n250ort, .id = "reading_type")


# read in pca data
pca <- read_csv("m21_spell_vocab_raw_z_pca.csv", show_col_types = FALSE)

# join dataframes
n250 <- n250 |> rename(SubjID = ERPset)
n250 <- n250 |> select(!mlabel)
n250 <- left_join(n250, pca, by = "SubjID")

# read in frequency data

#stmfrq <- read_csv("m21_stmfrq_AB_BA.csv")
#stmfrq$STIM <- toupper(stmfrq$STIM)
#stmfrq$Base <- toupper(stmfrq$Base)

frq_cw <- read_csv("cw_frq_2.csv")
frq_nw <- read_csv("nw_frq_2.csv")

frq_cw$STIM <- toupper(frq_cw$word)
frq_nw$STIM <- toupper(frq_nw$word)

# separate fillers, words, and nonwords
n250_wrds <- n250 |> filter(stimtype == "CW")
n250_wrds <- n250_wrds|> select(!c(complexity,reading_type))

n250_nwrds <- n250 |> filter(stimtype == "NW")
n250_nwrds <- n250_nwrds|> select(!c( complexity,reading_type))

n250_fill <- n250 |> filter(stimtype == "FILL")
n250_fill <- n250_fill|> select(!c(complexity,reading_type))

# join freq data 
n250_wrds_frq <- left_join(n250_wrds, frq_cw, by="STIM")
n250_nwrds_frq <- left_join(n250_nwrds, frq_nw, by="STIM")



# write function to replace missing logBF values with (a) zero and (b) the mean 
impute.bf <- function(x) replace(x, is.na(x), 0)  # If the missing values are NA
impute.bf.2 <- function(x) replace(x, is.na(x), mean(x, na.rm = TRUE))  # If the missing values are NA

#Divide participants based on median split of LogBF. 
n250_wrds_frq <- n250_wrds_frq |> mutate(logbf.imp = impute.bf(LogBF))
n250_nwrds_frq <- n250_nwrds_frq |> mutate(logbf.imp = impute.bf(LogBF))

n250_wrds_frq.median <- median(n250_wrds_frq$logbf.imp)
n250_wrds_frq <- n250_wrds_frq |>
  mutate(logbf.binary = case_when(
    logbf.imp < n250_wrds_frq.median ~ "Low",
    logbf.imp >= n250_wrds_frq.median ~ "High"
  ))

n250_nwrds_frq.median <- median(n250_nwrds_frq$logbf.imp)
n250_nwrds_frq <- n250_nwrds_frq |>
  mutate(logbf.binary = case_when(
    logbf.imp < n250_nwrds_frq.median ~ "Low",
    logbf.imp >= n250_nwrds_frq.median ~ "High"
  ))

n250_wrds_frq <- n250_wrds_frq |> mutate(logbf.imp.2 = impute.bf.2(LogBF))
n250_nwrds_frq <- n250_nwrds_frq |> mutate(logbf.imp.2 = impute.bf.2(LogBF))

n250_wrds_frq.median.2 <- median(n250_wrds_frq$logbf.imp.2)
n250_wrds_frq <- n250_wrds_frq |>
  mutate(logbf.binary.2 = case_when(
    logbf.imp.2 < n250_wrds_frq.median.2 ~ "Low",
    logbf.imp.2 >= n250_wrds_frq.median.2 ~ "High"
  ))

n250_nwrds_frq.median.2 <- median(n250_nwrds_frq$logbf.imp.2)
n250_nwrds_frq <- n250_nwrds_frq |>
  mutate(logbf.binary.2 = case_when(
    logbf.imp.2 < n250_nwrds_frq.median.2 ~ "Low",
    logbf.imp.2 >= n250_nwrds_frq.median.2 ~ "High"
  ))

# write function to replace zero and missing values with the mean 

impute.mean <- function(x) replace(x, is.na(x), mean(x, na.rm = TRUE))  # If the missing values are NA
impute.mean2 <- function(x) replace(x, x == 0, mean(x, na.rm = TRUE))   # If the missing values are 0


# impute voltage means words
n250_wrds_imp <- n250_wrds_frq |> 
  group_by(SubjID)|>
  mutate(value_imp = impute.mean2(value), .after = value)

# impute voltage means non-words
n250_nwrds_imp <- n250_nwrds_frq |> 
  group_by(SubjID)|>
  mutate(value_imp = impute.mean2(value), .after = value)






#Separate electrode labels into multiple factors based on *anteriority* and *laterality*. `tidyr::separate` makes separating columns simple by allowing you to pass an integer index of split position, including negatively indexed from the end of the string.

library(tidyr)

#Separate electrode labels for words
n250_wrds_imp <- n250_wrds_imp |> 
  separate(chlabel, into = c('anteriority', 'laterality'), sep = -1, convert = TRUE)
n250_wrds_imp <- n250_wrds_imp |>                               
  mutate(laterality = replace(laterality, laterality == "Z", 0))  # Replacing "Z" value with 0
n250_wrds_imp <-  filter(n250_wrds_imp, laterality == 0 & anteriority!= "O" |        
                                 laterality == 3 | laterality == 4) #Extract 5 x 3 matrix for analysis (F3 to P4)


#Separate electrode labels for non-words
n250_nwrds_imp <- n250_nwrds_imp |> 
  separate(chlabel, into = c('anteriority', 'laterality'), sep = -1, convert = TRUE)
n250_nwrds_imp <- n250_nwrds_imp |>                               
  mutate(laterality = replace(laterality, laterality == "Z", 0))  # Replacing "Z" value with 0
n250_nwrds_imp <-  filter(n250_nwrds_imp, laterality == 0 & anteriority!= "O" |        
                               laterality == 3 | laterality == 4) #Extract 5 x 3 matrix for analysis (F3 to P4)


# Format Words

n250_wrds_imp$anteriority <- case_match(n250_wrds_imp$anteriority,
                                                "F" ~ "Frontal",
                                                "C" ~ "Central",
                                                "P" ~ "Parietal")
  
n250_wrds_imp$laterality <- case_match(n250_wrds_imp$laterality,
                                            "0" ~ "Midline",
                                            "3" ~ "Left",
                                            "4" ~ "Right")

n250_wrds_imp$familysize_binary <- case_match(n250_wrds_imp$familysize_binary,
                                           "S" ~ "Small",
                                           "L" ~ "Large")

# Format Nonwords

n250_nwrds_imp$anteriority <- case_match(n250_nwrds_imp$anteriority,
                                            "F" ~ "Frontal",
                                            "C" ~ "Central",
                                            "P" ~ "Parietal")

n250_nwrds_imp$laterality <- case_match(n250_nwrds_imp$laterality,
                                           "0" ~ "Midline",
                                           "3" ~ "Left",
                                           "4" ~ "Right")

n250_nwrds_imp$familysize_binary <- case_match(n250_nwrds_imp$familysize_binary,
                                          "S" ~ "Small",
                                          "L" ~ "Large")






# write resulting files to disc

write_csv(n250_wrds_imp, "m21_n250_frq_words_impvalue.csv")
write_csv(n250_nwrds_imp, "m21_n250_frq_nwords_impvalue.csv")
