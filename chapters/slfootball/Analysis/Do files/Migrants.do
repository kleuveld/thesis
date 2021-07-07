/*
Migrants.do

Companion do-file to Conflict Exposure and Competitiveness.do
Author: Koen Leuveld
Date: 19/6/2015
Last changed:05/10/2015


Goal: create migration indicators from text data
*/



	*Make a list of all places
	use "$DATADIR\Raw Data\Foot_raw.dta", clear
	
	*Rename vars to make sense
	ren q05displace displaced
	ren q26a2chiefdom disp1_place
	ren q26b2chief disp2_place
	ren q26c2 disp3_place
	
	tempfile raw
	save `raw', replace
	
	
	forvalues i = 1/3{
		use `raw', clear
		keep uid displaced disp`i'_place
		rename disp`i'_place place
		gen i = `i'
		tempfile disp`i'_place
		save `disp`i'_place'
	}
	
	*append first two files to the last one (which is open when the loop ends).
	append using `disp1_place'
	append using `disp2_place'
	
	
	*For locations of chiefdoms within districts see: http://en.wikipedia.org/wiki/Chiefdoms_of_Sierra_Leone
	
	gen place_clean = ""
	
	*Bo District
	replace place_clean = "Bo District" if regexm(place,"^[Bb][Oo]([ ,]|$)") == 1
	*Kakaua
	replace place_clean = "Bo District" if regexm(place,"[Kk]([ua]|ei)[KkLl]+ue*[as]") == 1
	replace place_clean = "Bo District" if regexm(place,"[Bb]o (district)|[Bb]o chiefdom") == 1
	replace place_clean = "Bo District" if regexm(place,"[Bb]o [(district)(chiefdom]") == 1
	
	**Kenema District
	*Small bo
	replace place_clean = "Kenema District" if regexm(place,"[Ss]mall") == 1
	*Dama / Blama
	replace place_clean = "Kenema District" if regexm(place,"[BbDd]l*ama") == 1
	*Nongowa
	replace place_clean = "Kenema District" if regexm(place,"[Nn]o*n*g+o(w|u[il])a") == 1
	replace place_clean = "Kenema District" if regexm(place,"[Kk]enema") == 1
	replace place_clean = "Kenema District" if regexm(place,"Nongoula|Ningiuea| Nuguna|ngowomea|ningona") == 1
	*Lower bamabara
	replace place_clean = "Kenema District" if regexm(place,"^Lo") == 1
	*Komende
	replace place_clean = "Kenema District" if regexm(place,"Komende") == 1
	*Serabu
	replace place_clean = "Kenema District" if regexm(place,"Serabu") == 1
	
	**Bonthe
	replace place_clean = "Bonthe District" if regexm(place,"Bonthe|Dema|Sojbeane") == 1
	
	**Kono District
	replace place_clean = "Kono District" if regexm(place,"[Kk]ono") == 1
	
	**Freetown
	replace place_clean = "Freetown" if regexm(place,"[Ff]reet|[Ww]estern") == 1
	
	**Foreign
	replace place_clean = "Out of Sierra Leone" if regexm(place,"[Ll]iberia|[Gg]uinea|[Oo]ut of") == 1
	
	
	**Moyamba
	replace place_clean = "Moyamba District" if regexm(place,"Gbantoke|Kagbaro") == 1
	
	**Bombali
	replace place_clean = "Bombali District" if regexm(place,"Makani") == 1
	
	**Pujehun
	replace place_clean = "Pujehun District" if regexm(place,"Peje") == 1
	replace place_clean = "Pujehun District" if regexm(place,"^[Uu]pper") == 1
	
	**Kailahun
	replace place_clean = "Kailahun District" if regexm(place,"Yawei") == 1

	**Other
	replace place_clean = "Other/unable to tell" if place_clean == "" & place != ""
	
	tab place_clean
	drop place
	
	*Create outside kenema indicator, blanks shouldn't be counted either way
	gen outside_kenema =  place_clean != "Kenema District"
	replace outside_kenema = . if place_clean == "" 
	
	*Get it back to individual level
	reshape wide place_clean outside_kenema, i(uid) j(i)
	
	*Initialize always kenema to count people who have left, and then recode
	egen ind_alwaysken = rowmax(outside_kenema?)
	recode ind_alwaysken (1 = 0) (0=1)
	
	*People who have never been displaced, are not out of Kenema
	replace ind_alwaysken = 1 if displaced == 0
	
	*one guy did not say where he went, count if him as migrant
	replace ind_alwaysken = 0 if ind_alwaysken == .
	keep uid ind_alwaysken
	save "$DATADIR\Cleaned Data\foot_migrants.dta", replace
