library(tidyverse)
library(extrafont)
library(RColorBrewer)
rm(list=ls())
df <- readr::read_csv("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Data/projections/SIR_projections_Apr15.csv")

df %>% 
  mutate(difference = climate_projection_adjusted - I) %>% 
  filter(ISO_A3 == "AUS",
         R0_input==3,
         type=="Unmitigated") %>% 
  select(N,t,S,S_new,I,difference,climate_projection_adjusted) %>%
  
  
  #summarise(difference = sum(difference)) %>% 
  ungroup %>% 
  
  gather(variable,value,-t) %>% 
  ggplot(aes(x=t,y=value,group=variable,color=variable))+
  geom_line()



# Map Plotting ------------------------------------------------------------

df %>% 
  
  group_by(ISO_A3,R0_input) %>% 
  mutate(difference = cumsum(climate_projection_adjusted)/cumsum(I)) %>% 
  summarise(mean(difference))
  ungroup() -> plot_df

st_as_sf(rnaturalearthdata::countries110) %>% 
  filter(!name == "Antarctica") %>% 
  rename(ISO_A3 = iso_a3) %>% 
  full_join(plot_df,by="ISO_A3") -> world 




max(c(max(world$diff_popshare,na.rm=T),abs(min(world$diff_popshare,na.rm=T)))) %>% 
  rep(2)-> limits
limits[1] <- limits[1]*-1


ggplot(data=world %>% filter(month==6),aes(fill=diff_Ishare)) +
  geom_sf()+
  
  coord_sf(crs = "+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs") + 
  scale_x_continuous(breaks = c(-180,-90,0,90,180),labels = function(x){paste0(x,"°")}) + 
  scale_y_continuous(breaks = c(-45,0,45),labels = function(x){paste0(x,"°")})+
  
  labs(title = "June Weather Effect")+
  #     subtitle = "Percentage Point effects on daily growth rates of confirmed COVID-19 cases.")+
  
  scale_fill_gradient2(
    high = "#af8dc3",
    mid = "#f7f7f7",
    low = "#7fbf7b",
    midpoint = 0,
    name= "Additional Share of Population affected\ncompared to Baseline",
    breaks = seq(from = -0.4,to = 0.4,by = 0.1),
    limits = limits,
    labels = c("-40%","-30%","-20%","-10%","0%","+10%","+20%","+30%","+40%")
  ) +
  
  theme(legend.position = "bottom",
        legend.key.height = unit(1,"cm"),
        legend.key.width = unit(2,"cm"),
        panel.grid.major = element_line(linetype = 2,color = "lightgrey",size=0.1),
        panel.background = element_blank(),
        axis.ticks = element_blank(),
        text = element_text(size=15,family="Georgia")) -> june



ggplot(data=world %>% filter(month == 10),aes(fill=Effect)) +
  geom_sf()+
  
  coord_sf(crs = "+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs") + 
  scale_x_continuous(breaks = c(-180,-90,0,90,180),labels = function(x){paste0(x,"Â°")}) + 
  scale_y_continuous(breaks = c(-50,0,50),labels = function(x){paste0(x,"Â°")})+
  
  labs(title = "October Weather Effect",
       subtitle = "Percentage Point effects on daily growth rates of confirmed COVID-19 cases.")+
  
  scale_fill_gradient2(
    high = "#af8dc3",
    mid = "#f7f7f7",
    low = "#7fbf7b",
    midpoint = 0,
    labels = c("-30%", "-20%", "-10%", "0%", "+10%","+20%"),
    limits = c(-0.3,0.2)
  )+
  
  theme(legend.position = "bottom",
        legend.key.height = unit(1,"cm"),
        legend.key.width = unit(2,"cm"),
        panel.grid.major = element_line(linetype = 2,color = "lightgrey",size=0.1),
        panel.background = element_blank(),
        axis.ticks = element_blank(),
        text = element_text(size=15,family="Georgia")) -> oct

ggsave(june,filename = "C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Figures/Map_Projection_June.pdf",device = cairo_pdf,height=6,width = 12)
ggsave(oct,filename = "C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Figures/Map_Projection_October.pdf",device = cairo_pdf,height=6,width = 12)
