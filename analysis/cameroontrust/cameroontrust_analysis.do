

	*Folder with do files

	global gitloc  C:\Users\kld330\git
	global dataloc  D:\PhD\Papers\CameroonTrust\Data_encrypted //holds raw and clean data
	global tableloc ${gitloc}\thesis\chapters\cameroontrust\tables //where tables are put
	global figloc ${gitloc}\thesis\chapters\cameroontrust\figures //where figures are put
	global helperloc ${gitloc}\thesis\analysis\cameroontrust\2. Do files //holds do files

 *****************************
 **RUN CLEANING AND HELPERS**
 ****************************
  	run "${helperloc}/cameroontrust_helpers.do"
 	//run "$gitdir/cameroontrust_dataprep.do"
	use "${dataloc}/Clean/Trust_data_all.dta", clear

*******************************
**DEFINE GLOBALS FOR ANALYSIS**	
*******************************	
	global controls married villsize hhsize muslim wivesnumb leader education agehead roof relwealthbin
	
***************
*****************Table X: Descriptive Statistics
	eststo clear
	local using using "${tableloc}/summstats.tex"
	eststo summ: estpost su tdg sentvill risk fracexpected avfracreturn market $controls if !missing(market)
	esttab summ `using', cells("count mean(fmt(2)) sd(fmt(2)) min max") label noobs replace nonumbers



***************
**EXPECT*
***************
	local using "using "${tableloc}\results_expect.tex""
	
	eststo exp_tdg, ti("Altruism"): qui reg  tdg  market $controls, vce(cluster villID)
	
	eststo exp_risk, ti("Risk"): qui reg  risk market $controls, vce(cluster villID)
	
	eststo exp_exp, ti("Beliefs"): qui reg fracexpected market $controls, vce(cluster villID) 

	//eststo exp_full, ti("Full"): qui reg sentvill tdg risk fracexpected $controls, vce(cluster villID)
	
	
	esttab exp_* `using', star(* 0.10 ** 0.05 *** 0.01) se label indicate(Add. Controls = $controls ,labels(Yes No)) ///
		stats(N r2_a,fmt(%9.0f %12.2f)  labels("N" "Adj. R-Square")) replace nonotes //nomtitles 


***************
**SEND*
***************
*First, establish our observations:
	local using "using "${tableloc}\basic.tex""
	
	eststo basic_tdg, ti("Altruism"): qui reg sentvill tdg $controls, vce(cluster villID)
	
	eststo basic_risk, ti("Risk"): qui reg sentvill risk $controls, vce(cluster villID)
	
	eststo basic_exp, ti("Beliefs"): qui reg sentvill fracexpected $controls, vce(cluster villID) 

	eststo basic_full, ti("Full"): qui reg sentvill tdg risk fracexpected $controls, vce(cluster villID)
	
	
	esttab basic_* `using', star(* 0.10 ** 0.05 *** 0.01) se label indicate(Add. Controls = $controls ,labels(Yes No)) ///
		stats(N r2_a,fmt(%9.0f %12.2f)  labels("N" "Adj. R-Square")) replace nomtitles nonotes //booktabs
	
	
*then run the full model
	local using using "${tableloc}\interactions.tex"
	
	eststo market_tdg, ti("Altruism"): qui reg sentvill c.tdg##i.market $controls, vce(cluster villID)
	
	eststo market_risk, ti("Risk"): qui reg sentvill c.risk##i.market $controls, vce(cluster villID)
	
	eststo market_exp, ti("Beliefs"): qui reg sentvill c.fracexpected##i.market $controls, vce(cluster villID) 

	eststo market_full, ti("Full"): qui reg sentvill tdg risk fracexpected i.market c.tdg#i.market c.risk#i.market c.fracexpected#i.market $controls, vce(cluster villID)
	
	
	esttab market_* `using', star(* 0.10 ** 0.05 *** 0.01) se label indicate(Add. Controls = $controls ,labels(Yes No)) ///
		stats(N r2_a,fmt(%9.0f %12.2f)  labels("N" "Adj. R-Square")) nobaselevels replace nodepvars  nonotes /// booktabs ///
	 	coeflabels(1.market "Market" 1.market#c.tdg "TDG x Market" 1.market#c.risk "Risk x Market" ///
	 				1.market#c.fracexpected "Expected x Market") ///
	 	order(tdg 1.market#c.tdg  risk 1.market#c.risk fracexpected 1.market#c.fracexpected)  
	
	//eststo clear


*compute weigths
	//villsize hhsize muslim wives leader education agehead
	drop if market == .
	
	cem wivesnumb(0 0.5 1.5 99) muslim(0 0.5 1) agehead(#6) education(#3) ///
		leader(#3), treatment(market) showbreaks 


	balance_table $controls ///
		using "${tableloc}\balance_noweight.tex",  ///
		t(market) c(villID) title(Covariate balance, before matching) ///
		marker(tab:balance_noweight) 


	balance_table $controls ///
		using "${tableloc}\balance_weight.tex",  ///
		t(market) c(villID) w(cem_weights) ///
		title(Covariate balance, after matching) ///
		marker(tab:balance_weight)


*then run the full moel
	local using //"using "${tableloc}\interactions_w.tex""
	
	eststo market_tdg, ti("Altruism"): reg sentvill c.tdg##i.market $controls ///
	   [iweight=cem_weights], vce(cluster villID)
	
	eststo market_risk, ti("Risk"): qui reg sentvill c.risk##i.market $controls ///
		[iweight=cem_weights], vce(cluster villID)
	
	eststo market_exp, ti("Beliefs"): qui reg sentvill c.fracexpected##i.market ///
		$controls [iweight=cem_weights], vce(cluster villID) 

	eststo market_full, ti("Full"): qui reg sentvill tdg risk fracexpected i.market c.tdg#i.market c.risk#i.market c.fracexpected#i.market  $controls   [iweight=cem_weights], vce(cluster villID)
	
	
	esttab market_* `using', star(* 0.10 ** 0.05 *** 0.01) se label  indicate(Add. Controls = $controls ,labels(Yes No))  ///
		stats(N r2_a,fmt(%9.0f %12.2f)  labels("N" "Adj. R-Square")) nobaselevels replace nodepvars ///
	 	coeflabels(1.market "Market" 1.market#c.tdg "TDG x Market" 1.market#c.risk "Risk x Market" ///
	 				1.market#c.fracexpected "Expected x Market") ///
	 	order(tdg 1.market#c.tdg  risk 1.market#c.risk fracexpected 1.market#c.fracexpected)  
	
	eststo clear


