*==============================================================================================
* bio_child_v6.do
*
* Dates of birth of the biological children of each respondent.
*
* Reads:   relationship, household-member and natural-children files (survey data needed)
* Writes:  data/Wage/bio.dta
*
* Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
* and pregnancy losses. Social Science Research, 141, 103450.
*==============================================================================================

quietly do "config.do"   // folder settings: start Stata in the package folder

 global path2  ${REPL_RAW}/UKDA-6931-stata/stata/stata13_se/ukhls
 global data   ${REPL_DATA}
 global dataW  ${REPL_DATA}/Wage

foreach x in a b c d e f g h i j k l m n {
use "$path2/`x'_egoalt_protect", clear
local var hidp pno apno relationship
foreach v of local var {
	rename `x'_`v' `v'
}
keep pidp `var' apidp
gen wave = strpos("abcdefghijklmn","`x'")
local wave = wave
keep if relationship == 9
tempfile egoalt`wave'
save   "`egoalt`wave''", replace
}

use "`egoalt1'", clear
forvalues w = 2/14 {
	append using "`egoalt`w''"
}
sort pidp wave
by  pidp: egen wave_parent_min = min(wave)
by  pidp: egen wave_parent_max = max(wave)
sort  pidp apidp wave
by    pidp apidp: keep if _n == 1
tempfile egoalt_parent
save   "`egoalt_parent'"

foreach x in a b c d e f g h i j k l m n {
use "$path2/`x'_egoalt_protect", clear
local var hidp pno apno relationship
foreach v of local var {
	rename `x'_`v' `v'
}
keep pidp `var' apidp
gen wave = strpos("abcdefghijklmn","`x'")
local wave = wave
keep if relationship == 4
tempfile egoalt`wave'
save   "`egoalt`wave''", replace
}

use "`egoalt1'", clear
forvalues w = 2/14 {
	append using "`egoalt`w''"
}
sort  pidp wave
rename  pidp   bridge
rename apidp    pidp
rename  bridge apidp
sort apidp wave
by apidp: egen wave_child_min = min(wave)
by apidp: egen wave_child_max = max(wave)
by apidp: keep if _n == 1
tempfile egoalt_children
save   "`egoalt_children'"

* Dates of birth of coresident children (indall)
foreach x in a b c d e f g h i j k l m n {
use "$path2/`x'_indall_protect", clear
local name hidp pno birthy birthm doby_dv dobm_dv *dvage
foreach n of local name {
	rename `x'_`n' `n'
}
keep pidp `name'
gen wave = strpos("abcdefghijklmn","`x'")
local wave = wave
tempfile indall`wave'
save   "`indall`wave''", replace
}

use "`indall1'", clear
forvalues w = 2/14 {
	append using "`indall`w''"
}
sort pidp wave
rename pidp apidp
rename pno  apno
sort apidp wave
by   apidp: keep if _n == 1
tempfile indall
save   "`indall'"

* Merging datasets
use "`egoalt_parent'", clear
merge 1:1  pidp apidp wave using "`egoalt_children'", nogen
merge m:1 apidp       wave using "`indall'", keep(3) nogen   // only parent-child dyads with a DOB

sort  pidp wave apidp
order pidp apidp
clonevar pidp_children = apidp

* Date of birth
gen dob   = ym(doby_dv, dobm_dv)
gen birth = ym(birthy , birthm)
format dob   %tm
format birth %tm
clonevar childbirth_date = dob
replace  childbirth_date = birth if childbirth_date == .

tempfile parent_children
save   "`parent_children'", replace

foreach x in a f {
use "$path2/`x'_natchild_protect", clear
local var hidp pno lchlv lchyd4 lchdoby lchdobm lchal
foreach v of local var {
	rename `x'_`v' `v'
}
keep pidp `var'
gen wave = strpos("abcdefghijklmn","`x'")
local wave = wave
tempfile child`wave'
save   "`child`wave''", replace
}
use "`child1'", clear
append using "`child6'"
sort pidp wave
keep if lchlv == 2
tempfile nat_child
save   "`nat_child'"

use "`parent_children'", clear
append using "`nat_child'"
sort  pidp, stable

replace  childbirth_date = ym(lchdoby, lchdobm)                if childbirth_date == . & (lchdobm > 0 & lchdobm < .) & (lchdoby > 0 & lchdoby < .)
replace  childbirth_date = ym(lchdoby, 1 + mod(abs(int(pidp)) + lchdoby, 12)) if childbirth_date == . & (lchdobm == . | lchdobm < 0) & (lchdoby > 0 & lchdoby < .)
order pidp apidp doby_dv lchdoby childbirth_date

drop hidp pno apno dvage

* Dropping duplicates
duplicates tag pidp apidp childbirth_date, gen(duplicates)
bysort         pidp apidp childbirth_date (wave relationship doby_dv lchdoby) : gen N = _n
drop if N > 1 & duplicates > 0
drop duplicates N
sort pidp apidp

replace relationship = 9 if lchdoby != .

* FINAL FILE : biological children
order pidp wave apidp doby_dv childbirth_date
sort  pidp wave apidp childbirth_date relationship doby_dv
label var childbirth_date "Observed child date of birth (%tm)"

save "$dataW/bio", replace

* Coverage report
di as err "=== bio_child_v4 coverage ==="
count
di as err "rows: " r(N)
count if childbirth_date < .
di as err "rows with observed childbirth_date: " r(N)
quietly summarize doby_dv if doby_dv > 0 & doby_dv < .
di as err "child birth-year min=" r(min) "  max=" r(max)
quietly summarize wave
di as err "parent-wave min=" r(min) "  max=" r(max)
