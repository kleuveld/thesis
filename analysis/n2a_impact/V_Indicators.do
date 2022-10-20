**********************************
**N2Africa Village Indicators**
**********************************

/*
Goal: 
Create a village level datafile

Author: Koen Leuveld
Date: 13/5/2015
Last edited: 23/10/2019

NEEDED: 
N2Africa census village questionnaire
sutex to make a tex table of summ stats

Problems: 
Only 91 villages included in pre-baseline V data

To Do:
Include baseline community survey

*/

/*
Prepare
*/

//findit sutex
//global N2Dir D:\Dropbox\N2Africa DRC\DFID-ESRC Congo
//global PaperDir D:\Dropbox\PhD\Papers\Chiefs and Aid
//global texlocation "p"

/* 
capture cd "D:\Dropbox\N2Africa DRC\DFID-ESRC Congo"
capture cd "c:\users\koen\dropbox\N2Africa DRC\DFID-ESRC Congo"
capture cd "C:\Users\Elise Wang Sonne\Dropbox\DFID-ESRC Congo"
capture cd "D:\Dropbox\drc\DFID-ESRC Congo" 
 */

cd "C:/Users/Koen/Dropbox (Personal)/N2Africa DRC/DFID-ESRC Congo/Outputs ESRC/impact paper/EDCC/Replication"
****



/*
Treatment info etc. from reference data
*/

*Merge with village list for treatment info etc
use "1. Data\0. Reference\N2A Village List.dta", clear
keep vill_id village partenaire axe treatment

*generate blokcs
encode axe,gen(block)
drop axe

*Generate treatment dummies
la var treatment "Treatment"
la def treatment 0 "Control" 1 "N2 Only" 2 "Subsidy"
la val treatment treatment

gen treat_control = treatment == 0
la var treat_control "Control"

gen treat_train = treatment == 1
la var treat_train "Training"

gen treat_subs = treatment == 2
la var treat_subs "Subsidy"

gen treat_pool = treatment == 1 | treatment == 2
la var treat_pool "Training+Subsidy"

*partner dummies
tab partenaire, gen(part_)

tempfile ref 
save `ref'



/***
Village Data
***/
****

use "1. Data\1. Raw\1. Census\Etape A.dta", clear

/*
Category one: biophysical
*/

*Soil type

//Clean using regex, then encode
gen soil_clean = ""
replace soil_clean = "Argileux" if regexm(av_q_1_1_7,"[Aa]rgil[eé]u?x?[$;]|[Rr]ouge$") == 1
replace soil_clean = "Argilo-sableux" if regexm(av_q_1_1_7,"[Aa]rg[a-z]+ ?[ -] ?[Ss]ab[a-z]+") == 1
replace soil_clean = "Sableux" if regexm(av_q_1_1_7,"^(Sabl|Sol [Ss]abl)") == 1
replace soil_clean = "Fertile" if regexm(av_q_1_1_7,"[Ff]ertil[eé|Noir$") == 1

encode soil_clean, gen(vc_bp_soil)
la var vc_bp_soil "Soil Type"

*Altitude 
ren av_q1_1_6 vc_bp_alt
replace vc_bp_alt = . if vc_bp_alt == 0 | vc_bp_alt > 3
la var vc_bp_alt "Altitude (categorical)"
/*
Category two: socio-economic
*/
*Villagr size
ren liste_menages vc_se_size
replace vc_se_size = . if vc_se_size == 9999
la var vc_se_size "Village size (no. households)"

*Market access
ren av_q_1_2_d_1 vc_se_distinp
la var vc_se_distinp "Distance from input market (Km)"

ren av_q_1_2_d_2 vc_se_distoutp
la var vc_se_distoutp "Distance from output market (Km)"

ren av_q_1_2_d_3 vc_se_distcred
la var vc_se_distcred "Distance credit institution (Km)"

ren av_q_1_2_d_4 vc_se_distmwa
replace vc_se_distmwa = . if vc_se_distmwa == 98
la var vc_se_distmwa "Distance from seat of Mwami (Km)"

//some don't have credit at all, so having it close might be more useful
egen vc_se_credclose = cut(vc_se_distcred), at(0,10,100) icodes 
recode vc_se_credclose 1 = 0 0 =1
la def yesno 0 "No" 1 "Yes"
la val vc_se_credclose yesno
la var vc_se_credclose "Credit institution within 10km"

//99 means missing in distance
foreach var of varlist vc_se_dist* {
	replace `var' = . if `var' == 99
}

ren av_q1_3_1 vc_se_beer
la var vc_se_beer "Price of a bottle of beer"
replace vc_se_beer = . if vc_se_beer == 9998

*Immigrants
ren av_q2_4 vc_se_idp
la var vc_se_idp "Percentage of IDPs"
replace vc_se_idp = . if vc_se_idp > 100

ren av_q2_5 vc_se_ret
la var vc_se_ret "Percentage of returnees"
replace vc_se_ret = . if vc_se_ret > 100

*People engage in mining
ren av_q2_2_4 vc_se_mine
replace vc_se_mine =. if vc_se_mine > 100
la var vc_se_mine "Percentage of inhabitants engaged in mining"

gen vc_se_mineyn = 0
replace vc_se_mineyn = 1 if vc_se_mine > 0
la var vc_se_mineyn "People in village active in mining (yes/no)"

/*
Category three: Chief characteristics
*/
*Parental link
gen vc_chef_link = 0
replace vc_chef_link = 1 if av_q3_1_5 == 1
la var vc_chef_link "Current chef related to past chef"

*years chief
gen vc_chef_years =  2013 - av_q3_1_6_aa
la var vc_chef_year "No. year chief in place"

*elected
gen vc_chef_elected = 0
replace vc_chef_elected = 1 if av_q3_1_8 == 4
la var vc_chef_elected "Elected Chief"

/*
category four: cld characteristics (at three levels)
*/

*define codes and names for CLD levels (numbers are 1 2 3)
local level_code loc vill grp
local level_name Localité Village Groupement

*loop over CLD levels
forvalues i = 1/3{
	*extraxt relevant code and name for current level from locals defined above
	local code "`: word `i' of `level_code''"
	local name "`: word `i' of `level_name''"
	
	*cld exists?
	gen vc_cld`code'_yn = av_q3_2_a_`i' == 1
	replace vc_cld`code'_yn = . if av_q3_2_a_1 >= 8
	la var  vc_cld`code'_yn "`name' has CLD"
		
	*CLD set up by chief?
	gen vc_cld`code'_cheffound = av_q3_2_c_`i' == 1
	la var  vc_cld`code'_cheffound "`name' CLD set up by Chief"

	*CLD set up by NGO
	gen vc_cld`code'_ngofound = av_q3_2_c_`i' == 4
	la var  vc_cld`code'_ngofound "`name' CLD set up by NGO"
	
	*CLD set up by Members 
	gen vc_cld`code'_memfound = av_q3_2_c_`i' == 3
	la var  vc_cld`code'_memfound "`name' CLD set up by villagers"
	
	*village chief is a member of cld
	gen vc_cld`code'_chiefmem = av_q3_2_e_1 == 1
	la var  vc_cld`code'_chiefmem "Chief is member of `name' CLD"
}


keep vill_id vc_*
tempfile census
save `census'


/*
PGG Contributions
*/

use "1. Data\1. Raw\2. Baseline\PGG_Long.dta", clear



gen vc_pgg_contchief = cont if chef == 1

gen vc_pgg_cont10 = cont if round_id == 10
gen vc_pgg_contc10 = cont if chef == 1 & round_id == 10

gen vc_pgg_cont5p = cont if round_id > 5
gen vc_pgg_contc5p = cont if chef == 1 & round_id > 5

ren cont vc_pgg_cont

collapse (mean) vc_pgg_cont vc_pgg_contchief vc_pgg_cont10  vc_pgg_contc10 vc_pgg_cont5p vc_pgg_contc5p, by(vill_id)

la def pgg 1 "Low contributions", modify
la def pgg 2 "Medium contributions", modify
la def pgg 3 "High contributions", modify



foreach var of varlist vc_* {
	xtile test = `var', nquantiles(3)
	ren `var' dr_`var'
	ren test `var'
	
	la var `var' "PGG Contributions"
	la def `var' 1 "Low contributions", modify
	la def `var' 2 "Medium contributions", modify
	la def `var' 3 "High contributions", modify
	
	
	la val `var' `var'
	

}

drop dr_*

tempfile pgg
save `pgg'


/*
spillover distances
*/
use "1. Data\0. Reference\N2A Village List.dta", clear
local check = _N

*create pairwise combinations of all villages, and calculate distances between the pairs
ren * *_test
cross using  "1. Data\0. Reference\N2A Village List.dta"
geodist bl_gpslatitude_test bl_gpslongitude_test bl_gpslatitude bl_gpslongitude, gen(dist)

*calculate distance to closest control village
bysort vill_id: egen vc_spill_control = min(dist) if treatment_test == 0
bysort vill_id (vc_spill_control): replace vc_spill_control = vc_spill_control[1]
la var vc_spill_control "Distance to closest N2 Only Village"

*calculate distance to closest n2 only village
bysort vill_id: egen vc_spill_n2 = min(dist) if treatment_test == 1
bysort vill_id (vc_spill_n2): replace vc_spill_n2 = vc_spill_n2[1]
la var vc_spill_n2 "Distance to vc_spill N2 Only Village"

*calculate distance to closest subsidy village
bysort vill_id: egen vc_spill_subs = min(dist) if treatment_test == 2
bysort vill_id (vc_spill_subs): replace vc_spill_subs = vc_spill_subs[1]
la var vc_spill_subs "Distance to vc_spill Subsidy Village"


*clean up
keep vill_id vc_spill_control vc_spill_n2 vc_spill_subs

*since all distances are now constant within vill_id, we can drop all duplicates
duplicates drop
assert `check' == `=_N'

tempfile spillover
save `spillover'


/*
Community Survey
*/
use "1. Data\1. Raw\2. Baseline\N2A_BL_Comm.dta", clear
replace a_villid = 67 if a_villnm == "Itara"


ren d_landconf_yn vc_conf_land
la var vc_conf_land "Land conflicts (1=yes)"

la def vc_conf_land 0 "No land conflicts", modify
la def vc_conf_land 1 "Land conflicts", modify
la val vc_conf_land vc_conf_land


egen vc_conf_att = rowtotal(h_war?attackyn_?)
la var vc_conf_att  "Number of attacks on village"

gen vc_conf_attyn = vc_conf_att > 0 & vc_conf_att != .
la var vc_conf_attyn "Village attacked"
la def vc_conf_attyn 0 "Not Attacked", modify
la def vc_conf_attyn 1 "Attacked", modify
la val vc_conf_attyn vc_conf_attyn


gen vc_conf_flee = (h_war4flee_4 > 0 &  h_war4flee_4 != 98) |  (h_war5flee_5 > 0 &  h_war5flee_5 != 98)
la var vc_conf_flee "Recent migration"


ren a_villid vill_id

keep vill_id vc_*



*merge all data together
merge 1:1 vill_id using `census', gen(census_merge)
merge 1:1 vill_id using `pgg', gen(pgg_merge)
merge 1:1 vill_id using `spillover', gen(spill_merge)
merge 1:1 vill_id using `ref', gen(ref_merge)

save "1. Data\2. Clean\N2A_V_indicators", replace 

