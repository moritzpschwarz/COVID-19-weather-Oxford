library(tidyverse)
library(raster)
library(ff)

ras <- stack("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Data/climate_projections/t2m_daily_era5_2010-2019mean_Mar-Dec.nc")
ras <- rotate(ras)
ras <- resample(x = ras,y = raster(res = c(0.25,0.25)))
ras <- ras-273.15

cty <- rnaturalearthdata::countries110
pop <- raster("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Data/population/gpw_v4_population_count_rev11_2020_15_min.tif")

pop[is.na(pop)] <- 0
pp <- raster::extract(pop,cty,small=T,progress="text")
wtmn <- function(x,y) {if (length(x)>1 & sum(y)!=0) {weighted.mean(x,y,na.rm=TRUE)} else {mean(x,na.rm=TRUE)}}  # if country only covered by one cell, or if no population in aggregated grids, just report value of delta T in that cell


mat <- ff(vmode = "double",dim = c(ncell(ras),nlayers(ras)),filename = "stack_delaware.ffdata")
for (i in 1:nlayers(ras)){
  mat[,i] <- ras[[i]][]
  print(i)
}

ID_Raster <- raster(ras[[1]])
ID_Raster[] <- 1:ncell(ras[[1]])
ext_ID <- raster::extract(ID_Raster,cty,small=TRUE,progress="text")

final.TMEAN <- data.frame()
new.list <- list()
for (k in 1:306){  
  for (j in 1:177){
    date=k
    new.list[[j]] <- mat[as.numeric(ext_ID[[j]]),k]
  }
  #TMEAN <- mapply(wtmn,new.list,pp)
  intermediate.df <- data.frame(iso = cty$adm0_a3,
                                date = date,
                                TMEAN = mapply(wtmn,new.list,pp))
  final.TMEAN <- rbind(final.TMEAN,intermediate.df)
  print(k)
}
#names(final.TMEAN) <- c("iso","year","TMEAN") 
final.TMEAN$date <- as.Date(final.TMEAN$date,origin="2020-02-29")







ras <- stack("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Data/climate_projections/RH_daily_era5_2010-2019mean_Mar-Dec.nc")
ras <- rotate(ras)
ras <- resample(x = ras,y = raster(res = c(0.25,0.25)))

cty <- rnaturalearthdata::countries110
pop <- raster("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Data/population/gpw_v4_population_count_rev11_2020_15_min.tif")

pop[is.na(pop)] <- 0
pp <- raster::extract(pop,cty,small=T,progress="text")
wtmn <- function(x,y) {if (length(x)>1 & sum(y)!=0) {weighted.mean(x,y,na.rm=TRUE)} else {mean(x,na.rm=TRUE)}}  # if country only covered by one cell, or if no population in aggregated grids, just report value of delta T in that cell


mat <- ff(vmode = "double",dim = c(ncell(ras),nlayers(ras)),filename = "stack_delaware.ffdata")
for (i in 1:nlayers(ras)){
  mat[,i] <- ras[[i]][]
  print(i)
}

ID_Raster <- raster(ras[[1]])
ID_Raster[] <- 1:ncell(ras[[1]])
ext_ID <- raster::extract(ID_Raster,cty,small=TRUE,progress="text")

final.RH <- data.frame()
new.list <- list()
for (k in 1:306){  
  for (j in 1:177){
    date=k
    new.list[[j]] <- mat[as.numeric(ext_ID[[j]]),k]
  }
  #TMEAN <- mapply(wtmn,new.list,pp)
  intermediate.df <- data.frame(iso = cty$adm0_a3,
                                date = date,
                                RH = mapply(wtmn,new.list,pp))
  final.RH <- rbind(final.RH,intermediate.df)
  print(k)
}
final.RH$date <- as.Date(final.RH$date,origin="2020-02-29")







final.RH %>% 
  full_join(final.TMEAN,by=c("iso","date")) -> climate_projection


write.csv(x = climate_projection,"C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Data/climate_projections/climate_projections.csv",row.names=F)
