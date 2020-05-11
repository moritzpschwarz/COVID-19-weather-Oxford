clear all
set more off

* Make sure to have lincomest installed
ssc install lincomest
ssc install estout

cd "PUT PAHT" 
global raw "PUT PAHT/data/raw" 
global temp "PUT PAHT/data/temp" 
global use "PUT PAHT/data/use"
global out "PUT PAHT/data/out"


********************************************************************************
*************************	Preparation  ***************************************
********************************************************************************

*Data input: this do file starts from ESTIMATION_DDMMYYYY.dta, which already merged COVID and CLIMATE data.
*use "$raw/ESTIMATION_30032020.dta",clear 

use "$raw/ESTIMATION_30042020.dta",clear 
set more off


encode geo_resolution, gen(geo)
bysort location_ID: egen min_geo = min(geo)
bysort location_ID: egen max_geo = max(geo)

drop if min_geo!=max_geo
drop if min_geo <= 2      // **************** This drops all observations with national level information

	*create country by day FEs
encode country, gen(C_s) 
egen country_day = group(C_s date_case)
sort location_ID date_case
drop *L22 *L23 *L24 *L25 *L26 *L27 *L28 *L29 *L30 //drop lags more than 20, do not need for the moment



	*create average temp and 20 lags (MIN and MAX lags already created)
*gen T_AV = (TMAX + TMIN)/2

gen T_AV = TMEAN

local i = 1
while `i'<= 21 {
gen T_AV_L`i' = L`i'.T_AV
local i = `i' + 1 
}
	*create temperrature bins	

***** 10 degrees bins 
	** AV TEMP	
gen Temp_5 = T_AV<=5
gen Temp_15 = T_AV<=15
gen Temp_25 = T_AV<=25
gen Temp_25p = T_AV>=25  & T_AV!=.

replace Temp_25 = Temp_25 - Temp_15
replace Temp_15 = Temp_15 - Temp_5

local i = 1
while `i'<= 21 {
gen Temp_5_L`i' = L`i'.Temp_5
gen Temp_15_L`i' = L`i'.Temp_15
gen Temp_25_L`i' = L`i'.Temp_25
gen Temp_25p_L`i' = L`i'.Temp_25p
local i = `i' + 1 
}



***** 10 degrees bins 
	** AV TEMP	
gen Temp2_0 = T_AV<=0
gen Temp2_5 = T_AV<=5
gen Temp2_10 = T_AV<=10
gen Temp2_15 = T_AV<=15
gen Temp2_20 = T_AV<=20
gen Temp2_25 = T_AV<=25
gen Temp2_25p = T_AV>25  & T_AV!=.

replace Temp2_25 = Temp2_25 - Temp2_20
replace Temp2_20 = Temp2_20 - Temp2_15
replace Temp2_15 = Temp2_15 - Temp2_10
replace Temp2_10 = Temp2_10 - Temp2_5
replace Temp2_5 = Temp2_5 - Temp2_0

local i = 1
while `i'<= 21 {
gen Temp2_0_L`i' = L`i'.Temp2_0
gen Temp2_5_L`i' = L`i'.Temp2_5
gen Temp2_10_L`i' = L`i'.Temp2_10
gen Temp2_15_L`i' = L`i'.Temp2_15
gen Temp2_20_L`i' = L`i'.Temp2_20
gen Temp2_25_L`i' = L`i'.Temp2_25
gen Temp2_25p_L`i' = L`i'.Temp2_25p
local i = `i' + 1 
}




	** MIN TEMP
	
gen TMIN_m10 = TMIN<=-10
gen TMIN_0 = TMIN<=0
gen TMIN_10 = TMIN<=10
gen TMIN_20 = TMIN<=20
gen TMIN_20p = TMIN>=20  & TMIN!=. 

replace TMIN_20 = TMIN_20 - TMIN_10
replace TMIN_10 = TMIN_10 - TMIN_0
replace TMIN_0 = TMIN_0 - TMIN_m10



local i = 1
while `i'<= 21 {
gen TMIN_m10_L`i' = L`i'.TMIN_m10
gen TMIN_0_L`i' = L`i'.TMIN_0
gen TMIN_10_L`i' = L`i'.TMIN_10
gen TMIN_20_L`i' = L`i'.TMIN_20
gen TMIN_20p_L`i' = L`i'.TMIN_20p
local i = `i' + 1 
}


	** MAX TEMP	
gen TMAX_10 = TMAX<=10
gen TMAX_20 = TMAX<=20
gen TMAX_30 = TMAX<=30
gen TMAX_40 = TMAX<=40
gen TMAX_40p = TMAX>=40  & TMAX!=. //30 plus+

replace TMAX_40 = TMAX_40 - TMAX_30
replace TMAX_30 = TMAX_30 - TMAX_20
replace TMAX_20 = TMAX_20 - TMAX_10


local i = 1
while `i'<= 21 {
gen TMAX_10_L`i' = L`i'.TMAX_10
gen TMAX_20_L`i' = L`i'.TMAX_20
gen TMAX_30_L`i' = L`i'.TMAX_30
gen TMAX_40_L`i' = L`i'.TMAX_40
gen TMAX_40p_L`i' = L`i'.TMAX_40p
local i = `i' + 1 
}

	
	** MIN TEMP	


	*generate country total cases
bysort country date_case: egen COUNTRY_COUNT = sum(total_Case)
sort location_ID date_case
save "$use/ready.dta", replace
global readydata "$use/ready.dta" //As the data is updating regularly, global it.






********************************************************************************
********************************************************************************
*			TABLE A2			 		   *
********************************************************************************
********************************************************************************


use  "$use/ready.dta", clear

set more off
estimates clear


bysort country date_case: egen total_country = sum(total_Case)
bysort country: egen max_country = max(total_country)
sort location_ID date_case
keep if  L.total_country!=max_country

gen week = week(date_case)

sort location_ID date_case

drop *L16 *L17 *L18 *L19 *L20 *L21



* Column 1: Temperatures and humidity (BASELINE MODEL)
reghdfe D.ln_tot_Case T_AV T_AV_L* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)
estimates save "$temp/Model_1", replace

sum T_AV TMAX TMIN RH TP if e(sample)

global vars " "T_AV" "
foreach j in $vars {
lincomest  `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15, level(95)
}

reghdfe D.ln_tot_Case T_AV T_AV_L* if total_Case>=1 & country=="China", absorb(date_case#C_s location_ID#week) cluster(location_ID)
estimates save "$temp/Model_2", replace


global vars " "T_AV" "
foreach j in $vars {
lincomest  `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15, level(95)
}


reghdfe D.ln_tot_Case T_AV T_AV_L* if total_Case>=1 & country!="China", absorb(date_case#C_s location_ID#week) cluster(C_s)
estimates save "$temp/Model_3", replace


global vars " "T_AV" "
foreach j in $vars {
lincomest  `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15, level(95) 
}


global scales " "T_AV" "
 foreach j in $scales {


local i = 1
while `i' <= 3  {
estimates use "$temp/Model_`i'"
capture lincomest  `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15, level(95)
estimates store m`j'_`i'
local i = `i' + 1
}
}


	* output results to a txt and could copy this in excel to make tables
estout m* ///
using "$out/AT2.txt", ///
	cells( b(star fmt(%9.5f)) se(par(`"="("'`")""'))) ///
	title("") style(tab) keep((1)) ///
	stats(N, fmt(%10.0fc) labels("Observations")) label collabels(, none) ///
	starlevels(* .10 ** .05 *** .01) replace



---
---



********************************************************************************
********************************************************************************
*		 		APPENDIX TABLE A3	 			 		   *
********************************************************************************
********************************************************************************



set more off
estimates clear

use "$use/ready.dta", clear

gen week = week(date_case)
gen fortnight = int(week/2)
gen month = month(date_case)

bysort country date_case: egen total_country = sum(total_Case)
bysort country: egen max_country = max(total_country)
sort location_ID date_case
keep if  L.total_country!=max_country

drop *L16 *L17 *L18 *L19 *L20 *L21



reghdfe D.ln_tot_Case T_AV* RH* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)
estimates save "$temp/Model_1", replace


reghdfe D.ln_tot_Case T_AV* RH* TP* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)
estimates save "$temp/Model_2", replace



gen AV_RH = T_AV * RH
local i = 1
while `i'<=15 {
gen AV_RH_L`i' = L`i'.AV_RH
local i = `i'+1
}

reghdfe D.ln_tot_Case T_AV* RH* TP* AV_RH* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)
estimates save "$temp/Model_3", replace

gen THIRTY = T_AV * (T_AV >25)
gen ZERO = T_AV * (T_AV <0)

local i = 1
while `i'<= 15 {
gen ZERO_L`i' = L`i'.ZERO
local i = `i' + 1 
}

local i = 1
while `i'<= 15 {
gen THIRTY_L`i' = L`i'.THIRTY
local i = `i' + 1 
}



reghdfe D.ln_tot_Case T_AV* ZERO* THIRTY* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)
estimates save "$temp/Model_4", replace

reghdfe D.ln_tot_Case TMAX TMIN TMAX_L* TMIN_L* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)
estimates save "$temp/Model_5", replace



	****** output results
global scales " "T_AV" "ZERO" "THIRTY" "TMAX" "TMIN" "TP" "RH" "AV_RH" "
 foreach j in $scales {


local i = 1
while `i' <= 5 /* adapt to no. of columns */{
estimates use "$temp/Model_`i'"
capture lincomest  `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15, level(95)
estimates store m`j'_`i'
local i = `i' + 1
}
}

	* output results to a txt and could copy this in excel to make tables
estout m* ///
using "$out/AT3.txt", ///
	cells( b(star fmt(%9.4f)) se(par(`"="("'`")""'))) ///
	title("") style(tab) keep((1)) ///
	stats(N, fmt(%10.0fc) labels("Observations")) label collabels(, none) ///
	starlevels(* .10 ** .05 *** .01) replace
	
	*Get the mean value of dependent variable for different estimates




********************************************************************************
********************************************************************************
*		APPENDIX TABLE A4	   *
********************************************************************************
********************************************************************************

set more off
estimates clear


use "$use/ready.dta", clear

gen week = week(date_case)
gen fortnight = int(week/2)
gen month = month(date_case)

bysort country date_case: egen total_country = sum(total_Case)
bysort country: egen max_country = max(total_country)
sort location_ID date_case
keep if  L.total_country!=max_country

drop *L16 *L17 *L18 *L19 *L20 *L21


reg D.ln_tot_Case T_AV* if total_Case>=1, cluster(country)
estimates save "$temp/Model_1", replace

reghdfe D.ln_tot_Case T_AV* if total_Case>=1, absorb(date_case C_s) cluster(country)
estimates save "$temp/Model_2", replace


reghdfe D.ln_tot_Case T_AV* if total_Case>=1, absorb(date_case location_ID) cluster(country)
estimates save "$temp/Model_3", replace

reghdfe D.ln_tot_Case T_AV* if total_Case>=1, absorb(date_case#C_s location_ID) cluster(country)
estimates save "$temp/Model_4", replace


reghdfe D.ln_tot_Case T_AV* if total_Case>=1, absorb(date_case location_ID#week) cluster(country)
estimates save "$temp/Model_5", replace
gen meany_5=D.ln_tot_Case if e(sample)

reghdfe D.ln_tot_Case T_AV* if total_Case>=1, absorb(date_case##C_s location_ID#week) cluster(country)
estimates save "$temp/Model_6", replace



	* output results
global scales " "T_AV"  "
 foreach j in $scales {


local i = 1
while `i' <= 6 {
estimates use "$temp/Model_`i'"
capture lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15,level(95)
estimates store m`j'_`i'
local i = `i' + 1
}
}

	* output results to a txt and could copy this in excel to make tables
estout m* ///
using "$out/AT4.txt", ///
	cells( b(star fmt(%9.5f)) se(par(`"="("'`")""'))) ///
	title("") style(tab) keep((1)) ///
	stats(N, fmt(%10.0fc) labels("Observations")) label collabels(, none) ///
	starlevels(* .10 ** .05 *** .01) replace
	





********************************************************************************
********************************************************************************
*			APPENDIX TABLE A5: Alternative number of day lags	 			 		   *
********************************************************************************
********************************************************************************

*	Change number of lags, using BASELINE MODEL (column 1 in Table 1)


set more off
estimates clear

use "$use/ready.dta", clear

gen week = week(date_case)
gen fortnight = int(week/2)
gen month = month(date_case)

bysort country date_case: egen total_country = sum(total_Case)
bysort country: egen max_country = max(total_country)
sort location_ID date_case
keep if  L.total_country!=max_country


global scales " "T_AV"  " //we only need the coefficients for T_AV

drop *_L21


	*20 lags

	reghdfe D.ln_tot_Case T_AV* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)

foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 + `j'_L16 + `j'_L17 + `j'_L18 + `j'_L19 + `j'_L20,level(95)
est store lag20
}

	*19 lags
drop *L20
reghdfe D.ln_tot_Case T_AV* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)

foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 + `j'_L16 + `j'_L17 + `j'_L18 + `j'_L19, level(95)
est store lag19
}

	*18 lags
drop *L19 
reghdfe D.ln_tot_Case T_AV*  if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)


foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 + `j'_L16 + `j'_L17 + `j'_L18 , level(95)
est store lag18
}


	*17 lags
drop *L18 
reghdfe D.ln_tot_Case T_AV*  if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)


foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 + `j'_L16 + `j'_L17 , level(95) 
est store lag17
}

	*16 lags
drop *L17
reghdfe D.ln_tot_Case T_AV*  if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)

foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 + `j'_L16 , level(95)
est store lag16
}

	*15 lags (which is the baseline model)
drop *L16 
reghdfe D.ln_tot_Case T_AV*  if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)

foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 , level(95)
est store lag15
}


	*14 lags
drop *L15 
reghdfe D.ln_tot_Case T_AV*  if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)

foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 , level(95)
est store lag14
}

	*13 lags
drop *L14 
reghdfe D.ln_tot_Case T_AV*  if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)

foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13, level(95)
est store lag13
}

	*12 lags
drop *L13
reghdfe D.ln_tot_Case T_AV*  if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)

foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 , level(95)
est store lag12
}

	*11 lags
drop *L12 
reghdfe D.ln_tot_Case T_AV*  if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)

foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 , level(95)
est store lag11
}

	*10 lags
drop *L11 
reghdfe D.ln_tot_Case T_AV*  if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)

foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 , level(95)
est store lag10
}

	*9 lags
drop *L10 
reghdfe D.ln_tot_Case T_AV*  if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)

foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 , level(95)
est store lag9
}

	*8 lags
drop *L9 
reghdfe D.ln_tot_Case T_AV*  if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)

foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7+ `j'_L8 , level(95)
est store lag8
}
	*7 lags
drop *L8 
reghdfe D.ln_tot_Case T_AV*  if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)

foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 , level(95)
est store lag7
}

	*6 lags
drop *L7 
reghdfe D.ln_tot_Case T_AV*  if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)

foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6, level(95)
est store lag6
}

	*5 lags
drop *L6 
reghdfe D.ln_tot_Case T_AV*  if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)

foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 , level(95)
est store lag5
}

	*4 lags
drop *L5 
reghdfe D.ln_tot_Case T_AV*  if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)

foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 , level(95)
est store lag4
}


	*3 lags
drop *L4 
reghdfe D.ln_tot_Case T_AV*  if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)

foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 , level(95)
est store lag3
}

	*2 lags
drop *L3 
reghdfe D.ln_tot_Case T_AV*  if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)

foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 , level(95)
est store lag2
}

	*1 lag
drop *L2 
reghdfe D.ln_tot_Case T_AV*  if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)

foreach j in $scales {
lincomest `j' + `j'_L1 , level(95)
est store lag1
}

	*0 lag
drop *L1 
reghdfe D.ln_tot_Case T_AV*  if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)


foreach j in $scales {
lincomest `j' , level(95)
est store lag0
}

	* output results
estout lag* ///
using "$out/AT5.txt", ///
	cells( b(star fmt(%9.4f)) se(par(`"="("'`")""'))) ///
	title("") style(tab) keep((1)) ///
	stats(N, fmt(%10.0fc) labels("Observations")) label collabels(, none) ///
	starlevels(* .10 ** .05 *** .01) replace





********************************************************************************
********************************************************************************
*		APPENDIX TABLE A6 *
********************************************************************************
********************************************************************************



use  "$use/ready.dta", clear


set more off
estimates clear


bysort country date_case: egen total_country = sum(total_Case)
bysort country: egen max_country = max(total_country)
sort location_ID date_case
keep if  L.total_country!=max_country

gen week = week(date_case)
gen month = month(date_case)

sort location_ID date_case


local i = 1
while `i' <= 17 {
local j = `i' + 1
local k = `i' + 2
local l = `i' + 3
gen T_AV_X`l' = (T_AV_L`i' +  T_AV_L`j' + T_AV_L`k'+ T_AV_L`l')/4
local i = `i'+4
}


reghdfe D.ln_tot_Case T_AV T_AV_X* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(location_ID)
estimates save "$temp/Model_1", replace



global vars " "T_AV" "
foreach j in $vars {
lincomest  `j' +  `j'_X4 + `j'_X8 +  `j'_X12 +  `j'_X16 +   `j'_X20  , level(95)
est store lag20
}


drop *X20


reghdfe D.ln_tot_Case T_AV T_AV_X* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(location_ID)
estimates save "$temp/Model_1", replace



global vars " "T_AV" "
foreach j in $vars {
lincomest  `j' +  `j'_X4 + `j'_X8 +  `j'_X12 +  `j'_X16  , level(95)
est store lag16
}



drop *X16


reghdfe D.ln_tot_Case T_AV T_AV_X* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(location_ID)
estimates save "$temp/Model_1", replace



global vars " "T_AV" "
foreach j in $vars {
lincomest  `j' +  `j'_X4 + `j'_X8 +  `j'_X12   , level(95)
est store lag12
}




drop *X12

reghdfe D.ln_tot_Case T_AV T_AV_X* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(location_ID)
estimates save "$temp/Model_1", replace



global vars " "T_AV" "
foreach j in $vars {
lincomest  `j' +  `j'_X4 + `j'_X8    , level(95)
est store lag8
}



drop *X8


reghdfe D.ln_tot_Case T_AV T_AV_X* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(location_ID)
estimates save "$temp/Model_1", replace



global vars " "T_AV" "
foreach j in $vars {
lincomest  `j' +  `j'_X4  , level(95)
est store lag4
}



drop *X4


reghdfe D.ln_tot_Case T_AV if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(location_ID)
estimates save "$temp/Model_1", replace



global vars " "T_AV" "
foreach j in $vars {
lincomest  `j' , level(95)
est store lag0
}


* output results
estout lag* ///
using "$out/AT6.txt", ///
	cells( b(star fmt(%9.4f)) se(par(`"="("'`")""'))) ///
	title("") style(tab) keep((1)) ///
	stats(N, fmt(%10.0fc) labels("Observations")) label collabels(, none) ///
	starlevels(* .10 ** .05 *** .01) replace





	

********************************************************************************
********************************************************************************
*		APPENDIX TABLE 4 : Weather summary statistics *
********************************************************************************
********************************************************************************
use "$use/ready.dta", clear
set more off


reghdfe D.ln_tot_Case T_AV* TP* RH* if total_Case>=1, absorb(date_case#C_s location_ID) cluster(country)
estimates esample

sum T_AV TMIN TMAX Temp_0 Temp_10 Temp_20 Temp_30 Temp_30p TMIN_m10 TMIN_0 TMIN_10 TMIN_20 TMIN_20p TMAX_10 TMAX_20 TMAX_30 TMAX_40 TMAX_40p TP RH if e(sample) 

gen var=1
** Summarize 
tabout var  if e(sample) using "$out/AT4.txt", ///
	c(mean T_AV mean TMIN mean TMAX mean Temp_0 mean Temp_10 mean Temp_20 mean Temp_30 mean Temp_30p mean TMIN_m10 mean TMIN_0 mean TMIN_10 mean TMIN_20 mean TMIN_20p mean TMAX_10 mean TMAX_20 mean TMAX_30 mean TMAX_40 mean TMAX_40p mean TP mean RH ///
	min T_AV min TMIN min TMAX min Temp_0 min Temp_10 min Temp_20 min Temp_30 min Temp_30p min TMIN_m10 min TMIN_0 min TMIN_10 min TMIN_20 min TMIN_20p min TMAX_10 min TMAX_20 min TMAX_30 min TMAX_40 min TMAX_40p min TP min RH ///
	max T_AV max TMIN max TMAX max Temp_0 max Temp_10 max Temp_20 max Temp_30 max Temp_30p max TMIN_m10 max TMIN_0 max TMIN_10 max TMIN_20 max TMIN_20p max TMAX_10 max TMAX_20 max TMAX_30 max TMAX_40 max TMAX_40p max TP max RH ///
	sd T_AV sd TMIN sd TMAX sd Temp_0 sd Temp_10 sd Temp_20 sd Temp_30 sd Temp_30p sd TMIN_m10 sd TMIN_0 sd TMIN_10 sd TMIN_20 sd TMIN_20p sd TMAX_10 sd TMAX_20 sd TMAX_30 sd TMAX_40 sd TMAX_40p sd TP sd RH ///
	N T_AV N TMIN N TMAX N Temp_0 N Temp_10 N Temp_20 N Temp_30 N Temp_30p N TMIN_m10 N TMIN_0 N TMIN_10 N TMIN_20 N TMIN_20p N TMAX_10 N TMAX_20 N TMAX_30 N TMAX_40 N TMAX_40p N TP  N RH) ///
	f(2c 2c 2c 2c 2c  2c 2c 2c 2c 2c 2c 2c 2c 2c 2c  2c 2c 2c 2c 2c 2c 2c 2c 2c 2c  2c 2c 2c 2c 2c 2c 2c 2c 2c 2c  2c 2c 2c 2c 2c  2c 2c 2c 2c 2c  2c 2c 2c 2c 2c 2c 2c 2c 2c 2c  2c 2c 2c 2c 2c  2c 2c 2c 2c 2c  2c 2c 2c 2c 2c 2c 2c 2c 2c 2c  2c 2c 2c 2c 2c  0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c) ///
	clab(T_AV TMIN TMAX Temp_0 Temp_10 Temp_20 Temp_30 Temp_30p TMIN_m10 TMIN_0 TMIN_10 TMIN_20 TMIN_20p TMAX_10 TMAX_20 TMAX_30 TMAX_40 TMAX_40p TP RH  ///
	T_AV TMIN TMAX Temp_0 Temp_10 Temp_20 Temp_30 Temp_30p TMIN_m10 TMIN_0 TMIN_10 TMIN_20 TMIN_20p TMAX_10 TMAX_20 TMAX_30 TMAX_40 TMAX_40p TP RH  ///
	T_AV TMIN TMAX Temp_0 Temp_10 Temp_20 Temp_30 Temp_30p TMIN_m10 TMIN_0 TMIN_10 TMIN_20 TMIN_20p TMAX_10 TMAX_20 TMAX_30 TMAX_40 TMAX_40p TP RH  ///
	T_AV TMIN TMAX Temp_0 Temp_10  Temp_20 Temp_30 Temp_30p TMIN_m10 TMIN_0 TMIN_10 TMIN_20 TMIN_20p TMAX_10 TMAX_20 TMAX_30 TMAX_40 TMAX_40p TP RH  ///
	T_AV TMIN TMAX Temp_0 Temp_10  Temp_20 Temp_30 Temp_30p TMIN_m10 TMIN_0 TMIN_10 TMIN_20 TMIN_20p TMAX_10 TMAX_20 TMAX_30 TMAX_40 TMAX_40p TP RH ) sum replace	
	
	

****************************************************************************************************************************************************************
****************************************************************************************************************************************************************
*			FIGURES		 		   *
****************************************************************************************************************************************************************
****************************************************************************************************************************************************************



********************************************************************************
********************************************************************************
*			APPENDIX FIGURE A2			 		   *
********************************************************************************
********************************************************************************

set more off
estimates clear

use "$use/ready.dta", clear

gen week = week(date_case)
gen fortnight = int(week/2)
gen month = month(date_case)

bysort country date_case: egen total_country = sum(total_Case)
bysort country: egen max_country = max(total_country)
sort location_ID date_case
keep if  L.total_country!=max_country


drop *L16 *L17 *L18 *L19 *L20 *L21


reghdfe D.ln_tot_Case T_AV* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)
estimates save "$temp/Model_1", replace
gen meany_1=D.ln_tot_Case if e(sample)
sum meany_1

global vars " "T_AV" "
foreach j in $vars {
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 
}


#delim;
clear all;
set obs 25;

estimates use "$temp/Model_1";


#delim;
local i = 1;
gen coeff_AV = .;
gen se_AV = .;
lincom T_AV;
replace coeff_AV = r(estimate) in 1;
replace se_AV = r(se) in 1;
while `i' <=15 {;
local s = `i'+1;
lincom T_AV_L`i';
replace coeff_AV = r(estimate) in `s';
replace se_AV = r(se) in `s';
local i = `i'+1;
};


#delim;
gen se_AV_plus = (coeff_AV + 1.96*se_AV);
gen se_AV_minus = (coeff_AV - 1.96*se_AV);
replace coeff_AV = (coeff_AV);

gen n = _n-1 if _n<=16;


#delim;

label variable n "No. days before confirmation (Av. Temperature)";
twoway  (scatter coeff_AV n, mcolor(forest_green) msymbol(diamond)) (rarea se_AV_minus se_AV_plus n if n<=16, sort fcolor(forest_green%40) lcolor(forest_green%40) lwidth(vvvthin) cmissing(n)) (line coeff_AV n, sort lcolor(forest_green) lwidth(medium) lpattern(longdash))
, ytitle("Difference in logarithm of total cases", size(large)) yline(0, lcolor(black)) ylabel(, glcolor(gs5%25) glpattern(dash) labsize(large)) xtitle(, color(none) size(large)) xlabel(0(3)15, valuelabel labsize(large)) legend(off) graphregion(fcolor(white) lcolor(white));
graph export "$out/Figure_dynamics.png", replace;




***
* LOOK AT INDIVIDUAL COEFFICIENTS FOR T MIN AND T MAX TOO
***

** TMIN 

set more off
estimates clear

use "$use/ready.dta", clear

gen week = week(date_case)
gen fortnight = int(week/2)
gen month = month(date_case)

bysort country date_case: egen total_country = sum(total_Case)
bysort country: egen max_country = max(total_country)
sort location_ID date_case
keep if  L.total_country!=max_country


drop *L16 *L17 *L18 *L19 *L20 *L21


reghdfe D.ln_tot_Case TMAX TMIN TMAX_L* TMIN_L* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)
estimates save "$temp/Model_1", replace


#delim;
clear all;
set obs 25;

estimates use "$temp/Model_1";


#delim;
local i = 1;
gen coeff_AV = .;
gen se_AV = .;


lincom TMIN;
replace coeff_AV = r(estimate) in 1;
replace se_AV = r(se) in 1;
while `i' <=15 {;
local s = `i'+1;


lincom TMIN_L`i';
replace coeff_AV = r(estimate) in `s';
replace se_AV = r(se) in `s';
local i = `i'+1;
};


#delim;
gen se_AV_plus = (coeff_AV + 1.96*se_AV);
gen se_AV_minus = (coeff_AV - 1.96*se_AV);
replace coeff_AV = (coeff_AV);

gen n = _n-1 if _n<=16;
label variable n "No. days before confirmation (Min. Temperature)";
twoway  (scatter coeff_AV n, mcolor(edkblue) msymbol(diamond)) (rarea se_AV_minus se_AV_plus n if n<=15, sort fcolor(edkblue%40) lcolor(edkblue%40) lwidth(vvvthin) cmissing(n)) (line coeff_AV n, sort lcolor(edkblue) lwidth(medium) lpattern(longdash))
, ytitle("Difference in logarithm of total cases", size(large)) yline(0, lcolor(black)) ylabel(, glcolor(gs5%25) glpattern(dash) labsize(large)) xtitle(, color(none) size(large)) xlabel(0(3)15, valuelabel labsize(large)) legend(off) graphregion(fcolor(white) lcolor(white));
graph export "$out/Figure_dynamics_MIN.png", replace;



** TMAX



set more off
estimates clear

use "$use/ready.dta", clear

gen week = week(date_case)
gen fortnight = int(week/2)
gen month = month(date_case)

bysort country date_case: egen total_country = sum(total_Case)
bysort country: egen max_country = max(total_country)
sort location_ID date_case
keep if  L.total_country!=max_country


drop *L16 *L17 *L18 *L19 *L20 *L21

reghdfe D.ln_tot_Case TMAX TMIN TMAX_L* TMIN_L* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)
estimates save "$temp/Model_1", replace


#delim;
clear all;
set obs 25;

estimates use "$temp/Model_1";


#delim;
local i = 1;
gen coeff_AV = .;
gen se_AV = .;


lincom TMAX;
replace coeff_AV = r(estimate) in 1;
replace se_AV = r(se) in 1;
while `i' <=15 {;
local s = `i'+1;


lincom TMAX_L`i';
replace coeff_AV = r(estimate) in `s';
replace se_AV = r(se) in `s';
local i = `i'+1;
};


#delim;
gen se_AV_plus = (coeff_AV + 1.96*se_AV);
gen se_AV_minus = (coeff_AV - 1.96*se_AV);
replace coeff_AV = (coeff_AV);

gen n = _n-1 if _n<=16;
label variable n "No. days before confirmation (Max. Temperature)";
twoway  (scatter coeff_AV n, mcolor(red) msymbol(diamond)) (rarea se_AV_minus se_AV_plus n if n<=15, sort fcolor(red%40) lcolor(red%40) lwidth(vvvthin) cmissing(n)) (line coeff_AV n, sort lcolor(red) lwidth(medium) lpattern(longdash))
, ytitle("Difference in logarithm of total cases", size(large)) yline(0, lcolor(black)) ylabel(, glcolor(gs5%25) glpattern(dash) labsize(large)) xtitle(, color(none) size(large)) xlabel(0(3)15, valuelabel labsize(large)) legend(off) graphregion(fcolor(white) lcolor(white));
graph export "$out/Figure_dynamics_MAX.png", replace;

