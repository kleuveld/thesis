**************************************
**N2 Africa Yields Calculation**
********************************

/*
Date: 11/5/2015
Needs: Raw data from Baseline and Endline, and the Mesures file containing conversions between various units of measurement
Produces: Yields data for endline and baseline, in two separate files


Changelog:
14/6/2016: I removed all the technology quantities, as they were calculated incorrectly. KL
22/10/2019: remove all variables not included in EDCC analysis, and clean up. (3d1abf963c876f429e30fce353148891fc6fbdca)

*/

cd "C:/Users/Koen/Dropbox (Personal)/N2Africa DRC/DFID-ESRC Congo/Outputs ESRC/impact paper/EDCC/Replication"

*Since baseline and endline data have same structure, do a loop
forvalues time = 0/1{

	*Make the time a global, so we can debug parts of the loop easily without running the whole thing
	global t `time'
	
	*Load plot-level raw data, and make sure names and types correspond
	if $t == 0{
		use "1. Data\1. Raw\2. Baseline\HH_plots_all_data_included.dta", clear

		ren key KEY
		ren parent_key PARENT_KEY
	}
	else { 
		use "1. Data\1. Raw\3. Endline\N2Africa Phase II Ménage-hh_-e_-plots.dta", clear
		tostring cropcrop_other_*, replace
	}

	*Do some basic renaming
	ren crop* *
	ren r1* *
	ren r2* *
	ren r3* *
	ren r4* *
	
	*data has repated columns for each crop grown...
	*Run a loop over each planted crop...
	forvalues i = 1/4 {
	
		*convert sell price to USD
		replace sellprice_`i' = sellprice_`i'*0.0011 if sellpricecurr_`i' == 2
		ren sellprice_`i' crop_sellprice_`i'
		ren cropmarket_`i' crop_market_`i'
	
		*..for quantities sowed, harvested and sold..
		
		foreach j in sow harvest cropsell  {
				
			*enumerators were instructed to code "don't know" as 98, but also did 99, or 998 etc. They all end with 99 or 98, set those to "."
			replace `j'_`i' = . if regexm(string(`j'_`i',"%11.0g"),"9+[89]$") == 1 //`j'_`i' loops through sow_1 sow_2 ... harvest_3 ... cropsell_4
			
			*merge with the units file, the kg column will tell how many kgs a certain unit of a certain crop weighs
			ren crop_`i' codeculture_n2 //make sure the crop code corresponds to the code found in the units file
			ren `j'unit_`i' codemesure	//do the same for the units
			merge m:1 codeculture_n2 codemesure using "1. Data\0. Reference\N2A Unit Conversion.dta", keep(master match) keepusing(kg) nogen

			*a kg is 1 kg
			replace kg = 1 if codemesure == 2
			replace kg = 25 if codemesure == 13
			replace kg = 50 if codemesure == 14
			replace kg = 100 if codemesure == 15

			*so: kg_sow/harvest/cropsell_1/2/3/4
			gen kg`j'_`i' = `j'_`i' * kg
			
			*remove the kg column, and reset the names of the variables renamed to correspond with the units file, so they don't block the next iteration of the loop
			drop kg
			ren codemesure `j'unit_`i'
			ren  codeculture_n2 crop_`i'
			
			*clean up missing observations
			replace crop_`i' = . if harvest_`i' == .
		}
	}

	*Make sure that KEY refers to the household, to facilitate later merging
	ren KEY uniquekey
	ren PARENT_KEY KEY

	*Exchange rate francs to USD for hired labour
	replace workworkpay_dollar = workworkpay_franc*0.0011 if workworkpay_dollar==.
	ren workworkpay_dollar labour_usd
	
	*create plot characteristics variables
	recode useplotaccess (4=2) (1=4) (2=1) (98 = .) (96 = .)
	label define landaccess_list 1 "Communal" 2 "Rented, short-term" 3 "Rented, long-term" 4 "Property" 96 "Other", replace
	
	gen plot_prop = .
	replace plot_prop = 1 if useplotaccess == 4
	replace plot_prop = 0 if (useplotaccess >= 1 & useplotaccess <=3)
	label define property_right 0 "Not Owned" 1 "Owned" 
	label var plot_prop property_right
		
	gen plot_soilqual = usesoilqual
	recode plot_soilqual (1=5) (2=4) (3=3) (4=2) (5=1) (97=.) (98=.)
	label define soilqual_list 1 "Very Infertile" 2 "Infertile" 3 "Normal" 4 "Fertile" 5 "Very Fertile" 97 "Refuse" 98 "Other", replace
	

	*calculate plot size
	gen surface = .
	
	replace surface = dimsurface/10000 if dimsurfaceunits == 1 //M2
	replace surface = 25*25*dimsurface/10000 if dimsurfaceunits == 2 //Carré
	replace surface = 10*10*dimsurface/10000 if dimsurfaceunits == 3 //are
	replace surface = dimsurface if dimsurfaceunits == 4 //HA
	replace surface = dimlong * dimwide/10000 if dimsurfaceformat == 1
	

	*Drop variables we don't want
	
	keep KEY uniquekey surface crop_? crop_sellprice_? plot_prop plot_soilqual kgharvest_? kgcropsell_?

	*create farm-level indicators for soil quality and ownership, merged into separate data file at the end. 
	preserve
	keep KEY plot_prop plot_soilqual surface

	collapse (mean) hc_farm_own=plot_prop hc_farm_soilqual=plot_soilqual  [w=surface] , by(KEY) 
	ren * *_$t

	tempfile soil
	save `soil'

	restore
	
	*reshape to crop level
	drop plot_*
	reshape long crop_ crop_sellprice_ kgharvest_ kgcropsell_, i(uniquekey) j(crop_no)
	

	*drop empty rows
	drop if crop_ == .

	*Make names look nice, and ending on t
	ren *_ *
	ren * *_$t


	*clean up the plot id to be just 1,2,3...
	gen plot_id_$t = substr( uniquekey_$t, length(uniquekey_$t) - 1, 1)
	drop uniquekey_$t
	destring plot_id_$t, replace

	*Calculate yields (KGs/HA)
	gen yield_$t = kgharvest_$t / surface_$t
	
	*Calculate sale price per kg & clean up
	gen crop_sell_pricekg = crop_sellprice/kgcropsell
	
	*remove outliers

	replace crop_sell_pricekg = . if crop_sell_pricekg < 0.05

	replace crop_sell_pricekg = . if crop_sell_pricekg > 10
	
	egen crop_pricekg_$t = mean(crop_sell_pricekg), by(crop_$t)

	*drop crop_sell_pricekg
	replace crop_pricekg_$t = . if crop_pricekg_$t < 0.01 | crop_pricekg_$t > 100
	
	*Generate total crop value 
	gen crop_harvest_value_$t = kgharvest_$t * crop_pricekg_$t


	la var KEY_$t "Household Identifier"

	tempfile plot
	save `plot'

	**Make farm-level indicators.

	*generate indicator for leguminous crops
	egen out_legum_$t = anymatch(crop_$t),values(7 8 9)	
	egen out_cassava_$t = anymatch(crop_$t),values(1)	

	*collpase to farm level, and merge previous farm-level indicators
	collapse (sum) crop_harvest_value_$t (max) out_legum_$t out_cassava_$t , by(KEY_$t)
	merge 1:1 KEY_$t using `soil', nogen
	ren crop_harvest_value_$t out_prodvalue_$t

	*label variables
	la var out_prodvalue_$t "Total Value Agricultural Production (USD)" 
	la var  out_legum_$t "Grows leguminous crops (1=yes)"
	la var out_cassava_$t "Grows cassava (1=yes)"
	la var hc_farm_own_$t "Ownership of plots (weighted average)"
	la var hc_farm_soilqual_$t "Soil quality of plots (weighted average)"
	
	save "1. Data\2. Clean\N2A_Farm_$t.dta", replace


	*finalize cropplot level
	use `plot'
	
	la var plot_id_$t "Plot ID"
	la var crop_no_$t "Crop sequence"
	la var crop_$t  "Crop"
	la var kgharvest_$t	"Kg of crop harvested on plot"
	la var surface_$t "Surface of plot (ha)"
	la var yield_$t "Crop yield on plot (kg/ha)"

	drop crop_sellprice_$t  kgcropsell_$t crop_sell_pricekg crop_pricekg_$t crop_harvest_value_$t

	*Order and save
	order KEY_$t plot_id_$t
	
	
	save "1. Data\2. Clean\N2A_Crop_$t.dta", replace
}

 
