###############################
# data processing/wrangling script
###############################
#this script loads the raw data, processes and cleans it 
#and saves it as Rds file in the processed_data folder


###############################
#load needed packages. 
###############################
# make sure they are installed.
library(dplyr) #for data processing
library(tidyr) #for data processing
library(here) #to set paths

################
# load data 
################
#path to data
#note the use of the here() package and not absolute paths
data_location <- here::here("data","raw_data","SympAct_Any_Pos.Rda")

# note that for functions that come from specific packages (instead of base R)
# I often specify both package and function like so
# package::function() that's not required one could just call the function
# specifying the package makes it clearer where the function "lives",
# but it adds typing. You can do it either way.

# load data
rawdata <- readRDS(data_location)

#take a look at variables of the data frame
colnames(rawdata)


################
# clean data 
################

################
#remove variables we don't want
#note that in this data frame, the ones we don't want are at the beginning and end, so we could have also removed
#by location (i.e., indexing with numbers). 
# But that's not as robust, if you get an update on the data and someone reorganized the data, your code will
# produce the wrong results, and you might not even know it. Removal by name is generally safer.
# If someone renames and the column doesn't exist, you should get an error message, which is much better than code that still works
# but does the wrong thing.
d1 <- rawdata %>% dplyr::select(-contains(c("Score","Total","FluA","FluB","Dxname","Activity","Unique.Visit")))


################
#remove NA
d2 <- d1 %>% tidyr::drop_na()

################
# remove yes/no variables for those where we have multiple categories
# they happen to end with either YN or YN2, so this is an easy way to remove them
d3 <- d2 %>% dplyr::select(-ends_with(c("YN","YN2"))) 

################
# order the variables that have None/Mild/Moderate/Severe
# I couldn't get forcats to work, so doing it the base R way
d3$Weakness <- factor(d3$Weakness, levels = c("None","Mild","Moderate","Severe"), ordered = TRUE)
d3$CoughIntensity <- factor(d3$CoughIntensity, levels = c("None","Mild","Moderate","Severe"), ordered = TRUE)
d3$Myalgia <- factor(d3$Myalgia, levels = c("None","Mild","Moderate","Severe"), ordered = TRUE)

################
# remove binary variables that have <50 in one category
# look at summary to identify variablesm 
summary(d3)
# manually remove. Could also be done automated, but I like seeing what I/the code is doing.
d4 <- d3 %>% dplyr::select(-contains(c("Vision","Hearing")))

# location to save file
save_data_location <- here::here("data","processed_data","processeddata.rds")

# save cleaned and pre-processed file
saveRDS(d4, file = save_data_location)


