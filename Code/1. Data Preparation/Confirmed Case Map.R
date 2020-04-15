library(haven)
library(tidyverse)
library(sf)
library(maps)
library(ggrepel)
library(viridis)

df <- read_dta("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Data/Covid_19_latest.dta")
df %>% 
  filter(complete.cases(longitude,latitude),
         !geo_resolution == "admin0") %>% 
  mutate(date_case = as.Date(date_confirmation,format = "%d.%m.%Y")) %>% 
  rename(long = longitude,
         lat = latitude) %>% 
  group_by(date_case,long,lat,country) %>% 
  summarise(cases = n()) %>% 
  ungroup %>% 
  as.data.frame  -> data 

#st_as_sf(coords = c("long","lat")) 

st_as_sf(rnaturalearthdata::countries110) %>% 
  filter(!name == "Antarctica") -> world 


#world <- map_data("world") %>% filter(!region == "Antarctica")

# ggplot() +
#   geom_polygon(data = world, aes(x=long, y = lat, group = group), fill="grey", alpha=0.3) +
#   geom_point(data=data, aes(x=long, y=lat)) +
#   theme_void() +  coord_map() 
# 
# 
# 
# ggplot() +
#   geom_polygon(data = world, aes(x=long, y = lat, group = group), fill="grey", alpha=0.3) +
#   geom_point( data=data, aes(x=long, y=lat, alpha=cases)) +
#   #geom_text_repel( data=data %>% arrange(cases) %>% tail(10), aes(x=long, y=lat, label=country), size=5) +
#   geom_point( data=data %>% arrange(cases) %>% tail(10), aes(x=long, y=lat), color="red", size=3) +
#   theme_void() + 
#   #coord_map() +
#   coord_sf(crs = "+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")+
#   theme(legend.position="none")
# 
# 
# 
# 
# # Left: use size and color
# ggplot() +
#   geom_polygon(data = world, aes(x=long, y = lat, group = group), fill="grey", alpha=0.3) +
#   geom_point( data=data, aes(x=long, y=lat, size=cases, color=cases)) +
#   scale_size_continuous(range=c(1,12)) +
#   scale_color_viridis(trans="log") +
#   theme_void() + coord_sf(crs = "+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
# 
# # Center: reorder your dataset first! Big cities appear later = on top
# data %>%
#   arrange(cases) %>% 
#   mutate( name=factor(country, unique(country))) %>% 
#   ggplot() +
#   geom_polygon(data = world, aes(x=long, y = lat, group = group), fill="grey", alpha=0.3) +
#   geom_point( aes(x=long, y=lat, size=cases, color=cases), alpha=0.9) +
#   scale_size_continuous(range=c(1,12)) +
#   scale_color_viridis(trans="log") +
#   theme_void() +  coord_sf(crs = "+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs") + theme(legend.position="none")
# 
# # Right: just use arrange(desc(cases)) instead
# data %>%
#   arrange(desc(cases)) %>% 
#   mutate( country=factor(country, unique(country))) %>% 
#   ggplot() +
#   geom_polygon(data = world, aes(x=long, y = lat, group = group), fill="grey", alpha=0.3) +
#   geom_point( aes(x=long, y=lat, size=cases, color=cases), alpha=0.9) +
#   scale_size_continuous(range=c(1,12)) +
#   scale_color_viridis(trans="log") +
#   theme_void() +  coord_sf(crs = "+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs") + theme(legend.position="none")
# 
# 
# 
# 
# 
# 
# 
# 
# 
# # Create breaks for the color scale
# mybreaks <- c(0.02, 0.04, 0.08, 1, 7)
# 
# # Reorder data to show biggest cities on top
# data_new <- data %>%
#   arrange(cases) %>%
#   mutate( country=factor(country, unique(country))) #%>%
#   #mutate(pop=pop/1000000) 



world <- st_as_sf(world,coords = c("long","lat"))
data <- st_as_sf(data %>% arrange(cases),coords = c("long","lat"))
st_crs(data) <- "+proj=longlat +datum=WGS84 +no_defs"


# Build the map

ggplot() +
  geom_sf(data=world)+
  geom_sf(data=data,aes(size=cases, color=cases))+
  coord_sf(crs = "+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs")+

  #geom_polygon(data = world, aes(x=long, y = lat, group = group), fill="grey",color="grey", alpha=0.3,size = 0.1) +
  #geom_point(aes(x=long, y=lat, size=cases, color=cases), shape=20, stroke=FALSE) +
  scale_size_continuous(range = c(1,10),name="Number of Cases",guide = FALSE) +
  #scale_alpha_continuous(name="Number of Cases",guide = FALSE) +
  
  
  scale_color_gradient(low = rgb(red = 64,0,64,maxColorValue = 255),
                       high = rgb(255,0,0,maxColorValue = 255),name = "Number of COVID-19 Cases")+

  
  #scale_color_gradient(high = rgb(red = 64,0,64,maxColorValue = 255),low = rgb(0,128,0,maxColorValue = 255))
  
  #scale_color_viridis(option="magma", name="Number of Cases") +
  #theme_void() +
  #coord_sf(crs = "+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs") + 
  #coord_sf(crs = "+proj=robin") + 
  scale_x_continuous(breaks = c(-180,-90,0,90,180),labels = function(x){paste0(x,"°")}) + 
  scale_y_continuous(breaks = c(-45,0,45),labels = function(x){paste0(x,"°")})+
  #coord_quickmap() + 
  
  
  labs(title = "",
       x = "",
       y="",
       caption = "") +
  
  
  # labs(title = "Confirmed COVID-19 Cases",
  #      x = "",
  #      y="",
  #      caption = "Data retrieved from Xu et al. (2020) on April 9th, 2020.\nCases reported at the national level excluded.") +
  
  theme(
    legend.position = "bottom",
    panel.grid.major = element_line(linetype = 2,color = "lightgrey",size=0.5),
    panel.background = element_blank(),
    legend.key.height = unit(0.5,"cm"),
    legend.key.width = unit(2,"cm"),
    text = element_text(family = "Georgia",size=15),
    plot.background = element_blank(), 
    #panel.background = element_blank(), 
    legend.background = element_blank(),
    plot.caption = element_text(margin = margin(t = 10))
  ) -> plot


ggsave(plot,filename = "C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Figures/confirmed_cases_map.pdf",height = 6,width=10,device = cairo_pdf)
ggsave(plot,filename = "C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Figures/confirmed_cases_map.jpg",height = 6,width=10,dpi = 600)
