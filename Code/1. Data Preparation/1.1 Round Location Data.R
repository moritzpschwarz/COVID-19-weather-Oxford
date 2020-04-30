library(tidyverse)

df <- readxl::read_excel("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Data/Locations_30042020.xlsx",col_names = c("province", "latitude","longitude","location_ID","country"))

df %>% 
  mutate(longitude = round(longitude,2),
         latitude = round(latitude,2)) %>% 
  write.csv(.,"C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Data/Locations_30042020_rounded.csv",row.names=F)
