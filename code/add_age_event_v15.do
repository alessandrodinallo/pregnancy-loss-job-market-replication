*==============================================================================================
* add_age_event_v15.do
*
* Adds the age at the end of the pregnancy and the eligibility indicator to an existing
* analysis dataset. The full construction creates the same variables; this file is not
* needed after it.
*
* Reads:   analysis dataset data/Wage/data_wage_v15.dta (survey data needed)
* Writes:  the same file, with the two variables added
*
* Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
* and pregnancy losses. Social Science Research, 141, 103450.
*==============================================================================================

quietly do "config.do"   // folder settings: start Stata in the package folder

clear all
set more off
 global data ${REPL_DATA}/Wage

 use "$data/data_wage_v15.dta", clear

 capture drop age_event
 capture drop elig_ageev
 capture drop age_ev_tmp

 gen double age_ev_tmp = age_f if (x1==1 | x2==1)
 bysort pidp_f (wave): egen double age_event = min(age_ev_tmp)
 drop age_ev_tmp
 label var age_event "Age (f) at pregnancy-end event (x1|x2==1) -- event-based eligibility"
 gen byte elig_ageev = (age_event>=18) if !missing(age_event)
 label var elig_ageev "1 if age at event >=18 (event-based eligibility, no upper cap: max N; SSR R&R)"

 egen byte wtag = tag(pidp_f)
 di as err "=== age_event: distribuzione (donne) ==="
 tabstat age_event if wtag==1, stat(min p25 p50 p75 max n)
 di as err "=== elig_ageev x treated2 (donne) ==="
 tab elig_ageev treated2 if wtag==1, col missing
 count if wtag==1 & missing(age_event)
 di as err "donne senza age_event (nessun wave-evento osservato) = " r(N)
 drop wtag

 save "$data/data_wage_v15.dta", replace
 di as result "age_event + elig_ageev aggiunte a data_wage_v15.dta (additive)."
