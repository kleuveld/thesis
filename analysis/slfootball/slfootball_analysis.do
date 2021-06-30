/*
**Replication file for Conflict Exposure and Competitiveness
Author: Koen Leuveld
Date: 19/6/2015
Last changed:29/6/2015

Info:
This file takes the raw data as produced in Kenema, cleans it, and produces the tables as presented in the paper.
Some more elaborate data management tasks are moved to separate do files, in the "do-files" folder.

The main data file needed is foot_raw.xlsx, whith data as entered in Kenema. 
The cleaned file retains all variables needed for analysis, renamed to be consisten and comprehensible.
For figure 1, secondary data is needed from ACLED. This data is not provided, but is downloaded by
a do file called by this main file.

If the whole do file is run tables will be outputted in the tables sub-folder, with filenames following numbering in 
the paper. Alternatively, by not running the local statements setting table export locations, tables are outputted 
to screen.
*/

/*
Data files needed:
*/
	*Raw Excel Data: Foot_raw.xslx, located in Raw data
	*Secondary data: SLL-LED.dta, will be downloaded if not available


/*
Do files needed
*/

	*event_years.do, to make figure 1
	*Migrats.do, to structure migration data
	*Both are in the do files folder

/*
.ado files needed
*/
//nothing special is needed.


/*
Set stata version
*/

version 12

/*
Set working dir
*/
	*make sure to cd to the directory containing this Do File

		*Dropbox FC
		capture cd "C:\Users\Koen\Documents\GitHub\thesis\analysis\slfootball"



/*Clean and label*/

/*
Get data
*/
	*Import raw data from Excel
	import excel "Raw Data/Foot_raw.xlsx", sheet("data") firstrow case(lower) clear

	*Drop empty rows and columns
	drop ds- fh
	drop if _n > 162

	*Create unique identifier
	gen uid = eveningid * 100 + personid
	
	*Save as dta
	save "Raw Data/Foot_raw.dta", replace

	*Save it as a tempfile so raw data won't get overwritten accidently
	tempfile nowrite
	save `nowrite'


/*team id*/
	ren newteam teamid


/*war exposure*/

	ren q07ahear we_hear
	la var we_hear "Heard fighting"

	ren q07csawinjured we_sawinj
	la var we_sawinj "Saw injured person"

	ren q09injured we_wasinj
	la var we_wasinj "Was injured"
	
	ren q05displace we_displace
	la var we_displace "Displaced"

	gen we_all = (we_hear + we_sawinj + we_wasinj) / 3
	la var we_all "War Exposure"

	gen we_alldisp = (we_hear + we_sawinj + we_wasinj + we_displace) / 4
	la var we_alldisp "War Exp. incl. displacement"
	
	*make a categorical variable for the levels of war exposure, to be used in figures
	gen we_level = 0
	replace we_level = 1 if we_all > 0.3
	replace we_level = 2 if we_all > 0.6
	replace we_level = 3 if we_all == 1
		
	la def we 0 "0" 
	la def we 1 "0.33", add 
	la def we 2 "0.66", add
	la def we 3 "1", add
	la val we_level we
	la var we_level "War Exposure"
	
	
	*Rename ware epxosure names
	ren q26b1year disp1_year
	ren q26c1 disp2_year
	ren q26d1 disp3_year
	ren q27ewhen we_year
	
	*Clean the dates. If there's two years, we use the first one.
	foreach var of varlist disp1_year we_year{
		*regular expression to capture 19XX or 20XX
		capture replace `var' = regexs(1) if regexm(`var',"([21][09][0-9].)[^[0-9]") == 1
		destring `var', replace force
	}

/*individual chars*/

	*Parents fought
	ren q010parentsfight ind_parfight
	la var ind_parfight "Parent fought in war"

	*Age
	ren q11age ind_age
	la var ind_age "Age"
	
	gen ind_age2 = ind_age^2
	la var ind_age2 "Age squared"

	*Education Level
	gen ind_edu = .
	la var ind_edu "Education Level"
	
	**categorize raw data using regular expressions:
	***junior secondary
	replace ind_edu = 1 if regexm(q17education,"^[Jj][Ss][Ss]") == 1
	replace ind_edu = 1 if regexm(q17education,"^GLE$") == 1
	replace ind_edu = 1 if q17education == ""
	
	***senior secondary 1 and 2
	replace ind_edu = 2 if regexm(q17education,"^[Ss][Ss][Ss] *[12]") == 1
	replace ind_edu = 2 if regexm(q17education,"high school") == 1
	replace ind_edu = 2 if regexm(q17education,"[Ww]\.*[Aa]") == 1

	***senior secondary 3:
	replace ind_edu = 3 if regexm(q17education,"^[Ss][Ss][Ss] *3") == 1
	replace ind_edu = 3 if regexm(q17education,"A level") == 1
	
	***Tertiary, the rest
	replace ind_edu = 4 if ind_edu == .
	
	
	*Meals per day
	ren q15mealsperday ind_mealpd
	
	**people don't eat more than three meals a day
	replace ind_mealpd = 3 if ind_mealpd > 3
	la var ind_mealpd "Meals per day"

	
	*Religion and ethnicity dummies using regular expressions
	gen ind_muslim = regexm(q21religion,"^[Mm]uslim$")
	la var ind_muslim "Muslim"

	gen ind_mende = regexm(q22tribe,"^[Mm]ende$")
	la var ind_mende "Mende"

	gen ind_fula = regexm(q22tribe,"^[Ff]ul*ah*$")
	la var ind_fula "Fula"

	gen ind_mandingo = regexm(q22tribe,"[Mm]andingo")
	la var ind_mandingo "Mandingo"

	gen ind_temne = regexm(q22tribe,"^[Tt]eh*me*ne$")
	la var ind_temne "Temne"
	
 	*Always in Kenema
	**This vasriable needs a lot of cleaning, and has been moved to separate do file
	preserve
	**run said do file, results are stored in foot_migrants.dta
	run "do files/Migrants.do"
	restore
	**merge the data to preserved data file
	merge 1:1 uid using  "cleaned data\foot_migrants.dta", nogen
	
/*Football*/
	*Foul cards
	destring q115ayellow, replace force
	replace q115ayellow = 0 if q115ayellow == .

	destring q115bred, replace force
	replace q115bred = 0 if q115bred == .

	gen foot_foul = q115ayellow > 0 | q115bred > 0
	la var foot_foul "Foul card"

	*Whole game
	gen foot_whole = q112aminutes == "90"
	la var foot_whole "Played whole game"

	*self-declared skills
	gen foot_selfskills = (q116competitive - 2) / 3
	replace foot_selfskills = 1 if foot_selfskills == .
	la var foot_selfskills "Self-declared skills"
	
	*scored
	destring q112bgoals, replace force
	gen foot_score = q112bgoals > 0 & q112bgoals != .
	la var foot_score "Scored"
 
	
	*won
	**Data has been entered wrongly at some points. cleaned according to field notes:
	gen  foot_won = q111win
	destring foot_won, replace force
	quietly replace foot_won  =0 if eveningid==2 & team=="a"
	quietly replace foot_won  = 0 if eveningid==6 & team == "a"
	quietly replace foot_won  = 1 if eveningid == 6 & team == "b"
	
	quietly replace foot_won  =0 if eveningid ==3
	quietly replace foot_won =1 if foot_won ==3
	
	la var foot_won "Won the football game"
	
	*left footed
	ren q14alefthanded1yes2no foot_left
	replace foot_left = 0 if foot_left == 2
	la var foot_left "Left footed"
 
 /*Lab-in-the-field*/
	*Risk
	*initialize variables
	gen switch = .

	*run a loop that marks the last risky choice
	forvalues i = 1/6{
		replace switch = `i' if r`i' == 0
	}
	replace switch = 0 if switch == .

	egen life_risk = std(switch)
	
	*dictator giving
	ren dicoutgive dictgive0
	ren dictingive dictgive1

	**The variable is standardized in long form, to preserve differences in means between in- and outgroup
	reshape long dictgive, i(uid) j(ingroup)
	egen life_dict = std(dictgive)
	
	**Reshape back and give consistent names
	reshape wide dictgive life_dict, i(uid) j(ingroup)
	ren life_dict0 life_dictout
	ren life_dict1 life_dictin
	
	*Self selection into competition
	egen life_tournament = rowfirst(tournamentout tournamentin)
	la var life_tournament "Self-select in tournament"
	
	*dummy for all observations to indicate if ball game was played with in- or outgroup
	gen life_tourout = tournamentout != .
	la var life_tourout "Outgroup"
	
	gen life_tourin = life_tourout == 0
	la var life_tourin "Ingroup"
	
	*variables for summ stats table, to split between in and outgroup
	ren tournamentout life_outtour
	la var life_outtour "Outgroup Tournament"
	
	ren tournamentin life_intour
	la var life_intour "Ingroup Tournament"
		
	*Expected performance	
	gen life_expperf = 1 - (ballevel_exp - 1) / 5
	la var life_expperf "Expected performance"
	
	*ballshit
	ren ballshit life_ballshit 
	
	*Save
	order ui eveningid personid team we_* ind_* foot_* life_*
	save "cleaned data\foot_cleaned_all.dta", replace
	keep uid eveningid personid teamid we_* team ind_* foot_* life_*
	save "cleaned data\foot_cleaned.dta", replace

	

	
/*ANYALYSIS*/

/*Tables*/

	*if the following lines of code are run, the output will be saved to file, otherwise output is displayed on screen
	
	**put file names in locals
	foreach i in 1 3 4 5 6 a1 a2 a3 a4{
		local t`i'`"using "tables\t`i'.tex""'
	}

	**put replace option in a local (empty if this not run, thus not specified)
	local replace replace

/*
Table 1: Descriptive stats
*
*/
	use "cleaned data\foot_cleaned.dta", clear
	eststo summ: estpost su we_all ind_parfight ind_age ind_edu ind_mealpd ind_muslim ind_mende ind_fula ind_mandingo ind_temne ind_alwaysken foot_foul foot_whole foot_selfskill foot_score foot_won foot_left life_risk life_dictout life_dictin  life_outtour life_intour life_expperf life_ballshit
	*no fancy stuff here, just dumb copy to word

	//eststo summ: estpost su tdg sentvill risk fracexpected avfracreturn market $controls if !missing(market)
	esttab summ `t1', cells("count mean(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2))") label noobs replace nonumbers




/*
Table 2 is the design of the risk game
*/

/*
Table 3: Exposure to conflict
*/
	eststo t3_1: qui reg we_all ind_age ind_age2, robust
	eststo t3_2: qui reg we_all ind_age ind_age2 ind_muslim ind_mende ind_fula ind_mandingo ind_temne, robust
	eststo t3_3: qui reg we_all ind_age ind_age2 ind_parfight, robust
	eststo t3_4: qui reg we_all ind_age ind_age2 ind_muslim ind_mende ind_fula ind_mandingo ind_temne ind_alwaysken ind_edu ind_mealpd foot_left foot_whole foot_selfskills foot_score foot_won ind_parfight , robust
	esttab t3_* `t3', `replace'  star(* 0.10 ** 0.05 *** 0.01) label ///
	stats(N r2,fmt(%9.0f %12.3f)  labels("N" "R2")) se ///
		 order(ind_age ind_age2 ind_muslim ind_mende ind_fula ind_mandingo ind_temne ind_alwaysken ///
		 ind_edu ind_mealpd foot_left foot_whole foot_selfskills foot_score foot_won ind_parfight ) ///
		 nonotes nomtitles


/*
Table 4: Aggressiveness and risk propensity
*/
	qui probit foot_foul we_all, robust
	eststo t4_1 : qui mfx
	qui probit foot_foul we_all ind_age ind_age2 ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left , robust
	eststo t4_2 : qui mfx
	eststo t4_3: qui reg life_risk we_all, robust
	eststo t4_4: qui reg life_risk we_all ind_age ind_age2 ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left , robust

	esttab t4_* `t4', `replace' star(* 0.10 ** 0.05 *** 0.01) label margin ///
		mtitles("\specialcell{Foul\\Card}" "\specialcell{Foul\\Card}" ///
			"\specialcell{Risk\\Propensity}" "\specialcell{Risk\\Propensity}") ///
		stats(N r2_p r2,fmt(%9.0f %12.3f)  labels("N" "Pseudo R-Squared" "R2" )) se nonotes

/*
Table 5:  Dictator game donations
*/

	*data is in wrong shape for this analysis: we need the dictator decisions to be rows: 2 per person (in and outgroup)
	preserve
	ren life_dictin life_dict1
	ren life_dictout life_dict0
	reshape long life_dict, i(uid) j(ingroup)
	egen dict = std(life_dict)
	la var ingroup "Ingroup"
	
	*generate interaction term between ingroup and war exposure.
	gen int_we_in = ingroup * we_all 
	la var int_we_in "Exposure to conflict × in-group "

	eststo t5_1 :qui reg dict we_all if ingroup == 0, r
	eststo t5_2 :qui reg dict we_all ind_age ind_age2 ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left if ingroup == 0, r
	eststo t5_3 :qui reg dict we_all if ingroup == 1, r
	eststo t5_4 :qui reg dict we_all ind_age ind_age2 ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left if ingroup == 1, r
	eststo t5_5 :qui reg dict we_all ingroup int_we_in ind_age ind_age2 ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left, r
	esttab t5_* `t5', `replace' star(* 0.10 ** 0.05 *** 0.01) label ///
		mtitles("Out-group" "Out-group" "In-group" "In-group" "Pooled") ///
		stats(N r2,fmt(%9.0f %12.3f)  labels("N" "R2")) se ///
		order(we_all ingroup int_we_in ind_age) nonotes

	*Get back wide data
	restore
		
/*
TABLE 6 WILLINGNESS TO COMPETE
*/
	*generate interaction term
	gen int_we_tourin = we_all *  life_tourin
	la var int_we_tourin "Exposure to conflict × in-group" 
	
	
	qui probit life_tournament we_all if life_tourout == 1, robust
	eststo t6_1 : qui mfx
	qui probit life_tournament we_all ind_age ind_age2 ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left if life_tourout == 1, robust
	eststo t6_2 : qui mfx
	qui probit life_tournament we_all if life_tourout == 0, robust
	eststo t6_3 : qui mfx
	qui probit life_tournament we_all ind_age ind_age2 ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left if life_tourout == 0, robust
	eststo t6_4 : qui mfx
	qui probit life_tournament we_all life_tourin int_we_tourin  ind_age ind_age2 ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left, robust
	eststo t6_5 : qui mfx

	esttab t6_* `t6', `replace' star(* 0.10 ** 0.05 *** 0.01) label margin ///
		mtitles("Out-group" "Out-group" "In-group" "In-group" "Pooled") ///
		stats(N r2_p,fmt(%9.0f %12.3f)  labels("N" "Pseudo R-Squared")) se ///
		order(we_all life_tourin int_we_tourin) nonotes
		
		
/*
TABLE A1: WILLINGNESS TO COMPETE (out-group), age group fixed effects
*/
	
	*dummies for 1-year FE
	qui tab ind_age, gen(agedummy)
	
	*dummies for 2/3/4-year FE
	forvalues i = 2/4{
		egen bin_`i'year = cut(ind_age), at(14(`i')35)
		qui tab bin_`i'year, gen(bin`i'year_dummy)
	}
	
	qui probit life_tournament we_all ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left agedummy* if life_tourout == 1, robust
	eststo ta1_1 : qui mfx	
	qui probit life_tournament we_all ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left bin2year_dummy* if life_tourout == 1, robust
	eststo ta1_2 : qui mfx	
	qui probit life_tournament we_all ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left bin3year_dummy* if life_tourout == 1, robust
	eststo ta1_3 : qui mfx
	qui probit life_tournament we_all ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left bin4year_dummy* if life_tourout == 1, robust
	eststo ta1_4 : qui mfx	
	
	esttab ta1_* `ta1', `replace' star(* 0.10 ** 0.05 *** 0.01) label margin ///
		stats(N r2_p,fmt(%9.0f %12.3f)  labels("N" "R2")) se ///
		mtitles("\specialcell{1-year\\age-group f.e.}" "\specialcell{2-year\\age-group f.e.}" ///
			"\specialcell{3-year\\age-group f.e.}" "\specialcell{4-year\\age-group f.e.}") ///
		drop(*dummy*) nonotes
		
		
/*
TABLE A2: WILLINGNESS TO COMPETE (out-group), migration
*/		
	*generate the interaction term
	gen int_we_ken = we_all * ind_alwaysken
	
	qui probit life_tournament we_all ind_age ind_age2 ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left if life_tourout == 1 & ind_alwaysken == 1, robust
	eststo ta2_1 : qui mfx		
	qui probit life_tournament we_all ind_age ind_age2 ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left if life_tourout == 1 & ind_alwaysken == 0, robust
	eststo ta2_2 : qui mfx	
	qui probit life_tournament we_all ind_alwaysken int_we_ken ind_age ind_age2 ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left if life_tourout == 1, robust
	eststo ta2_3 : qui mfx
	qui probit life_tournament we_all ind_alwaysken int_we_ken int_we_tourin life_tourin ind_age ind_age2 ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left, robust
	eststo ta2_4 : qui mfx
		
	esttab ta2_* `ta2', `replace' star(* 0.10 ** 0.05 *** 0.01) label margin ///
		stats(N r2_p,fmt(%9.0f %12.2f)  labels("N" "R2")) se ///
		mtitles("\specialcell{Outgroup:\\Always in\\Kenema}" "\specialcell{Outgroup:\\Migrated}" ///
			"\specialcell{Outgroup:\\All}" "\specialcell{Pooled}") ///
		order(we_all ind_alwaysken int_we_ken) nonotes
		
/*
TABLE A3: WILLINGNESS TO COMPETE (out-group), various FE
*/	
	*generate dummies for FE
	qui tab teamid,gen(teamdummy)
	qui tab eveningid,gen(eveningdummy)
	
	qui probit life_tournament we_alldisp ind_age ind_age2 ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left if life_tourout == 1, robust
	eststo ta3_1 : qui mfx	
	qui probit life_tournament we_all ind_age ind_age2 ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left eveningdummy* if life_tourout == 1, robust
	eststo ta3_2 : qui mfx	
	qui probit life_tournament we_all ind_age ind_age2 ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_left teamdummy* if life_tourout == 1, robust
	eststo ta3_3 : qui mfx	
	qui probit life_tournament we_all ind_age ind_age2 ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left if life_tourout == 1, vce(cluster teamid) 
	eststo ta3_4 : qui mfx		
	
	esttab  ta3_*`ta3', `replace' star(* 0.10 ** 0.05 *** 0.01) label margin ///
		stats(N r2_p,fmt(%9.0f %12.3f)  labels("N" "R2")) se ///
		order(we_alldisp we_all) drop(*dummy*) ///
		b(%12.3f)
	
	
/*
TABLE A4: WILLINGNESS TO COMPETE (out-group), risk preferences and expected performance
*/	
	qui probit life_tournament we_all life_risk  ind_age ind_age2 ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left if life_tourout == 1, robust
	eststo ta4_1 : qui mfx	
	qui probit life_tournament we_all life_expperf ind_age ind_age2 ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left if life_tourout == 1, robust
	eststo ta4_2 : qui mfx	
	qui probit life_tournament we_all ind_age life_ballshit ind_age2 ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left if life_tourout == 1, robust
	eststo ta4_3 : qui mfx	
	qui probit life_tournament we_all life_risk life_expperf life_ballshit ind_age ind_age2 ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left if life_tourout == 1, r
	eststo ta4_4 : qui mfx		
	
	esttab ta4_* `ta4', `replace' star(* 0.10 ** 0.05 *** 0.01) label margin ///
		stats(N r2_p,fmt(%9.0f %12.3f)  labels("N" "R2")) se  ///
		order(we_all life_risk life_expperf life_ballshit) nonotes

	
/*
Figures
*/			

	use "cleaned data\foot_cleaned.dta", clear

/*Figure 1: SLL-LED events and displacement*/
	preserve
	
	*get data in shape to easily plot conflict events and years
	run "do files/event_years.do"
	
	twoway 	(bar violence year, fcolor(none) lcolor(black) lwidth(thick)) ///
					(connected we year, msymbol(diamond) lpattern(dash) lwidth(medthick)) ///
					(connected disp year, msymbol(triangle) lwidth(thick)) , ///
					ytitle(Percentage of total conflict events) ///		   
					xscale(range(1991 2002)) ///
					xlabel(1991/2002) ///
					legend(cols(1))scheme(s2mono) ///
					ysize(8) xsize(11)
		   
	graph export "Figures\f1_violent_events.png", as(png) replace
	graph export "Figures\f1_violent_events.eps", as(eps) replace
	restore

/*Figure 2: Age in sample and exposure to conflict*/	
	graph drop _all	
	
	*Panel A
	hist ind_age, fcolor(none) lcolor(black) freq d width(1) start(14) norm xlabel(14 (2) 31) ysize(2) xsize(3) scheme(s2mono) name(agefreq, replace) title("(A)")
	
	bysort ind_age: egen agewar=mean(we_all)
	
	*Panel B
	twoway 	(scatter agewar ind_age)  ///
					(qfit agewar ind_age) ///
					, ylabel(0 (0.1) 1) xlabel (14 (2) 31) ///
					ytitle("Average Victimization Index") ///
					ysize(2) xsize(3) legend(off) ///
					scheme(s2mono) name(agewar, replace) title("(B)")

	
	graph combine agefreq agewar, ysize(4) xsize(11)
	graph export "Figures\f2_agefreq_agewe.png", as(png) replace
	graph export "Figures\f2_agefreq_agewe.eps", as(eps) replace
	
/*Figure 3: Balls hit in the effort game*/	
	graph drop _all
	
	*create four histograms for combinations of ingroup/outgroup and tournament selection
	hist life_ballshit if life_tourin==0 & life_tournament==1, d norm percent xlab(0 (2) 10) xtitle ("Balls on Target") name(hist1) fcolor(none) lcolor(black) scheme(s2mono)
	hist life_ballshit if life_tourin== 1 & life_tournament==1, d norm percent xlab(0 (2) 10) xtitle ("Balls on Target") name(hist2) fcolor(none) lcolor(black) scheme(s2mono)
	hist life_ballshit if life_tourin==0 & life_tournament==0, d norm percent xlab(0 (2) 10) ylab(0 (10) 30) xtitle ("Balls on target") name(hist3) fcolor(none) lcolor(black) scheme(s2mono)
	hist life_ballshit if life_tourin== 1 & life_tournament==0, d norm percent xlab(0 (2) 10) xtitle ("Balls on Target") name(hist4) fcolor(none) lcolor(black) scheme(s2mono)	 
	
	*cobmine and export
	graph combine hist1 hist2 hist3 hist4, ysize(8) xsize(11)
	graph export "Figures\f3_ballshit.png", as(png) replace	
	graph export "Figures\f3_ballshit.eps", as(eps) replace	

/*Figure 4: Foul cards, competitiveness and exposure to violence*/		
	preserve
	graph drop _all
	
	use "cleaned data\foot_cleaned.dta", clear

	*Top row (panel A and B)
	*create mean and CI for foul cards and competition
	foreach var in foot_foul life_tournament{
		bysort we_all: egen mean`var' = mean(`var')
		gen ci`var'_u = .
		gen ci`var'_l = .
		forvalues i = 0/3{
			qui ci `var' if we_level == `i',binomial 
			replace ci`var'_u = `r(ub)' if we_level == `i'
			replace ci`var'_l = `r(lb)' if we_level == `i'
		}
	}	

 
	*create top left panel (A)
	twoway 	(connected meanfoot_foul we_level, msymbol(square_hollow) lpattern(dash)) /// 
					(rcap cifoot_foul_u cifoot_foul_l we_level) ///
					, legend(off) ytitle("Foul Card") ylabel(0 0.25 0.5 0.75 1) yscale(range (0 1)) xlabel(, valuelabel) scheme(s2mono) ///
					name(foot_foul) title("(A)")
	
	*create top right panel (B)
	twoway 	(connected meanlife_tournament we_level, sort msymbol(square_hollow) lpattern(dash)) /// 
					(rcap cilife_tournament_u cilife_tournament_l we_level, sort) ///
					, legend(off) ytitle("Competition") ylabel(0 0.25 0.5 0.75 1) yscale(range (0 1)) xlabel(, valuelabel) scheme(s2mono) ///
					name(life_tournament) title("(B)")
	
	*Bottom Row (Panel C and D)
	*create mean and CI per ingroup/outgroup for competition
	forvalues j = 0/1{
		bysort we_all: egen meanlife_tournament_`j' = mean(life_tournament) if life_tourin == `j'
		gen cilife_tournament_`j'_l = .
		gen cilife_tournament_`j'_u = .

		forvalues i = 0/3{
			qui ci life_tournament if we_level == `i' & life_tourin == `j',binomial 
			replace cilife_tournament_`j'_u = `r(ub)' if we_level == `i' & life_tourin == `j'
			replace cilife_tournament_`j'_l = `r(lb)' if we_level == `i' & life_tourin == `j'
		}
	}
	
	
	*create bottom left panel (C)
	twoway 	(connected meanlife_tournament_0 we_level, msymbol(square_hollow) lpattern(dash)) /// 
					(rcap cilife_tournament_0_u cilife_tournament_0_l we_level) ///
					, legend(off) ytitle("Competition (Out-group)") ylabel(0 0.25 0.5 0.75 1) yscale(range (0 1)) xlabel(, valuelabel) scheme(s2mono) ///
					name(life_tournament_0) title("(C)")
	
	*create bottom right panel (D)
	twoway 	(connected meanlife_tournament_1 we_level, msymbol(square_hollow) lpattern(dash)) /// 
					(rcap cilife_tournament_1_u cilife_tournament_1_l we_level) ///
					, legend(off) ytitle("Competition (In-group)") ylabel(0 0.25 0.5 0.75 1) yscale(range (0 1))xlabel(, valuelabel) scheme(s2mono) ///
					name(life_tournament_1) title("(D)")	
	
	*combine into one
	graph combine foot_foul life_tournament life_tournament_0  life_tournament_1, ycommon xcommon ysize(8) xsize(11)

	*Export the graphs
	graph export "Figures\f4_we_competition.png", as(png) replace
	graph export "Figures\f4_we_competition.eps", as(eps) replace
