library(tidyverse)
library(extrafont)
library(RColorBrewer)
library(sf)
rm(list=ls())
df <- readr::read_csv("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Data/projections/SIR_projections_Apr15.csv")

df %>% 
  mutate(difference = climate_projection_adjusted - I) %>% 
  filter(ISO_A3 == "AUS",
         R0_input==2.7,
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
  summarise(difference = mean(difference)-1) %>% 
  ungroup() %>% 
  filter(R0_input == 3) -> plot_df

st_as_sf(rnaturalearthdata::countries110) %>% 
  filter(!name == "Antarctica") %>% 
  rename(ISO_A3 = iso_a3) %>% 
  full_join(plot_df,by="ISO_A3") -> world 




max(c(max(world$difference,na.rm=T),abs(min(world$difference,na.rm=T)))) %>% 
  rep(2)-> limits
limits[1] <- limits[1]*-1


ggplot(data=world,aes(fill=difference,color="")) +
  geom_sf()+
  
  coord_sf(crs = "+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs") + 
  scale_x_continuous(breaks = c(-180,-90,0,90,180),labels = function(x){paste0(x,"°")}) + 
  scale_y_continuous(breaks = c(-45,0,45),labels = function(x){paste0(x,"°")})+
  
  #labs(title = "June Weather Effect")+
  #     subtitle = "Percentage Point effects on daily growth rates of confirmed COVID-19 cases.")+
  labs(caption = paste0("Maximum: ",scales::percent(round(max(world$difference,na.rm=T),2),accuracy = 1),"\nMinimum: ",scales::percent(round(min(world$difference,na.rm=T),2),accuracy = 1)))+
  
  scale_fill_gradient2(
    
    high = rgb(red = 64,0,64,maxColorValue = 255),
    low = rgb(0,128,0,maxColorValue = 255),
    mid = rgb(255,255,255,maxColorValue = 255),
    na.value = rgb(255,255,128,maxColorValue = 255),
    #high = "#af8dc3",
    #mid = "#f7f7f7",
    #low = "#7fbf7b",
    midpoint = 0,
    name= "Mean Change in\nConfirmed Cases to Baseline",
    limits = c(-1,max(world$difference,na.rm=T)),
    labels = c("-100%","-50%","0%","+50%",">+100%","+150%")
  ) +
  
  scale_colour_manual(values="black") +              
  guides(colour = guide_legend("No data", override.aes = list(colour = "black",fill = rgb(255, 255, 128, maxColorValue = 255))))+

  theme(legend.position = "bottom",
        legend.title = element_text(margin = margin(r=20)),
        legend.key.height = unit(1,"cm"),
        legend.key.width = unit(2,"cm"),
        panel.grid.major = element_line(linetype = 2,color = "lightgrey",size=0.1),
        panel.background = element_blank(),
        axis.ticks = element_blank(),
        text = element_text(size=15,family="Georgia"))







world %>% mutate(difference = ifelse(difference>1,1,difference)) -> world_lim

ggplot(data=world_lim,aes(fill=difference,color="")) +
  geom_sf()+
  
  coord_sf(crs = "+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs") + 
  scale_x_continuous(breaks = c(-180,-90,0,90,180),labels = function(x){paste0(x,"°")}) + 
  scale_y_continuous(breaks = c(-45,0,45),labels = function(x){paste0(x,"°")})+
  
  #labs(title = "June Weather Effect")+
  #     subtitle = "Percentage Point effects on daily growth rates of confirmed COVID-19 cases.")+
  labs(caption = paste0("Maximum: ",scales::percent(round(max(world$difference,na.rm=T),2),accuracy = 1),"\nMinimum: ",scales::percent(round(min(world$difference,na.rm=T),2),accuracy = 1)))+
  
  scale_fill_gradient2(
    
    high = rgb(red = 64,0,64,maxColorValue = 255),
    low = rgb(0,128,0,maxColorValue = 255),
    mid = rgb(255,255,255,maxColorValue = 255),
    na.value = rgb(255,255,128,maxColorValue = 255),
    #high = "#af8dc3",
    #mid = "#f7f7f7",
    #low = "#7fbf7b",
    midpoint = 0,
    name= "Mean Change in Confirmed\nCOVID-19 Cases to Baseline",
    limits = c(-1,max(world_lim$difference,na.rm=T)),
    labels = c("-100%","-50%","0%","+50%",">+100%")
  ) +
  
  scale_colour_manual(values="black") +              
  guides(colour = guide_legend("No data",order = 2, override.aes = list(colour = "black",fill = rgb(255, 255, 128, maxColorValue = 255))))+
  
  
  theme(legend.position = "bottom",
        legend.title = element_text(margin = margin(r = 20)),
        legend.key.height = unit(1, "cm"),
        legend.key.width = unit(1.5, "cm"),
        panel.grid.major = element_line(linetype = 2,color = "lightgrey",size = 0.1),
        panel.background = element_blank(),
        axis.ticks = element_blank(), 
        text = element_text(size = 15, family = "Georgia")) -> plot

ggsave(plot,filename = "C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Figures/Map_Projection_SIR_22Apr.pdf",device = cairo_pdf,height=6,width = 10)
ggsave(plot,filename = "C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Figures/Map_Projection_SIR_22Apr.jpg",height=6,width = 10)
