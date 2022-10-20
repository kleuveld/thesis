
capture program drop balance_table
program define balance_table
	version  13
	syntax varlist [if] using/, Treatment(varlist) [Cluster(varlist)] [Sheet(string)] [Title(string)] [rawcsv]
	preserve
	if "`if'"!="" {
		qui keep `if'
	}


	**Create table
	tempname memhold
	tempfile balance
	qui postfile `memhold' str80 Variable Nall str12 MeanSDall N1 str12 MeanSD1 N0 str12 MeanSD0 str12 diff using "`balance'", replace
	**Calculate statistics
	//replace `treatment' = `treatment' - 1
	foreach var of varlist `varlist' {
		scalar Variable = `"`: var label `var''"'

		 *calculate statistics for full sample
		qui su `var'
		scalar nall = `r(N)'
		scalar meanall = `r(mean)'
		scalar sdall = r(sd)

		*calculate statistics per treatment
		forvalues i = 0/1{
			qui su `var' if `treatment'== `i'
			scalar n`i' = `r(N)'
			scalar mean`i' = `r(mean)'
			scalar sd`i' = `r(sd)'
		}

		foreach x in all 0 1{
			local mean`x'_f = string(mean`x',"%9.2f")
			local sd`x'_f = "("+ string(sd`x',"%9.2f") + ")"
		}
		
		**Calculate p-values with correction for clusters
		qui regress `var' `treatment', vce(cluster `cluster')
		matrix table = r(table)
		scalar diff = table[1,1]
		scalar pvalue = table[4,1]

		*calculate difference
		local diff_f = string(diff,"%9.2f") + cond(pvalue < 0.1,"*","") + cond(pvalue < 0.05,"*","") + cond(pvalue < 0.01,"*","")
		
		post `memhold' (Variable) (nall) ("`meanall_f'") (n1) ("`mean1_f'") (n0) ("`mean0_f'") ("`diff_f'")
		post `memhold' ("")       (.)  ("`sdall_f'")   (.)  ("`sd1_f'")   (.)  ("`sd0_f'")   ("")
		
		scalar drop _all
	}

	postclose `memhold'

	**Export table
	use "`balance'", clear
	
	foreach x in all 1 0{
		la var N`x' "N"
		la var MeanSD`x' "Mean"		
	}
	la var diff " "


	export excel "`using'", sheet("`sheet'") firstrow(variables) sheetreplace
	
	restore
end


