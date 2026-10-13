*==============================================================================================
* did_matching_childless_v3.do
*
* Matched difference-in-differences between women with a pregnancy loss and women who
* remain childless. Source of Appendix Figures B3 and B4.
*
* Reads:   analysis dataset data/Wage/data_wage_v15.dta (survey data needed)
* Writes:  estimates/B3_V15E_AGE46_allcoef.dta, nested tables (csv) and a spreadsheet of
*          coefficients
*
* Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
* and pregnancy losses. Social Science Research, 141, 103450.
*==============================================================================================

quietly do "config.do"   // folder settings: start Stata in the package folder

clear all
set more off
 global data   ${REPL_DATA}/Wage
 global rbreg  ${REPL_EST}
 global rbgra  ${REPL_FIG}
 capture mkdir "$rbreg"
 capture mkdir "$rbgra"

 use "$data/data_wage_v15.dta", clear
 drop if wave == .
 duplicates tag pidp_f wave, gen(dup)
 bysort pidp_f wave: gen n_pw = _n
 drop if n_pw > 1 & dup > 0
 drop dup n_pw

 capture confirm variable age_event, exact
 if _rc {
     di as error "age_event non trovata: eseguire prima add_age_event_v15.do"
     exit 111
 }

 foreach var in age_f year any_child first_wave_worked min_wave_t ///
                gor_f union_type hiqual_f {
     replace `var' = . if `var' < 0
 }

 bysort pidp_f (wave): egen first_loss_wave  = min(cond(x2==1, wave, .))
 bysort pidp_f (wave): egen first_child_wave = min(cond(x1==1, wave, .))
 bysort pidp_f: egen has_preg  = max(cond((x1==1 | x2==1), 1, 0))
 bysort pidp_f: egen max_child = max(any_child)

 gen byte treat_loss = .
 replace  treat_loss = 1 if first_loss_wave < . & first_loss_wave < first_child_wave
 replace  treat_loss = 0 if has_preg == 0 & max_child == 0
 drop if missing(treat_loss)

 tempfile transition_data
 save `transition_data', replace

 gen match_wave = first_loss_wave - 2 if treat_loss == 1
 bysort pidp_f (wave): gen wave_index = _n
 replace match_wave = wave if treat_loss == 0 & wave_index == 2
 drop wave_index

 bysort pidp_f (wave): gen byte keepobs = (wave == match_wave)
 keep if keepobs == 1
 drop if missing(match_wave)
 drop keepobs

 keep if (treat_loss == 1 & age_event >= 18 & age_event < 46) ///
       | (treat_loss == 0 & age_f    >= 18 & age_f    < 46)

 count if treat_loss == 1
 di as err "B3: trattate (loss childless, AGE46) pre-match = " r(N)
 count if treat_loss == 0
 di as err "B3: controlli (childless mai-incinte, 18-45 al match) pre-match = " r(N)

 gen byte treatment = (treat_loss == 1)
 sort pidp_f
 set seed 48321
 psmatch2 treatment c.age_f i.gor_f i.union_type i.hiqual_f i.year, ///
     neighbor(1) caliper(0.02) common

 keep if _weight != .
 count if treatment == 1
 di as err "B3: trattate MATCHATE = " r(N)
 count if treatment == 0
 di as err "B3: controlli MATCHATI = " r(N)

 tempfile matched_ids
 keep pidp_f match_wave
 save `matched_ids', replace

 use `transition_data', clear
 merge m:1 pidp_f using `matched_ids', keep(master match)
 tab _merge
 keep if _merge == 3
 drop _merge

 gen index_event = wave - match_wave
 replace index_event = . if index_event < -5 | index_event > 4
 drop if missing(index_event)
 gen index_event_pos = index_event + 4
 replace index_event_pos = 0 if index_event_pos == -1
 label define wave_index 0 "-4" 1 "-3" 2 "-2" 3 "-1" 4 "0" 5 "1" 6 "2" 7 "3" 8 "4"
 label values index_event_pos wave_index

 xtset pidp_f wave

 local dvs  "fimnlabgrs_CPI_trim_f fimnlabgrs_hrclean_CPI_trim_ln_f tot_work_hours_f tot_work_hours_cond_ln_trim_f employed11_f"
 local tags "earnings wage workhrs workhrs_cond employed"
 local nout : word count `tags'

 tempname pf
 postfile `pf' str14 outcome byte bin double b double se double t str3 star ///
     using "$rbreg/B3_V15E_AGE46_allcoef.dta", replace

forvalues o = 1/`nout' {
    local dv  : word `o' of `dvs'
    local tag : word `o' of `tags'

    reghdfe `dv' ib2.index_event_pos##ib0.treat_loss c.age_f##c.age_f i.union_type, ///
        absorb(pidp_f wave) vce(cluster pidp_f)
    estimates store B3_`tag'

    forvalues k = 0/8 {
        if `k' == 2 continue
        local bb = .
        local se = .
        capture local bb = _b[`k'.index_event_pos#1.treat_loss]
        capture local se = _se[`k'.index_event_pos#1.treat_loss]
        local tt = .
        local st ""
        if `se' < . & `se' > 0 {
            local tt = `bb'/`se'
            if abs(`tt') > 1.645 local st "*"
            if abs(`tt') > 1.96  local st "**"
            if abs(`tt') > 2.576 local st "***"
        }
        post `pf' ("`tag'") (`k') (`bb') (`se') (`tt') ("`st'")
    }
    capture esttab B3_`tag' using "$rbreg/B3_V15E_AGE46_`tag'.csv", replace ///
        keep(*.index_event_pos#1.treat_loss) b(%9.3f) se(%9.3f) plain ///
        star(* 0.10 ** 0.05 *** 0.01) stats(N)
}
postclose `pf'

 preserve
 use "$rbreg/B3_V15E_AGE46_allcoef.dta", clear
 label define binlab 0 "-4" 1 "-3" 3 "-1" 4 "0" 5 "1" 6 "2" 7 "3" 8 "4"
 label values bin binlab
 order outcome bin b se t star
 export excel using "$rbreg/B3_V15E_AGE46_coefficients.xlsx", firstrow(variables) replace
 restore

 di as err ""
 di as err "=== output: B3_V15E_AGE46_{earnings,wage,workhrs,workhrs_cond,employed}.csv | B3_V15E_AGE46_coefficients.xlsx ==="
 di as result "B3 loss-vs-childless (AGE46, opzione 1). Estimando DIVERSO dall'headline; triangolazione secondaria DIETRO D17. Framing 'directionally consistent', caveat fertility-selection PRIMA dei risultati."
