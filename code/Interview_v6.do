*==============================================================================================
* Interview_v6.do
*
* Interview dates of every respondent in every wave, BHPS and Understanding Society.
*
* Reads:   individual and household files of each wave (survey data needed)
* Writes:  data/Wage/interview.dta, interview_wide.dta, interview_long.dta
*
* Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
* and pregnancy losses. Social Science Research, 141, 103450.
*==============================================================================================

quietly do "config.do"   // folder settings: start Stata in the package folder

 global path   ${REPL_RAW}/UKDA-6614-stata-2/stata/stata11_se
 global path1  ${REPL_RAW}/UKDA-6614-stata/stata/stata13_se/ukhls
 global path2  ${REPL_RAW}/UKDA-6931-stata/stata/stata13_se/ukhls
 global data   ${REPL_DATA}/Wage

 local bhps_let  a b c d e f g h i j k l m n o p q r
 local bhps_idx  abcdefghijklmnopqr
 local nb : word count `bhps_let'

 local ukhls_let  a b c d e f g h i j k l m n o
 local ukhls_idx  abcdefghijklmno
 local nu : word count `ukhls_let'
 local use_protect = 0
 local u_start = `nb' + 2
 local u_end   = `nb' + `nu'

 if `use_protect' {
   local ukhls_dir "$path2"
   local ind_suf   "_indresp_protect"
   local hh_suf    "_hhresp_protect"
 }
 else {
   local ukhls_dir "$path1"
   local ind_suf   "_indresp"
   local hh_suf    "_hhresp"
 }

foreach x of local bhps_let {
 local wave = strpos("`bhps_idx'","`x'")
 use pid *hid *hidp *istrtdat* using "$path/bhps_w`wave'/b`x'_indresp.dta", clear
 rename b`x'_* *
 gen 	wave = strpos("`bhps_idx'","`x'")
 lab var wave "Wave"
 tempfile indresp`wave'
 save   "`indresp`wave''", replace
}

use "`indresp1'", clear
forvalues w = 2/`nb'{
 append using "`indresp`w''"
}
replace istrtdaty = 1991 if wave == 1
gen 	date_interview = ym(istrtdaty, istrtdatm) if !missing(istrtdaty,istrtdatm) & istrtdaty>0 & istrtdatm>0
format  date_interview %tm
sort pid wave
keep pid wave date_interview
tempfile  interview
save    "`interview'"

foreach x of local bhps_let {
 local wave = strpos("`bhps_idx'","`x'")
 use pidp pid *hid *hidp using "$path/bhps_w`wave'/b`x'_indall.dta", clear
 rename b`x'_* *
 gen 	wave = strpos("`bhps_idx'","`x'")
 lab var wave "Wave"
 tempfile indall`wave'
 save   "`indall`wave''", replace
}
use "`indall1'", clear
forvalues w = 2/`nb'{
 append using "`indall`w''"
}

merge 1:1 pid wave using  "`interview'"
tab _merge
drop _merge
bysort pid (wave): replace date_interview = date_interview[_n-1] if date_interview == .

keep pidp wave date_interview
capture isid pidp wave
if _rc di as error "WARNING: pidp wave not unique before BHPS reshape wide"
rename date_interview intdat
reshape wide intdat , i(pidp) j(wave)

forvalues i = 2/`nb' {
 local j = `i' - 1
 replace intdat`i' = intdat`j' + 12 if intdat`i' == .
}
forvalues i = 2/`nb' {
 local j = `i' - 1
 gen intdat_lag`i' = intdat`j'
 format  intdat_lag`i' %tm
}

tempfile  BHPS_wide
save     `BHPS_wide'

reshape long intdat intdat_lag, i(pidp) j(wave)
clonevar date_interview = intdat
clonevar date_interview_lag = intdat_lag
order pidp wave intdat intdat_lag
replace date_interview_lag = date_interview - 12 if date_interview_lag == .
replace intdat_lag 		   = intdat - 12 		 if intdat_lag == .

tempfile  BHPS_long
save     `BHPS_long'

foreach x of local ukhls_let {
 use "`ukhls_dir'/`x'`ind_suf'", clear
 local name  hidp hrpno hrpid
 foreach n of local name {
  rename `x'_`n' `n'
 }
 keep pidp `name'
 local wave = strpos("`ukhls_idx'","`x'")
 gen 	wave = strpos("`ukhls_idx'","`x'")
 lab var wave "Wave"
 tempfile int`wave'
 save   "`int`wave''"
}
use "`int1'", clear
forvalues w = 2/`nu'{
 append using "`int`w''"
}
tempfile id
save    `id', replace

foreach x of local ukhls_let {
 use "`ukhls_dir'/`x'`hh_suf'", clear   // household file: interview date d/m/y
 local name hidp hrpid intdated intdatem intdatey
 foreach n of local name {
  rename `x'_`n' `n'
 }
 keep `name'
 gen     date_interview = ym(intdatey,intdatem) if !missing(intdatey,intdatem) & intdatey>0 & intdatem>0
 lab var date_interview "Date interview"
 format  date_interview %tm
 drop intdated
 local wave = strpos("`ukhls_idx'","`x'")
 gen 	wave = strpos("`ukhls_idx'","`x'")
 lab var wave "Wave"
 tempfile int`wave'
 save   "`int`wave''"
}
use "`int1'", clear
forvalues w = 2/`nu'{
 append using "`int`w''"
}
keep hidp wave date_interview
tempfile hhdate
save    `hhdate' , replace

use   `id' , clear
merge m:1 hidp wave using "`hhdate'"
tab _merge
drop if _merge == 2
drop _merge

preserve
 keep   pidp wave date_interview
 rename date_interview intdat
 sort pidp wave
 drop if pidp == .
 capture isid pidp wave
 if _rc di as error "WARNING: pidp wave not unique before UKHLS interview.dta reshape"
 reshape wide intdat , i(pidp) j(wave)
 forvalues i = 2/`nu' {
  local j = `i' - 1
  replace intdat`i' = intdat`j' + 12 if intdat`i' == .
 }
 forvalues i = 2/`nu' {
  local j = `i' - 1
  gen intdat_lag`i' = intdat`j'
  format  intdat_lag`i' %tm
 }
 save     "$data/interview.dta" , replace
restore

replace wave = wave + `nb'
keep   pidp wave date_interview
rename date_interview intdat
sort pidp wave
drop if pidp == .
capture isid pidp wave
if _rc di as error "WARNING: pidp wave not unique before UKHLS reshape wide"
reshape wide intdat , i(pidp) j(wave)
order pidp intdat*

forvalues i = `u_start'/`u_end' {
 local j = `i' - 1
 replace intdat`i' = intdat`j' + 12 if intdat`i' == .
}
forvalues i = `u_start'/`u_end' {
 local j = `i' - 1
 gen intdat_lag`i' = intdat`j'
 format  intdat_lag`i' %tm
}

tempfile UKHLS_wide
save    `UKHLS_wide'

reshape long intdat intdat_lag, i(pidp) j(wave)
clonevar date_interview = intdat
clonevar date_interview_lag = intdat_lag
order pidp wave intdat intdat_lag
replace date_interview_lag = date_interview - 12 if date_interview_lag == .
replace intdat_lag 		   = intdat - 12 		 if intdat_lag == .

tempfile UKHLS_long
save    `UKHLS_long'

* Combine BHPS + UKHLS
use     	`UKHLS_wide'
merge 1:1 pidp using `BHPS_wide'
tab _merge
drop _merge
sort pidp
capture isid pidp
if _rc di as error "WARNING: interview_wide still has duplicate pidp after merge (unexpected)"
save     "$data/interview_wide.dta" , replace

use     	`UKHLS_long'
append using `BHPS_long'
sort pidp wave
save     "$data/interview_long.dta" , replace
