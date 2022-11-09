cap prog drop balance_table
program define balance_table
	version  13
	syntax varlist [if] using/, Treatment(varlist) [Cluster(varlist)] ///
		[Sheet(string)] [Weight(varlist)] [rawcsv] ///
		[title(passthru)] [marker(passthru)] [headerlines(passthru)]

	n di as res "title1 = `title'"

	preserve
	if "`if'"!="" {
		qui keep `if'
	}

	**Manipulate input
	if "`weight'"=="" {
		tempvar equal_weight
		qui gen `equal_weight' = 1
		local weight `equal_weight'
	}
	**Create table
	tempname memhold
	tempname memhold_raw
	tempname raw 
	tempfile balance
	tempfile balance_raw
	qui postfile `memhold' str80 Variable Nall str12 MeanSDall N1 str12 MeanSD1 N0 str12 MeanSD0 str12 diff using "`balance'", replace
	qui postfile `memhold_raw' str32 var str80 varlabel nall meanall sdall n1 mean1 sd1 n0 mean0 sd0 diff p using "`balance_raw'", replace
	**Calculate statistics
	foreach var of varlist `varlist' {
		scalar Variable = `"`: var label `var''"'

		 *calculate statistics for full sample
		qui su `var' [aweight=`weight']
		scalar nall = `r(N)'
		scalar meanall = `r(mean)'
		scalar sdall = r(sd)

		*calculate statistics per treatment
		forvalues i = 0/1{
			qui su `var' if `treatment'== `i' [aweight=`weight']
			scalar n`i' = `r(N)'
			scalar mean`i' = `r(mean)'
			scalar sd`i' = `r(sd)'
		}

		foreach x in all 0 1{
			local mean`x'_f = string(mean`x',"%9.2f")
			local sd`x'_f = "("+ string(sd`x',"%9.2f") + ")"
		}
		
		**Calculate p-values with correction for clusters
		local aweight "[aweight=`weight']"
		local reg_weight "[iweight=`weight']"
		
	
		qui regress `var' `treatment' `reg_weight', vce(cluster `cluster')
		matrix table = r(table)
		scalar diff = table[1,1]
		scalar pvalue = table[4,1]

		*calculate difference
		local diff_f = string(diff,"%9.2f") + cond(pvalue < 0.1,"*","") + cond(pvalue < 0.05,"*","") + cond(pvalue < 0.01,"*","")
		
		post `memhold' (Variable) (nall) ("`meanall_f'") (n1) ("`mean1_f'") (n0) ("`mean0_f'") ("`diff_f'")
		post `memhold' ("")       (.)  ("`sdall_f'")   (.)  ("`sd1_f'")   (.)  ("`sd0_f'")   ("")
		
		post `memhold_raw' ("`var'") (Variable) (nall) (meanall) (sdall) (n1) (mean1) (sd1) (n0) (mean0) (sd0) (diff) (pvalue)

		scalar drop _all
	}

	postclose `memhold'
	postclose `memhold_raw'

	**Export table
	use "`balance'", clear
	
	foreach x in all 1 0{
		la var N`x' "N"
		la var MeanSD`x' "Mean"		
	}
	la var diff " "

	if regexm("`using'",".xlsx?$")==1 {
		n di as result "exporting excel"
		export excel "`using'", sheet("`sheet'") firstrow(variables) sheetreplace
	}
	if regexm("`using'",".tex$")==1 {
		n di as result "exporting tex"
		n di "title = `title'"
		n di "marker = `marker'"
		tempfile temp
		qui texsave using "`temp'", location(hp) autonumber varlabels replace frag  size(3) `marker' `title' `headerlines' footnote("Standard Deviations in parantheses; *p $<$ 0.1,**p $<$ 0.05,***p $<$ 0.01")
		qui filefilter "`temp'" "`using'", from("&{(1)}&{(2)}&{(3)}&{(4)}&{(5)}&{(6)}&{(7)} \BStabularnewline") to("&{(1)}&{(2)}&{(3)}&{(4)}&{(5)}&{(6)}&{(7)} \BStabularnewline\n&\BSmulticolumn{2}{c}{All}&\BSmulticolumn{2}{c}{Treatment}&\BSmulticolumn{2}{c}{Control}&{(4)-(6)}\BStabularnewline") replace
		
	}
	if regexm("`using'",".csv$")==1 {
		n di as result "exporting csv"
		qui export delimited using "`using'", datafmt replace
	}

	if length("`raw'") > 0{
		n di as result  "exporting rawcsv"
		qui use "`balance_raw'", clear
		format mean* sd* %9.2f
		foreach var of varlist mean*{
			gen `var'_pct = `var' * 100
			format `var'_pct %9.0f
		}

		if regexm("`using'","(.*)\..*"){
			local usingraw = regexs(1) 
		}
		qui export delimited using "`usingraw'.csv", datafmt replace
	}

	restore
end
