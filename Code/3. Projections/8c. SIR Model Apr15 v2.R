library(shiny)
library(gridExtra)
library(tidyverse)
library(deSolve)
library(extrafont)
library(RColorBrewer)

select <- dplyr::select

# Source:  
# https://github.com/tinu-schneider/Flatten_the_Curve

# Functions ---------------------------------------------------------------

# Function to compute the derivative of the ODE system
# -----------------------------------------------------------
#  t - time
#  y - current state vector of the ODE at time t
#  parms - Parameter vector used by the ODE system (beta, gamma)

sir <- function(t, y, parms, 
                social_dist_period, 
                reduction) {
  
  beta0 <- parms[1]
  gamma <- parms[2]
  
  # Reduce contact rate 
  beta_t <- if_else(t <= social_dist_period[1], 
                    beta0,
                    if_else(t <= social_dist_period[2], 
                            beta0 * reduction[1],
                            beta0 * reduction[2]
                    )
  )
  
  S <- y[1]
  I <- y[2]
  
  return(list(c(S = -beta_t * S * I, 
                I =  beta_t * S * I - gamma * I)))
}


## we assume that many globals exist...!
solve_ode <- function(sdp_start, sdp_end, red, typ, beta, n_init, gamma, N) {
  ode_solution <- lsoda(y = c(N - n_init, n_init), 
                        times = times, 
                        func  = sir, 
                        parms = c(beta, gamma), 
                        social_dist_period = c(sdp_start,sdp_end),
                        reduction = red) %>%
    as.data.frame() %>%
    setNames(c("t", "S", "I")) %>%
    mutate(beta = beta, 
           gama = gamma,
           R0 = N * beta / gamma, 
           s  = S / N, 
           i  = I / N, 
           type = typ)
  
  daily <- ode_solution %>%
    filter(t %in% seq(0, max_time, by = 1)) %>%
    mutate(C = if_else(row_number() == 1, 0, lag(S, k = 1) - S), 
           c = C / N)
  
  daily
}

# Set Coefficients from the Estimation ------------------------------------

readxl::read_excel("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/stata/temp/Baseline_Model.xlsx") %>% 
  gather(variable,value,-...1) %>% 
  rename(estimate=...1) %>% 
  filter(estimate=="b") -> coefficients


# Load Data ---------------------------------------------------------------
df <- readxl::read_excel("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Data/scenarios/Imperial-College-COVID19-Global-unmitigated-mitigated-suppression-scenarios.xlsx",sheet = 2)

covid_actual <- haven::read_dta("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/stata/use/ready.dta")

jetlag <- function(data, variable, n=10, variable_name = ""){
  variable <- enquo(variable)
  
  indices <- seq_len(n)
  quosures <- purrr::map( indices, ~quo(lag(!!variable, !!.x)) ) %>% 
    #set_names(paste0(sprintf("L%02d.", indices),variable_name))
    set_names(paste0("L",indices,".",variable_name))
  mutate( data, !!!quosures)
}
climate <- readr::read_csv("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Data/climate_projections/climate_projections.csv")

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
  cbind(ready,Effect=.) %>% 
  rename(ISO_A3 = iso) -> effect



## CONSTANTS - if commented out, then we take it from the data

# Grid where to evaluate
max_time <- 150 # 150
times <- seq(0, max_time, by = 1)


identify_country <- covid_actual %>% distinct(longitude,latitude)
sp::coordinates(identify_country) <- c("longitude","latitude")
raster::crs(identify_country) <- "+proj=longlat +datum=WGS84 +no_defs"

identify_country_extract <- raster::extract(y=identify_country,x=rnaturalearthdata::countries110)

identify_country_extract %>% 
  rename(ISO_A3 = iso_a3,NAME_LONG = name_long) %>% 
  select(ISO_A3,NAME_LONG) %>% 
  cbind(identify_country %>% as.data.frame,.) %>% 
  full_join(covid_actual,by=c("longitude","latitude")) -> covid_actual

covid_actual %>% 
  mutate(date_case = as.Date(date_case,origin = "1960-01-01")) %>% 
  
  select(date_case,ISO_A3) %>% 
  
  group_by(ISO_A3) %>% 
  mutate(date_case = max(date_case)) %>% 
  ungroup %>% 
  
  group_by(date_case,ISO_A3) %>% 
  tally(name = "current_cases")-> current_cases




country_in_data <- readxl::read_excel("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Data/scenarios/Imperial-College-COVID19-Global-unmitigated-mitigated-suppression-scenarios.xlsx",sheet = 1)
country_in_data %>% 
  select(country_code,`Region, subregion, country or area *`) %>% 
  rename(ISO_A3 = country_code,
         Country = `Region, subregion, country or area *`) %>% 
  full_join(df,by="Country") -> df



# Now we set-up the scenarios ---------------------------------------------

df %>% 
  rename(N = total_pop,
         red = Social_distance,
         typ = Strategy) %>% 
  inner_join(current_cases,by="ISO_A3") %>% 
  mutate(n_init=current_cases) %>% 
  mutate(#n_init = 10,
    gamma = 1/5,
    beta = R0 / N * gamma,
    red = 0.999-red) %>% 
  group_by(ISO_A3,R0) %>% 
  mutate(sdp_start = c(0,30,30),
         sdp_end = c(max_time,90,max_time),
         red_active = red,
         red_inactive = c(0.999,0.999,0.999)) %>% 
  ungroup() -> projection_df



final <- data.frame()
for (i in 1:nrow(projection_df)){
  print(i)
  results_df <-
    solve_ode(
      sdp_start = projection_df$sdp_start[i],
      sdp_end = projection_df$sdp_end[i],
      N = projection_df$N[i],
      n_init = projection_df$n_init[i],
      beta = projection_df$beta[i],
      gamma = projection_df$gamma[i],
      red = c(projection_df$red_active[i],projection_df$red_inactive[i]),
      typ = projection_df$typ[i]
    )
  
  intermediate <- data.frame(ISO_A3= projection_df$ISO_A3[i],
                             R0_input = projection_df$R0[i],
                             N= projection_df$N[i],
                             results_df)
  final <- rbind(final,intermediate)
}


# Create Growth Rates and Merge with starting dates -----------------------------------------------------

final %>% 
  group_by(ISO_A3,R0_input,type) %>% 
  mutate(growth = I/lag(I)) %>% 
  ungroup %>% 
  mutate(ISO_A3 = as.character(ISO_A3)) %>% 
  full_join(current_cases,by="ISO_A3") %>% 
  mutate(date = date_case + t) %>% 
  na.omit()-> final

# Introduce Climate Effect ------------------------------------------------

country_in_data <- readxl::read_excel("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Data/scenarios/Imperial-College-COVID19-Global-unmitigated-mitigated-suppression-scenarios.xlsx",sheet = 1)
country_in_data %>% 
  rename(ISO_A3 = country_code,
         Country = `Region, subregion, country or area *`) %>% 
  full_join(effect,by="ISO_A3") %>% 
  select(Country,ISO_A3,date,Effect) -> effect_to_merge

final %>% 
  full_join(effect_to_merge,by=c("ISO_A3","date")) %>% 
  
  mutate(combined_growth = growth + Effect,
         climate_projection = I) %>% 
  
  na.omit() -> climate_projection_df

climate_projection_df %>% 
  group_by(ISO_A3,R0_input,type) %>%
  mutate(climate_projection = accumulate(combined_growth[-n()], `*`, .init = first(climate_projection))) %>% 
  ungroup() %>% 
  
  mutate(S_new = N-climate_projection) %>% 
  
  na.omit()-> climate_projection_df

climate_projection_df %>% 
  mutate(Effect_adjusted = Effect*(S/N),
         combined_growth_adjusted = growth + Effect_adjusted,
         climate_projection_adjusted = I) %>% 
  group_by(ISO_A3,R0_input,type) %>%
  mutate(climate_projection_adjusted = accumulate(combined_growth_adjusted[-n()], `*`, .init = first(climate_projection_adjusted))) %>% 
  ungroup-> climate_projection_df


# climate_projection_df %>% 
#   filter(Country=="Australia",R0_input == 2.4,type=="Social distancing whole population") %>% 
#   select(Country,t,S_new,S,N,I,combined_growth,combined_growth_adjusted,climate_projection,climate_projection_adjusted) %>% 
#   
#   View




# Projection Comaprison Plot ----------------------------------------------
mycols <- RColorBrewer::brewer.pal(11,"RdBu")[c(2,10)]

type.labs <- c("Unmitigated","Enhanced social\ndistancing of elderly\nDistancing Day 30-150","Social distancing\nwhole population\nDistancing Day 30-90")
names(type.labs) <- c("Unmitigated","Enhanced social distancing of elderly","Social distancing whole population")

climate_projection_df %>% 
  distinct(R0_input) -> model_assumptions


for(j in 1:length(model_assumptions$R0_input)){
  print(j)
  climate_projection_df %>% filter(ISO_A3 %in% c("AUS","CHN","GBR","USA")) %>% 
    ungroup %>% 
    select(Country,date,N,I,R0_input,type,climate_projection,climate_projection_adjusted) %>% 
    mutate(type = factor(type,levels = c("Unmitigated","Enhanced social distancing of elderly","Social distancing whole population")),
           I = I/N,
           #climate_projection= climate_projection/N,
           climate_projection= NULL,
           climate_projection_adjusted = climate_projection_adjusted/N,
           N=NULL)  %>% 
    filter(R0_input==model_assumptions$R0_input[j]) %>% 
    gather(variable,value,-Country,-date,-R0_input,-type) %>% 
    #mutate(value = value/1000000) %>% 
    
    ggplot(aes(x=date,y=value,group=variable,fill=variable,color=variable)) + 
    geom_ribbon(alpha = 0.3,aes(ymin=0,ymax=value))+
    geom_line(size=1)+
    geom_hline(aes(yintercept=0))+
    facet_grid(Country~type,scales = "free", 
               labeller = labeller(type = type.labs))+
    labs(x = "", y = "Share of Population Infected", #title = "COVID-19 cases in a highly stylized SIR Model", 
         #subtitle = "Daily new cases in % of the population", 
         caption  = bquote("Using"~R[0]~"="~.(model_assumptions$R0_input[j]))) +
    
    scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
    scale_color_manual(values = mycols,guide=F) +
    scale_fill_manual(name = "Scenario", values = mycols,labels = c("SIR Model with Weather Effect","SIR Model")) +
    
    
    theme(#axis.text.y = element_blank(),
      legend.position = "bottom",
      axis.ticks  = element_blank(),
      text = element_text(size=15,family="Georgia"),
      panel.background = element_blank(),
      panel.spacing = unit(0.6,"cm"),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      strip.background = element_blank()) -> plot 
  
  
  ggsave(plot,filename = paste0("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Figures/Level Projections_R0",model_assumptions$R0_input[j],"_Apr16_adjusted.pdf"),device = cairo_pdf,height = 8,width = 10)
  ggsave(plot,filename = paste0("C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Figures/Level Projections_R0",model_assumptions$R0_input[j],"_Apr16_adjusted.jpg"),height = 8,width = 10)
}

# 
# climate_projection_df %>% filter(Country == "Australia",
#                                  R0_input == 3,
#                                  type == "Social distancing whole population") %>% 
#   select(t,growth,combined_growth,Effect) %>% 
#   gather(variable,value,-t) %>% 
#   ggplot(aes(x = t, y =value, group=variable,color=variable)) + 
#   geom_line() + 
#   scale_y_continuous(labels = scales::percent_format(accuracy = 1))+
#   geom_hline(aes(yintercept = 1))+
#   scale_color_discrete(labels = c("Combined Effect","SIR no Weather Effect","Weather Effect"),name="")+
#   labs(title = "New Version - Linearized Coef: 0.01",y="Growth",
#        subtitle = "Australia, R0=3.4, Social Distancing Whole Population\nMeasures in place t=30-90") + theme_bw()

write.csv(climate_projection_df,"C:/Users/morit/OneDrive - Nexus365/Covid-19 Paper/Data/projections/SIR_projections_Apr15.csv",row.names = F)
