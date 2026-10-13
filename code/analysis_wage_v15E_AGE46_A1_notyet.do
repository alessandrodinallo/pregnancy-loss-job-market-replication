*==============================================================================================
* analysis_wage_v15E_AGE46_A1_notyet.do
*
* Event-study models with the not-yet-treated women as comparison group.
* Source of one row of Appendix Table A18.
*
* Reads:   analysis dataset data/Wage/data_wage_v15.dta (survey data needed)
* Writes:  estimates/RB_V15E_AGE46_A1NY_* (nested tables, coefficients)
*
* Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
* and pregnancy losses. Social Science Research, 141, 103450.
*==============================================================================================

quietly do "config.do"   // folder settings: start Stata in the package folder

clear all
set more off
 global data   ${REPL_DATA}/Wage
 global rbreg  ${REPL_EST}
 capture mkdir "$rbreg"
 local s f
 global demo    c.age_`s'##c.age_`s'  c.income_partner_`s'
 global year    ib2011.year i.gor_`s'
 global union   ib1.union_type
 global SES     c.ISEI_`s'##c.ISEI_`s' i.ISEI_miss_`s' ib1.hiqual_`s' soc00_N_wave ib1.private_`s' ib1.nssec5_v2_`s'
 global exp     c.work_exp_`s'##c.work_exp_`s' i.work_exp_miss_`s' c.tenure_`s'##c.tenure_`s' i.tenure_miss_`s'
 global jobend2 c.num_job_end_v2_`s'##c.num_job_end_v2_`s'
 global postj2  i.any_job_end_post_`s'
 capture confirm variable any_job_end_post_`s', exact
 if _rc global postj2 i.any_job_end_post_v2_`s'
 global health  c.sf12mcs_std_`s' c.sf12pcs_std_`s'
 local m1 $year $demo $union
 local m5 $year $demo $union $SES $exp $jobend2 $postj2 $health i.time_x3_cat

 use "$data/data_wage_v15.dta", clear
 drop if wave == .
 duplicates tag pidp_`s' wave, gen(dup)
 bysort pidp_`s' wave: gen n_pw = _n
 drop if n_pw > 1 & dup > 0
 drop dup n_pw

 capture confirm variable age_event, exact
 if _rc {
     di as error "age_event non trovata: eseguire prima add_age_event_v15.do"
     exit 111
 }

 keep if x1 !=. & x2 !=. & age_event>=18 & age_event<46            ///
       & (treated1 == 1 | treated2 == 1)                           ///
       & first_wave_worked <= min_wave_t & first_wave_worked !=.   ///
       & self_employed1_`s' == 0

 gen evw_loss = wave if x2==1
 bysort pidp_`s': egen loss_wave  = min(evw_loss)
 gen byte has_loss = !missing(loss_wave)

 gen evw_birth = wave if x1==1
 bysort pidp_`s': egen birth_wave = min(evw_birth)
 gen byte is_ctrl = (treated2==0 & has_loss==0 & !missing(birth_wave))

 capture confirm variable time_x2_cat4, exact
 if _rc {
     di as error "time_x2_cat4 non trovata"
     exit 111
 }

 gen byte insample = 0
 replace insample = 1 if has_loss==1
 replace insample = 1 if is_ctrl==1 & wave <= birth_wave-2
 keep if insample==1

 replace time_x2_cat4 = 2 if is_ctrl==1

 egen byte wtag = tag(pidp_`s')
 count if wtag==1 & has_loss==1
 di as err "A1 not-yet: donne LOSS effettive = " r(N)
 count if wtag==1 & is_ctrl==1
 di as err "A1 not-yet: donne CONTROLLO effettive (future mothers, pre-concep) = " r(N)
 count if wtag==1
 di as err "A1 not-yet: donne totali in stima = " r(N)
 drop wtag

 gen byte worker = !missing(fimnlabgrs_hrclean_CPI_trim_ln_`s') & !missing(tot_work_hours_cond_ln_trim_`s')
 xtset pidp_`s' wave

 local dvs   "fimnlabgrs_CPI_trim_`s' fimnlabgrs_hrclean_CPI_trim_ln_`s' tot_work_hours_`s' tot_work_hours_cond_ln_trim_`s' employed11_`s'"
 local tags  "earnings wage workhrs workhrs_cond employed"
 local types "U C U C U"
 local nout : word count `tags'

 tempname pf
 postfile `pf' str14 outcome str6 estim byte model byte bin double b double se double t str3 star ///
     using "$rbreg/RB_V15E_AGE46_A1NY_allcoef.dta", replace

 tempname pt
 postfile `pt' str14 outcome str6 estim double p_25bef double p_12bef double p_joint ///
     using "$rbreg/RB_V15E_AGE46_A1NY_pretrend.dta", replace

forvalues o = 1/`nout' {
    local dv  : word `o' of `dvs'
    local tag : word `o' of `tags'
    local ty  : word `o' of `types'
    local ssamp ""
    if "`ty'" == "C" local ssamp "& worker"

    quietly xtreg `dv' ib2.time_x2_cat4 `m5' if 1 `ssamp', vce(cluster pidp_`s')
    capture drop cs
    gen byte cs = e(sample)

    foreach est in RE TWFE {
        forvalues k = 1/5 {
            if "`est'" == "RE"   quietly xtreg   `dv' ib2.time_x2_cat4 `m`k'' if cs, vce(cluster pidp_`s')
            if "`est'" == "TWFE" quietly reghdfe `dv' ib2.time_x2_cat4 `m`k'' if cs, absorb(pidp_`s' wave) vce(cluster pidp_`s')
            estimates store `est'`k'
            forvalues j = 1/9 {
                if `j' == 2 continue
                local bb = .
                local se = .
                capture local bb = _b[`j'.time_x2_cat4]
                capture local se = _se[`j'.time_x2_cat4]
                local tt = .
                local st ""
                if `se' < . & `se' > 0 {
                    local tt = `bb'/`se'
                    if abs(`tt') > 1.645 local st "*"
                    if abs(`tt') > 1.96  local st "**"
                    if abs(`tt') > 2.576 local st "***"
                }
                post `pf' ("`tag'") ("`est'") (`k') (`j') (`bb') (`se') (`tt') ("`st'")
            }
        }
        if "`est'" == "RE"   quietly xtreg   `dv' ib2.time_x2_cat4 `m1' if cs, vce(cluster pidp_`s')
        if "`est'" == "TWFE" quietly reghdfe `dv' ib2.time_x2_cat4 `m1' if cs, absorb(pidp_`s' wave) vce(cluster pidp_`s')
        local p1 = .
        local p3 = .
        local pj = .
        capture test 1.time_x2_cat4
        if !_rc local p1 = r(p)
        capture test 3.time_x2_cat4
        if !_rc local p3 = r(p)
        capture test (1.time_x2_cat4=0)(3.time_x2_cat4=0)
        if !_rc local pj = r(p)
        post `pt' ("`tag'") ("`est'") (`p1') (`p3') (`pj')

        capture esttab `est'1 `est'2 `est'3 `est'4 `est'5 using "$rbreg/RB_V15E_AGE46_A1NY_`tag'_`est'_nested.csv", replace ///
            keep(*.time_x2_cat4) b(%9.3f) se(%9.3f) plain star(* 0.10 ** 0.05 *** 0.01) stats(N)
    }
}
postclose `pf'
postclose `pt'

 preserve
 use "$rbreg/RB_V15E_AGE46_A1NY_allcoef.dta", clear
 label define binlab 1 "25+ before" 3 "12-1 before" 4 "0-12 after" 5 "13-24 after" ///
     6 "25-36 after" 7 "37-48 after" 8 "49-60 after" 9 "61+ after"
 label values bin binlab
 order outcome estim model bin b se t star
 export excel using "$rbreg/RB_V15E_AGE46_A1NY_coefficients.xlsx", firstrow(variables) replace sheet("coef")
 restore
 preserve
 use "$rbreg/RB_V15E_AGE46_A1NY_pretrend.dta", clear
 export excel using "$rbreg/RB_V15E_AGE46_A1NY_coefficients.xlsx", firstrow(variables) sheetmodify sheet("pretrend")
 restore

 di as err ""
 di as err "=== output: RB_V15E_AGE46_A1NY_<outcome>_{RE,TWFE}_nested.csv | RB_V15E_AGE46_A1NY_coefficients.xlsx (coef+pretrend) ==="
 di as result "A1 not-yet-treated (loss vs future-mothers pre-concepimento). GUARDARE il foglio 'pretrend': se i lead (25+before/12-1before) sono NS -> il pre-trend di B3 e' risolto (fertility-selection neutralizzata). Focus BREVE periodo (0-12)."
