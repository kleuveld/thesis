******************************************
****N2AFRICA Impact Evaluation Do-File****
******************************************

/*
Created by: Maarten Voors
Last updated: 12-11-2019 by Koen

Objective: This do-file runs all analysis for the N2Africa impact evaluation paper. 
Dropping control, wave 1 was done post-treatment

Update 09-11-2017: 
- Set crop yield to zero if a hh does not grow a given crop (and add dummy for whether this was done)
- Include additional control in distance heterogeneity estimations: other X's interacted with treatment

Update 16-01-2018:
- Spillover analysis with proximity to subsidy treatment

Update 09-01-2019:
- Moved to EDCC paper so it sits with the paper

Update 28-01-2019
- Adding attrition analysis
- Streamlining

Update 19/9/1019 (KL)
- Update to attrition and spillover


Public outputs have to be produced comprising each survey and corresponding data set

Data prep files:
2. Do Files\V_Indicators.do
2. Do Files\HH_Indicators.do
2. Do Files\Crop_Yields.do

Note: Use forward slashes for mac

*/

****** prelim *******

global gitloc  C:\Users\kld330\git
global dataloc  D:\PhD\Papers\N2A Impact\1. Data //holds raw and clean data
global tableloc ${gitloc}\thesis\chapters\n2a_impact\tables //where tables are put
global figloc ${gitloc}\thesis\chapters\n2a_impact\figures //where figures are put
global helperloc ${gitloc}\thesis\analysis\n2a_impact\2. Do files //holds do files


set more off
qui run "${helperloc}\n2a_impact_helpers.do"

*cd "D:/Dropbox/DFID-ESRC Congo"
global TABLELOC "C:\Users\Koen\Documents\GitHub\thesis\tables\n2a_impact"
global FIGURELOC "C:\Users\Koen\Documents\GitHub\thesis\figures\n2a_impact"


***Load HH Data
use "${dataloc}/2. Clean/HH_indicators_allt_long.dta", clear

*merge with pre-baseline village survey
merge m:1 vill_id using "${dataloc}/2. Clean/N2A_V_indicators.dta",keep(match master) gen(merge_census) //Missing: 63 71 72 97 98 99 100 101 102 103 104 (W4W) 69 is back again

* gen unique IDs	
sort vill_id hh_id t
egen unique_id = group(vill_id hh_id) 

codebook unique_id
xtset unique_id t

***Create treatment indicators
*set global variable specifications
global part part_2-part_6
global controls /*hc_head_age hc_hh_size*/ 
global balance_pb hc_head_female hc_head_age hc_head_edu hc_head_born hc_head_farm hc_hh_size hc_hh_roof vc_se_distinp out_prodvalue hc_farm_soilqual hc_farm_own out_legum //panel b of balance table
global imbalance  L.out_fsec_hfias
global outcomes out_know_inoc out_know_fert out_input_inoc out_input_fert out_yield_yldtrbean  out_yield_yldtrcass out_fsec_hfias
global newyields out_yield_cass_jp out_yield_bean_jp
global notes "* p$<$0.10, ** p$<$0.05, *** p$<$0.01; Standard errors clustered at the village level in parentheses; controls include stratum fixed effect and baseline levels of food insecurity."


************************************************************************************************************************************  
**Table 1: Baseline Statistics and Balance
************************************************************************************************************************************  
* drop control
la var out_prodvalue "Tot. Val. Ag. Prod. (USD)"


la var hc_farm_soilqual "Plot soil quality (wgtd average) "
la var  hc_farm_own "Plot ownership (wgtd average)"

keep if treat_control==0
local using using "${tableloc}/table1.tex"
balance_table $outcomes $balance_pb  `using' ///
	if t==0 & t_merge == 3, t(treat_subs) cluster(vill_id) sheet(balance) ///
	title(Baseline descriptive statistics and balance) marker(tab:n2a_impact:balance) headerlines("\tiny")

************************************************************************************************************************************  
***Table 2: Impact of adding subsidy program
************************************************************************************************************************************  

*generate variable to indicate the sample for each regression
gen sample = .

/* * set panel dimensions
assert hh_id < 1000
g id = vill_id * 1000 + hh_id
isid id t
xtset id t
 */
gen lag = .
la var lag "Lagged dep. var."
* estimations
foreach var in $outcomes  {
	replace lag = L.`var'
	eststo impact_`var': reg `var' treat_subs lag $imbalance i.block if t==1, vce(cluster vill_id)
	replace sample = e(sample)
	su `var' if sample & !treat_subs
	scalar ymean = r(mean)
	scalar ysd = r(sd)
	estadd scalar ymean : impact_`var' 
	estadd scalar ysd : impact_`var' 
	//estadd ysumm
}


local using using "${tableloc}/table2.tex"
esttab impact_* `using', star(* 0.10 ** 0.05 *** 0.01) b(a3) ///
	keep(treat_subs lag) se noobs scalars(N "ymean Mean Control Group" "ysd SD Control Group"  "N_clust No. clusters") /// 
	title(Knowledge, input use, yield, and food security \label{tab:n2aimpact:main}) ///
	mtitles("\specialcell{Inoculant\\knowledge}" "\specialcell{Fertilizer\\knowledge}" ///
			"\specialcell{Inoculant\\use}" "\specialcell{Fertilizer\\Use}" ///
			"\specialcell{Beans\\Yield}" "\specialcell{Casava\\Yield}" ///
			"\specialcell{HFIAS\\Score}"}) ///
	sfmt(%6.0f %6.2f %6.2f %6.0f ) label replace nonotes addn($notes) booktabs

eststo clear

************************************************************************************************************************************  
***Table 3: HTE
************************************************************************************************************************************  
***Generate dummies for the analysis (appending d to the name)

*** head education, dummy
g hc_head_edu_d = hc_head_edu
recode hc_head_edu_d (1=0) (2/7=1)
la def edub 0 "Edu below primary" 1 "Edu primary or above"
la val hc_head_edu_d edub
la var hc_head_edu_d "Primary education"

***market access
summ vc_se_distinp, d
g vc_se_distinp_d = vc_se_distinp>r(p50)
replace vc_se_distinp_d=. if vc_se_distinp==.
lab var vc_se_distinp_d "Market dist. $>$ 5km"

***property rights
gen hc_farm_own_d = .
replace hc_farm_own_d = 1 if hc_farm_own > 0 &!missing(hc_farm_own)
replace hc_farm_own_d=0 if hc_farm_own==0 
la var hc_farm_own_d "Owns land"
la val hc_farm_own_d yesno

*vc_se_size
summ vc_se_size, d 
di r(p50)
g vc_se_size_d = vc_se_size>r(p50) & !missing(vc_se_size)
la var vc_se_size_d "Village size $>$ `r(p50)'"


* define globals and generate interaction terms
global hte hc_head_edu_d vc_se_distinp_d hc_farm_own_d hc_head_female vc_se_size_d
global inter
 
foreach var in $hte{
	di "var=`var'"
	g `var'_t = `var'*treat_subs
	la var `var'_t "`: var label `var'' * subsidy"

	
	global inter $inter `var'_t
}

la var hc_head_female_t "Female head * subsidy"


*run the analysis for each outcome
foreach var in $outcomes  {
	replace lag = L.`var'
	eststo hte_`var': reg `var' treat_subs $hte $inter lag $controls $imbalance i.block if t==1, vce(cluster vill_id)
	replace sample = e(sample)
	su `var' if sample & !treat_subs
	scalar ymean = r(mean)
	scalar ysd = r(sd)
	estadd scalar ymean: hte_`var'
	estadd scalar ysd : hte_`var'
}

local using using "${tableloc}/table3.tex"
esttab hte_* `using', star(* 0.10 ** 0.05 *** 0.01) b(a3) ///
	title(Heterogeneous Effects \label{tab:n2aimpact:hte}) ///
	mtitles("\specialcell{Inoculant\\knowledge}" "\specialcell{Fertilizer\\knowledge}" ///
			"\specialcell{Inoculant\\use}" "\specialcell{Fertilizer\\Use}" ///
			"\specialcell{Beans\\Yield}" "\specialcell{Casava\\Yield}" ///
			"\specialcell{HFIAS\\Score}"}) ///
	keep(treat_subs $inter lag) se noobs scalars(N "ymean Mean Control Group" "ysd SD Control Group"  "N_clust No. clusters") /// 
	sfmt(%6.0f %6.2f %6.2f %6.0f ) label replace nonotes addn($notes)

eststo clear


************************************************************************************************************************************  
***Table A2: Attrition
************************************************************************************************************************************  

*create attrition indicator
gen attrit = t_merge == 1

tab block, gen(blockdummy)
drop blockdummy1

*production value has outliers, so we log-transform it.
clonevar out_prodvalue_old = out_prodvalue
replace out_prodvalue = 0.01  if out_prodvalue == 0
replace out_prodvalue = log(out_prodvalue)
la var out_prodvalue "Log of Total Value Agr. Production (USD)"

*raw regression
eststo a: reg attrit treat_subs if treatment != 0 & t == 0, vce(cluster vill_id)

*regression with all variables presented in the descriptive table
foreach var of varlist $balance_pb blockdummy?{
	gen attr_`var' = `var' * treat_subs
	local label: var label `var'
	la var  attr_`var' "Treatment * `label'"
}
eststo b: reg attrit treat_subs attr_* $balance_pb blockdummy2 blockdummy3 if treatment != 0 & t == 0, vce(cluster vill_id)

*output the table
local using using "${tableloc}\tableA2.tex"

esttab a b `using',  replace label cells(b(star fmt(%9.3f)) se(par fmt(%9.3f))) ///
	title ("Correlates of Attrition" \label{tab:n2aimpact:attr}) collabels(none) mlabels("Attrition" "Attrition" "Attrition") ///
	drop($balance_pb blockdummy2 blockdummy3) ///
	nobaselevels starlevels(* .1 ** .05 *** .01) ///
	scalars( N "N_clust No. clusters") sfmt(%6.0f %6.0f) ///
	addn("Notes: * p$<$0.10, ** p$<$0.05, *** p$<$0.01; Standard errors clustered at the village level in parentheses.")

eststo clear

*undo log-transformation of production value in case its needed later.
replace out_prodvalue = out_prodvalue_old
drop out_prodvalue_old
drop attr_* blockdummy*

************************************************************************************************************************************  
* Table A3: Robustness Yields and Food Security
************************************************************************************************************************************  

************************************************************************************************************************************  
**Replace missing yields by zero, create dummy indicating these cases
************************************************************************************************************************************  
*yields
*prodvalue is missing if no production; for out purposes here, we consider them 0.
replace out_prodvalue = 0 if out_prodvalue == .

*estimations
foreach var in out_prodvalue {
	replace lag = L.`var'
	eststo a3_`var': reg `var' treat_subs lag $controls $imbalance i.block if t==1, vce(cluster vill_id)
	replace sample = e(sample)
	su `var' if sample & !treat_subs
	scalar ymean = r(mean)
	scalar ysd = r(sd)
	di ysd
	estadd scalar ymean: a3_`var'
	estadd scalar ysd : a3_`var'
}

*Food insecurity
replace out_fsec_insecure = . if out_fsec_qual  == .

*run logit model
foreach var in out_fsec_insecure {
	replace lag = L.`var'
	
	logit `var' treat_subs lag $controls $imbalance i.block if t==1, vce(cluster vill_id)
	eststo a3_`var': margins, dydx(*) atmean post
	replace sample = e(sample)
	su `var' if sample & !treat_subs
	scalar ymean = r(mean)
	scalar ysd = r(sd)
	scalar N_clust = 64
	estadd scalar ymean: a3_`var'
	estadd scalar ysd : a3_`var'
	estadd scalar N_clust : a3_`var'
}


local using using "${tableloc}/tableA3.tex"
esttab a3_* `using' , star(* 0.10 ** 0.05 *** 0.01) b(a3) ///
	title ("Robustness Checks on Yields and Food Security" \label{tab:n2aimpact:robust}) ///
	mtitles("\specialcell{Log Total Value Agr.\\Production (USD)}" ///
			"\specialcell{HFIAS: Severely Food\\Insecure}") ///
	keep(treat_subs lag) se noobs scalars(N "ymean Mean Control Group" "ysd SD Control Group"  "N_clust No. clusters") /// 
	sfmt(%6.0f %6.2f %6.2f %6.0f ) label replace nonotes addn($notes Marginal effects (at means) for a logit regression are reported column 2)

eststo clear


************************************************************************************************************************************  
*Table A4: Spillover analysis
************************************************************************************************************************************  

*generate spill-over indicators (interaction between proximity dummy and control)
gen spillover = (vc_spill_subs < 1) * (treat_subs == 0)
la var spillover "Subsidy $<$1km"

*Estimations
foreach var in $outcomes  {
	replace lag = L.`var'
	eststo spill1_`var': reg `var' treat_subs spillover lag $controls $imbalance i.block if t==1, vce(cluster vill_id)
	replace sample = e(sample)
	su `var' if sample & !treat_subs
	scalar ymean = r(mean)
	scalar ysd = r(sd)
	estadd scalar ymean: spill1_`var'
	estadd scalar ysd: spill1_`var' 
}

local using using "${tableloc}/tableA4.tex"
esttab spill1_* `using', star(* 0.10 ** 0.05 *** 0.01) b(a3) ///
	keep(treat_subs spillover lag) se noobs scalars(N "ymean Mean Control Group" "ysd SD Control Group"  "N_clust No. clusters") ///
	title(Spillover analysis \label{tab:n2aimpact:spill}) ///
	mtitles("\specialcell{Inoculant\\knowledge}" "\specialcell{Fertilizer\\knowledge}" ///
			"\specialcell{Inoculant\\use}" "\specialcell{Fertilizer\\Use}" ///
			"\specialcell{Beans\\Yield}" "\specialcell{Casava\\Yield}" ///
			"\specialcell{HFIAS\\Score}"}) /// 
	sfmt(%6.0f %6.2f %6.2f %6.0f ) label replace nonotes addn($notes)

eststo clear
