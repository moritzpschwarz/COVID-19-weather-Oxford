clear all
set more off
/*
The Influence of the Weather on COVID-19 using Geospatial Data
Francois Cohen, Sihan Li, Yangsiyu Lu and Moritz Schwarz 

**SUMMARY
The purpose of this file is to generate tables for the paper.

last updated by FC, 11 April, 2020
*/


*MS's path
cd "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper" 
global temp "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\stata\temp" 
global raw "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\Data\" 
global use "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\stata\use"
global out "C:\Users\morit\OneDrive - Nexus365\Covid-19 Paper\stata\out"


*FC's path
cd "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/" 
global temp "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/temp" 
global raw "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Data" 
global use "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/use"
global out "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/out"


*YL's paths
*cd "/Users/yangsiyu/Documents/D/oxford/Research/RA/RA5COVID19/stata/" 
*global temp "/Users/yangsiyu/Documents/D/oxford/Research/RA/RA5COVID19/stata/temp" 
*global raw "/Users/yangsiyu/Documents/D/oxford/Research/RA/RA5COVID19/stata/raw" 
*global use "/Users/yangsiyu/Documents/D/oxford/Research/RA/RA5COVID19/stata/use"
*global out "/Users/yangsiyu/Documents/D/oxford/Research/RA/RA5COVID19/stata/out"


********************************************************************************
*************************	Preparation  ***************************************
********************************************************************************

*Data input: this do file starts from ESTIMATION_DDMMYY.dta, which already merged COVID and CLIMATE data.
*use "$raw/ESTIMATION_300320.dta",clear 

use "$raw/ESTIMATION_extended_080420.dta",clear 
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
gen T_AV = (TMAX + TMIN)/2

local i = 1
while `i'<= 21 {
gen T_AV_L`i' = L`i'.T_AV
local i = `i' + 1 
}
	*create temperrature bins	

***** 10 degrees bins 
	** AV TEMP	
gen Temp_0 = T_AV<=0
gen Temp_10 = T_AV<=10
gen Temp_20 = T_AV<=20
gen Temp_30 = T_AV<=30
gen Temp_30p = T_AV>=30  & T_AV!=.

replace Temp_30 = Temp_30 - Temp_20
replace Temp_20 = Temp_20 - Temp_10
replace Temp_10 = Temp_10 - Temp_0


local i = 1
while `i'<= 21 {
gen Temp_0_L`i' = L`i'.Temp_0
gen Temp_10_L`i' = L`i'.Temp_10
gen Temp_20_L`i' = L`i'.Temp_20
gen Temp_30_L`i' = L`i'.Temp_30
gen Temp_30p_L`i' = L`i'.Temp_30p
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
*			MAIN RESULTS : UPPER PANELS 			 		   *
********************************************************************************
********************************************************************************


set more off
estimates clear
use "$use/ready.dta", clear


bysort country date_case: egen total_country = sum(total_Case)
bysort country: egen max_country = max(total_country)
sort location_ID date_case
keep if  L.total_country!=max_country

gen week = week(date_case)


drop Temp_20*

*drop if country=="China"
drop if country!="China"

reghdfe D.ln_tot_Case Temp_* if total_Case>=1, absorb(date_case location_ID##week) cluster(location_ID)
estimates save "$temp/Model_1", replace
*get the mean value of dependent variable
gen meany_1=D.ln_tot_Case if total_Case>=1

*Prepare settings for the graph
#delim;
clear all;
set obs 13;

estimates use "$temp/Model_1";
global scales " "Temp_0"  "Temp_10" "Temp_30" "Temp_30p" ";

;
local i = 1;
gen coeff = .;
gen se = .;
foreach j in $scales {;
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15
 + `j'_L16  + `j'_L17  + `j'_L18  + `j'_L19  + `j'_L20  + `j'_L21 
;
replace coeff = r(estimate) in `i';
replace se = r(se) in `i';
local i = `i'+1;
};

#delim;
gen se_plus = (coeff + 1.96*se);
gen se_minus = (coeff - 1.96*se);
replace coeff = (coeff)	;
gen n = _n if _n<3;
replace n = _n+1 if _n>=3;
replace se_plus = 0 in 13;
replace se_minus = 0 in 13;
replace coeff = 0 in 13;
replace n=3 in 13;

label variable n "Average Temperature (°C)";
label define n_label 1 "<0" 2 "0-10" 3 "10-20" 4 "20-30" 5 ">30";
label values n n_label;

#delim;
replace coeff = . if n==5;
replace  se_plus = . if n==5;
replace  se_minus = . if n==5;


twoway  (scatter coeff n, mcolor(forest_green) msymbol(diamond)) (rarea se_minus se_plus n, sort fcolor(forest_green%40) lcolor(forest_green%40) lwidth(vvvthin) cmissing(n)) 
(line coeff n, sort lcolor(forest_green) lwidth(medium) lpattern(longdash)) if n<=5 & n>=1, ytitle("Difference in logarithm of total cases") yline(0, lcolor(black)) 
ylabel(-1(0.5)0.5, glcolor(gs5%25) glpattern(dash)) xtitle(, color(none)) xlabel(1(1)5, valuelabel labsize(small)) legend(off) graphregion(fcolor(white) lcolor(white));
graph export "$out/Figure_bins_China.png", replace;
*graph export "$out/Figure_bins_Outside_China.png", replace;


********************************************************************************
********************************************************************************
*			MAIN RESULTS : LOWER PANELS 			 		   *
********************************************************************************
********************************************************************************


set more off

use "$use/ready.dta", clear


bysort country date_case: egen total_country = sum(total_Case)
bysort country: egen max_country = max(total_country)
sort location_ID date_case
keep if  L.total_country!=max_country


replace TMIN_20 = TMIN_20 + TMIN_20p

local i = 1
while `i'<=21 {
replace TMIN_20_L`i' = L`i'.TMIN_20
local i = `i'+1
}
drop *20p*

gen week = week(date_case)


gen TMAX_40_G = TMAX_40 + TMAX_40p


local i = 1
while `i'<=21 {
gen TMAX_40_G_L`i' = L`i'.TMAX_40_G
local i = `i'+1
}

reghdfe D.ln_tot_Case TMIN_m10* TMIN_0* TMIN_20* TMAX_10* TMAX_20* TMAX_40_G* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(location_ID)
estimates save "$temp/Model_2", replace
*get the mean value of dependent variable
gen meany_2=D.ln_tot_Case if total_Case>=1


#delim;
clear all;
set obs 13;

estimates use "$temp/Model_2";

global scales " "TMIN_m10" "TMIN_0" "TMIN_20" ";
local i = 1;
gen coeff = .;
gen se = .;
foreach j in $scales {;
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15
 + `j'_L16  + `j'_L17  + `j'_L18  + `j'_L19  + `j'_L20  + `j'_L21 
;
replace coeff = r(estimate) in `i';
replace se = r(se) in `i';
local i = `i'+1;
};
#delim;
gen se_plus = (coeff + 1.96*se);
gen se_minus = (coeff - 1.96*se);
replace coeff = (coeff);
gen n = _n if _n<3;
replace n = _n+1 if _n>=3;
replace coeff = 0 in 13;
replace se_plus = 0 in 13;
replace se_minus = 0 in 13;
replace n=3 in 13;

label variable n "Minimum Temperature (°C)";
label define n_label 1 "<-10" 2 "-10-0" 3 "0-10" 4 ">10" ;
label values n n_label;

#delim;
twoway  (scatter coeff n, mcolor(edkblue) msymbol(diamond)) (rarea se_minus se_plus n, sort fcolor(edkblue%40) lcolor(edkblue%40) lwidth(vvvthin) cmissing(n)) 
(line coeff n, sort lcolor(edkblue) lwidth(medium) lpattern(longdash)) if n<=4 & n>=1, ytitle("Difference in logarithm of total cases") yline(0, lcolor(black)) 
ylabel(-0.4(0.2)0.4, glcolor(gs5%25) glpattern(dash)) xtitle(, color(none)) xlabel(1(1)4, valuelabel labsize(small)) legend(off) graphregion(fcolor(white) lcolor(white));
*title("Specification with 10°C temperature bins");
graph export "$out/Figure_bins_min.png", replace;




#delim;
clear all;
set obs 13;

estimates use "$temp/Model_2";

global scales " "TMAX_10" "TMAX_20"  "TMAX_40_G" ";
;
local i = 1;
gen coeff = .;
gen se = .;
foreach j in $scales {;
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15
 + `j'_L16  + `j'_L17  + `j'_L18  + `j'_L19  + `j'_L20  + `j'_L21 
 ;
replace coeff = r(estimate) in `i';
replace se = r(se) in `i';
local i = `i'+1;
};
#delim;
gen se_plus = (coeff + 1.96*se);
gen se_minus = (coeff - 1.96*se);
replace coeff = (coeff);
gen n = _n if _n<3;
replace n = _n+1 if _n>=3;
replace coeff = 0 in 13;
replace se_plus = 0 in 13;
replace se_minus = 0 in 13;
replace n=3 in 13;

label variable n "Maximum Temperature (°C)";
label define n_label 1 "<10" 2 "10-20" 3 "20-30" 4 ">30" ;
label values n n_label;


*#delim;
*replace coeff = . if n==5;
*replace  se_plus = . if n==5;
*replace  se_minus = . if n==5;

#delim;
twoway  (scatter coeff n, mcolor(red) msymbol(diamond)) (rarea se_minus se_plus n, sort fcolor(red%40) lcolor(red%40) lwidth(vvvthin) cmissing(n)) 
(line coeff n, sort lcolor(red) lwidth(medium) lpattern(longdash)) if n<=4 & n>=1, ytitle("Difference in logarithm of total cases") yline(0, lcolor(black)) 
ylabel(-0.4(0.2)0.4, glcolor(gs5%25) glpattern(dash)) xtitle(, color(none)) xlabel(1(1)4, valuelabel labsize(small)) legend(off) graphregion(fcolor(white) lcolor(white));
*title("Specification with 10°C temperature bins");
graph export "$out/Figure_bins_max.png", replace;




********************************************************************************
********************************************************************************
*		 		 LINEARISED RESULTS 	 			 		   *
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


* Column 1: Temperatures and humidity (BASELINE MODEL)
reghdfe D.ln_tot_Case T_AV* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)
estimates save "$temp/Model_1", replace
putexcel set "$temp/Baseline_Model", sheet("Baseline_Model") replace
putexcel A1=matrix(r(table)), names
*get the mean value of dependent variable
gen meany_1=D.ln_tot_Case if e(sample)
sum meany_1

global vars " "T_AV" "
foreach j in $vars {
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15  + `j'_L16 + `j'_L17 + `j'_L18 + `j'_L19 + `j'_L20 + `j'_L21 
}


reghdfe D.ln_tot_Case T_AV* if total_Case>=1 & country=="China", absorb(date_case#C_s location_ID#week) cluster(location_ID)
estimates save "$temp/Model_2", replace
*get the mean value of dependent variable
gen meany_2=D.ln_tot_Case if e(sample)

global vars " "T_AV" "
foreach j in $vars {
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15  + `j'_L16 + `j'_L17 + `j'_L18 + `j'_L19 + `j'_L20 + `j'_L21 
}


reghdfe D.ln_tot_Case T_AV* if total_Case>=1 &  country!="China", absorb(date_case#C_s location_ID#week) cluster(country)
estimates save "$temp/Model_3", replace
*get the mean value of dependent variable
gen meany_3=D.ln_tot_Case if e(sample)


global vars " "T_AV" "
foreach j in $vars {
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15  + `j'_L16 + `j'_L17 + `j'_L18 + `j'_L19 + `j'_L20 + `j'_L21 
}


global scales " "T_AV" "
 foreach j in $scales {


local i = 1
while `i' <= 3 /* adapt to no. of columns */{
estimates use "$temp/Model_`i'"
capture lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 + `j'_L16 + `j'_L17 + `j'_L18 + `j'_L19 + `j'_L20 + `j'_L21, level(95)
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
	
	*Get the mean value of dependent variable for different estimates
tabstat meany_*




********************************************************************************
********************************************************************************
*		 		 ADDING WEATHER VARIABLES	 			 		   *
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


reghdfe D.ln_tot_Case T_AV* RH* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)
estimates save "$temp/Model_1", replace


reghdfe D.ln_tot_Case T_AV* RH* TP* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)
estimates save "$temp/Model_2", replace


* Column 4: interact with humidity
gen AV_RH = T_AV * RH
local i = 1
while `i'<=21 {
gen AV_RH_L`i' = L`i'.AV_RH
local i = `i'+1
}

reghdfe D.ln_tot_Case T_AV* RH* TP* AV_RH* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)
estimates save "$temp/Model_3", replace
*get the mean value of dependent variable
gen meany_4=D.ln_tot_Case if e(sample)



* Column 2: uses 3 trends to capture the effect of an extra degree over three segments: <0,>30

gen THIRTY = T_AV * (T_AV >=30)
gen ZERO = T_AV * (T_AV <=0)

local i = 1
while `i'<= 21 {
gen ZERO_L`i' = L`i'.ZERO
local i = `i' + 1 
}

local i = 1
while `i'<= 21 {
gen THIRTY_L`i' = L`i'.THIRTY
local i = `i' + 1 
}



reghdfe D.ln_tot_Case T_AV* ZERO* THIRTY* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)
estimates save "$temp/Model_4", replace

reghdfe D.ln_tot_Case TMAX TMIN TMAX_L* TMIN_L* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)
//have to seperately code TMAX TMIN TMAX_L* TMIN_L* as there are TMAX/TMIN temp bins)
estimates save "$temp/Model_5", replace
*get the mean value of dependent variable
gen meany_3=D.ln_tot_Case if e(sample)



	****** output results
global scales " "T_AV" "ZERO" "THIRTY" "TMAX" "TMIN" "TP" "RH" "AV_RH" "
 foreach j in $scales {


local i = 1
while `i' <= 5 /* adapt to no. of columns */{
estimates use "$temp/Model_`i'"
capture lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 + `j'_L16 + `j'_L17 + `j'_L18 + `j'_L19 + `j'_L20 + `j'_L21, level(95)
estimates store m`j'_`i'
local i = `i' + 1
}
}

	* output results to a txt and could copy this in excel to make tables
estout m* ///
using "$out/AT3.txt", ///
	cells( b(star fmt(%9.5f)) se(par(`"="("'`")""'))) ///
	title("") style(tab) keep((1)) ///
	stats(N, fmt(%10.0fc) labels("Observations")) label collabels(, none) ///
	starlevels(* .10 ** .05 *** .01) replace
	
	*Get the mean value of dependent variable for different estimates
tabstat meany_*




********************************************************************************
********************************************************************************
*		CHANGING THE FIXED EFFECTS 		   *
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


* Column 1: No fixed effects

reg D.ln_tot_Case T_AV* if total_Case>=1, cluster(country)
estimates save "$temp/Model_1", replace

* Column 2: Day FE

reghdfe D.ln_tot_Case T_AV* if total_Case>=1, absorb(date_case) cluster(country)
estimates save "$temp/Model_2", replace


* Column 3: Day FE + Country FE

reghdfe D.ln_tot_Case T_AV* if total_Case>=1, absorb(date_case C_s) cluster(country)
estimates save "$temp/Model_3", replace


* Column 4: Day FE + Area FE

reghdfe D.ln_tot_Case T_AV* if total_Case>=1, absorb(date_case location_ID) cluster(country)
estimates save "$temp/Model_4", replace

* Column 5: Day FE + COuntry by day FE (BASELINE, the same as Column 1 in Table 1)
reghdfe D.ln_tot_Case T_AV* if total_Case>=1, absorb(date_case#C_s location_ID) cluster(country)
estimates save "$temp/Model_5", replace
gen meany_5=D.ln_tot_Case if e(sample)



	* output results
global scales " "T_AV"  "
 foreach j in $scales {


local i = 1
while `i' <= 5 {
estimates use "$temp/Model_`i'"
capture lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15  + `j'_L16 + `j'_L17 + `j'_L18 + `j'_L19 + `j'_L20 + `j'_L21,level(95)
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
*			APPENDIX TABLE 2: Alternative number of day lags	 			 		   *
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

local i = 22
while `i'<= 30 {
gen T_AV_L`i' = L`i'.T_AV
local i = `i' + 1 
}


	*30 lags
reghdfe D.ln_tot_Case T_AV* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)


foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15  + `j'_L16 + `j'_L17 + `j'_L18 + `j'_L19 + `j'_L20 + `j'_L21 + `j'_L22 + `j'_L23 + `j'_L24 + `j'_L25 + `j'_L26 + `j'_L27 + `j'_L28 + `j'_L29 + `j'_L30 , level(95) 
est store lag30
}

drop *_L30


	*29 lags
reghdfe D.ln_tot_Case T_AV* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)


foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15  + `j'_L16 + `j'_L17 + `j'_L18 + `j'_L19 + `j'_L20 + `j'_L21 + `j'_L22 + `j'_L23 + `j'_L24 + `j'_L25 + `j'_L26 + `j'_L27 + `j'_L28 + `j'_L29  , level(95)
est store lag29
}

drop *_L29

	*28 lags
reghdfe D.ln_tot_Case T_AV* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)


foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15  + `j'_L16 + `j'_L17 + `j'_L18 + `j'_L19 + `j'_L20 + `j'_L21 + `j'_L22 + `j'_L23 + `j'_L24 + `j'_L25 + `j'_L26 + `j'_L27 + `j'_L28 , level(95)
est store lag28
}

drop *_L28


	*27 lags
reghdfe D.ln_tot_Case T_AV* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)


foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15  + `j'_L16 + `j'_L17 + `j'_L18 + `j'_L19 + `j'_L20 + `j'_L21 + `j'_L22 + `j'_L23 + `j'_L24 + `j'_L25 + `j'_L26 + `j'_L27, level(95)
est store lag27
}

drop *_L27

	*26 lags
reghdfe D.ln_tot_Case T_AV* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)


foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15  + `j'_L16 + `j'_L17 + `j'_L18 + `j'_L19 + `j'_L20 + `j'_L21 + `j'_L22 + `j'_L23 + `j'_L24 + `j'_L25 + `j'_L26, level(95) 
est store lag26
}

drop *_L26

	*25 lags
reghdfe D.ln_tot_Case T_AV* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)


foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15  + `j'_L16 + `j'_L17 + `j'_L18 + `j'_L19 + `j'_L20 + `j'_L21 + `j'_L22 + `j'_L23 + `j'_L24 + `j'_L25 , level(95)
est store lag25
}

drop *_L25


	*24 lags
reghdfe D.ln_tot_Case T_AV* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)


foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15  + `j'_L16 + `j'_L17 + `j'_L18 + `j'_L19 + `j'_L20 + `j'_L21 + `j'_L22 + `j'_L23 + `j'_L24, level(95)
est store lag24
}

drop *_L24


	*23 lags
reghdfe D.ln_tot_Case T_AV* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)


foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15  + `j'_L16 + `j'_L17 + `j'_L18 + `j'_L19 + `j'_L20 + `j'_L21 + `j'_L22 + `j'_L23 , level(95)
est store lag23
}

drop *_L23


	*22 lags
reghdfe D.ln_tot_Case T_AV* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)


foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15  + `j'_L16 + `j'_L17 + `j'_L18 + `j'_L19 + `j'_L20 + `j'_L21 + `j'_L22, level(95)
est store lag22
}

drop *_L22


	*21 lags
reghdfe D.ln_tot_Case T_AV* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)


foreach j in $scales {
lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15  + `j'_L16 + `j'_L17 + `j'_L18 + `j'_L19 + `j'_L20 + `j'_L21, level(95)
est store lag21
}

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
*		APPENDIX TABLE 3 : Restricting the sample below a certain number of national cases 	 		   *
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


* Robustness - Before n cases declared in the country: 500, 1000. 2000 and 5000

*	Column 1: <500
reghdfe D.ln_tot_Case T_AV*  if  COUNTRY_COUNT<1000 & total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)
estimates save "$temp/Model_1", replace
gen meany_1=D.ln_tot_Case if e(sample)

*	Column 2: <1000
reghdfe D.ln_tot_Case T_AV*  if  COUNTRY_COUNT<2500 & total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)
estimates save "$temp/Model_2", replace
gen meany_2=D.ln_tot_Case if e(sample)

*	Column 3: <2000
reghdfe D.ln_tot_Case T_AV*  if  COUNTRY_COUNT<5000 & total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)
estimates save "$temp/Model_3", replace
gen meany_3=D.ln_tot_Case if e(sample)

*	Column 4: <5000
reghdfe D.ln_tot_Case T_AV*  if  COUNTRY_COUNT>5000 & total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)
estimates save "$temp/Model_4", replace
gen meany_4=D.ln_tot_Case if e(sample)

* Column 5: Alldata (BASELINE, the same as Column 1 in Table 1)
reghdfe D.ln_tot_Case T_AV*  if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)
estimates save "$temp/Model_5", replace
gen meany_5=D.ln_tot_Case if e(sample)


	* output results
global scales " "T_AV" "TP" "RH" "
 foreach j in $scales {


local i = 1
while `i' <= 5 {
estimates use "$temp/Model_`i'"
capture lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15  + `j'_L16 + `j'_L17 + `j'_L18 + `j'_L19 + `j'_L20 + `j'_L21,level(95)
estimates store m`j'_`i'
local i = `i' + 1
}
}

	* output results to a txt and could copy this in excel to make tables
estout m* ///
using "$out/AT6.txt", ///
	cells( b(star fmt(%9.5f)) se(par(`"="("'`")""'))) ///
	title("") style(tab) keep((1)) ///
	stats(N, fmt(%10.0fc) labels("Observations")) label collabels(, none) ///
	starlevels(* .10 ** .05 *** .01) replace
tabstat meany_*


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
*			APPENDIX FIGURE: VALUE OF INDIVIDUAL LAGS			 		   *
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



reghdfe D.ln_tot_Case T_AV* if total_Case>=1, absorb(date_case#C_s location_ID#week) cluster(country)
estimates save "$temp/Model_1", replace
*get the mean value of dependent variable
gen meany_1=D.ln_tot_Case if e(sample)
sum meany_1

global vars " "T_AV" "
foreach j in $vars {
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15  + `j'_L16 + `j'_L17 + `j'_L18 + `j'_L19 + `j'_L20 + `j'_L21 
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
while `i' <=21 {;
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

gen n = _n-1 if _n<=22;
*replace n = _n+1 if _n>=9;
*replace se_plus = . in 13;
*replace se_minus = . in 13;
*replace coeff = 0 in 13;
*replace n=9 in 13;

#delim;

*label define n_label 1 "<10" 2 "10-12" 3 "12-14" 4 "14-16" 5 "16-18" 6 "18-20" 7 "20-22" 8 "22-24" 9 "24-26" 10 "26-28" 11 "28-30" 12 "30-32" 13 ">32";
*label values n n_label;
label variable n "No. days before confirmation (Av. Temperature)";
twoway  (scatter coeff_AV n, mcolor(forest_green) msymbol(diamond)) (rarea se_AV_minus se_AV_plus n if n<=22, sort fcolor(forest_green%40) lcolor(forest_green%40) lwidth(vvvthin) cmissing(n)) (line coeff_AV n, sort lcolor(forest_green) lwidth(medium) lpattern(longdash))
, ytitle("Difference in logarithm of total cases", size(large)) yline(0, lcolor(black)) ylabel(, glcolor(gs5%25) glpattern(dash) labsize(large)) xtitle(, color(none) size(large)) xlabel(0(3)21, valuelabel labsize(large)) legend(off) graphregion(fcolor(white) lcolor(white));
* title("Value of lags for daily av. temperature in model (3)");
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
while `i' <=21 {;
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

gen n = _n-1 if _n<=22;
label variable n "No. days before confirmation (Min. Temperature)";
twoway  (scatter coeff_AV n, mcolor(edkblue) msymbol(diamond)) (rarea se_AV_minus se_AV_plus n if n<=22, sort fcolor(edkblue%40) lcolor(edkblue%40) lwidth(vvvthin) cmissing(n)) (line coeff_AV n, sort lcolor(edkblue) lwidth(medium) lpattern(longdash))
, ytitle("Difference in logarithm of total cases", size(large)) yline(0, lcolor(black)) ylabel(, glcolor(gs5%25) glpattern(dash) labsize(large)) xtitle(, color(none) size(large)) xlabel(0(3)21, valuelabel labsize(large)) legend(off) graphregion(fcolor(white) lcolor(white));
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
while `i' <=21 {;
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

gen n = _n-1 if _n<=22;
label variable n "No. days before confirmation (Max. Temperature)";
twoway  (scatter coeff_AV n, mcolor(red) msymbol(diamond)) (rarea se_AV_minus se_AV_plus n if n<=22, sort fcolor(red%40) lcolor(red%40) lwidth(vvvthin) cmissing(n)) (line coeff_AV n, sort lcolor(red) lwidth(medium) lpattern(longdash))
, ytitle("Difference in logarithm of total cases", size(large)) yline(0, lcolor(black)) ylabel(, glcolor(gs5%25) glpattern(dash) labsize(large)) xtitle(, color(none) size(large)) xlabel(0(3)21, valuelabel labsize(large)) legend(off) graphregion(fcolor(white) lcolor(white));
graph export "$out/Figure_dynamics_MAX.png", replace;




********************************************************************************
********************************************************************************
*			SUBNATIONAL FIXED EFFECTS USING LONG AND LAT			 		   *
********************************************************************************
********************************************************************************



cd "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/" 
global temp "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/temp" 
global raw "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Data" 
global use "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/use"
global out "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/out"

estimates clear

use "$use/ready.dta", clear

gen lon_1 = int(longitude/1)
gen lat_1 = int(latitude/1)

egen FE_region_1 = group(lon_1 lat_1 C_s)

gen lon_2 = int(longitude/2)
gen lat_2 = int(latitude/2)

egen FE_region_2 = group(lon_2 lat_2 C_s)


gen lon_3 = int(longitude/3)
gen lat_3 = int(latitude/3)

egen FE_region_3 = group(lon_3 lat_3 C_s)


gen lon_4 = int(longitude/4)
gen lat_4 = int(latitude/4)

egen FE_region_4 = group(lon_4 lat_4 C_s)


gen lon_5 = int(longitude/5)
gen lat_5 = int(latitude/5)

egen FE_region_5 = group(lon_5 lat_5 C_s)






* Column 1: Grid 1 degree x 1 degree

gen AV_RH = T_AV * RH
local i = 1
while `i'<=21 {
gen AV_RH_L`i' = L`i'.AV_RH
local i = `i'+1
}


bysort country date_case: egen total_country = sum(total_Case)
bysort country: egen max_country = max(total_country)
sort location_ID date_case
keep if  L.total_country!=max_country


drop if country=="China"
drop if geo==3



gen week = week(date_case)


reghdfe D.ln_tot_Case T_AV* TP* RH* if total_Case>=1, absorb(date_case##FE_region_1 location_ID) cluster(country)
estimates save "$temp/Model_1", replace

reghdfe D.ln_tot_Case T_AV* TP* RH*  if total_Case>=1, absorb(date_case##FE_region_2 location_ID) cluster(country)
estimates save "$temp/Model_2", replace

reghdfe D.ln_tot_Case T_AV* TP* RH*  if total_Case>=1, absorb(date_case##FE_region_3 location_ID) cluster(country)
estimates save "$temp/Model_3", replace

reghdfe D.ln_tot_Case T_AV* TP* RH*  if total_Case>=1, absorb(date_case##FE_region_4 location_ID) cluster(country)
estimates save "$temp/Model_4", replace

reghdfe D.ln_tot_Case T_AV* TP* RH*  if total_Case>=1, absorb(date_case##FE_region_5 location_ID) cluster(country)
estimates save "$temp/Model_5", replace





* output results
global scales " "T_AV" "RH" "AV_RH" "TP" "
 foreach j in $scales {


local i = 1
while `i' <= 5 {
estimates use "$temp/Model_`i'"
capture lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15  + `j'_L16 + `j'_L17 + `j'_L18 + `j'_L19 + `j'_L20 + `j'_L21,level(95)
estimates store m`j'_`i'
local i = `i' + 1
}
}

	* output results to a txt and could copy this in excel to make tables
estout m* ///
using "$out/AT5.txt", ///
	cells( b(star fmt(%9.4f)) se(par(`"="("'`")""'))) ///
	title("") style(tab) keep((1)) ///
	stats(N, fmt(%10.0fc) labels("Observations")) label collabels(, none) ///
	starlevels(* .10 ** .05 *** .01) replace
	




********************************************************************************
********************************************************************************
*			SUBNATIONAL FIXED EFFECTS USING LONG AND LAT			 		   *
********************************************************************************
********************************************************************************



cd "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/" 
global temp "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/temp" 
global raw "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Data" 
global use "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/use"
global out "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/out"

estimates clear

use "$use/ready.dta", clear

gen lon_1 = int(longitude/1)
gen lat_1 = int(latitude/1)

egen FE_region_1 = group(lon_1 lat_1 C_s)

gen lon_2 = int(longitude/2)
gen lat_2 = int(latitude/2)

egen FE_region_2 = group(lon_2 lat_2 C_s)


gen lon_3 = int(longitude/3)
gen lat_3 = int(latitude/3)

egen FE_region_3 = group(lon_3 lat_3 C_s)


gen lon_4 = int(longitude/4)
gen lat_4 = int(latitude/4)

egen FE_region_4 = group(lon_4 lat_4 C_s)


gen lon_5 = int(longitude/5)
gen lat_5 = int(latitude/5)

egen FE_region_5 = group(lon_5 lat_5 C_s)






global EU_list " "Austria" "Belgium" "Bulgaria" "Croatia" "Republic of Cyprus" "Czech Republic" "Denmark" "Estonia" "Finland" "France" "Germany" "Greece" "Hungary" "Ireland" "Italy" "Latvia" "Lithuania" "Luxembourg" "Malta" "Netherlands" "Poland" "Portugal" "Romania" "Slovakia" "Slovenia" "Spain" "Sweden" "United Kingdom" "

gen EU_UK = .
foreach j in $EU_list {
di "`j'"
capture replace EU_UK = 1 if country=="`j'"
}

gen Other_countries = 1 if country!="China" & country!="United States" & EU_UK!=1


* Column 1: Grid 1 degree x 1 degree

gen AV_RH = T_AV * RH
local i = 1
while `i'<=21 {
gen AV_RH_L`i' = L`i'.AV_RH
local i = `i'+1
}


bysort country date_case: egen total_country = sum(total_Case)
bysort country: egen max_country = max(total_country)
sort location_ID date_case
keep if  L.total_country!=max_country



gen week = week(date_case)


drop if geo==3


reghdfe D.ln_tot_Case T_AV* TP* RH*   if total_Case>=1, absorb(date_case##FE_region_3 location_ID) cluster(country)
estimates save "$temp/Model_6", replace
gen meany_5=D.ln_tot_Case if e(sample)


reghdfe D.ln_tot_Case T_AV* TP* RH*  if total_Case>=1 & country=="China", absorb(date_case##FE_region_3 location_ID) cluster(location_ID)
estimates save "$temp/Model_7", replace
gen meany_1=D.ln_tot_Case if e(sample)

reghdfe D.ln_tot_Case T_AV* TP* RH*  if total_Case>=1 & EU_UK==1, absorb(date_case##FE_region_3 location_ID) cluster(country)
estimates save "$temp/Model_8", replace
gen meany_2=D.ln_tot_Case if e(sample)


reghdfe D.ln_tot_Case T_AV* TP* RH*  if total_Case>=1 & country=="United States", absorb(date_case##FE_region_3 location_ID) cluster(location_ID)
estimates save "$temp/Model_9", replace
gen meany_3=D.ln_tot_Case if e(sample)

reghdfe D.ln_tot_Case T_AV* TP* RH*  if total_Case>=1 & country!="China", absorb(date_case##FE_region_3 location_ID) cluster(country)
estimates save "$temp/Model_10", replace
gen meany_4=D.ln_tot_Case if e(sample)






* output results
global scales " "T_AV" "RH" "AV_RH" "TP" "
 foreach j in $scales {


local i = 6
while `i' <= 10 {
estimates use "$temp/Model_`i'"
capture lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15  + `j'_L16 + `j'_L17 + `j'_L18 + `j'_L19 + `j'_L20 + `j'_L21,level(95)
estimates store m`j'_`i'
local i = `i' + 1
}
}

	* output results to a txt and could copy this in excel to make tables
estout m* ///
using "$out/AT5.txt", ///
	cells( b(star fmt(%9.4f)) se(par(`"="("'`")""'))) ///
	title("") style(tab) keep((1)) ///
	stats(N, fmt(%10.0fc) labels("Observations")) label collabels(, none) ///
	starlevels(* .10 ** .05 *** .01) replace
	
---
---


********************************************************************************
********************************************************************************
*			BEFORE AND AFTER GENERAL RESTRICTION IN INTERNAL MOVEMENT			 		   *
********************************************************************************
********************************************************************************



global interventions "  "S6_IsGeneral" "

foreach R in $interventions {

reghdfe D.ln_tot_Case T_AV* RH* if total_Case>=1 & `R'==0, absorb(date_case#C_s location_ID) cluster(country)
estimates save "$temp/Model_1", replace

reghdfe D.ln_tot_Case TMAX TMIN TMAX_L* TMIN_L* RH* if total_Case>=1 & `R'==0, absorb(date_case#C_s location_ID) cluster(country)
estimates save "$temp/Model_2", replace

reghdfe D.ln_tot_Case T_AV* RH* if total_Case>=1 & `R'>=1 & `R'!=., absorb(date_case#C_s location_ID) cluster(country)
estimates save "$temp/Model_3", replace

reghdfe D.ln_tot_Case TMAX TMIN TMAX_L* TMIN_L* RH* if total_Case>=1  & `R'>=1 & `R'!=., absorb(date_case#C_s location_ID) cluster(country)
estimates save "$temp/Model_4", replace

}


global vars " "TMIN" "TMAX" "RH" "
foreach j in $vars {
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15  + `j'_L16 + `j'_L17 + `j'_L18 + `j'_L19 + `j'_L20 + `j'_L21
}

}









********************************************************************************
********************************************************************************
*			SOME CHECKS ON THE LEADS			 		   *
********************************************************************************
********************************************************************************



***
1) EXCLUDE CONTEMPORANEOUS VALUE
***


set more off
estimates clear
use "$use/ready.dta", clear

drop T_AV RH


reghdfe D.ln_tot_Case T_AV* RH* if total_Case>=1, absorb(date_case#C_s location_ID) cluster(country)

global vars " "T_AV" "RH" "
foreach j in $vars {
lincom `j'_L1 +`j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 + `j'_L16  + `j'_L17  + `j'_L18  + `j'_L19  + `j'_L20  + `j'_L21 
}


***
3) INCLUDE LEADS
***

***
*a. 3 leads in model
***

set more off
estimates clear
use "$use/ready.dta", clear


local i = 1
while `i'<= 5 {
gen T_AV_F`i' = F`i'.T_AV
gen RH_F`i' = F`i'.RH
gen TP_F`i' = F`i'.TP
local i = `i'+1
}

reghdfe D.ln_tot_Case T_AV* TP* RH* if total_Case>=1, absorb(date_case#C_s location_ID) cluster(country)


global vars " "T_AV" "TP" "RH" "
foreach j in $vars {
lincom `j'_F1 + `j'_F2 + `j'_F3 + `j'_F4 + `j'_F5 
}



global vars " "T_AV" "TP" "RH" "
foreach j in $vars {
lincom `j'_F1 + `j'_F2 + `j'_F3 + `j'_F4 + `j'_F5 + `j'_F6 + `j'_F7 + `j'_F8 + `j'_F9 + `j'_F10 
}



* with MIN/MAX


set more off
estimates clear
use "$use/ready.dta", clear

local i = 1
while `i'<= 10 {
gen TMIN_F`i' = F`i'.TMIN
gen TMAX_F`i' = F`i'.TMAX
gen RH_F`i' = F`i'.RH
local i = `i'+1
}

reghdfe D.ln_tot_Case TMIN  TMIN_L* TMIN_F* TMAX  TMAX_L* TMAX_F* RH* if total_Case>=1, absorb(date_case#C_s location_ID) cluster(country)



***
* b. Falsification test: 21 leads instead of 21  lags
***


set more off
estimates clear
use "$use/ready.dta", clear

local i = 1
while `i'<= 21 {
gen T_AV_F`i' = F`i'.T_AV
gen RH_F`i' = F`i'.RH
gen TP_F`i' = F`i'.TP
local i = `i'+1
}

reghdfe D.ln_tot_Case T_AV_F* TP_F* RH_F* if total_Case>=1, absorb(date_case#C_s location_ID) cluster(country)

global vars " "T_AV" "TP" "RH" "
foreach j in $vars {
lincom `j'_F1 + `j'_F2 + `j'_F3 + `j'_F4 + `j'_F5 + `j'_F6 + `j'_F7 + `j'_F8 + `j'_F9 + `j'_F10 + `j'_F11 + `j'_F12 + `j'_F13 + `j'_F14 + `j'_F15  + `j'_F16  + `j'_F17  + `j'_F18  + `j'_F19  + `j'_F20  + `j'_F21 
}

* with MIN/MAX

set more off
estimates clear
use "$use/ready.dta", clear


local i = 1
while `i'<= 21 {
gen TMIN_F`i' = F`i'.TMIN
gen TMAX_F`i' = F`i'.TMAX
gen RH_F`i' = F`i'.RH
local i = `i'+1
}

reghdfe D.ln_tot_Case TMIN_F* TMAX_F* RH_F* if total_Case>=1, absorb(date_case#C_s location_ID) cluster(country)

global vars " "TMIN" "TMAX" "RH" "
foreach j in $vars {
lincom `j'_F1 + `j'_F2 + `j'_F3 + `j'_F4 + `j'_F5 + `j'_F6 + `j'_F7 + `j'_F8 + `j'_F9 + `j'_F10 + `j'_F11 + `j'_F12 + `j'_F13 + `j'_F14 + `j'_F15  + `j'_F16  + `j'_F17  + `j'_F18  + `j'_F19  + `j'_F20  + `j'_F21 
}







********************************************************************************
********************************************************************************
*				TABLE 2: MANY FES	 		   *
********************************************************************************
********************************************************************************

set more off
estimates clear

use "$use/ready.dta", clear


gen dow = dow(date_case)
gen dom = day(date_case)

* Column 4: interact with humidity
gen AV_RH = T_AV * RH
local i = 1
while `i'<=21 {
gen AV_RH_L`i' = L`i'.AV_RH
local i = `i'+1
}


global EU_list " "Austria" "Belgium" "Bulgaria" "Croatia" "Republic of Cyprus" "Czech Republic" "Denmark" "Estonia" "Finland" "France" "Germany" "Greece" "Hungary" "Ireland" "Italy" "Latvia" "Lithuania" "Luxembourg" "Malta" "Netherlands" "Poland" "Portugal" "Romania" "Slovakia" "Slovenia" "Spain" "Sweden" "United Kingdom" "

gen EU_UK = .
foreach j in $EU_list {
di "`j'"
capture replace EU_UK = 1 if country=="`j'"
}

gen Other_countries = 1 if country!="China" & country!="United States" & EU_UK!=1



gen week = week(date_case)
gen month = month(date_case)

drop TMIN_m10* TMIN_0* TMIN_10* TMIN_20* TMAX_10* TMAX_20* TMAX_30* TMAX_40* 

*** 	!!!  Table 2 reports results from different models for Rows 1,2 &3, ie. T_AV,TMAX,TMIN


bysort country date_case: egen total_country = sum(total_Case)
bysort country: egen max_country = max(total_country)
sort location_ID date_case
keep if  L.total_country!=max_country


gen fortnight = int(week/2)


* ROW1: The following 5 models are used for getting results for Row 1 (T_AV)


reghdfe D.ln_tot_Case T_AV* TP* RH*   if total_Case>=1, absorb(date_case#C_s location_ID##week) cluster(country)
estimates save "$temp/Model_1", replace
gen meany_1=D.ln_tot_Case if e(sample)


reghdfe D.ln_tot_Case T_AV* TP* RH*  if total_Case>=1, absorb(date_case#C_s location_ID##fortnight) cluster(location_ID)
estimates save "$temp/Model_2", replace
gen meany_2=D.ln_tot_Case if e(sample)

reghdfe D.ln_tot_Case T_AV* TP* RH*  if total_Case>=1, absorb(date_case#C_s location_ID##month) cluster(country)
estimates save "$temp/Model_3", replace
gen meany_3=D.ln_tot_Case if e(sample)

reghdfe D.ln_tot_Case T_AV* TP* RH*  if total_Case>=1, absorb(date_case#C_s location_ID) cluster(country)
estimates save "$temp/Model_4", replace
gen meany_5=D.ln_tot_Case if e(sample)


global scales " "T_AV" "RH" "AV_RH" "TP" "
 foreach j in $scales {


local i = 1
while `i' <= 4 {
estimates use "$temp/Model_`i'"
capture lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15  + `j'_L16 + `j'_L17 + `j'_L18 + `j'_L19 + `j'_L20 + `j'_L21,level(95)
estimates store m`j'_`i'
local i = `i' + 1
}
}

	* output results to a txt and could copy this in excel to make tables
estout m* ///
using "$out/T_JP.txt", ///
	cells( b(star fmt(%9.5f)) se(par(`"="("'`")""'))) ///
	title("") style(tab) keep((1)) ///
	stats(N, fmt(%10.0fc) labels("Observations")) label collabels(, none) ///
	starlevels(* .10 ** .05 *** .01) replace
	
	*Get the mean value of dependent variable for different estimates
tabstat meany_*



********************************************************************************
********************************************************************************
*				TABLE 2: MANY FES MIN AND MAX	 		   *
********************************************************************************
********************************************************************************

set more off
estimates clear

use "$use/ready.dta", clear


gen dow = dow(date_case)
gen dom = day(date_case)

* Column 4: interact with humidity
gen AV_RH = T_AV * RH
local i = 1
while `i'<=21 {
gen AV_RH_L`i' = L`i'.AV_RH
local i = `i'+1
}


global EU_list " "Austria" "Belgium" "Bulgaria" "Croatia" "Republic of Cyprus" "Czech Republic" "Denmark" "Estonia" "Finland" "France" "Germany" "Greece" "Hungary" "Ireland" "Italy" "Latvia" "Lithuania" "Luxembourg" "Malta" "Netherlands" "Poland" "Portugal" "Romania" "Slovakia" "Slovenia" "Spain" "Sweden" "United Kingdom" "

gen EU_UK = .
foreach j in $EU_list {
di "`j'"
capture replace EU_UK = 1 if country=="`j'"
}

gen Other_countries = 1 if country!="China" & country!="United States" & EU_UK!=1



gen week = week(date_case)
gen month = month(date_case)

drop TMIN_m10* TMIN_0* TMIN_10* TMIN_20* TMAX_10* TMAX_20* TMAX_30* TMAX_40* 

*** 	!!!  Table 2 reports results from different models for Rows 1,2 &3, ie. T_AV,TMAX,TMIN


bysort country date_case: egen total_country = sum(total_Case)
bysort country: egen max_country = max(total_country)
sort location_ID date_case
keep if  L.total_country!=max_country


gen fortnight = int(week/2)

* ROW1: The following 5 models are used for getting results for Row 1 (T_AV)


reghdfe D.ln_tot_Case TMIN TMIN_L* TMAX TMAX_L* TP* RH* AV_RH*  if total_Case>=1, absorb(date_case#C_s location_ID##week) cluster(country)
estimates save "$temp/Model_1", replace
gen meany_1=D.ln_tot_Case if e(sample)


reghdfe D.ln_tot_Case TMIN TMIN_L* TMAX TMAX_L* TP* RH* AV_RH* if total_Case>=1, absorb(date_case#C_s location_ID##fortnight) cluster(location_ID)
estimates save "$temp/Model_2", replace
gen meany_2=D.ln_tot_Case if e(sample)

reghdfe D.ln_tot_Case TMIN TMIN_L* TMAX TMAX_L* TP* RH* AV_RH* if total_Case>=1, absorb(date_case#C_s location_ID##month) cluster(country)
estimates save "$temp/Model_3", replace
gen meany_3=D.ln_tot_Case if e(sample)

reghdfe D.ln_tot_Case TMIN TMIN_L* TMAX TMAX_L* TP* RH* AV_RH* if total_Case>=1, absorb(date_case#C_s location_ID) cluster(country)
estimates save "$temp/Model_4", replace
gen meany_4=D.ln_tot_Case if e(sample)


global scales " "TMIN" "TMAX" "RH" "AV_RH" "TP" "
 foreach j in $scales {


local i = 1
while `i' <= 4 {
estimates use "$temp/Model_`i'"
capture lincomest `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15  + `j'_L16 + `j'_L17 + `j'_L18 + `j'_L19 + `j'_L20 + `j'_L21,level(95)
estimates store m`j'_`i'
local i = `i' + 1
}
}

	* output results to a txt and could copy this in excel to make tables
estout m* ///
using "$out/T_JP.txt", ///
	cells( b(star fmt(%9.5f)) se(par(`"="("'`")""'))) ///
	title("") style(tab) keep((1)) ///
	stats(N, fmt(%10.0fc) labels("Observations")) label collabels(, none) ///
	starlevels(* .10 ** .05 *** .01) replace
	
	*Get the mean value of dependent variable for different estimates
tabstat meany_*




