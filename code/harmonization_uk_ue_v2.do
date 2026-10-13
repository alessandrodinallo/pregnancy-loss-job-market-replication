*==============================================================================================
* harmonization_uk_ue_v2.do
*
* Monthly unemployment rate of women by region and age group.
*
* Reads:   data/uk_ue1.dta to data/uk_ue12.dta (public series, one file per region)
* Writes:  data/Wage/uk_ue_women.dta
*
* Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
* and pregnancy losses. Social Science Research, 141, 103450.
*==============================================================================================

quietly do "config.do"   // folder settings: start Stata in the package folder

 global path1 ${REPL_DATA}
 global out   ${REPL_DATA}/Wage

forvalues y = 1/12 {
use "$path1/uk_ue`y'.dta", clear

drop if _n == 1   // region-name header row

keep var1 var4 var5 var6 var7
foreach var of varlist var1 var4 var5 var6 var7 {
    replace `var' = subinstr(`var', ",", ".", .)   // European comma decimal
    replace `var' = subinstr(`var', "*", "",  .)
}

foreach var of varlist var1 var4 var5 var6 var7 {
    destring `var', gen(`var'_)
}
keep *_
rename *_ *

assert _N >= 263
drop if _n > 263
rename var1 ue
rename var4 ue1824
rename var5 ue1624
rename var6 ue2534
rename var7 ue3549

gen q = _n
gen y = 40 * 12 + 16 + q + 1
format y %tm
gen     date  = dofm(y)
gen     year  = year(date)
lab var year "Year FE"
gen     month = month(date)
lab var month "Month FE"
drop date

gen gor   = `y'
tempfile ue`y'
save    `ue`y'', replace
}

use `ue1', clear
forvalues y = 2/12 {
append using `ue`y''
}

isid month year gor
save "$out/uk_ue_women", replace

* coverage report
di as err "=== uk_ue coverage ==="
di as err "N obs = " _N
quietly levelsof gor, local(gors)
di as err "gor codes: `gors'   (should be 1..12 incl. NI)"
quietly summarize y
di as err "month range (%tm): " %tm r(min) " to " %tm r(max)
