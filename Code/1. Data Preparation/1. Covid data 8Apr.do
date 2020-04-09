***
*CODE TO DOWNLOAD AND PROCESS THE COVID 19 DATA
***

clear
import delimited https://github.com/beoutbreakprepared/nCoV2019/raw/master/latest_data/latestdata.csv

save "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\Covid_19_latest.dta", replace
*save "/soge-home/staff/smit0148/OXFORD Research/COVID PAPER/Covid_19_latest.dta", replace


use "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\Covid_19_latest.dta", clear
*use "/soge-home/staff/smit0148/OXFORD Research/COVID PAPER/Covid_19_latest.dta", clear

gen row_No = _n

* Possible dates: date_onset_symptoms date_admission_hospital date_confirmation
* We use date of confirmation of Covid 19 since other dates are nearly always empty
* The date of confirmation is often a range (between 01.02.2020 - 03.02.2020) (only for 1.7% of cases though)

split date_confirmation, generate(date_) parse(-)
replace date_1 = subinstr(date_1," ","",100) // minimum date of confirmation
replace date_2 = subinstr(date_2," ","",100) // maximum date of confirmation

gen date_1_No = date(date_1, "DMY")
gen date_2_No = date(date_2, "DMY")


// corrects for the fact that some cases happened at some point over a window period
gen window = date_2_No - date_1_No + 1
replace window = 1 if date_2_No ==.
expand window
bysort row_No: egen rank_window = rank(_n)

gen date_case = date_1_No + rank_window - 1

gen Case = 1/window  
gen Case_strict = (window==1)

* create case counts per location

egen location_ID = group(longitude latitude)

bysort location_ID date_case : egen sum_Case = sum(Case) // case count with weight
bysort location_ID date_case : egen sum_Case_strict = sum(Case_strict) // case count only when date is certain


* Aggregation over Wuhan variable

gen Case_wuhan = (wuhan0_not_wuhan1==0) * Case
gen Case_not_wuhan = (wuhan0_not_wuhan1==1) * Case
gen Case_excl_wuhan = Case - Case_wuhan

gen Case_strict_wuhan = (wuhan0_not_wuhan1==0) * Case_strict
gen Case_strict_not_wuhan = (wuhan0_not_wuhan1==1) * Case_strict
gen Case_strict_excl_wuhan = Case_strict - Case_strict_wuhan


gen Case_China = Case * (country=="China")

global variables_wuhan " "Case_China" "Case_wuhan" "Case_not_wuhan" "Case_excl_wuhan" "Case_strict_wuhan" "Case_strict_not_wuhan" "Case_strict_excl_wuhan"  "
foreach j in $variables_wuhan {
bysort location_ID date_case : egen sum_`j' = sum(`j')
}


* Make sure that countries will be described when we aggregate the data

encode country, gen(country_code)
bysort location_ID: egen country_code_max = max(country_code)
*gen A = 1 if country_code==.
replace country_code = country_code_max if country_code==.
*tab country_code if A==1
decode country_code, gen(COUNTRY)
drop country*
rename COUNTRY country



* Now this is a dataset of counts per location and per day

duplicates drop location_ID date_case, force

keep latitude longitude country province location_ID date* sum*


* use fillin with all possible dates to create complete dataset with all possible dates


keep if date_case !=.  // make sure all possible dates are in the dataset
sum date_case
local min = r(min)
local max = r(max)
count
local value = r(N) 
local obs_N = `value' + `max' - `min' + 1
set obs `obs_N' 
replace date_case = _n - `value' + `min' -1 if _n>`value'


fillin location_ID date_case


** Make sure that fillin variables have the right country, province, longitude and latitude

global variables_counts " "sum_Case_China" "sum_Case" "sum_Case_wuhan" "sum_Case_not_wuhan" "sum_Case_excl_wuhan" "sum_Case_strict" "sum_Case_strict_wuhan" "sum_Case_strict_not_wuhan" "sum_Case_strict_excl_wuhan"  "
foreach j in $variables_counts {
replace `j' = 0 if _fillin==1
}

encode country, gen(country_code)
bysort location_ID: egen country_code_max = max(country_code)
replace country_code = country_code_max if country_code==.
decode country_code, gen(COUNTRY)
drop country*
rename COUNTRY country

encode province, gen(province_code)
bysort location_ID: egen province_code_max = max(province_code)
replace province_code = province_code_max if province_code==.
decode province_code, gen(PROVINCE)
drop province*
rename PROVINCE province

bysort location_ID: egen LONGITUDE = min(longitude)
bysort location_ID: egen LATITUDE = min(latitude)

drop longitude latitude

rename LONGITUDE longitude
rename LATITUDE latitude


* identify fully balanced dataset

drop if location_ID == .
xtset location_ID date_case




* create location-specific sums of infections since first infection

sum date_case
local min = r(min)
local max = r(max)


global variables_counts_abbrev " "Case_China" "Case" "Case_wuhan" "Case_not_wuhan" "Case_excl_wuhan" "Case_strict" "Case_strict_wuhan" "Case_strict_not_wuhan" "Case_strict_excl_wuhan"  "
foreach j in $variables_counts_abbrev {
gen total_`j' = sum_`j' if date_case ==`min'

local i = `min' + 1
while `i' <= `max' {
replace total_`j' = L.total_`j' + sum_`j' if date_case == `i'
local i = `i' + 1
}

}


* gen log(total cases)


global variables_counts_abbrev " "Case_China" "Case" "Case_wuhan" "Case_not_wuhan" "Case_excl_wuhan" "Case_strict" "Case_strict_wuhan" "Case_strict_not_wuhan" "Case_strict_excl_wuhan"  "
foreach j in $variables_counts_abbrev {
gen ln_tot_`j' = ln(total_`j')
}

compress
*save "/soge-home/staff/smit0148/OXFORD Research/COVID PAPER/Covid_19_28032020.dta", replace
save "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\Covid_19_08042020.dta", replace


------
------


---
---

CODE TO IDENTIFY LOCATIONS

---
---


clear
*import delimited https://github.com/beoutbreakprepared/nCoV2019/raw/master/latest_data/latestdata.csv
*save "/soge-home/staff/smit0148/OXFORD Research/COVID PAPER/Covid_19_latest.dta", replace


use "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\Covid_19_latest.dta", clear
*use "/soge-home/staff/smit0148/OXFORD Research/COVID PAPER/Covid_19_latest.dta", clear

gen row_No = _n

* Possible dates: date_onset_symptoms date_admission_hospital date_confirmation
* We use date of confirmation of Covid 19 since other dates are nearly always empty
* The date of confirmation is often a range (between 01.02.2020 - 03.02.2020) (only for 1.7% of cases though)

split date_confirmation, generate(date_) parse(-)
replace date_1 = subinstr(date_1," ","",100) // minimum date of confirmation
replace date_2 = subinstr(date_2," ","",100) // maximum date of confirmation

gen date_1_No = date(date_1, "DMY")
gen date_2_No = date(date_2, "DMY")


// corrects for the fact that some cases happened at some point over a window period
gen window = date_2_No - date_1_No + 1
replace window = 1 if date_2_No ==.
expand window
bysort row_No: egen rank_window = rank(_n)

gen date_case = date_1_No + rank_window - 1

gen Case = 1/window  
gen Case_strict = (window==1)

* create case counts per location

egen location_ID = group(longitude latitude)

bysort location_ID date_case : egen sum_Case = sum(Case) // case count with weight
bysort location_ID date_case : egen sum_Case_strict = sum(Case_strict) // case count only when date is certain


* Aggregation over Wuhan variable

gen Case_wuhan = (wuhan0_not_wuhan1==0) * Case
gen Case_not_wuhan = (wuhan0_not_wuhan1==1) * Case
gen Case_excl_wuhan = Case - Case_wuhan

gen Case_strict_wuhan = (wuhan0_not_wuhan1==0) * Case_strict
gen Case_strict_not_wuhan = (wuhan0_not_wuhan1==1) * Case_strict
gen Case_strict_excl_wuhan = Case_strict - Case_strict_wuhan

global variables_wuhan " "Case_wuhan" "Case_not_wuhan" "Case_excl_wuhan" "Case_strict_wuhan" "Case_strict_not_wuhan" "Case_strict_excl_wuhan"  "
foreach j in $variables_wuhan {
bysort location_ID date_case : egen sum_`j' = sum(`j')
}


* Make sure that countries will be described when we aggregate the data

encode country, gen(country_code)
bysort location_ID: egen country_code_max = max(country_code)
*gen A = 1 if country_code==.
replace country_code = country_code_max if country_code==.
*tab country_code if A==1
decode country_code, gen(COUNTRY)
drop country*
rename COUNTRY country

duplicates drop location_ID, force
keep province country latitude longitude location_ID
sort latitude longitude

*export excel using "/soge-home/staff/smit0148/OXFORD Research/COVID PAPER/Locations.xlsx"
export excel using "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\Locations_08042020.xlsx", replace

---


