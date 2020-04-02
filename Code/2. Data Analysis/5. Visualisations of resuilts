

**** AVERAGE EFFECTS

clear all
set obs 30

global scales " "T_AV" "TP" "RH" "

quietly foreach j in $scales {

gen coeff_`j' = .
gen se_`j' = .

local i = 1
while `i' <= 15 {
estimates use "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Model_`i'"
capture lincom `j' + `j'_L1 + `j'_L2 + `j'_L3 + `j'_L4 + `j'_L5 + `j'_L6 + `j'_L7 + `j'_L8 + `j'_L9 + `j'_L10 + `j'_L11 + `j'_L12 + `j'_L13 + `j'_L14 + `j'_L15 
replace coeff_`j' = r(estimate) in `i'
replace se_`j' = r(se) in `i'
local i = `i' + 1
}

replace coeff_`j' = . in 4
replace se_`j' = . in 4
}

gen n = _n


table n if _n<=15, contents(mean coeff_T_AV mean se_T_AV)
table n if _n<=15, contents(mean coeff_TP mean se_TP)
table n if _n<=15, contents(mean coeff_RH mean se_RH)

---

**** GRAPH FOR MODEL WITH BINS 10 DEGREES

#delim;
clear all;
set obs 13;

estimates use "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Model_4";

global scales " "Temp_0"  "Temp_10" "Temp_30" "Temp_30p" ";
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
gen se_plus = (coeff + 1.96*se);
gen se_minus = (coeff - 1.96*se);
replace coeff = (coeff);
gen n = _n if _n<3;
replace n = _n+1 if _n>=3;
replace se_plus = . in 13;
replace se_minus = . in 13;
replace coeff = 0 in 13;
replace n=3 in 13;

label variable n "Temperature bins (°C)";
label define n_label 1 "<0" 2 "0-10" 3 "10-20" 4 "20-30" 5 ">30";
label values n n_label;

#delim;
twoway  (scatter coeff n, mcolor(edkblue) msymbol(diamond)) (rarea se_minus se_plus n, sort fcolor(edkblue%40) lcolor(edkblue%40) lwidth(vvvthin) cmissing(n)) 
(line coeff n, sort lcolor(edkblue) lwidth(medium) lpattern(longdash)) if n<=5 & n>=1, ytitle("Difference in ln. total infections") yline(0, lcolor(black)) 
ylabel(, glcolor(gs5%25) glpattern(dash)) xtitle(, color(none)) xlabel(1(1)5, valuelabel labsize(small)) legend(off) graphregion(fcolor(white) lcolor(white));
*title("Specification with 10°C temperature bins");
graph export "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Figure_bins.png", replace;





**** GRAPH FOR MODEL WITH BINS 5 DEGREES

#delim;
clear all;
set obs 13;

estimates use "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Model_4b";

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
gen se_plus = (coeff + 1.96*se);
gen se_minus = (coeff - 1.96*se);
replace coeff = (coeff);
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
twoway  (scatter coeff n, mcolor(edkblue) msymbol(diamond)) (rarea se_minus se_plus n, sort fcolor(edkblue%40) lcolor(edkblue%40) lwidth(vvvthin) cmissing(n)) 
(line coeff n, sort lcolor(edkblue) lwidth(medium) lpattern(longdash)) if n<=8 & n>=1, ytitle("Difference in ln. total infections") yline(0, lcolor(black)) 
ylabel(, glcolor(gs5%25) glpattern(dash)) xtitle(, color(none)) xlabel(1(1)8, valuelabel labsize(small)) legend(off) graphregion(fcolor(white) lcolor(white));






* short term dynamics of model 3 (this is impressive by the way)
* 3 - Temperatures, precipiations and humidity


#delim;
clear all;
set obs 20;

estimates use "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Model_3";


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
*replace n = _n+1 if _n>=9;
*replace se_plus = . in 13;
*replace se_minus = . in 13;
*replace coeff = 0 in 13;
*replace n=9 in 13;

#delim;

*label define n_label 1 "<10" 2 "10-12" 3 "12-14" 4 "14-16" 5 "16-18" 6 "18-20" 7 "20-22" 8 "22-24" 9 "24-26" 10 "26-28" 11 "28-30" 12 "30-32" 13 ">32";
*label values n n_label;
label variable n "No. days before 2019-nCovid case confirmation";
twoway  (scatter coeff_AV n, mcolor(red) msymbol(diamond)) (rarea se_AV_minus se_AV_plus n if n<=15, sort fcolor(red%40) lcolor(red%40) lwidth(vvvthin) cmissing(n)) (line coeff_AV n, sort lcolor(red) lwidth(medium) lpattern(longdash))
, ytitle("Difference in ln. total infections", size(large)) yline(0, lcolor(black)) ylabel(, glcolor(gs5%25) glpattern(dash) labsize(large)) xtitle(, color(none) size(large)) xlabel(0(3)15, valuelabel labsize(large)) legend(off) graphregion(fcolor(white) lcolor(white));
* title("Value of lags for daily av. temperature in model (3)");
graph export "/soge-home/staff/smit0148/OXFORD Research/COVID-19 PAPER/Figure_dynamics.png", replace;



