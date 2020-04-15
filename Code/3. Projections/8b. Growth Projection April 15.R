rm(list=ls())
library(tidyverse)
library(lubridate)
library(extrafont)
library(Cairo)
library(RColorBrewer)
library(sf)
library(viridis)
library(arules)

readxl::read_excel("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/stata/temp/Baseline_Model.xlsx") %>% 
  gather(variable,value,-...1) %>% 
  rename(estimate=...1) %>% 
  filter(estimate=="b") -> coefficients


climate <- readr::read_csv("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Data/climate_projections/climate_projections.csv")

jetlag <- function(data, variable, n=10, variable_name = ""){
  variable <- enquo(variable)
  
  indices <- seq_len(n)
  quosures <- purrr::map( indices, ~quo(lag(!!variable, !!.x)) ) %>% 
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
  jetlag(., TMEAN, 15,variable_name = "TMEAN") %>% 
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
  filter(iso %in% c("USA","AUS","GBR","CHN")) -> plot_df


iso.labs <- c("Australia","China","United Kingdom","United States")
names(iso.labs) <- c("AUS","CHN","GBR","USA")


ggplot(plot_df,aes(x=date,y=Effect,group=iso,fill=iso))+
  geom_area() +
  geom_hline(aes(yintercept = 0))+
  
  facet_wrap(~iso,labeller = labeller(iso=iso.labs)) +
  
  labs(
    #title = "Projections of Daily Growth Impact Rate of Weather on 2019-nCovid",
       #subtitle = "Using 2010-2019 Daily Mean Climatology derived from ERA5.",
       y="Percentage Point Effect on Daily Growth in Reported Cases",
       x="") + 
  scale_fill_brewer(palette = "RdBu")+
  scale_y_continuous(labels = scales::percent_format(accuracy = 1))+
  
  theme(legend.position = "none",
        strip.background = element_blank(),
        plot.background = element_blank(),
        panel.background = element_blank(),
        panel.spacing = unit(0.5,"cm"),
        plot.subtitle = element_text(size=10),
        text = element_text(family = "Georgia",size=15)) -> plot


ggsave(
  plot = plot,
  filename = "C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Figures/Growth Rate Projections.pdf",
  device = cairo_pdf,
  height = 8,
  width = 8
)


ggsave(
  plot = plot,
  filename = "C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Figures/Growth Rate Projections.jpg",
  height = 8,
  width = 8
)











# 
# 
# 
# 
# 
# 
# effect %>% 
#   group_by(iso,month(date)) %>% 
#   summarise(Effect = mean(Effect)) -> monthly_effects
#   
# 
# #monthly_effects %>% filter(iso %in% c("USA","AUT","GBR","AUS","CHN")) %>% View
# 
# 
# st_as_sf(rnaturalearthdata::countries50) %>% 
#   filter(!NAME_EN == "Antarctica") %>% 
#   full_join(monthly_effects %>% 
#               rename(ISO_A3 = iso,
#                      month = `month(date)`),by="ISO_A3") -> world 
# 
# 
# # Plotting ----------------------------------------------------------------
# breaks <- seq(from = -0.3,to = 0.2, by=0.1)
# 
# # plot_df <- world %>% 
# #   mutate(Effect = as.factor(discretize(Effect, 
# #                                        include.lowest = T,
# #                                        breaks = breaks,
# #                                        method = "fixed",
# #                                        labels = scales::percent(seq(from = -0.2,to = 0.2, by=0.1)))))
# 
# 
# ggplot(data=world %>% filter(month == 6),aes(fill=Effect)) +
#   geom_sf()+
#   
#   coord_sf(crs = "+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs") + 
#   scale_x_continuous(breaks = c(-180,-90,0,90,180),labels = function(x){paste0(x,"°")}) + 
#   scale_y_continuous(breaks = c(-45,0,45),labels = function(x){paste0(x,"°")})+
#   
#   labs(title = "June Weather Effect",
#        subtitle = "Percentage Point effects on daily growth rates of confirmed COVID-19 cases.")+
#   
#   scale_fill_gradient2(
#     high = "#af8dc3",
#     mid = "#f7f7f7",
#     low = "#7fbf7b",
#     midpoint = 0,
#     labels = c("-30%", "-20%", "-10%", "0%", "+10%","+20%"),
#     limits = c(-0.3,0.2)
#   )+
#   
#   theme(legend.position = "bottom",
#         legend.key.height = unit(1,"cm"),
#         legend.key.width = unit(2,"cm"),
#         panel.grid.major = element_line(linetype = 2,color = "lightgrey",size=0.1),
#         panel.background = element_blank(),
#         axis.ticks = element_blank(),
#         text = element_text(size=15,family="Georgia")) -> june
#   
#   
#   
# ggplot(data=world %>% filter(month == 10),aes(fill=Effect)) +
#   geom_sf()+
#   
#   coord_sf(crs = "+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs") + 
#   scale_x_continuous(breaks = c(-180,-90,0,90,180),labels = function(x){paste0(x,"°")}) + 
#   scale_y_continuous(breaks = c(-50,0,50),labels = function(x){paste0(x,"°")})+
#   
#   labs(title = "October Weather Effect",
#        subtitle = "Percentage Point effects on daily growth rates of confirmed COVID-19 cases.")+
#   
#   scale_fill_gradient2(
#     high = "#af8dc3",
#     mid = "#f7f7f7",
#     low = "#7fbf7b",
#     midpoint = 0,
#     labels = c("-30%", "-20%", "-10%", "0%", "+10%","+20%"),
#     limits = c(-0.3,0.2)
#   )+
#   
#   theme(legend.position = "bottom",
#         legend.key.height = unit(1,"cm"),
#         legend.key.width = unit(2,"cm"),
#         panel.grid.major = element_line(linetype = 2,color = "lightgrey",size=0.1),
#         panel.background = element_blank(),
#         axis.ticks = element_blank(),
#         text = element_text(size=15,family="Georgia")) -> oct
# 
# ggsave(june,filename = "C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Figures/Map_Projection_June.pdf",device = cairo_pdf,height=6,width = 12)
# ggsave(oct,filename = "C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Figures/Map_Projection_October.pdf",device = cairo_pdf,height=6,width = 12)











# ggplot(data=world) +
#   geom_sf()+
#   coord_sf(crs = "+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000 +ellps=GRS80 +units=m +no_defs ")



# common_scale <- scale_fill_continuous(low="#2166AC",high="#B2182B", 
#                                      breaks = breaks,
#                                      limits = c(-0.3,0.15),
#                                      labels = scales::percent_format(accuracy = 1),
#                                      name = "")

# common_scale <- scale_fill_manual(values = brewer.pal(length(breaks)-1,"RdYlBu"), 
#                                   #breaks = breaks,
#                                   limits = c(-0.3,0.15),
#                                   labels = scales::percent_format(accuracy = 1),
#                                   name = "")
