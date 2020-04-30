import delimited "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\Google Mobility Data.csv"
rename location_id location_ID
gen date_case = date(date,"YMD")

merge m:m location_ID date_case using "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\climate data\CLIMATE_08042020.dta", gen(MERGED)

duplicates drop location_ID date_case, force

save "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\Mobility and Climate 22Apr.dta", replace