/*ANYALYSIS*/
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



/*Tables*/

	*if the following lines of code are run, the output will be saved to file, otherwise output is displayed on screen
	
	**put file names in locals
	foreach i in 1 3 4 5 6 a1 a2 a3 a4{
		local t`i'`"using "$OUTPUTDIR\Tables\t`i'.tex""'
	}

	**put replace option in a local (empty if this not run, thus not specified)
	local replace replace

/*
Table 1: Descriptive stats
*
*/
	use "$DATADIR/Cleaned Data/foot_anon.dta", clear
	eststo summ: estpost su we_all ind_parfight ind_age ind_edu ind_mealpd ind_muslim ind_mende ind_alwaysken foot_foul foot_whole foot_selfskill foot_score foot_won foot_left life_risk life_dictout life_dictin  life_outtour life_intour life_expperf life_ballshit
	esttab summ `t1', cells("count mean(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2))") label noobs replace nonumbers

/*
Table 2 is the design of the risk game
*/

/*
Table 3: Exposure to conflict
*/
	eststo t3_1: qui reg we_all i.ind_age, robust
	eststo t3_2: qui reg we_all i.ind_age ind_muslim ind_mende, robust
	eststo t3_3: qui reg we_all i.ind_age ind_parfight, robust
	eststo t3_4: qui reg we_all i.ind_age ind_muslim ind_mende ind_alwaysken ind_edu ind_mealpd foot_left foot_whole foot_selfskills foot_score foot_won ind_parfight , robust
	esttab t3_* `t3', `replace'  star(* 0.10 ** 0.05 *** 0.01) ///
	stats(N r2,fmt(%9.0f %12.3f)  labels("N" "R2")) label se ///
		 order(?.ind_age ind_muslim ind_mende ind_alwaysken ///
		 ind_edu ind_mealpd foot_left foot_whole foot_selfskills foot_score foot_won ind_parfight ) ///
		 nonotes nomtitles nobaselevels

tab ind_age, gen(ind_age)
drop ind_age1
/*
Table 4: Aggressiveness and risk propensity
*/
	qui probit foot_foul we_all, robust
	eststo t4_1 : qui mfx
	qui probit foot_foul we_all ind_age? ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left , robust
	eststo t4_2 : qui mfx
	eststo t4_3: qui reg life_risk we_all, robust
	eststo t4_4: qui reg life_risk we_all ind_age? ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left , robust

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
	eststo t5_2 :qui reg dict we_all i.ind_age ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left if ingroup == 0, r
	eststo t5_3 :qui reg dict we_all if ingroup == 1, r
	eststo t5_4 :qui reg dict we_all i.ind_age ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left if ingroup == 1, r
	eststo t5_5 :qui reg dict we_all ingroup int_we_in i.ind_age ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left, r
	esttab t5_* `t5', `replace' star(* 0.10 ** 0.05 *** 0.01) label ///
		mtitles("Out-group" "Out-group" "In-group" "In-group" "Pooled") ///
		stats(N r2,fmt(%9.0f %12.3f)  labels("N" "R2")) se ///
		order(we_all ingroup int_we_in ?.ind_age) nonotes nobaselevels

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
	qui probit life_tournament we_all ind_age?  ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left if life_tourout == 1, robust
	eststo t6_2 : qui mfx
	qui probit life_tournament we_all if life_tourout == 0, robust
	eststo t6_3 : qui mfx
	qui probit life_tournament we_all ind_age?  ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left if life_tourout == 0, robust
	eststo t6_4 : qui mfx
	qui probit life_tournament we_all life_tourin int_we_tourin  ind_age?  ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left, robust
	eststo t6_5 : qui mfx

	esttab t6_* `t6', `replace' star(* 0.10 ** 0.05 *** 0.01) label margin ///
		mtitles("Out-group" "Out-group" "In-group" "In-group" "Pooled") ///
		stats(N r2_p,fmt(%9.0f %12.3f)  labels("N" "Pseudo R-Squared")) se ///
		order(we_all life_tourin int_we_tourin) nonotes
		
		
/*
TABLE A1: WILLINGNESS TO COMPETE (out-group), age group fixed effects
*/
/* 	
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
		
 */		
/*
TABLE A2: WILLINGNESS TO COMPETE (out-group), migration
*/		
	*generate the interaction term
	gen int_we_ken = we_all * ind_alwaysken
	
	qui probit life_tournament we_all ind_age? ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left if life_tourout == 1 & ind_alwaysken == 1, robust
	eststo ta2_1 : qui mfx		
	qui probit life_tournament we_all ind_age? ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left if life_tourout == 1 & ind_alwaysken == 0, robust
	eststo ta2_2 : qui mfx	
	qui probit life_tournament we_all ind_alwaysken int_we_ken ind_age? ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left if life_tourout == 1, robust
	eststo ta2_3 : qui mfx
	qui probit life_tournament we_all ind_alwaysken int_we_ken int_we_tourin life_tourin ind_age? ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left, robust
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
	
	qui probit life_tournament we_alldisp ind_age? ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left if life_tourout == 1, robust
	eststo ta3_1 : qui mfx	
	qui probit life_tournament we_all ind_age? ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left eveningdummy* if life_tourout == 1, robust
	eststo ta3_2 : qui mfx	
	qui probit life_tournament we_all ind_age? ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_left teamdummy* if life_tourout == 1, robust
	eststo ta3_3 : qui mfx	
	qui probit life_tournament we_all ind_age? ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left if life_tourout == 1, vce(cluster teamid) 
	eststo ta3_4 : qui mfx		
	
	esttab  ta3_*`ta3', `replace' star(* 0.10 ** 0.05 *** 0.01) label margin ///
		stats(N r2_p,fmt(%9.0f %12.3f)  labels("N" "R2")) se ///
		order(we_alldisp we_all) drop(*dummy*) ///
		b(%12.3f)
	
	
/*
TABLE A4: WILLINGNESS TO COMPETE (out-group), risk preferences and expected performance
*/	
	qui probit life_tournament we_all life_risk  ind_age? ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left if life_tourout == 1, robust
	eststo ta4_1 : qui mfx	
	qui probit life_tournament we_all life_expperf ind_age? ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left if life_tourout == 1, robust
	eststo ta4_2 : qui mfx	
	qui probit life_tournament we_all ind_age? life_ballshit  ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left if life_tourout == 1, robust
	eststo ta4_3 : qui mfx	
	qui probit life_tournament we_all life_risk life_expperf life_ballshit ind_age? ind_edu ind_mealpd ind_muslim ind_mende foot_whole foot_selfskill foot_score foot_won foot_left if life_tourout == 1, r
	eststo ta4_4 : qui mfx		
	
	esttab ta4_* `ta4', `replace' star(* 0.10 ** 0.05 *** 0.01) label margin ///
		stats(N r2_p,fmt(%9.0f %12.3f)  labels("N" "R2")) se  ///
		order(we_all life_risk life_expperf life_ballshit) nonotes

	
/*
Figures
*/			
	version 12
	use "$DATADIR/Cleaned Data\foot_anon.dta", clear

/*Figure 1: SLL-LED events and displacement*/
/* 	preserve
	
	*get data in shape to easily plot conflict events and years
	run "$HELPERDIR/do files/event_years.do"
	
	twoway 	(bar violence year, fcolor(none) lcolor(black) lwidth(thick)) ///
					(connected we year, msymbol(diamond) lpattern(dash) lwidth(medthick)) ///
					(connected disp year, msymbol(triangle) lwidth(thick)) , ///
					ytitle(Percentage of total conflict events) ///		   
					xscale(range(1991 2002)) ///
					xlabel(1991/2002) ///
					legend(cols(1))scheme(s2mono) ///
					ysize(8) xsize(11)
		   
	graph export "$OUTPUTDIR/Figures\f1_violent_events.png", as(png) replace
	graph export "$OUTPUTDIR/Figures\f1_violent_events.eps", as(eps) replace
	restore
 */
/*Figure 2: Age in sample and exposure to conflict*/	
	graph drop _all	
	
	*Panel A
	hist ind_age, fcolor(none) lcolor(black) freq d ysize(2) xsize(3) scheme(s2mono) name(agefreq, replace) title("(A)")
	
	bysort ind_age: egen agewar=mean(we_all)
	
	*Panel B xlabel (1 (1) 4)
	twoway 	(scatter agewar ind_age)  ///
					(qfit agewar ind_age) ///
					, ylabel(0 (0.1) 1)  ///
					ytitle("Average Victimization Index") ///
					ysize(2) xsize(3) legend(off) ///
					scheme(s2mono) name(agewar, replace) title("(B)")

	
	graph combine agefreq agewar, ysize(4) xsize(11)
	graph export "$OUTPUTDIR/Figures\f2_agefreq_agewe.png", as(png) replace
	graph export "$OUTPUTDIR/Figures\f2_agefreq_agewe.eps", as(eps) replace
	
/*Figure 3: Balls hit in the effort game*/	
	graph drop _all
	
	*create four histograms for combinations of ingroup/outgroup and tournament selection
	hist life_ballshit if life_tourin==0 & life_tournament==1, d norm percent xlab(0 (2) 10) xtitle ("Balls on Target") name(hist1) fcolor(none) lcolor(black) scheme(s2mono)
	hist life_ballshit if life_tourin== 1 & life_tournament==1, d norm percent xlab(0 (2) 10) xtitle ("Balls on Target") name(hist2) fcolor(none) lcolor(black) scheme(s2mono)
	hist life_ballshit if life_tourin==0 & life_tournament==0, d norm percent xlab(0 (2) 10) ylab(0 (10) 30) xtitle ("Balls on target") name(hist3) fcolor(none) lcolor(black) scheme(s2mono)
	hist life_ballshit if life_tourin== 1 & life_tournament==0, d norm percent xlab(0 (2) 10) xtitle ("Balls on Target") name(hist4) fcolor(none) lcolor(black) scheme(s2mono)	 
	
	*cobmine and export
	graph combine hist1 hist2 hist3 hist4, ysize(8) xsize(11)
	graph export "$OUTPUTDIR/Figures\f3_ballshit.png", as(png) replace	
	graph export "$OUTPUTDIR/Figures\f3_ballshit.eps", as(eps) replace	

/*Figure 4: Foul cards, competitiveness and exposure to violence*/		
	preserve
	versio 12
	graph drop _all
	
	use "$DATADIR/Cleaned Data\foot_anon.dta", clear

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
	graph export "$OUTPUTDIR/Figures\f4_we_competition.png", as(png) replace
	graph export "$OUTPUTDIR/Figures\f4_we_competition.eps", as(eps) replace
