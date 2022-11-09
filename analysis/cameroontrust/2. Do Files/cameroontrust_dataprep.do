/*Dependencies*/

/*Set direcectories*/
	global gitloc  C:\Users\kld330\git
	global dataloc  D:\PhD\Papers\CameroonTrust\Data_encrypted //holds raw and clean data
	global tableloc ${gitloc}\thesis\chapters\cameroontrust\tables //where tables are put
	global figloc ${gitloc}\thesis\chapters\cameroontrust\figures //where figures are put
	global helperloc ${gitloc}\thesis\analysis\cameroontrust\2. Do files //holds do files
*********
**********
**PHASE2**
**********
*********

	use "${dataloc}\Raw\Phase2\SNVPH2.dta", clear

/*Create a temfile to prevent accidental overwriting*/
	tempfile phase2
	save `phase2'


	/* Generate Unique Composed ID */
		sort q003 q004a q004b
		assert  q003>=0 & q003<=200
		summarize q004a
		assert  q004a >=0 & q004a <=797
		summarize q004b
		assert  q004b >=0 & q004b <=6
		gen long hhID= (q003*100000) + (q004a*100) +  q004b
		move hhID qh001
		ren q003 villID

/* Keep variables of interest*/
	keep hhID villID qh013 qh014 qh023 qh040 qh046 qh047 ivsa1 ivsa4 ivra1 - ivra10 ivra11 icsa1 icsa4 icra11 rcm1 - rcm10 tda1

*******************
**General Variables**
*******************

/* Rename Variables */
	rename qh014 marstat 
	la var marstat "Marital status"
	replace marstat = . if marstat == 9
	la def marstat 1 "Single" 2 "Married (monogamous)" 3 "Married (polygamous)" 4 "Widowed" 5 "Divorced" 6 "Civil Union (monogamous)" 7 "Civil Union (polygamous)" 
	la val marstat marstat

	gen married = inlist(marstat,2,3)
	la var married "Married"


	rename qh023 elig
	la var elig "Eligible for biogas"
	recode elig (2=0) (9=.)
	la def yesno 1 "Yes" 0 "No"
	la val elig yesno

	rename qh040 wivesnumb
	la var wivesnumb "Number of wives"

	rename qh046 relwealthvill
	la var relwealthvill "Wellbeing relative to village"
	rename qh047 relwealthchef
	la var relwealthchef "Wellbeing relative to chef"

	la def relwealth 1 "Much higher" 2 "Higher" 3 "The Same" 4 "Lower" 5 "Much lower"
	la val relwealthvill relwealthchef relwealth


	gen relwealthbin = .
	la var relwealthbin  "High wellbeing relative to village" 
	replace relwealthbin = inlist(relwealthvill,1,2) if !missing(relwealthvill)
	la def lowhigh 1 "High" 0 "Same or low"
	la val relwealthbin lowhigh

/* Generate Variable for Leaders. 1 if Leader; 0 if not leader */
	gen leader =.
	replace leader =1 if qh013==1
	replace leader =1 if qh013==2
	replace leader =1 if qh013==3
	replace leader =0 if leader ==.
	replace leader =. if qh013==.
	
	la var leader "Village leader"
	drop qh013


*******************
****Trust game*****
*******************

	rename ivsa1 sentvill
	la var sentvil "IG: Tokens sent"

	rename ivsa4 expected
	la var expected "Tokens expected"

	gen fracexpected = expected / sentvill
	la var fracexpected "IG: Fraction expected"
	replace fracexpected = 0 if sentvill == 0
	order fracexpected, after(expected)

	rename ivra11 comprevill
	la var comprevill "Comprehension"

	rename icsa1 sentchief
	la var sentchief "Tokens sent (chef)"

	rename icsa4 expectedchief
	la var expectedchief "Tokens expected (chef)"
	rename icra11 comprechef
	la var comprechef "Comprehension (chef)"	

	//ivra1 - ivra10
	*average fraction returned
	forvalues i = 1/10{
		gen ivrafrac`i' = ivra`i'/`i'
	}


	egen avfracreturn = rowmean(ivrafrac1 - ivrafrac10)
	la var  avfracreturn "IG: fraction returned"
	
	
********************
***Risk Game (HH)***
********************	
 
	*indicator for risk is the first switch point from 
	gen risk = .
	la var risk "RG: switch point"
	forvalues i = 1/10{
			qui replace risk = `i' if rcm`i' == 2 & risk == .
	}	 
	qui replace risk = 11  if risk == . & rcm1 != .

	gen riskswitch = 0
	gen  riskswitchb2r = 0

	/*count switchpounts*/
		forvalues i = 2/10{
			local j = `i' - 1
			
		/*count total switchpoints*/
			qui replace riskswitch = riskswitch + 1 if rcm`i' != rcm`j'
			
		/*count blue to red (illegal) switchpoints*/
			qui replace riskswitchb2r = riskswitchb2r + 1 if rcm`i' == 1 & rcm`j'== 2
		}
	gen riskincons =  riskswitch > 1 | riskswitchb2r > 0 if !missing(rcm1) 
	la var riskincons "Inconsistent risk preferences"
	la val riskincons yesno

	drop riskswitch riskswitchb2r rcm1 - rcm10


*********
***TDG***
*********
	rename tda1 tdg
	la var tdg "TDG: tokens sent"


	save `phase2', replace



	
*******
**Phase 1**
*******


/*Import raw file*/

	use "${dataloc}/Raw/Phase1\hh.dta", clear
	sort q003 q004a q004b

/* Selecting variables of Interest */

	//keep q003 q004a q004b q1031 q1032 q1033 q1034 q1035 q1036 q1037a q1037b q1037c q1037d q1037e q1038a q1038b q1038c q1038d q1039a q1039b q1039c q1039d q003 q004a q004b

/* Generate Unique Identifier*/
	sort q003 q004a q004b
	assert  q003>=0 & q003<=200
	summarize q004a
	assert  q004a >=0 & q004a <=797
	summarize q004b
	assert  q004b >=0 & q004b <=6
	gen long hhID= (q003*100000) + (q004a*100) +  q004b
	move hhID q1031
	ren q003 villID
	
/* Rename Variables of Interest*/

	gen roof = 0
	la var roof "Improved roof"
	replace roof = 1 if inlist(q520,1,2,3)

	keep hhID villID roof
	tempfile phase1 
	save `phase1'
	

	
************************
**Village Size*********
***********************

	use "${dataloc}/Raw/Phase1\fd.dta",clear

	/* Generating Variable Villag size */
	collapse (count) villsize = fd00, by ( q003)

	ren q003 villID
	la var villsize "Village Size"

	keep villID villsize

	tempfile villsize 
	save `villsize'

	
**********************************
**Household Members***********
**************************
	use "${dataloc}/Raw/Phase1\hl.dta", clear
	
/*ID vars*/
	sort q003 q004a q004b
	assert  q003>=0 & q003<=200
	summarize q004a
	assert  q004a >=0 & q004a <=797
	summarize q004b
	assert  q004b >=0 & q004b <=6
	gen long hhID= (q003*100000) + (q004a*100) +  q004b
	ren q003 villID


/*nuber of wives*/
//	gen wive = 0 
//	replace wive = 1 if q103==2

/*Married dummy*/
	gen married = 0
	replace married=1 if (q111==2 | q111==3) & q101 ==1 
	
/*Head age*/
	gen agehead = .
	replace agehead = q104 if q104 <= 95 & q101 == 1


	
/*Muslim*/
	gen muslim = 0
	replace muslim = 1 if q007 == 4

/*Education dummy*/
	gen education = 0
	replace education  = 1 if q202 == 1 & q101 == 1
	
/*how long have you lived here*/
	gen days = .
	replace q501n = . if q501n > 90
	replace days = q501n if q501u == 1
	replace days = q501n * (365.25/12) if q501u == 2 //months
	replace days = q501n * 356 if q501u == 3 //years
	gen duration = day/365 //get back to year
	replace duration = . if q101 != 1
	replace duration = round(duration)
	tab duration if q101 == 1
	

	gen startage = max(0,agehead - duration) //age at which head moved into
	foreach i in 10 15 20 25 {
		gen migrant`i' = startage > `i'
	}
	
	gen hhsize = 1

/*collapse*/
	*note: the variables collapsed to max are hh-level variables, and are thus the same for each line.s
	collapse (sum) hhsize /* wives = wive */ married agehead (max) duration muslim education migrant10 migrant15 migrant20 migrant25, by(hhID)
	la var hhsize "HH Size"
	la var married "Head married"
	la var agehead "Age HH head"
	//la var wives "No. of wives"
	la var muslim "Muslim"
	la var education "Head educated"
	la var duration "Years in village"
	foreach i in 10 15 20 25 {
			la var migrant`i' "Migrant"

	}

	keep hhID hhsize married agehead muslim education duration migrant*
	tempfile roster 
	save `roster'


*********
**MARKET ACCESS
******************

	use "${dataloc}/Raw/Phase1\VSECT2A.dta", clear
	ren vq003 villID


	replace vq202 = . if vq202 == 9
	keep if vq200 == 10 | vq200 == 11
	gen market = vq202 == 1

	replace vq206b = . if vq206b == 999
	ren vq206b distmajortown

	replace vq209 = . if vq209 == 9
	gen asphalt = vq209 == 1



	collapse (max) market distmajortown asphalt, by(villID)
	la var market "Market in village"
	la var distmajortown "Dist. to major town"
	la var asphalt "Asphalt road in village"

	tempfile market 
	save `market'



******************
**MARKET INTEGRATION
***************

	use "${dataloc}/Raw/Phase1\HHSECT69.dta", clear

/*ID vars*/
	sort q003 q004a q004b
	assert  q003>=0 & q003<=200
	summarize q004a
	assert  q004a >=0 & q004a <=797
	summarize q004b
	assert  q004b >=0 & q004b <=6
	gen long hhID= (q003*100000) + (q004a*100) +  q004b
	ren q003 villID

	
	replace q672 = . if q672 == 99999
	replace q674 = . if q674 == 99999
	replace q676 = . if q676 == 99999

	collapse (sum) produced = q672 consumed = q674 sold = q676 , by(hhID)

	gen fracsold = sold / produced
	replace fracsold = . if fracsold > 1
	la var fracsold "Frac. output sold"

	keep hhID fracsold
	
	tempfile foodsold 
	save  `foodsold'

*****************
***Market Participation
********************
	use "${dataloc}/Raw/Phase1/HHSECT7A.dta", clear
	
	/*ID vars*/
	sort q003 q004a q004b
	assert  q003>=0 & q003<=200
	summarize q004a
	assert  q004a >=0 & q004a <=797
	summarize q004b
	assert  q004b >=0 & q004b <=6
	gen long hhID= (q003*100000) + (q004a*100) +  q004b
		
		
	replace q704a = . if q704a == 99999
	replace q704b = . if q704b == 99999

	//collapse (sum) bought = q704a notbought = q704b, by(hhID)

	//gen FRACBOUGHT = bought / (bought + notbought)

	ren q704a value_bought 
	ren q704b value_notbought 
	gen value_total = value_bought + value_notbought

	gen value_produced = (q703 == 1 | q703 == 7) * value_total
	gen value_charity = (q703 == 3 | q703 == 6) * value_total
	gen value_barter = (q703 == 4) * value_total
	gen value_buy = (q703 == 2 | q703 == 5) * value_total

	collapse (sum) value_*, by(hhID)

	local stuff bought notbought produced charity barter buy
	foreach i in `stuff' {
		gen frac`i' = value_`i' / value_total
		la var frac`i'  "Frac. food `i'"
	}
	drop value_*

		
	tempfile foodbought
	save  `foodbought'
	

	
***************
**MERGE****
*********
	use `phase2', clear
	merge m:1 hhID using "`phase1'", gen(_phase1merge) //40 master, 81 using
	merge m:1 villID using "`villsize'", gen(_villsizemerge)
	merge m:1 hhID using "`roster'", gen(_rostermerge)
	merge m:1 villID using "`market'", gen(_mrktaccmerge)
	merge m:1 hhID using "`foodsold'", gen(_sellmerge)
	merge m:1 hhID using "`foodbought'", gen(_buymerge)
	//merge m:1 hhID using "`aa'", gen(_aamerge)
	sort hhID 
	save "${dataloc}\Clean\Trust_data_all.dta", replace	

	
	


	
