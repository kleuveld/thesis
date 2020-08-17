/*
Event Years.do

Companion do-file to Conflict Exposure and Competitiveness.do
Author: Koen Leuveld
Date: 19/6/2015
Last changed:3/2/2016

Goal: graph conflict intenstiy over time, using both our sample and ACLED local data

NOTES
*This file is called by the main replication file.
*We make use of SLL-LED data provided by ACLED. This is not provided with the replication material, but downloaded and saved by this do-file if needed.

OUTLINE
*The file constructs four temporary datasets. Each contains counts of events collapsed to years.
*These four files are merged together, so that the data can be plotted.
*/



*Make a file that consists of number of events per year:
	
	**loop over the dispx and we events to get a count per year for each
	foreach var in disp1 disp2 disp3 we {
		use "Cleaned Data\foot_cleaned_all.dta", clear
		collapse (count) `var' = eveningid, by(`var'_year)
		ren `var'_year year //we merge on year later
		drop if year == . 	//there are some missing, nothing can be done with those
	
		*save as a tempfile so we can merge it all together later
		tempfile `var'
		save ``var''
	}

	**ACLED data
	*use SLL-LED data if donwloaded
	capture	use "Secondary Data\SLL-LED.dta", clear
	
	*Download and save if not available
	if _rc == 601 {
		import excel "http://www.acleddata.com/wp-content/uploads/2015/01/SLL-LED_Sierre-Leone_Local_Source_1991-2001.xlsx", sheet("Dyadic") firstrow clear
		save "Secondary Data\SLL-LED.dta"
	}
	
	*Drop anything that is not Nongowa chiefdom, which is the chiefdom of Kenema city
	drop if ADMIN3 != "Nongowa"
	
	*We use only violent events
	drop if EVENT_TYPE == "Headquarters or base established"
	drop if EVENT_TYPE == "Non-violent activity by a conflict actor"
	drop if EVENT_TYPE == "Non-violent transfer of territory"

	*Collapse to provide a count per year
	collapse (count) violence = GWNO, by(YEAR)

	ren YEAR year
		
	*Merge the file with the temporaty files created above
	qui merge 1:1 year using `disp1', nogen 
	qui merge 1:1 year using `disp2', nogen 
	qui merge 1:1 year using `disp3', nogen 
	qui merge 1:1 year using `we', nogen 
	
	*Sum the different displacement figures	
	egen disp = rowtotal(disp?)
	drop disp?
	
	*Label the variables
	la var we "Exposure to conflict (sample)"
	la var disp "Displacement (sample)"
	la var violence "Violent Events Kenema (SLL-LED)"
	la var year "Year"
	
	*Scale variables to percentage of column totals
	foreach var of varlist violence we disp {
		qui sum `var'
		qui replace `var' = `var' / r(sum) * 100
	}
	
	drop if year == 1990
	
	*save
	save "Cleaned Data/event_years.dta",replace


