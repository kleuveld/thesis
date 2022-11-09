***************************************
**Household-level Indicators N2Africa**
***************************************

/*
Goal: 	To create the following data files containing hh level indicators for N2Africa DRC:
		*baseline
		*endline
		*baseline + endline wide
		*baseline + endline long
		

Author: Koen Leuveld
Date: 13/3/2015
Last changed: 22/10/2019

NEEDED: 	-N2Africa baseline household data, as created by ODK Meta Household.do
			-N2Africa endline data, dito
			-Plot-crop level data (N2A_Crop_$t.dta), created by Crop_Yields.do
			-Farm-level data (N2A_Farm_$t), created by Crop_Yields.do
			
NOTES: 		-Since data is similar across base- and endline, the dofile loops over 0-1 to indicate
			 baseline and endline respectively.
			-The baseline data comes from four raw files, version variable denotes which. e1 and u1 come from the
			 first few days, in which a longer questionnaire was used. In these, up to five plots are presents
			 in the agricultural data, for the others only three.
			-Structure of each data file will be as follows:
				-Outcome indicators will be prepended with out_, followed by an indicator for the step 
				 (know,input,yield or fsec), then a short name for the indicator. Eg. out_know_inoc is for
				 the knowledge of inoculants.
				-In wide form, each indicator is appended with "_0" for baseline, "_1" for endline.

Info: 		The theory of change consists of the following steps:
			Step 1: Knowledge of agricultural techniques
			Step 2: Increased use of inputs
			Step 3: Yields
			Step 4: Food Security

*/


/*
Prepare:
*/

global gitloc  C:\Users\kld330\git
global dataloc  D:\PhD\Papers\N2A Impact\1. Data //holds raw and clean data
global tableloc ${gitloc}\thesis\chapters\n2a_impact\tables //where tables are put
global figloc ${gitloc}\thesis\chapters\n2a_impact\figures //where figures are put
global helperloc ${gitloc}\thesis\analysis\n2a_impact\2. Do files //holds do files
set  more off

*set tempfiles
tempfile hh hh_indicators_0 hh_indicators_1 yield


*Run the t loop (baseline and endline)
forvalues time = 0/1{
	*We use a global to easily test parts of the code
	global t `time'

	*Load file and clean IDs		
	if $t == 0{
		use "${dataloc}\1. Raw\2. Baseline\HH_all_data_included.dta", clear
		drop if x_replaceyn == 1

		*Fix issues with individual households
		replace x_hhid1 = 11 if x_vill_id == 9 & x_hhid1 == 9 & hh_a_mem_nm_1 == "Kwibe mugobe"
		drop if x_hhid1 == 7 & x_vill_id == 12 & hh_a_mem_nm_1 == "." 
		replace x_hhid1 = 19 if x_vill_id == 16 & x_hhid1 == 16 & hh_a_mem_nm_1 == "Marhegeko" 
		drop if x_hhid1 == 10 & x_vill_id == 33 & hh_a_mem_nm_1 == "."
		replace x_hhid1=15 if x_vill_id==51 & x_hhid1 == 14 & hh_a_mem_nm_1 == "Venant Mushweru" 
		replace x_hhid1=11 if x_vill_id== 63 & x_hhid1 == 10 & hh_a_mem_nm_1 =="Bogarari" 
		drop if x_hhid1 == 7 & x_vill_id == 68 & hh_a_mem_nm_1 == "."
		replace x_hhid1 = 19 if x_vill_id == 74 & x_hhid1 == 17 & hh_a_mem_nm_1=="Ganywamulume kashumu"
		replace x_hhid1= 20 if x_vill_id==68 & hh_a_mem_nm_1=="Kihahe cleophace"

		*Check for duplicates
		sort x_vill_id x_hhid1 x_athomeyn x_agricultureyn
		by x_vill_id x_hhid1: gen dup2 = cond(_N==1, 0, _n)
		tab dup2
		li x_vill_id x_hhid1 dup2 if dup2 > 0, nolabel

		*Drop duplicates
		drop if dup2!=0 & hh_a_mem_nm_1 =="" | x_vill_id==.
		drop dup2

		*Fix issues with individual households
		by x_vill_id x_hhid1: gen dup2 = cond(_N==1, 0, _n)
		tab dup2
		li x_vill_id x_hhid1 dup2 if dup2 > 0, nolabel

		replace x_hhid1 = 21 if x_vill_id == 3 & x_hhid1 == 20 & dup2 == 2
		replace x_hhid1 = 19 if x_vill_id == 6 & x_hhid1 == 6 & dup2 == 1
		replace x_hhid1 = 21 if x_vill_id == 6 & x_hhid1 == 6 & dup2 == 2
		replace x_hhid1 = 22 if x_vill_id == 6 & x_hhid1 == 6 & dup2 == 3
		replace x_hhid1 = 15 if x_vill_id == 15 & x_hhid1 == 13 & dup2 == 3
		replace x_hhid1 = 19 if x_vill_id == 15 & x_hhid1 == 13 & dup2 == 1
		replace x_hhid1 = 21 if x_vill_id == 20 & x_hhid1 == 20 & dup2 == 2
		replace x_hhid1 = 6 if x_vill_id == 28 & x_hhid1 == 5 & dup2 == 2
		replace x_hhid1 = 13 if x_vill_id == 42 & x_hhid1 == 12 & dup2 == 1
		replace x_hhid1 =2 if x_vill_id == 57 & x_hhid1 == 3 & dup2 == 2
		replace x_hhid1 = 11 if x_vill_id == 57 & x_hhid1 == 4 & dup2 == 2
		replace x_hhid1 = 11 if x_vill_id == 59 & x_hhid1 == 7 & dup2 == 2
		replace x_hhid1 = 6 if x_vill_id == 65 & x_hhid1 == 5 & dup2 == 2
		replace x_hhid1 = 21 if x_vill_id == 68 & x_hhid1 == 20 & dup2 == 2
		replace x_hhid1 = 16 if x_vill_id == 86 & x_hhid1 == 15 & dup2 == 2
		replace x_hhid1 = 18 if x_vill_id == 97 & x_hhid1 == 8 & dup2 == 1
		replace x_hhid1 = 10 if x_vill_id == 100 & x_hhid1 == 9 & dup2 == 2
		drop if x_vill_id == 28 & x_hhid1 == 6 & x_athomeyn == 0
		replace x_hhid1 = 11 if x_vill_id == 6 & x_hhid1 == 9 & hh_a_mem_nm_1 == "Bigaja jonathan"


		isid x_vill_id x_hhid1

		*normalize ID vars
		ren KEY KEY_0
		ren x_hhid1 hh_id
		ren x_vill_id vill_id

	}
	else { 
		use "${dataloc}\1. Raw\3. Endline\N2Africa Phase II Ménage.dta", clear
		
		rename hh_id x_hhid1
		drop if x_hhid1 == . | x_hhid1 == 999 | x_hhid1 == 99
		sort vill_id x_hhid1
		quietly by vill_id x_hhid1: gen dup = cond(_N==1, 0, _n)
		tab dup
		li vill_id x_hhid1 if dup > 0, nolabel

		sort vill_id x_hhid1 KEY dup
		**Fixing repeat HH ID errors in endline
		replace x_hhid1 = 2 if vill_id == 100 & x_hhid1 == 23 & dup == 1
		drop if x_hhid1 == 18 & vill_id == 7 & dup == 1
		replace x_hhid1 = 11 if vill_id == 9 & x_hhid1 == 1 & hhname_ent == "Byamungy"
		replace x_hhid1 = 9 if vill_id == 9 & x_hhid1 == 1 & hhname_ent == "Kwibe Mugobe"
		replace x_hhid1=12 if vill_id==9 & x_hhid1 == 2 & hhname_ent == "Sifa teze"
		replace x_hhid1=13 if vill_id==9 & x_hhid1 == 8 & hhname_ent == "Vumiliya"
		replace x_hhid1=14 if vill_id == 9 & x_hhid1 == 6 & hhname_ent == "Kamale mokili phillip"
		replace x_hhid1=16 if vill_id== 10 & x_hhid1 == 2 & hhname_ent == "Furaha agnes"
		replace x_hhid1=10	if vill_id == 10 & x_hhid1 == 3 & hhname_ent == "Anastasia furaha" 
		replace x_hhid1=6 if vill_id == 12 & x_hhid1 == 7 & hhname_ent == "Mauwa Francine" 
		replace x_hhid1=19 if vill_id == 16 & x_hhid1==15 & hhname_ent == "Dieudonné nakabembe" 
		replace x_hhid1=11 if vill_id == 33 & x_hhid1 == 6 & hhname_ent == "Faida" 
		drop if x_hhid1==17 & vill_id == 34 & dup==2
		replace x_hhid1 = 6 if vill_id==39 & x_hhid1 ==2 & hhname_ent =="Bahati mwagano"
		replace x_hhid1=15 if vill_id==51 & x_hhid1 == 14 & hhname_ent == "Mushweru venant" 
		drop if x_hhid1 == 12 & vill_id==53 & dup>1 & hhname_ent == "Francine"
		replace x_hhid1 = 14 if x_hhid1 == 12 & vill_id == 53 & hhname_ent == "David Cideka" 
		replace x_hhid1 = 11 if x_hhid1 == 10 & vill_id == 63 & hhname_ent == "Tulizo Vumilia" 
		replace x_hhid1 = 11 if x_hhid1 == 7 & vill_id == 68 & hhname_ent== "Babu bulako"
		replace x_hhid1 = 12 if x_hhid1 == 7 & vill_id == 68 & hhname_ent== "Nihasha nakanyere" 
		replace x_hhid1 = 21 if x_hhid1 == 20 & vill_id == 68 & hhname_ent == "Sukane Ndahobali"
		replace x_hhid1 = 11 if x_hhid1 == 3 & vill_id == 71 & hhname_ent=="Kasongo mudende"
		replace x_hhid1 = 13 if x_hhid1 == 12 & vill_id == 73 & hhname_ent=="Maombi elena" 
		drop if x_hhid1 == 1 & vill_id == 75 & dup == 2
		replace x_hhid1 = 11 if x_hhid1 == 5 & vill_id == 76 & hhname_ent=="Kagulwe berco"
		replace x_hhid1 = 3 if x_hhid1 == 1 & vill_id == 81 & hhname_ent=="Ruvuna kalangiro"
		drop if x_hhid1 == 4 & vill_id == 82 & dup!=3
		drop if x_hhid1 == 2 & vill_id == 101 & hhname_ent=="Y"
		replace x_hhid1 = 21 if vill_id == 68 & x_hhid1 == 20 & hhname_ent == "Sukane Ndahobali"

		quietly bysort vill_id x_hhid1: gen dup2 = cond(_N==1, 0, _n)
		li vill_id x_hhid1 if dup2 > 0, nolabel
		isid vill_id x_hhid1

		//keep KEY vill_id x_hhid1
		ren x_hhid1 hh_id
		ren KEY KEY_1

		duplicates report vill_id hh_id
		assert  `r(unique_value)' == `r(N)'
	}
	
	*prevent accidental overwriting of source data
	save `hh', replace
	

	/*
	Step 0: survey paradata
	*/
	gen survey_respondent = .
	if $t == 0{
		levelsof hh_a_respondent, local(respondents)
		foreach i in `respondents'{
			replace survey_respondent = hh_a_mem`i'relhead_`i' if hh_a_respondent == `i'
		}
	}
	la val survey_respondent relation_cdm
	la var survey_respondent "Relation Respondent with Head"
	
	/*
	*********************************************
	STEP: 1: Knowledge of agricultural tecnhiques
	Module hh_g of baseline date
	*********************************************
	*/

	/*
	CROP LIST FOR REFERENCE
	1	Cassava
	2	Sweet Potato
	3	Rice
	4	Maize
	5	Sorghum
	6	Potato
	7	Beans
	8	Soy beans
	9	Groundnuts
	10	Cow peas
	11	Sugarcane
	12	Amaranth
	13	Yam
	14	Banana
	15	Coffee
	16	Oil Palm
	96	Other
	99	None
	*/

	*Have you ever heard about root nodules?
	gen out_know_root_$t = hh_g_n2aknow_root 
	la var out_know_root_$t "Root nodules?"
	la val out_know_root_$t yes_no

	*knows vendors of fertlizer
	if $t == 1{
		ren hh_g_n2fertvendors out_know_fertvendor
		replace out_know_fertvendor = . if out_know_fertvendor > 90
		replace out_know_fertvendor = 1 if out_know_fertvendor > 0 & out_know_fertvendor != .
		la var out_know_fertvendor "Knows fertilizer vendors (y/n)"
		la val out_know_fertvendor yes_no
	}

	*For which crops is it beneficial to inoculate? A: 7 and 8
	egen out_know_inoc_$t = anymatch(hh_g_n2aknowl_incobe? hh_g_n2aknowl_incobe?? ), values(7 8)
	la var out_know_inoc_$t "Inoculant knowledge"
	la val out_know_inoc_$t yes_no

	*NOTE: there exists also a question: do you know what inoculation is?

	*What type of fertilizer should be added to legumes
	*NOTE!!!1!!: I do not know the answer. Assuming urea is wrong (NPK might be wrong too)
	/*FERTILIZER LIST FOR REFERENCE
	2	Sympal (poudre gris)
	3	TSP (granules gris)
	4	NPK (granules gris)
	5	Urea (granues blanches)
	6	KCl (granules orange)
	7	DAP (granules noir)
	97	Refut
	98	Don't know
	*/

	egen out_know_fert_$t = anymatch(hh_g_n2aknowl_fertiliadd? hh_g_n2aknowl_fertiliadd?? ), values(5)
	recode out_know_fert_$t (1=0) (0=1)
	la var out_know_fert_$t "Fertilizer knowledge"
	la val out_know_fert_$t yes_no

	*Did you receive agricultural training on the following crops?
	egen out_know_trcrop_$t =  rownonmiss(hh_g_n2aknowl_legumes1_? hh_g_n2aknowl_legumes1_??)
	replace out_know_trcrop_$t = 1 if out_know_trcrop > 1
	la var out_know_trcrop_$t "Agr. Training: Crop"
	la val out_know_trcrop_$t yes_no

	*Did you receive agricultural training on the following techniques?
	egen out_know_trtech_$t =  rownonmiss(hh_g_n2aknowl_legumes2_?)
	replace out_know_trtech_$t = 1 if out_know_trtech > 1
	la var out_know_trtech_$t "Agr. Training: Technique"
	la val out_know_trtech_$t yes_no

	/*
	*********************************************
	STEP: 2: Use of inputs
	*********************************************
	*/

	*hired labor
	*NOTE:Baseline just has yes/no for this data, endline splits it up per activity
	egen out_input_hirlab_$t = anymatch(workparjouryn*), values(1)
	la var out_input_hirlab "Hired Labour"
	la val out_input_hirlab yes_no

	*work association
	egen out_input_assoc_$t = anymatch(workasso_yn?), values(1)
	la var out_input_assoc_$t "Work Assoc."
	la val out_input_assoc_$t yes_no

	*inorganic fertilizer
	egen out_input_fert_$t = anymatch(techfert_yn?), values(1)
	la var out_input_fert_$t "Fertilizer Use"
	la val out_input_fert_$t yes_no


	*organic fertilizer
	egen out_input_manure_$t = anymatch(techorg_yn?), values(1)
	la var out_input_manure_$t "Org. Fertilizer Use"
	la val out_input_manure_$t yes_no

	*inoculant
	egen out_input_inoc_$t = anymatch(techinoc_yn?), values(1)
	la var out_input_inoc_$t "Inoculant Use"
	la val out_input_inoc_$t yes_no


	*Know of N2Africa Project 
	if $t == 1 {
		ren hh_e_known2africaA out_know_n2africaA_1
		la var out_know_n2africaA_1 "Was aware of N2Africa A"
		
		ren hh_e_participaten2africaA  out_partic_n2africaA_1
		la var out_partic_n2africaA_1 "Particapted in N2Africa A"
		
		ren hh_e_known2africaB  out_know_n2africaB_1
		la var out_know_n2africaB_1 "Was aware of N2Africa B"

		ren hh_e_participaten2africaB out_partic_n2africaB_1
		la var out_partic_n2africaB_1 "Participated in N2Africa B"
	}
	save `hh', replace
	
	/*
	*********************************************
	STEP: 3: Yield
	*********************************************
	*/

	*load plotcrop-level data
	use "${dataloc}\2. Clean\N2A_Crop_$t.dta", clear

	ren *_$t *
	
	 /* save the value labels for variables in local list*/
	foreach var in crop{
		levelsof crop, local(crop_levels)       	/* create local list of all values of `var' */
		foreach val of local crop_levels {       	/* loop over all values in local list `var'_levels */
			local crop`val' : label crop_list `val' /* create macro that contains label for each value */
		}
	}
	
	
	*define macros to facilitate renaming etc.
	*I would include cow peas (10), but no one grows them...
	local crop_brev cass bean soy pean
	local crop_code 1 7 8 9
	local crop_full Cassava Beans Soy Peanuts
	local nc : word count `crop_brev'

	*Incidacte which crops to keep
	egen OK = anymatch(crop), values(`crop_code')

	*main crop
	gen ismaincrop1  = crop if plot_id == 1 & crop_no == 1
	bys KEY: egen ismaincrop2 = max(ismaincrop) 
	

	*collapse to crop level
	collapse (sum) kgharvest surface (max) ismaincrop? if OK == 1, by(KEY crop)
	
	
	*raw yield
	gen yield = kgharvest / surface
		
	*clean, log transformed indicator
	
	*limit outliers
	*clone relevant variables, retaining labels
	clonevar kgharvestlim = kgharvest
	clonevar surfacelim = surface
	
	*replace outliers
	replace surfacelim = . if surfacelim > 10
	replace surfacelim = . if surfacelim <= 0.0025
	
	replace kgharvestlim = . if kgharvestlim > 4000 & crop ==7
	
	*generate yields
	gen yieldlim = kgharvestlim/surfacelim
	
	*remove the outliers
	replace yieldlim = . if yieldlim  > 40000 & crop == 1
	replace yieldlim = . if yieldlim > 8000 & crop == 7
	
	*generate transformation
	gen yldtr = log(yieldlim + sqrt(yieldlim^2 + 1))
	
	*drop the lim vars
	drop *lim
		
	*reshape to household level
	reshape wide kgharvest* surface* yield* yldtr* ismaincrop?, i(KEY) j(crop)
	
	*consolidate main crop
	egen hc_hh_maincrop = rowmax(ismaincrop2?)
	drop ismaincrop*
	
	*label variable and restore labels
	la var hc_hh_maincrop "Main Crop" 	
	foreach value of local crop_levels{            
		la def hc_hh_maincrop `value' "`crop`value''" , add		
	}
	la val hc_hh_maincrop hc_hh_maincrop
	replace hc_hh_maincrop = . if hc_hh_maincrop > 16 
	
	 *rename variables
	tokenize `crop_brev'
	foreach crop in `crop_code'{		
		capture ren *`crop' *`1' 
		macro shift
	}

	*Rename vars to follow naming scheme
	unab allvars: _all
	unab vars_to_exclude: KEY  hc_*
	foreach var in `:list allvars - vars_to_exclude' {
		ren `var' out_yield_`var'
	}
	
	*Label the variables 
	foreach var of  varlist *{
		forvalues i=1/`nc'{
			local name: di subinstr("`: var label `var''","`: word `i' of `crop_code''","`: word `i' of `crop_full''",.)
			la var `var' "`name'"
			local name: di subinstr("`: var label `var''","kgharvest","harvested (kg)",.)
			la var `var' "`name'"
			local name: di subinstr("`: var label `var''","yldtr","Yield",.)
			la var `var' "`name'"
		}
	}
	
	la var hc_hh_maincrop "Main Crop"

	*add time to var
	ren * *_$t


	*Merge with household data
	save `yield', replace

	use `hh', clear

	merge 1:1 KEY_$t using `yield', keep(match master) gen(yld_merge)
	di $t
	isid vill_id hh_id

	
	*Turn the _merge into an indicator of engaging in agr.
	gen hc_doesagr_$t = yld_merge==3
	la val hc_doesagr_$t yes_no
	la var hc_doesagr_$t "Household does agriculture"

	
	/*
	*********************************************
	STEP 4: Food security
	see coates et al. 2007 for the construction of these indicators.
	*********************************************
	*/

	*There's some differences between endline and baseline
	if $t == 1 {
		ren hh_g_n2f_* hh_f_*
	}
	
	*The first two variables are oddly named (even more oddly than the others), breaking the following loop
	*rename them to comform:
	ren hh_f_start_occ hh_f_start_worry
	ren hh_f_start_occ_fr hh_f_start_worry_occ

	foreach var of varlist hh_f_start_*_occ   {
		local origvar = subinstr("`var'","_occ","",.)
		n di "`var' -> `origvar'"
		replace `var' = 0 if missing(`var') & !missing(`origvar')
	}

	*Household Food Insecurity Access Scale (HFIAS) Subdomains:
	**List of the 9 food insecurity indicators
	 gen out_fsec_indic1_$t = hh_f_start_worry
     gen out_fsec_indic2_$t = hh_f_start_pref
     gen out_fsec_indic3_$t = hh_f_start_var
	 gen out_fsec_indic4_$t = hh_f_start_want
	 gen out_fsec_indic5_$t = hh_f_start_small
     gen out_fsec_indic6_$t = hh_f_start_few 
	 gen out_fsec_indic7_$t = hh_f_start_no
	 gen out_fsec_indic8_$t = hh_f_start_night
	 gen out_fsec_indic9_$t = hh_f_start_day

	*Anxiety:
	gen out_fsec_anx_$t = hh_f_start_worry
	la var out_fsec_anx_$t "HFIAS Anxiety"

	*Quality
	gen out_fsec_qual_$t = min(1,hh_f_start_pref+hh_f_start_var+hh_f_start_want) if !missing(hh_f_start_pref+hh_f_start_var+hh_f_start_want)
	la var out_fsec_qual_$t "HFIAS Quality"

	*Intake
	gen out_fsec_intake_$t = min(1,hh_f_start_small +hh_f_start_few+hh_f_start_no+hh_f_start_night+hh_f_start_day) if !missing(hh_f_start_small +hh_f_start_few+hh_f_start_no+hh_f_start_night+hh_f_start_day)
	la var out_fsec_intake_$t "HFIAS Intake" 

	*HFIAS Total: (occurences anxiety + occurences quality + occurences intake)
	gen out_fsec_hfias_$t = (hh_f_start_worry_occ) + (hh_f_start_pref_occ + hh_f_start_var_occ + hh_f_start_want_occ) + (hh_f_start_small_occ + hh_f_start_few_occ + hh_f_start_no_occ + hh_f_start_night_occ + hh_f_start_day_occ) 
	la var out_fsec_hfias_$t "HFIAS Total" 

	*Houeshold food insecurity Access(HFIA)
	gen out_fsec_hfia_$t = .

	replace out_fsec_hfia_$t = 1 if hh_f_start_worry_occ < 2 & hh_f_start_pref == 0 & hh_f_start_var == 0 & hh_f_start_want == 0 & hh_f_start_small == 0 & hh_f_start_few == 0 & hh_f_start_no == 0 & hh_f_start_night == 0 & hh_f_start_day == 0
	replace out_fsec_hfia_$t = 2 if ((hh_f_start_worry_occ > 1 & !missing(hh_f_start_worry_occ)) | (hh_f_start_pref_occ > 0 & !missing(hh_f_start_pref_occ)) | hh_f_start_var_occ == 1 | hh_f_start_want_occ == 1) & hh_f_start_small == 0 & hh_f_start_few == 0 & hh_f_start_no == 0 & hh_f_start_night == 0 & hh_f_start_day == 0
	replace out_fsec_hfia_$t = 3 if ((!missing(hh_f_start_var_occ) & hh_f_start_var_occ > 1) | (hh_f_start_want_occ > 1 & !missing(hh_f_start_want_occ)) | hh_f_start_small_occ == 1 | hh_f_start_small_occ == 2 | hh_f_start_few_occ == 1 | hh_f_start_few_occ == 2) & hh_f_start_no == 0 & hh_f_start_night == 0 & hh_f_start_day == 0
	replace out_fsec_hfia_$t = 4 if (hh_f_start_small_occ  == 3 | hh_f_start_few_occ == 3 | (hh_f_start_no_occ > 0 & !missing(hh_f_start_no_occ)) | hh_f_start_night_occ == 1 | hh_f_start_night_occ == 2 | (hh_f_start_day_occ > 0 & !missing(hh_f_start_day_occ)))

	
	la var out_fsec_hfia_$t "HFIA (categorial)"
	la def hfia 1 "Food Secure" 2 "Mildly Food Insecure Access" 3 "Moderately Food Insecure Access" 4 "Severely Food Insecure Access"
	la val out_fsec_hfia_$t hfia

	gen out_fsec_insecure_$t = out_fsec_hfia_$t == 4 & !missing(out_fsec_hfia_$t) & !missing(out_fsec_qual_)
	la var out_fsec_insecure_$t "HFIAS: Severely Food Insecure"
	la def insecure 0 "Food Secure - Moderetaly Food Insecure" 1 "Severely Food Insecure"
	la val out_fsec_insecure_$t insecure

	/*
	*********************************************
	Controls
	*********************************************
	*/
	
	*Rename baseline vars to conform to endline
	if $t == 0 {
		ren hh_a_mem1*_1 a_*1
	}

	*Age
	ren a_age1 hc_head_age_$t
	replace hc_head_age_$t = . if hc_head_age_$t >= 98
	la var hc_head_age_$t "Age household head"

	*Gender
	ren a_gender1 hc_head_female_$t
	replace hc_head_female_$t = hc_head_female - 1
	la var hc_head_female_$t "Female household head"
	la def hc_head_female 0 "Male", add
	la def hc_head_female 1 "Female", add
	la val hc_head_female hc_head_female

	*Education



	ren a_school1 hc_head_edu_$t
	if $t == 0{
		recode hc_head_edu_$t (5=6) (6=7)
		la def schooling_list 5 "Some years higher",modify
		la def schooling_list 6	"Higher education",modify
		la def schooling_list 7	"Professional education",modify
	}



	replace hc_head_edu_$t = . if hc_head_edu_$t == 97 | hc_head_edu_$t == 98 
	la var hc_head_edu_$t "Level of education head (category)"

	*Literacy
	gen hc_head_lit_$t = .
	
	if $t == 0{
		replace  hc_head_lit_$t = a_literacy1  
	}
	la var hc_head_lit_$t  "Household head is literate"
	
	*Primary occupation is farmer
	if $t == 0{
		gen  hc_head_farm_$t = 0
		replace hc_head_farm_$t = 1 if a_occup1 == 2
	}
	else {
		gen hc_head_farm_$t = 0
		replace hc_head_farm_$t = 1 if a_timeagric1 >= 3
	}
	la var hc_head_farm_$t "Primary occupation head is farmer"

	*Born in village
	ren hh_c_headborn hc_head_born_$t 
	la var hc_head_born_$t "Household head born in village"

	/*
	Characteristic of general household
	*/

	*rename vars
	if $t == 0{
		ren hh_a_size hc_hh_size_$t
	}
		else {
	ren hh_hh_size hc_hh_size_$t
	}

	*Size
	la var hc_hh_size "Household size"

	*Tin roof
	gen hc_hh_roof_$t = 0
	replace hc_hh_roof_$t = 1 if hh_c_roofmat == 1
	la var hc_hh_roof_$t "Household has a tin roof"
	
	*borrowed money
	if $t == 0{
		ren hh_e_credityn hc_hh_credityn_$t
	}
	
	else {
		ren hh_g_n2creditcredityn hc_hh_credityn_$t
	}
	
	/*
	Agricultural knowledge	
	*/
	
	*Media
	egen hc_know_media_$t = anymatch(hh_g_mediaaknowl_*), values(2/5)
	la var hc_know_media_$t "Knowledge through media"
	la val hc_know_media_$t yes_no
	
	*Cooperative (perhaps some social capital category?)
	egen hc_know_coop_$t = anymatch(hh_i_mem_agrcoop*), values(1/19) //note: I'm assuming those who said hh mem #20 was a member have mis-clicked
	la var hc_know_coop_$t "Member of agr. coop."
	la val hc_know_coop_$t yes_no	
	
	

	
	*Plot ownership and Plot fertility
	merge 1:1 KEY_$t using "${dataloc}\2. Clean\N2A_Farm_$t.dta",gen(farm_merge) keep(master match)
	*Keep only ID, outcome and control variables
	keep KEY_$t vill_id hh_id survey_* out_* hc_* *_merge
	
	di $t
	duplicates report vill_id hh_id
	assert  `r(unique_value)' == `r(N)'
	*Save data
	save `hh_indicators_$t'


}
/*
********************************
Assemble Long and Wide Data Sets
********************************
*/

*Create wide data

merge 1:1 vill_id hh_id using `hh_indicators_0', gen(t_merge) //, keep(match) nogen
recode t_merge (2=1) (1=2)
la def attrit 1 "Baseline Only" 2 "Endline Only" 3 "Baseline and Endline"
la val t_merge attrit
order vill_id hh_id KEY_? t out_* hc_*

save "${dataloc}\2. Clean\HH_indicators_allt_wide.dta", replace


keep vill_id hh_id t_merge
tempfile tmerge
save `tmerge'

*create long data
use `hh_indicators_1'
ren *_1 *
save `hh_indicators_1', replace

use `hh_indicators_0'
ren *_0 *

append using `hh_indicators_1', gen(t)
la def time 0 "Baseline" 1 "Endline"
la val t time

merge m:1 vill_id hh_id using `tmerge'
order vill_id hh_id KEY t out_* hc_*

*Save data
save "${dataloc}\2. Clean\HH_indicators_allt_long.dta", replace


