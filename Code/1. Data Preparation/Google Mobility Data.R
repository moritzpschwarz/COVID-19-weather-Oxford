library(tidyverse)
library(sf)

points <- readxl::read_excel("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Data/Locations_08042020.xlsx",col_names = c("province","latitude","longitude","location_id","country")) %>% 
  distinct(longitude,latitude,location_id) %>% 
  drop_na

points <- st_as_sf(points,coords =c("longitude","latitude"))
st_crs(points) <- "+proj=longlat +datum=WGS84 +no_defs"

#countries <- st_read("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Data/gadm36.shp")
#joined <- st_join(points,countries)
#names(joined)

admin1 <- st_read("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Data/Admin_1 Polygons/ne_10m_admin_1_states_provinces.shp")
joined_admin1 <- st_join(points,admin1)


# Checks
if(joined_admin1 %>% filter(name_en=="Coast Province") %>% nrow>1){warning("Check Coast Province in Kenya!!!")}



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
                                  # Chile
                                  sub_region_1 == "Araucania"~"Araucanía",
                                  sub_region_1 == "Bio Bio"~"Bío Bío",
                                  sub_region_1 == "Magallanes and Chilean Antarctica"~"Magallanes y la Antártica Chilena",
                                  sub_region_1 == "Santiago Metropolitan Region"~"Santiago Metropolitan",
                                  # Croatia
                                  sub_region_1 == "City of Zagreb" ~ "Zagreb",
                                  # Mexico
                                  sub_region_1 == "Yucatan"~"Yucatán",
                                  sub_region_1 == "Nuevo Leon"~"Nuevo León",
                                  sub_region_1 == "San Luis Potosi"~"San Luis Potosí",
                                  sub_region_1 == "State of Mexico"~"México",
                                  # Germany
                                  sub_region_1 == "Mecklenburg-Vorpommern"~"Mecklenburg-Western Pomerania",
                                  # Switzerland
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
                                  # Italy
                                  sub_region_1 == "Lombardy"~"Lombardia",
                                  sub_region_1 == "Trentino-South Tyrol"~"Trentino-Alto Adige",
                                  sub_region_1 == "Piedmont"~"Piemonte",
                                  sub_region_1 == "Tuscany"~"Toscana",
                                  # Greece
                                  sub_region_1 == "Decentralized Administration of Thessaly and Central Greece"~"Central Greece Region",
                                  sub_region_1 == "Decentralized Administration of Attica"~"Attica Region",
                                  sub_region_1 == "Decentralized Administration of Peloponnese, Western Greece and the Ionian"~"West Greece Region",
                                  # Sweden
                                  sub_region_1 == "Gavleborg County"~"Gävleborg County",
                                  sub_region_1 == "Jamtland County"~"Jämtland County",
                                  sub_region_1 == "Jonkoping County"~"Jönköping County",
                                  sub_region_1 == "Varmland County"~"Värmland County",
                                  # Nigeria
                                  sub_region_1 == "Bauchi"~"Bauchi State",
                                  sub_region_1 == "Edo"~"Edo State",
                                  sub_region_1 == "Ekiti"~"Ekiti State",
                                  sub_region_1 == "Osun"~"Osun State",
                                  sub_region_1 == "Oyo"~"Oyo State",
                                  sub_region_1 == "Rivers"~"Rivers State",
                                  sub_region_1 == "Kaduna"~"Kaduna State",
                                  # Kenya
                                  sub_region_1 == "Nairobi County"~"Nairobi",
                                  sub_region_1 == "Abu Dhabi"~"Abu Dhabi Emirate",
                                  sub_region_1 == "Lisbon"~"Lisbon District",
                                  sub_region_1 == "Arequipa"~"Arequipa Region",
                                  sub_region_1 == "Ucayali"~"Ucayali Region",
                                  sub_region_1 == "Galați"~"Galati",
                                  sub_region_1 == "Riyadh Province"~"Riyadh Region",
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
                                  sub_region_1 == "Hyogo Prefecture"~"Hyogo",
                                  sub_region_1 == "Kochi Prefecture"~"Kochi",
                                  TRUE ~ sub_region_1)) -> df
         

joined_admin1 %>% 
  select(geometry,iso_3166_2,iso_a2,admin,name,name_alt,name_en,type,region,name_de,adm0_a3,gns_name,longitude,latitude) %>% 
  mutate(name_en = as.character(name_en),
         name_alt = as.character(name_alt),
         name_de = as.character(name_de),
         gns_name = as.character(gns_name),
         region = as.character(region),
         name = as.character(name)) %>% 
  mutate(name_en = case_when(# Japan
                             name_alt == "Koti"~"Kochi",
                             name_alt == "Kioto"~"Kochi",
                             name_alt == "Hiogo"~"Hyogo",
                             name_alt == "Ezo|Yeso|Yezo"~"Hokkaido",
                             # Norway
                             name_en == "Hordaland"~"Vestland",
                             name_en == "West Agder"~"Agder",
                             name_en == "Telemark"~"Vestfold Og Telemark",
                             name_en == "Oppland"~"Innlandet",
                             name_en == "Troms"~"Troms Og Finnmark",
                             name_en == "Nord-Trøndelag"~"Trondelag",
                             name_en == "Buskerud"~"Viken",
                             # France
                             name_en == "Alpes-de-Haute-Provence"~"Provence-Alpes-Côte d'Azur",
                             name_en == "Bas-Rhin"~"Grand Est",
                             name_en == "Calvados"~"Normandy",
                             name_en == "Corse-du-Sud"~"Corsica",
                             name_en == "Côte-d'Or"~"Bourgogne-Franche-Comté",
                             name_en == "Côtes-d'Armor"~"Brittany",
                             name_en == "Dordogne"~"Nouvelle-Aquitaine",
                             name_en == "Essonne"~"Île-de-France",
                             name_en == "Gironde"~"Nouvelle-Aquitaine",
                             name_en == "Haute-Corse"~"Corsica",
                             name_en == "Haute-Savoie"~"Auvergne-Rhône-Alpes",
                             name_en == "Loir-et-Cher"~"Centre-Val de Loire",
                             name_en == "Loire"~"Auvergne-Rhône-Alpes",
                             name_en == "Maine-et-Loire"~"Pays de la Loire",
                             name_en == "Meuse"~"Grand Est",
                             name_en == "Morbihan"~"Brittany",
                             name_en == "Paris"~"Île-de-France",
                             name_en == "Rhône"~"Auvergne-Rhône-Alpes",
                             name_en == "Savoie"~"Auvergne-Rhône-Alpes",
                             name_en == "Somme"~"Hauts-de-France",
                             name_en == "Tarn"~"Occitanie",
                             name_en == "Orne"~"Normandy",
                             
                             # Spain
                             name_en == "Albacete Province"~"Castile-La Mancha",
                             name_en == "Araba / Álava"~"Basque Country",
                             name_en == "Barcelona Province"~"Catalonia",
                             name_en == "Cáceres Province"~"Extremadura",
                             name_en == "Castellón Province"~"Valencian Community",
                             name_en == "Ciudad Real Province"~"Castile-La Mancha",
                             name_en == "Lleida Province"~"Catalonia",
                             name_en == "Lugo Province"~"Galicia",
                             name_en == "Palencia Province"~"Castile and León",
                             name_en == "Salamanca Province"~"Castile and León",
                             name_en == "Santa Cruz de Tenerife Province"~"Canary Islands",
                             name_en == "Seville Province"~"Andalusia",
                             name_en == "Toledo Province"~"Castile-La Mancha",
                             name_en == "Valencia Province"~"Valencian Community",
                             name_en == "Valladolid Province"~"Castile and León",
                             name_en == "Zaragoza Province"~"Aragon",
                             # Kenya
                             name_en == "Coast Province"~"Kwale County", #!!!! This is case specific - need to check for new cases,
                             name_alt == "Swietokrzyskie"~"Swietokrzyskie",
                             
                             # UK
                             grepl(pattern = "London Borough|City of Westminster|Royal Borough of Greenwich|Royal Borough of Kensington and Chelsea",x = name_en)~"Greater London",
                             name_en == "Barnsely"~"South Yorkshire",
                             name_en == "Birmingham"~"West Yorkshire",
                             name_en == "Bolton"~"Greater Manchester",
                             name_en == "Bournemouth"~"Dorset",
                             name_en == "Bradford"~"West Yorkshire",
                             name_en == "Bristol"~"City of Bristol",
                             name_en == "Barnsley"~"South Yorkshire",
                             name_en == "Bury"~"Greater Manchester",
                             name_en == "Calderdale"~"West Yorkshire",
                             name_en == "City of Sunderland"~"Tyne and Wear",
                             name_en == "Coventry"~"West Midlands",
                             name_en == "Doncaster"~"South Yorkshire",
                             name_en == "Dudley"~"West Midlands",
                             name_en == "Gateshead"~"Tyne and Wear",
                             name_en == "Glasgow"~"Glasgow City",
                             name_en == "Highland"~"Highland Council",
                             name_en == "Knowsley"~"Merseyside",
                             name_en == "Leeds"~"West Yorkshire",
                             name_en == "Liverpool"~"Merseyside",
                             name_en == "Manchester"~"Greater Manchester",
                             name_en == "Metropolitan Borough of Wigan"~"Greater Manchester",
                             name_en == "Mid-Ulster"~"Mid Ulster",
                             name_en == "North Tyneside"~"Tyne and Wear",
                             name_en == "Oldham"~"Greater Manchester",
                             name_en == "Rhondda Cynon Taf"~"Rhondda Cynon Taff",
                             name_en == "Rochdale"~"Greater Manchester",
                             name_en == "Rotherham"~"South Yorkshire",
                             name_en == "Sandwell"~"West Midlands",
                             name_en == "Sefton"~"Merseyside",
                             name_en == "Sheffield"~"South Yorkshire",
                             name_en == "Solihull"~"West Midlands",
                             name_en == "South Ayrshire"~"South Ayrshire Council",
                             name_en == "South Tyneside"~"Tyne and Wear",
                             name_en == "Stockport"~"Greater Manchester",
                             name_en == "Tameside"~"Greater Manchester",
                             name_en == "Telford and Wrekin"~"West Midlands",
                             name_en == "Wakefield"~"West Yorkshire",
                             name_en == "Walsall"~"West Midlands",
                             name_en == "Wolverhampton"~"West Midlands",
                             name_en == "Newcastle upon Tyne"~"Tyne and Wear",
                             TRUE~name_en),
         name_en = ifelse(name_de == "Präfektur Osaka","Osaka Prefecture",name_en),
         name_en = ifelse(iso_a2=="IT",region,name_en),
         name_en = ifelse(name=="Galati",name,name_en),
         name_en = ifelse(iso_a2=="SI",name_alt,name_en),
         
         name_en = ifelse(is.na(name_en)&iso_a2=="GB",name,name_en),
         name_en = ifelse(name_en == "Halton","Merseyside",name_en)) -> joined_admin1_alt


joined_admin1_alt %>%
  data.frame %>% 
  select(adm0_a3,iso_a2,admin,name_en) %>% 
  rename(sub_region_1 = name_en) %>% 
  mutate(sub_region_1 = as.character(sub_region_1)) %>% 
  cbind(readxl::read_excel("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Data/Locations_08042020.xlsx",col_names = c("province","latitude","longitude","location_id","country")) %>% 
          distinct(longitude,latitude,location_id) %>% 
          drop_na,.) %>%
  anti_join(df, by="sub_region_1") %>% 
  distinct(adm0_a3,iso_a2,admin,sub_region_1) %>% arrange(admin) -> not_in_df

dealt_with <- c("BE","FR")

# Check if country in mobility data
not_in_df %>% 
  filter(iso_a2 %in% df$country_region_code,
         !iso_a2 %in% dealt_with)
#df %>% filter(country_region_code=="SA") %>% distinct(sub_region_1) %>% View

# Checks are done - now merging -------------------------------------------
joined_admin1_alt %>%
  data.frame %>% 
  select(adm0_a3,iso_a2,admin,name_en) %>% 
  rename(sub_region_1 = name_en) %>% 
  mutate(sub_region_1 = as.character(sub_region_1)) %>% 
  cbind(readxl::read_excel("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Data/Locations_08042020.xlsx",col_names = c("province","latitude","longitude","location_id","country")) %>% 
          distinct(longitude,latitude,location_id) %>% 
          drop_na,.) %>% 
  inner_join(df,by="sub_region_1") %>% 
  as_tibble  -> mobility_data

write.csv(mobility_data,"C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Data/Google Mobility Data.csv",row.names = F)




