
---

use  "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/ESTIMATION_300320_FCO.dta", clear

*compress





* ECONOMETRIC MODELS

encode country, gen(C_s) // country FEs

egen country_day = group(C_s date_case)


sort location_ID date_case

gen T_AV = (TMAX + TMIN)/2

local i = 1
while `i'<= 15 {
gen T_AV_L`i' = L`i'.T_AV
local i = `i' + 1 
}

gen Temp_0 = T_AV<=0
gen Temp_10 = T_AV<=10
gen Temp_20 = T_AV<=20
gen Temp_30 = T_AV<=30
gen Temp_30p = T_AV>=30  & T_AV!=.

replace Temp_30 = Temp_30 - Temp_20
replace Temp_20 = Temp_20 - Temp_10
replace Temp_10 = Temp_10 - Temp_0


local i = 1
while `i'<= 15 {
gen Temp_0_L`i' = L`i'.Temp_0
gen Temp_10_L`i' = L`i'.Temp_10
*gen Temp_20_L`i' = L`i'.Temp_20
gen Temp_30_L`i' = L`i'.Temp_30
gen Temp_30p_L`i' = L`i'.Temp_30p
local i = `i' + 1 
}

drop Temp_20*

drop *L16 *L17 *L18 *L19 *L20 *L21 *L22 *L23 *L24 *L25 *L26 *L27 *L28 *L29 *L30

bysort country date_case: egen COUNTRY_COUNT = sum(total_Case)

sort location_ID date_case






** BASELINE MODELS 

* 1 - Temperature only

reghdfe D.ln_tot_Case T_AV* if total_Case>=1, absorb(date_case#C_s location_ID) cluster(country)
estimates save "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Model_1", replace

global scales " "T_AV" "
foreach j in $scales {
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 
}


* 2 - Temperatures and precipitations

reghdfe D.ln_tot_Case T_AV* TP* if total_Case>=1, absorb(date_case#C_s location_ID) cluster(country)
estimates save "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Model_2", replace

global scales " "T_AV" "TP" "
foreach j in $scales {
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 
}

* 3 - Temperatures, precipiations and humidity
gen SAMPLE_FIGURE_WEATHER_DATA = e(sample)

reghdfe D.ln_tot_Case T_AV* TP* RH* if total_Case>=1, absorb(date_case#C_s location_ID) cluster(country)
estimates save "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Model_3", replace

global scales " "T_AV" "TP" "RH" "
foreach j in $scales {
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 
}

***
DO THE HISTOGRAM
***

histogram T_AV if SAMPLE_FIGURE_WEATHER_DATA==1
graph save "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Histogram_AV"
histogram TP if SAMPLE_FIGURE_WEATHER_DATA==1
graph save "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Histogram_TP"
histogram RH if SAMPLE_FIGURE_WEATHER_DATA==1
graph save "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Histogram_RH"





* 4 - 10 degree temperature bins, precipiations and humidity


reghdfe D.ln_tot_Case Temp_* TP* RH* if total_Case>=1 , absorb(date_case#C_s location_ID) cluster(location_ID)
estimates save "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Model_4", replace

global scales " "Temp_0" "Temp_10" "Temp_30" "Temp_30p" "TP" "RH" "
foreach j in $scales {
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 
}

* 4b - 5 degree bins


gen Temp2_0 = T_AV<=0
gen Temp2_5 = T_AV<=5
gen Temp2_10 = T_AV<=10
gen Temp2_15 = T_AV<=15
gen Temp2_20 = T_AV<=20
gen Temp2_25 = T_AV<=25
gen Temp2_30 = T_AV<=30
gen Temp2_30p = T_AV>=30 & T_AV!=.

replace Temp2_30 = Temp2_30 - Temp2_25
replace Temp2_25 = Temp2_25 - Temp2_20
replace Temp2_20 = Temp2_20 - Temp2_15
replace Temp2_15 = Temp2_15 - Temp2_10
replace Temp2_10 = Temp2_10 - Temp2_5

local i = 1
while `i'<= 15 {
gen Temp2_0_L`i' = L`i'.Temp2_0
gen Temp2_5_L`i' = L`i'.Temp2_5
gen Temp2_10_L`i' = L`i'.Temp2_10
gen Temp2_15_L`i' = L`i'.Temp2_15
*gen Temp2_20_L`i' = L`i'.Temp2_20
gen Temp2_25_L`i' = L`i'.Temp2_25
gen Temp2_30_L`i' = L`i'.Temp2_30
gen Temp2_30p_L`i' = L`i'.Temp2_30p
local i = `i' + 1 
}


reghdfe D.ln_tot_Case Temp2_* TP* RH* if total_Case>=1 , absorb(date_case#C_s location_ID) cluster(location_ID)
estimates save "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Model_4b", replace

global scales " "Temp2_0" "Temp2_5" "Temp2_10" "Temp2_15" "Temp2_25"  "Temp2_30" "Temp2_30p" "TP" "RH" "
foreach j in $scales {
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 
}


* For now, all models with temperatures, precipitations and humidity


* 3.a China only (note that cluster robust SE are for locations, not countries in the China only case)

reghdfe D.ln_tot_Case T_AV* TP* RH* if total_Case>=1 & country=="China", absorb(date_case#C_s location_ID) cluster(location_ID)
estimates save "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Model_5", replace

global scales " "T_AV" "TP" "RH" "
foreach j in $scales {
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 
}

* 3.b Outside China

reghdfe D.ln_tot_Case T_AV* TP* RH* if total_Case>=1 & country!="China", absorb(date_case#C_s location_ID) cluster(country)
estimates save "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Model_6", replace

global scales " "T_AV" "TP" "RH" "
foreach j in $scales {
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 
}


* Robustness - Before n cases declared in the country: 500, 1000. 2000 and 5000

reghdfe D.ln_tot_Case T_AV* TP* RH* if  COUNTRY_COUNT<500 & total_Case>=1, absorb(date_case#C_s location_ID) cluster(country)
estimates save "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Model_7", replace

global scales " "T_AV" "TP" "RH" "
foreach j in $scales {
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 
}


reghdfe D.ln_tot_Case T_AV* TP* RH* if  COUNTRY_COUNT<1000 & total_Case>=1, absorb(date_case#C_s location_ID) cluster(country)
estimates save "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Model_8", replace

global scales " "T_AV" "TP" "RH" "
foreach j in $scales {
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 
}


reghdfe D.ln_tot_Case T_AV* TP* RH* if  COUNTRY_COUNT<2000 & total_Case>=1, absorb(date_case#C_s location_ID) cluster(country)
estimates save "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Model_9", replace

global scales " "T_AV" "TP" "RH" "
foreach j in $scales {
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 
}


reghdfe D.ln_tot_Case T_AV* TP* RH* if  COUNTRY_COUNT<5000 & total_Case>=1, absorb(date_case#C_s location_ID) cluster(country)
estimates save "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Model_10", replace

global scales " "T_AV" "TP" "RH" "
foreach j in $scales {
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 
}



* Robustness: touching the fixed effects


* No fixed effects

reg D.ln_tot_Case T_AV* TP* RH* if total_Case>=1, cluster(country)
estimates save "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Model_11", replace

global scales " "T_AV" "TP" "RH" "
foreach j in $scales {
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 
}


* Day FE

reghdfe D.ln_tot_Case T_AV* TP* RH* if total_Case>=1, absorb(date_case) cluster(country)
estimates save "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Model_12", replace

global scales " "T_AV" "TP" "RH" "
foreach j in $scales {
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 
}


* Day FE + Country FE

reghdfe D.ln_tot_Case T_AV* TP* RH* if total_Case>=1, absorb(date_case C_s) cluster(country)
estimates save "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Model_13", replace


global scales " "T_AV" "TP" "RH" "
foreach j in $scales {
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 
}


* Day FE + Location FE

reghdfe D.ln_tot_Case T_AV* TP* RH* if total_Case>=1, absorb(date_case location_ID) cluster(country)
estimates save "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Model_14", replace


global scales " "T_AV" "TP" "RH" "
foreach j in $scales {
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 
}


* Baseline FEs

reghdfe D.ln_tot_Case T_AV* TP* RH* if total_Case>=1, absorb(date_case#C_s location_ID) cluster(country)
estimates save "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Model_15", replace

global scales " "T_AV" "TP" "RH" "
foreach j in $scales {
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 
}



* Two lines (before and after 30 degrees)

gen THIRTY = T_AV * (T_AV >=30)


gen ZERO = T_AV * (T_AV <=0)

local i = 1
while `i'<= 15 {
gen ZERO_L`i' = L`i'.ZERO
local i =`i'+1
}

local i = 1
while `i'<= 15 {
gen THIRTY_L`i' = L`i'.THIRTY
local i =`i'+1
}



reghdfe D.ln_tot_Case T_AV* THIRTY* ZERO* TP* RH* if total_Case>=1, absorb(date_case#C_s location_ID) cluster(country)
estimates save "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Model_16", replace

global scales " "T_AV" "THIRTY" "ZERO" "TP" "RH" "
foreach j in $scales {
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 
}




*******************************************************
*	Interactions of temp and humidty
*******************************************************
	
use "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/robustness_290320.dta", clear
set more off
drop  *L16 *L17 *L18 *L19 *L20 // only use 15 days lags as the baseline model
gen AVRH=T_AV*RH

local i = 1
while `i'<= 15 {
gen AVRH_L`i' = T_AV_L`i' * RH_L`i'
local i = `i' + 1 
}

reghdfe D.ln_tot_Case  T_AV* AVRH* TP* RH* if total_Case>=1, absorb(date_case#C_s location_ID) cluster(country)


global scales " "T_AV" "AVRH" "TP" "RH" "
foreach j in $scales {
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 
}




gen AMPLI = TMAX - TMIN

local i = 1
while `i'<= 15 {
gen AMPLI_L`i' = L`i'.AMPLI
local i =`i'+1
}


reghdfe D.ln_tot_Case T_AV* AMPLI* TP* RH* if total_Case>=1, absorb(date_case#C_s location_ID) cluster(country)
estimates save "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Model_16", replace

global scales " "T_AV" "AMPLI" "TP" "RH" "
foreach j in $scales {
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 
}




** WE NEED TO CHANGE NUMBER OF LAGS AS ROBUSNTESS CHECK
** MIN AND MAX TEMP SEPARATELY
** MIN AND MAX TEMP BINS
** INTERACTIONS BETWWEN TEMP AND HUMIDITY

** WE WOULD IDEALLY WANT TO HAVE A MODEL WITH ANOMALIES (DIFFERENCE TO THE CLIMATE NORMALS)
** We NEED TO DO THE POLICY INTERACTIONS SECTION






**** GRAPH FOR MODEL WITH BINS 5 DEGREES

#delim;
global scales " "Temp2_0"  "Temp2_5" "Temp2_10" "Temp2_15" "Temp2_25" "Temp2_30" "Temp2_30p" ";
;
local i = 1;
gen coeff = .;
gen se = .;
foreach j in $scales {;
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15;
replace coeff = r(estimate) in `i';
replace se = r(se) in `i';
local i = `i'+1;
};
#delim;
gen se_plus = (coeff + 1.96*se)*100000;
gen se_minus = (coeff - 1.96*se)*100000;
replace coeff = (coeff)*100000;
gen n = _n if _n<5;
replace n = _n+1 if _n>=5;
replace se_plus = . in 13;
replace se_minus = . in 13;
replace coeff = 0 in 13;
replace n=5 in 13;

label variable n "Temperature bins (°C)";
label define n_label 1 "<0" 2 "0-5" 3 "5-10" 4 "10-15" 5 "15-20" 6 "20-25" 7 "25-30" 8 ">30";
label values n n_label;

#delim;
twoway  (scatter coeff n, mcolor(edkblue) msymbol(diamond)) (rarea se_minus se_plus n, sort fcolor(ltblue%40) lcolor(ltblue%40) lwidth(vvvthin) cmissing(n)) 
(line coeff n, sort lcolor(edkblue) lwidth(medium) lpattern(longdash)) if n<=8 & n>=1, ytitle("Mortality rate per 100,000 inhabitants") yline(0, lcolor(black)) 
ylabel(, glcolor(gs5%25) glpattern(dash)) xtitle(, color(none)) xlabel(1(1)8, valuelabel labsize(small)) legend(off) graphregion(fcolor(white) lcolor(white));







* short term dynamics of model 3 (this is impressive by the way)
* 3 - Temperatures, precipiations and humidity


reghdfe D.ln_tot_Case T_AV* TP* RH* if total_Case>=1, absorb(date_case#C_s location_ID) cluster(country)


global scales " "T_AV" "TP" "RH" "
foreach j in $scales {
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 
}


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
gen se_AV_plus = (coeff_AV + 1.96*se_AV)*100000;
gen se_AV_minus = (coeff_AV - 1.96*se_AV)*100000;
replace coeff_AV = (coeff_AV)*100000;

gen n = _n-1 if _n<=16;
*replace n = _n+1 if _n>=9;
*replace se_plus = . in 13;
*replace se_minus = . in 13;
*replace coeff = 0 in 13;
*replace n=9 in 13;

#delim;

*label define n_label 1 "<10" 2 "10-12" 3 "12-14" 4 "14-16" 5 "16-18" 6 "18-20" 7 "20-22" 8 "22-24" 9 "24-26" 10 "26-28" 11 "28-30" 12 "30-32" 13 ">32";
*label values n n_label;
label variable n "Days before infection";
twoway  (scatter coeff_AV n, mcolor(red) msymbol(diamond)) (rarea se_AV_minus se_AV_plus n if n<=15, sort fcolor(red%40) lcolor(red%40) lwidth(vvvthin) cmissing(n)) (line coeff_AV n, sort lcolor(red) lwidth(medium) lpattern(longdash))
, ytitle("Difference in logarithm of total cases", size(large)) yline(0, lcolor(black)) ylabel(, glcolor(gs5%25) glpattern(dash) labsize(large)) xtitle(, color(none) size(large)) xlabel(0(3)15, valuelabel labsize(large)) legend(off) graphregion(fcolor(white) lcolor(white));
;
***graph export "/soge-home/staff/smit0148/LSE Research/MEXICO PAPER/MEXICO PROGRAMS 2020/Tables and figures/Figures PNG/Figure_3b.png", replace;










----
----

OLDIES

----
----

*reghdfe D.ln_tot_Case Temp* if total_Case>=1 & country!="China", absorb(date_case#C_s location_ID) cluster(location_ID)

reghdfe D.ln_tot_Case Temp* if total_Case>=1 , absorb(date_case#C_s location_ID) cluster(location_ID)

*reghdfe D.ln_tot_Case Temp* if total_Case>=1 & country!="China", absorb(date_case location_ID) cluster(location_ID)


global scales " "Temp_0" "Temp_10" "Temp_30" "Temp_30p" "
foreach j in $scales {
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 
*lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 + `j'_L16 + `j'_L17 + `j'_L18 + `j'_L19 + `j'_L20 
}


reghdfe D.ln_tot_Case T_AV* if total_Case>=1 & country!="China", absorb(date_case#C_s location_ID) cluster(location_ID)



----

reghdfe sum_Case T_AV T_AV_L* TP* if total_Case>=1 & country!="China", absorb(date_case C_s ) cluster(location_ID)



reghdfe sum_Case T_AV T_AV_L* if total_Case>=1 & country!="China", absorb(date_case#C_s location_ID) cluster(location_ID)



reghdfe D.ln_tot_Case LD(1/10).ln_tot_Case T_AV T_AV_L* TP* RH* if total_Case>=1, absorb(date_case) cluster(location_ID)


reghdfe sum_Case LD(1/10).ln_tot_Case T_AV T_AV_L* TP* RH* if total_Case>=1, absorb(date_case) cluster(location_ID)


global scales " "T_AV" "
foreach j in $scales {
lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 
*lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 + `j'_L16 + `j'_L17 + `j'_L18 + `j'_L19 + `j'_L21 + `j'_L22 + `j'_L23 + `j'_L24 + `j'_L25 + `j'_L26 + `j'_L27 + `j'_L28 + `j'_L29 + `j'_L30
}


poi2hdfe sum_Case TMAX TMAX_L7 if total_Case>=1, id1(location_ID) id2(country_day) cluster(C_s)




reghdfe sum_Case LD(1/10).sum_Case TMIN TMIN_L*, absorb(date_case) cluster(location_ID)






reghdfe D.ln_tot_Case T_AV T_AV_L* if total_Case>=1, absorb(date_case#C_s location_ID) cluster(location_ID)

reghdfe D.ln_tot_Case TMAX TMAX_L* if total_Case>=1, absorb(date_case#C_s location_ID) cluster(location_ID)



poi2hdfe sum_Case TMAX TMAX_L7 if total_Case>=1, id1(location_ID) id2(country_day) cluster(C_s)

reghdfe D.ln_tot_Case RH RH_L7 RH_L14 TMAX TMAX_L7 TMAX_L14 TMIN TMIN_L7 TMIN_L14 TP TP_L7 TP_L14 if total_Case>=1, absorb(date_case#C_s location_ID) cluster(location_ID)


---

**** THIS WILL TAKE A WHILE because it has all climate variabels in there
poi2hdfe sum_Case RH* TMAX* TMIN* TP*, id1(location_ID) id2(country_day) cluster(C_s)

poi2hdfe sum_Case RH RH_L7 RH_L14 TMAX TMAX_L7 TMAX_L14 TMIN TMIN_L7 TMIN_L14 TP TP_L7 TP_L14, id1(location_ID) id2(country_day) cluster(C_s)


---

* First Differences and FEs

reghdfe D.ln_tot_Case RH RH_L7 RH_L14 TMAX TMAX_L7 TMAX_L14 TMIN TMIN_L7 TMIN_L14 TP TP_L7 TP_L14 if total_Case>=1, absorb(date_case#C_s location_ID) cluster(location_ID)

* or in levels *

reghdfe sum_Case RH RH_L7 RH_L14 TMAX TMAX_L7 TMAX_L14 TMIN TMIN_L7 TMIN_L14 TP TP_L7 TP_L14 if total_Case>=1, absorb(date_case#C_s location_ID) cluster(location_ID)


* or DLM

reghdfe D.ln_tot_Case LD(1/10).ln_tot_Case RH RH_L7 RH_L14 TMAX TMAX_L7 TMAX_L14 TMIN TMIN_L7 TMIN_L14 TP TP_L7 TP_L14, absorb(date_case) cluster(location_ID)


reghdfe D.sum_Case LD(1/10).sum_Case RH RH_L7 RH_L14 TMAX TMAX_L7 TMAX_L14 TMIN TMIN_L7 TMIN_L14 TP TP_L7 TP_L14, absorb(date_case) cluster(location_ID)

---
*ALREADY EXISTS
*egen country_day = group(country date_case)

**xtpoisson sum_Case i.country_day, fe vce(robust)

----
----

* A: autoregressive lag model
* cases today = cases the days before + time fixed effect (day FE)

reghdfe D.ln_tot_Case LD(1/3).ln_tot_Case RH RH_L7 RH_L14 TMAX TMAX_L7 TMAX_L14 TMIN TMIN_L7 TMIN_L14 TP TP_L7 TP_L14, absorb(date_case) cluster(location_ID)


* Controlling for policies - Add the policy information given by Francois Lafond
* TE BE INCLUDED



* Model with country FE x day FE, and location FE

reghdfe D.ln_tot_Case RH RH_L7 RH_L14 TMAX TMAX_L7 TMAX_L14 TMIN TMIN_L7 TMIN_L14 TP TP_L7 TP_L14, absorb(date_case#C_s location_ID) cluster(location_ID)




* Open Covid Data
*use "C:\Users\morit\Documents\DPhil Oxford\CoVid-19\CoVid-19 Cohen et al\Data\Covid_19_28032020.dta", clear


******OLD
use "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Covid_19_28032020.dta", clear


gen longitud = longitude
gen latitud = latitude

append "$path/LOCATIONS_WEATHER_30032020.dta"

replace latitud = latitud * 3.14159/180;
replace longitud = longitud * 3.14159/180;


local i = 1;
while `i' <= N {;
quietly gen longitud_`i' = longitud if _n==`i';
quietly replace longitud_`i' = 0 if longitud_`i'==.;
quietly egen LON_`i' = min(longitud_`i');
drop longitud_`i';

quietly gen latitud_`i' = latitud if _n==`i';
quietly replace latitud_`i' = 0 if latitud_`i'==.;
quietly egen LAT_`i' = max(latitud_`i');
drop latitud_`i';

quietly gen a_`i' = sin((latitud-LAT_`i')/2)^2+cos(latitud)*cos(LAT_`i')*sin((longitud-LON_`i')/2)^2;
quietly gen d_`i' = (2*atan2((a_`i')^0.5,(1-a_`i')^0.5)) * 6371;
drop a_`i';
drop LON_`i';
drop LAT_`i';

local i = `i' + 1;
};




merge m:1 longitude_4_int latitude_4_int date_case using "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Data/CLIMATE_30032020.dta", gen(MERGED)




*merge m:1 longitude latitude date_case using "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Data/CLIMATE_29032020.dta", gen(MERGED)
*merge m:m longitude latitude date_case using "C:\Users\morit\Documents\DPhil Oxford\CoVid-19\CoVid-19 Cohen et al\Data\CLIMATE_29032020.dta", gen(MERGED)

