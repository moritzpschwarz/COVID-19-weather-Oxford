
filter(Country == "Australia",
       R0_input==3,
       type=="Unmitigated") %>% 
  select(N,t,S,I,C,c) %>% 
  gather(variable,value,-t) %>% 
  ggplot(aes(x=t,y=value,group=variable,color=variable))+
  geom_line()



# Map Plotting ------------------------------------------------------------

climate_projection_df %>% 
  filter(R0_input==3,
         type=="Unmitigated",
         t == 30) %>% 
  select(Country,I,climate_projection,N) %>% 
  mutate(diff_popshare =(climate_projection-I)/N,
         diff_Ishare = (climate_projection-I)/I)

st_as_sf(rnaturalearthdata::countries50) %>% 
  filter(!NAME_EN == "Antarctica") %>% 
  full_join(monthly_effects %>% 
              rename(ISO_A3 = iso,
                     month = `month(date)`),by="ISO_A3") -> world 















ggplot(data=world %>% filter(month == 6),aes(fill=Effect)) +
  geom_sf()+
  
  coord_sf(crs = "+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs") + 
  scale_x_continuous(breaks = c(-180,-90,0,90,180),labels = function(x){paste0(x,"°")}) + 
  scale_y_continuous(breaks = c(-45,0,45),labels = function(x){paste0(x,"°")})+
  
  labs(title = "June Weather Effect",
       subtitle = "Percentage Point effects on daily growth rates of confirmed COVID-19 cases.")+
  
  scale_fill_gradient2(
    high = "#af8dc3",
    mid = "#f7f7f7",
    low = "#7fbf7b",
    midpoint = 0,
    breaks = seq(from = -0.3,to = 0.3,by = 0.1),
    labels = c("-30%", "-20%", "-10%", "0%", "+10%","+20%","+30%"),
    limits = c(-0.3,0.3)
  )+
  
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
  scale_x_continuous(breaks = c(-180,-90,0,90,180),labels = function(x){paste0(x,"°")}) + 
  scale_y_continuous(breaks = c(-50,0,50),labels = function(x){paste0(x,"°")})+
  
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
