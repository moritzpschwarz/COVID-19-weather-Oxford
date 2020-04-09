clear

* Humidity
*import delimited "/soge-home/staff/smit0148/OXFORD Research/COVID PAPER/first10_RH.csv", delimiter(";") varnames(1) 
import delimited "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\climate data\Covid_climate_data_RH_updated_04082020.csv", delimiter(",") varnames(1) 

gen date_case = mdy(month,day,year)

drop month day year


* Drop Duplicates
*duplicates drop lon lat date, force

compress
save "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\climate data\RH_08042020.dta", replace

rename rh RH
rename lon longitude
rename lat latitude

*egen location_ID = group(id)

xtset id date_case

local i = 1
while `i'<= 30 {
gen RH_L`i' = L`i'.RH
local i = `i' + 1 
}

compress
save "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\climate data\RH_08042020.dta", replace





clear
* TMEAN
*import delimited "/soge-home/staff/smit0148/OXFORD Research/COVID PAPER/first10_RH.csv", delimiter(";") varnames(1) 
import delimited "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\climate data\Covid_climate_data_tmean_updated_04082020.csv", delimiter(",") varnames(1) 

gen date_case = mdy(month,day,year)

drop month day year


replace tmeank = tmeank-273.15

* Drop Duplicates
*duplicates drop lon lat date, force

compress
save "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\climate data\TMAX_08042020.dta", replace

rename tmeank TMEAN
rename lon longitude
rename lat latitude

*egen location_ID = group(id)

xtset id date_case

local i = 1
while `i'<= 30 {
gen TMEAN_L`i' = L`i'.TMEAN
local i = `i' + 1 
}

compress
save "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\climate data\TMEAN_08042020.dta", replace





clear
* TMAX
*import delimited "/soge-home/staff/smit0148/OXFORD Research/COVID PAPER/first10_RH.csv", delimiter(";") varnames(1) 
import delimited "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\climate data\Covid_climate_data_tasmax_updated_04082020.csv", delimiter(",") varnames(1) 

gen date_case = mdy(month,day,year)

drop month day year


replace tasmaxk = tasmaxk-273.15

* Drop Duplicates
*duplicates drop lon lat date, force

compress
save "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\climate data\TMAX_08042020.dta", replace

rename tasmaxk TMAX
rename lon longitude
rename lat latitude

*egen location_ID = group(id)

xtset id date_case

local i = 1
while `i'<= 30 {
gen TMAX_L`i' = L`i'.TMAX
local i = `i' + 1 
}

compress
save "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\climate data\TMAX_08042020.dta", replace






clear

* TMIN
*import delimited "/soge-home/staff/smit0148/OXFORD Research/COVID PAPER/first10_RH.csv", delimiter(";") varnames(1) 
import delimited "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\climate data\Covid_climate_data_tasmin_updated_04082020.csv", delimiter(",") varnames(1) 

gen date_case = mdy(month,day,year)

drop month day year


replace tasmink = tasmink-273.15

* Drop Duplicates
*duplicates drop lon lat date, force

compress
save "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\climate data\TMIN_08042020.dta", replace

rename tasmink TMIN
rename lon longitude
rename lat latitude

*egen location_ID = group(id)

xtset id date_case

local i = 1
while `i'<= 30 {
gen TMIN_L`i' = L`i'.TMIN
local i = `i' + 1 
}

compress
save "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\climate data\TMIN_08042020.dta", replace





clear

* TP
*import delimited "/soge-home/staff/smit0148/OXFORD Research/COVID PAPER/first10_RH.csv", delimiter(";") varnames(1) 
import delimited "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\climate data\Covid_climate_data_tp_updated_04082020.csv", delimiter(",") varnames(1) 

gen date_case = mdy(month,day,year)

drop month day year

* Drop Duplicates
*duplicates drop lon lat date, force

compress
save "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\climate data\TP_08042020.dta", replace

rename totalprecipitationmm TP
rename lon longitude
rename lat latitude

*egen location_ID = group(id)

xtset id date_case

local i = 1
while `i'<= 30 {
gen TP_L`i' = L`i'.TP
local i = `i' + 1 
}

compress
save "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\climate data\TP_08042020.dta", replace








clear

use "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\climate data\RH_08042020.dta", clear

merge m:m id date_case using "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\climate data\TMEAN_08042020.dta"
drop _merge

merge m:m id date_case using "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\climate data\TMAX_08042020.dta"
drop _merge

merge m:m id date_case using "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\climate data\TMIN_08042020.dta"
drop _merge

merge m:m id date_case using "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\climate data\TP_08042020.dta"
drop _merge

rename id location_ID

*replace longitude = round(longitude,0.2)
*replace latitude = round(latitude,0.2)

* Drop Duplicates
*duplicates drop lon lat date, force

compress
save "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\climate data\CLIMATE_08042020.dta", replace




* Open Covid Data
use "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\Covid_19_extended_08042020.dta", clear

*replace longitude = round(longitude,0.2)
*replace latitude = round(latitude,0.2)


*merge m:1 longitude latitude date_case using "/soge-home/staff/smit0148/OXFORD Research/COVID PAPER/RH_28032020.dta", gen(MERGED)
merge m:m location_ID date_case using "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\climate data\CLIMATE_08042020.dta", gen(MERGED)

compress
save "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\ESTIMATION_extended_080420.dta",replace

outsheet _all using ESTIMATION_300320.csv, comma nolabel 
