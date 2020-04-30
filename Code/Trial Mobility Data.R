library(tidyverse)
library(sf)




stata <- haven::read_dta("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/stata/use/ready.dta")
stata %>% 
  distinct(longitude,latitude) -> points

points <- st_as_sf(points,coords =c("longitude","latitude"))
st_crs(points) <- "+proj=longlat +datum=WGS84 +no_defs"

countries <- st_read("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Data/gadm36.shp")
joined <- st_join(points,countries)

names(joined)


admin1 <- st_read("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Data/Admin_1 Polygons/ne_10m_admin_1_states_provinces.shp")
joined_admin1 <- st_join(points,admin1)



df_raw <- readr::read_csv("https://www.gstatic.com/covid19/mobility/Global_Mobility_Report.csv")

df_raw %>% 
  drop_na(sub_region_1) %>%
  select(-sub_region_2) %>% 
  mutate(sub_region_1 = case_when(sub_region_1 == "Cordoba"~"Córdoba Province",
                                  sub_region_1 == "Tucumán" ~ "Tucumán Province",
                                  sub_region_1 == "Jujuy" ~ "Jujuy Province",
                                  sub_region_1 == "Neuquen" ~ "Neuquén Province",
                                  sub_region_1 == "Entre Rios"~"Entre Ríos Province",
                                  sub_region_1 == "Brussels"~"Brussels-Capital Region",
                                  sub_region_1 == "Gabrovo" ~ "Gabrovo Province",
                                  sub_region_1 == "Araucania"~"Araucanía",
                                  sub_region_1 == "Bio Bio"~"Bío Bío",
                                  sub_region_1 == "Magallanes and Chilean Antarctica"~"Magallanes y la Antártica Chilena",
                                  sub_region_1 == "Santiago Metropolitan Region"~"Santiago Metropolitan",
                                  sub_region_1 == "City of Zagreb" ~ "Zagreb",
                                  sub_region_1 == "Yucatan"~"Yucatán",
                                  sub_region_1 == "Nuevo Leon"~"Nuevo León",
                                  sub_region_1 == "San Luis Potosi"~"San Luis Potosí",
                                  sub_region_1 == "State of Mexico"~"México",
                                  sub_region_1 == "Mecklenburg-Vorpommern"~"Mecklenburg-Western Pomerania",
                                  sub_region_1 == "Aargau"~"canton of Aargau",
                                  sub_region_1 == "Basel City"~"Basel-Stadt",
                                  sub_region_1 == "Zurich"~"Canton of Zürich",
                                  sub_region_1 == "Jura"~"Canton of Jura",
                                  sub_region_1 == "Lucerne"~"Canton of Lucerne",
                                  sub_region_1 == "Basel-Landschaft"~"Canton of Basel-Landschaft",
                                  sub_region_1 == "Schwyz"~"Canton of Schwyz",
                                  sub_region_1 == "St. Gallen"~"Canton of St. Gallen",
                                  sub_region_1 == "Vaud"~"Canton of Vaud",
                                  sub_region_1 == "Geneva"~"Canton of Geneva",
                                  sub_region_1 == "Valais"~"Canton of Valais",
                                  sub_region_1 == "Neuchâtel"~"Canton of Neuchâtel",
                                  sub_region_1 == "Fribourg"~"Canton of Fribourg",
                                  sub_region_1 == "Grisons"~"Graubünden",
                                  TRUE ~ sub_region_1)) %>% 
  # Brazil
  mutate(sub_region_1 = ifelse(country_region_code == "BR",gsub("State of ","",sub_region_1),sub_region_1)) %>% 
  # Chile 
  mutate(sub_region_1 = ifelse(country_region_code == "CL",paste0(sub_region_1," Region"),sub_region_1)) %>% 
  # Colombia 
  mutate(sub_region_1 = ifelse(country_region_code == "CO",paste0(sub_region_1," Department"),sub_region_1),
         sub_region_1 = case_when(sub_region_1 == "Amazonas Department Department"~"Amazonas Department",
                                  sub_region_1 == "Bogota Department"~"Bogotá",
                                  sub_region_1 == "Meta Department"~"Meta",
                                  sub_region_1 == "Atlantico Department"~"Atlántico Department",
                                  sub_region_1 == "Bolivar Department"~"Bolívar Department",
                                  sub_region_1 == "Narino Department"~"Nariño Department",
                                  sub_region_1 == "Quindio Department"~"Quindío Department",
                                  sub_region_1 == "North Santander Department"~"Norte de Santander Department",
                                  sub_region_1 == "San Andrés and Providencia Department"~"Archipelago of Saint Andréws",
                                  TRUE ~ sub_region_1)) %>% 

  # Japan
  mutate(sub_region_1 = ifelse(country_region_code == "JP",paste0(sub_region_1," Prefecture"),sub_region_1),
         sub_region_1 = case_when(sub_region_1 == "Tokyo Prefecture"~"Tokyo",
                                  sub_region_1 == "Hokkaido Prefecture"~"Hokkaido",
                                  #sub_region_1 == "Hyogo Prefecture"~"Hyogo Prefecture",
                                  #sub_region_1 == "Kochi Prefecture"~"Kochi Prefecture",
                                  #sub_region_1 == "Kyoto Prefecture"~"Kyoto Prefecture",
                                  TRUE ~ sub_region_1)) -> df

joined_admin1 %>%
  data.frame %>% 
  select(adm0_a3,iso_a2,admin,name_en) %>% 
  rename(sub_region_1 = name_en) %>% 
  mutate(sub_region_1 = as.character(sub_region_1),
         sub_region_1 = gsub("o","o",sub_region_1)) -> test
  cbind(stata %>% 
          distinct(longitude,latitude),.) %>% 
  anti_join(df, by="sub_region_1") %>% 
  distinct(adm0_a3,iso_a2,admin,sub_region_1) %>% arrange(admin) -> not_in_df


dealt_with <- c("BE")

# Check if country in mobility data
not_in_df %>% 
  filter(iso_a2 %in% df$country_region_code,
         !iso_a2 %in% dealt_with) %>% 
  filter(iso_a2=="JP") %>% arrange(sub_region_1) -> test


# admin1 %>% filter(iso_a2 == "GB") %>% select(name, name_alt, name_en) %>% View


df %>% 
  filter(country_region_code=="JP") %>% 
  distinct(sub_region_1) %>% View


















skip_because_no_sub_region_1 <- c("AFG","DZA","ECU")

not_in_df %>% 
  as_tibble() %>% 
  filter(!adm0_a3 %in% skip_because_no_sub_region_1)














df %>% 
  filter(country_region == "Austria") %>% 
  distinct(sub_region_1) %>% as.data.frame()

df %>% distinct(country_region,sub_region_1) %>% View



drop_na(name_en) %>% 
  rename(sub_region_1 = name_en) %>% 
  select(geometry, sub_region_1)  -> test

inner_join(df,by = c("sub_region_1"))
