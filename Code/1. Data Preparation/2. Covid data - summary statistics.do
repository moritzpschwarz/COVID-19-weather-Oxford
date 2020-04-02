***
*CODE TO DOWNLOAD AND PROCESS THE COVID 19 DATA
***

*clear
*import delimited https://github.com/beoutbreakprepared/nCoV2019/raw/master/latest_data/latestdata.csv

*save "/soge-home/staff/smit0148/OXFORD Research/COVID PAPER/Covid_19_latest.dta", replace



use "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\Covid_19_latest.dta", clear

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


*-------
*SUMMARY STATISTICS TABLE
*-------

* Dates of data
sum date_1_No
gen d_min = day(r(min))
gen m_min = month(r(min))
gen y_min = year(r(min))
gen d_max = day(r(max))
gen m_max = month(r(max))
gen y_max = year(r(max))

bysort date_case: egen total_day_Case = sum(sum_Case)
bysort date_case: egen total_day_Case_wuhan = sum(sum_Case_wuhan)
bysort date_case: egen total_day_Case_China = sum(sum_Case_China)
bysort date_case: egen rank_date_case = rank(_n)

* statistics to know how many countries are affected at date t
gen country_Affected = (total_Case>=1)
bysort country date_case: egen rank_country = rank(_n)
replace country_Affected = 0 if rank_country >1
bysort date_case: egen No_country_affected = sum(country_Affected)

* statistics to know how many locations are affected at date t
gen location_ID_Affected = (total_Case>=1)
bysort location_ID date_case: egen rank_location_ID = rank(_n)
replace location_ID_Affected = 0 if rank_location_ID >1
bysort date_case: egen No_location_ID_affected = sum(location_ID_Affected)



keep if rank_date_case==1 
tsset location_ID date_case, format(%tdMonth_dd,_CCYY)

twoway (bar total_day_Case date_case, yaxis(1) sort) (bar total_day_Case_China date_case, yaxis(1) sort) (line No_location_ID_affected date_case, yaxis(2) yscale(range(0) axis(2)) sort),  xtitle(Date) xlabel(minmax) ytitle("Number of new cases", axis(1)) ytitle("Sum of infected areas to date", axis(2)) legend(order(1 "New cases" 2 "New cases in China" 3 "Sum of infected areas") region(lcolor(white))) graphregion(fcolor(white)) title("a) Confirmed cases and infected areas in dataset")
graph export "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Figures\Figure_1a.png", replace







* check this

ytitle(Total number of infected locations, yaxis(2)) 

sum No_country_affected

* (line No_country_affected date_case, yaxis(2) yscale(range(0) axis(2)) sort) 
----

gen day_value = day(date_case)
gen month_value = month(date_case)
gen year_value = year(date_case)
tostring *_value, replace

gen date_value = day_value + "." + date_value + "." + year_value
encode date_value, gen(date_value_No)
recode date_value_No



----
* ECONOMETRIC MODELS

encode country, gen(C_s) // country FEs

egen country_day = group(C_s date_case)

* Poisson model

gen A =  runiform() * sum_Case * 0.3

poi2hdfe sum_Case A, id1(location_ID) id2(country_day) cluster(C_s)


---

* First Differences and FEs

reghdfe D.ln_tot_Case if total_Case>=1, absorb(date_case#C_s location_ID) cluster(location_ID)

* or in levels *

reghdfe sum_Case if total_Case>=1, absorb(date_case#C_s location_ID) cluster(location_ID)


* or DLM

reghdfe D.ln_tot_Case LD(1/10).ln_tot_Case, absorb(date_case) cluster(location_ID)


reghdfe D.sum_Case LD(1/10).sum_Case, absorb(date_case) cluster(location_ID)

---

egen country_day = group(country date_case)

**xtpoisson sum_Case i.country_day, fe vce(robust)

----
----

* A: autoregressive lag model
* cases today = cases the days before + time fixed effect (day FE)

reghdfe D.ln_tot_Case LD(1/3).ln_tot_Case, absorb(date_case) cluster(location_ID)


* Controlling for policies - Add the policy information given by Francois Lafond
* TE BE INCLUDED



* Model with country FE x day FE, and location FE

reghdfe D.ln_tot_Case, absorb(date_case#C_s location_ID) cluster(location_ID)




---
---

CODE TO IDENTIFY LOCATIONS

---
---


clear
import delimited https://github.com/beoutbreakprepared/nCoV2019/raw/master/latest_data/latestdata.csv

save "/soge-home/staff/smit0148/OXFORD Research/COVID PAPER/Covid_19_latest.dta", replace



use "/soge-home/staff/smit0148/OXFORD Research/COVID PAPER/Covid_19_latest.dta", clear

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
export excel using "/soge-home/staff/smit0148/OXFORD Research/COVID PAPER/Locations.xlsx"

---


