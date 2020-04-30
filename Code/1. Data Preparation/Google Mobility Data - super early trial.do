

**** CITE AS:
*Google LLC "Google COVID-19 Community Mobility Reports." 
*https://www.google.com/covid19/mobility/ Accessed: <Date>. 

*** Download
clear
import delimited https://www.gstatic.com/covid19/mobility/Global_Mobility_Report.csv

drop if sub_region_1 == ""
gen date1 = date(date,"YMD")
drop date
rename date1 date

