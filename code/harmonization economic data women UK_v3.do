*==============================================================================================
* harmonization economic data women UK_v3.do
*
* Monthly consumer price index and monthly employment rate of women in the United Kingdom.
*
* Reads:   data/UK_inflation_ONS_2026.dta, data/employment_rate_UK.dta (public series)
* Writes:  data/inflation_UK.dta, data/employment_women_UK.dta
*
* Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
* and pregnancy losses. Social Science Research, 141, 103450.
*==============================================================================================

quietly do "config.do"   // folder settings: start Stata in the package folder

 global data    ${REPL_DATA}
 global do      ${REPL_CODE}
 global results ${REPL_OTHER}

* Women's employment rate (monthly, percent)
use "$data/employment_rate_UK", clear
gen double date = monthly(var1, "YM")
assert !missing(date)
format date %tm
gen year  = yofd(dofm(date))
gen month = month(dofm(date))

replace var2 = subinstr(var2, ",", ".", .)   // European comma decimal
destring var2, gen(emp_rate_women)
label var emp_rate_women "Women's employment rate (%, monthly)"

isid year month
keep year month emp_rate_women
save "$data/employment_women_UK", replace

use "$data/UK_inflation_ONS_2026", clear
gen double date = monthly(var1, "YM")
assert !missing(date)
format date %tm
gen year  = yofd(dofm(date))
gen month = month(dofm(date))

replace var2 = subinstr(var2, ",", ".", .)
destring var2, gen(CPI)
replace CPI = CPI/100
label var CPI "CPI price index, ONS d7bt (base 2015 = 1)"

isid year month
keep year month date CPI
save "$data/inflation_UK", replace

* coverage report
di as err "=== CPI coverage ==="
quietly summarize date
di as err "date range (%tm): " %tm r(min) "  to  " %tm r(max)
quietly summarize CPI
di as err "CPI range: " r(min) " - " r(max) "   (2015 index should be ~1.0)"
list year month CPI if year==2015 & month==6, clean noobs
