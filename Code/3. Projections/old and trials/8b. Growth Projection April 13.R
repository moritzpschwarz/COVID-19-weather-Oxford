rm(list=ls())
library(tidyverse)
library(lubridate)
library(extrafont)
library(Cairo)
library(RColorBrewer)
library(sf)
library(viridis)

readxl::read_excel("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/stata/temp/Baseline_Model.xlsx") %>% 
  gather(variable,value,-...1) %>% 
  rename(estimate=...1) %>% 
  filter(estimate=="b") -> coefficients


climate <- readr::read_csv("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Data/climate_projections/climate_projections.csv")

jetlag <- function(data, variable, n=10, variable_name = ""){
  variable <- enquo(variable)
  
  indices <- seq_len(n)
  quosures <- map( indices, ~quo(lag(!!variable, !!.x)) ) %>% 
    #set_names(paste0(sprintf("L%02d.", indices),variable_name))
    set_names(paste0("L",indices,".",variable_name))
  mutate( data, !!!quosures)
}


climate %>% 
  filter(date<"2020-03-31") %>% 
  group_by(iso) %>% 
  summarise(TMEAN_March = mean(TMEAN),
            RH_March = mean(RH)) %>% 
  ungroup -> climate_base

climate %>% 
  full_join(climate_base,by="iso") %>% 
  mutate(TMEAN = TMEAN - TMEAN_March,
         RH = RH - RH_March) %>% 
  group_by(iso) %>% 
  jetlag(., TMEAN, 21,variable_name = "TMEAN") %>% 
  ungroup %>% 
  arrange(iso,date) %>% 
  select(-TMEAN_March,-RH_March,-RH) %>% 
  na.omit() -> ready


ready %>% 
  select(contains("TMEAN")) %>% 
  "*"(coefficients %>% filter(!variable=="_cons") %>% pull(value)) %>% 
  rowSums() %>% 
  cbind(ready,Effect=.) -> effect

effect %>% 
  group_by(iso,month(date)) %>% 
  summarise(Effect = mean(Effect)) -> monthly_effects
  

#monthly_effects %>% filter(iso %in% c("USA","AUT","GBR","AUS","CHN")) %>% View


st_as_sf(rnaturalearthdata::countries50) %>% 
  filter(!NAME_EN == "Antarctica") %>% 
  full_join(monthly_effects %>% 
              rename(ISO_A3 = iso,
                     month = `month(date)`),by="ISO_A3") -> world 


# Plotting ----------------------------------------------------------------

theme_settings <- theme(panel.background = element_blank(),
                        legend.position = "bottom",
                        legend.key.height = unit(1,"cm"),
                        legend.key.width = unit(2,"cm"),
                        legend.title = element_text(title.pos)
                        axis.title.x = element_blank(),
                        axis.text = element_blank(),
                        axis.ticks = element_blank(),
                        text = element_text(size=15,family="Georgia"))


breaks <- seq(from = -0.3,to = 0.2, by=0.1)

# common_scale <- scale_fill_continuous(low="#2166AC",high="#B2182B", 
#                                      breaks = breaks,
#                                      limits = c(-0.3,0.15),
#                                      labels = scales::percent_format(accuracy = 1),
#                                      name = "")

common_scale <- scale_fill_manual(values = brewer.pal(length(breaks)-1,"RdYlBu"), 
                                      #breaks = breaks,
                                      limits = c(-0.3,0.15),
                                      labels = scales::percent_format(accuracy = 1),
                                      name = "")



plot_df <- world %>% 
  mutate(Effect = as.factor(discretize(Effect, 
                                       include.lowest = T,
                                       breaks = breaks,
                                       method = "fixed",
                                       labels = scales::percent(seq(from = -0.2,to = 0.2, by=0.1)))))


ggplot(data=plot_df %>% filter(month == 7),aes(fill=Effect)) +
  geom_sf()+
  coord_sf(crs = "+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs") + 
  
  labs(x="",y="",title = "July Weather Effect",subtitle = "Percentage Point effects on daily growth rates of confirmed COVID-19 cases.")+
  
  theme_settings + 
  scale_fill_manual(values = brewer.pal(length(breaks),"RdYlBu")) -> jul
  
  
  
  

ggplot(data=plot_df %>% filter(month == 12),aes(fill=Effect)) +
  geom_sf()+
  coord_sf(crs = "+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs") + 
  
  labs(x="",y="",title = "December Weather Effect",subtitle = "Percentage Point effects on daily growth rates of confirmed COVID-19 cases.")+

  theme_settings + 
  scale_fill_manual(values = brewer.pal(length(breaks),"RdYlBu")) -> dec


ggsave(jul,filename = "C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Figures/Map_Projection_July.pdf",device = cairo_pdf,height=8,width = 12)
ggsave(dec,filename = "C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Figures/Map_Projection_December.pdf",device = cairo_pdf,height=8,width = 12)

# ggplot(data=world) +
#   geom_sf()+
#   coord_sf(crs = "+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000 +ellps=GRS80 +units=m +no_defs ")