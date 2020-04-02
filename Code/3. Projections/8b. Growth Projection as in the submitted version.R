library(tidyverse)
library(extrafont)
library(Cairo)
library(RColorBrewer)

climate <- readr::read_csv("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Data/climate_projections/climate_projections.csv")

# Set Coefficients from the Estimation ------------------------------------

#From Model 1: 31 March 2020

temp_coef <- -0.0031
rh_coef <- -0.0005

climate %>% 
  filter(date<"2020-03-31") %>% 
  group_by(iso) %>% 
  summarise(TMEAN_March = mean(TMEAN),
            RH_March = mean(RH)) %>% 
  ungroup -> climate_base

climate %>% 
  full_join(climate_base,by="iso") %>% 
  mutate(TMEAN_future = TMEAN - TMEAN_March,
         RH_future = RH - RH_March,
         Effect = TMEAN_future * temp_coef + RH_future*rh_coef) -> effect

effect %>% 
  filter(iso %in% c("USA","AUS","GBR","CHN")) -> plot_df


iso.labs <- c("Australia","China","United Kingdom","United States")
names(iso.labs) <- c("AUS","CHN","GBR","USA")


ggplot(plot_df,aes(x=date,y=Effect,group=iso,fill=iso))+
  geom_area() +
  geom_hline(aes(yintercept = 0))+
  
  facet_wrap(~iso,labeller = labeller(iso=iso.labs)) +
  
  labs(title = "Projections of Daily Growth Impact Rate of Weather on 2019-nCovid",
       subtitle = "Using 2010-2019 Daily Mean Climatology derived from ERA5.",
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
