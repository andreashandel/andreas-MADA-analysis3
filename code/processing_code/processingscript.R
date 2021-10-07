###############################
# processing script
#
#this script loads the raw data, processes and cleans it 
#and saves it as Rds file in the processed_data folder

#load needed packages. make sure they are installed.
library(readxl) #for loading Excel files
library(dplyr) #for data processing
library(tidyr) #for data processing
library(here) #to set paths

#path to data
#note the use of the here() package and not absolute paths
data_location <- here::here("data","raw_data","SympAct_Any_Pos.Rda")

#load data. 
#note that for functions that come from specific packages (instead of base R)
# I often specify both package and function like so
#package::function() that's not required one could just call the function
#specifying the package makes it clearer where the function "lives",
#but it adds typing. You can do it either way.
rawdata <- readRDS(data_location)

#take a look at variables of the data frame
colnames(rawdata)

#remove those variables we don't want
#note that in this data frame, the ones we don't want are at the beginning and end, so we could have also removed
#by location. But that's not as robust, if you get an update on the data and someone reorganized the data, your code will
#produce the wrong results. And you might not even know it. Removal by name is generally safer.
#If someone renames and the column doesn't exist, you should get an error message, which is much better than code that still works
#but does the wrong thing.
d1 <- rawdata %>% dplyr::select(-contains(c("Score","Total","FluA","FluB","Dxname","Activity","Unique.Visit")))


#remove NA
d2 <- d1 %>% tidyr::drop_na()

# location to save file
save_data_location <- here::here("d2","processed_data","processeddata.rds")

saveRDS(processeddata, file = save_data_location)


