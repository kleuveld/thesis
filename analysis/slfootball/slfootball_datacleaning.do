
/*
Set stata version
*/

version 12

/*
Set working dirs
*/
	*reset globals
	global  HELPERDIR //helper do files
	global DATADIR 	//personal data, so restricted access
	global OUTPUTDIR //outputs such as tables and figures
	
	*get data folders
	
	*There should be a Raw Data, Cleaned Data, and Secondary Data folder
	*(NB: PATHS IN CRYPTOMATOR ARE CASE SENSITIVE!) 
		*Cryptomator Koen private 
		capture cd  "D:\PhD\Papers\Football\pAPER\Replication"
		global  DATADIR = "`: pwd'"


	*get óutput folders
		*Git KL private
		capture cd "C:\Users\kld330\git\thesis\chapters\slfootball\"

		global  OUTPUTDIR `: pwd'

	*get helper folder
		*Git KL VU
		capture cd "C:\Users\kld330\git\thesis\analysis\slfootball"

		global  HELPERDIR `: pwd'	


/*Clean and label*/

/*
Get data
*/
	*Import raw data from Excel
	import excel "${DATADIR}\Raw Data\Foot_raw.xlsx", sheet("data") firstrow case(lower) clear

	*Drop empty rows and columns
	drop ds- fh
	drop if _n > 162

	*Create unique identifier
	gen uid = eveningid * 100 + personid
	
	*Save as dta
	save "$DATADIR/Raw Data/Foot_raw.dta", replace

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
	run "$PUBLICDIR/Do Files/Migrants.do"
	restore
	**merge the data to preserved data file
	merge 1:1 uid using  "$DATADIR/Cleaned Data/foot_migrants.dta", nogen
	
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
	save "$DATADIR/Cleaned Data\foot_cleaned_all.dta", replace
	keep uid eveningid personid teamid we_* team ind_* foot_* life_*
	save "$DATADIR/Cleaned Data\foot_cleaned.dta", replace
