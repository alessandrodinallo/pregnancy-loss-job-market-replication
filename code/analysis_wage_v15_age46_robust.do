*==============================================================================================
* analysis_wage_v15_age46_robust.do
*
* Event-study models for the five outcomes, Models 1 to 5, random effects and two-way fixed
* effects. Source of one row of Appendix Table A18.
*
* Reads:   analysis dataset data/Wage/data_wage_v15.dta (survey data needed)
* Writes:  estimates/RB_V15E_AGE46_allcoef.dta, nested tables (csv), a spreadsheet of
*          coefficients; figures in figures/
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
 local m2 $year $demo $union $SES
 local m3 $year $demo $union $SES $exp $jobend2 $postj2
 local m4 $year $demo $union $SES $exp $jobend2 $postj2 $health
 local m5 $year $demo $union $SES $exp $jobend2 $postj2 $health i.time_x3_cat

 use "$data/data_wage_v15.dta", clear
 drop if wave == .
 duplicates tag pidp_`s' wave, gen(dup)
 bysort pidp_`s' wave: gen n_pw = _n
 drop if n_pw > 1 & dup > 0
 drop dup n_pw

 capture confirm variable age_event, exact
 if _rc {
     di as error "age_event non trovata in data_wage_v15: eseguire prima add_age_event_v15.do"
     exit 111
 }

 keep if x1 !=. & x2 !=. & age_event>=18 & age_event<46            ///
       & (treated1 == 1 | treated2 == 1)                           ///
       & first_wave_worked <= min_wave_t & first_wave_worked !=.   ///
       & self_employed1_`s' == 0

 egen byte wtag = tag(pidp_`s')
 count if wtag==1
 di as err "AGE46 robustness: donne totali = " r(N)
 count if wtag==1 & treated2==1
 di as err "  di cui perdita = " r(N)
 count if wtag==1 & treated1==1
 di as err "  di cui parto   = " r(N)
 tabstat age_event if wtag==1, by(treated2) stat(min p50 max n)
 drop wtag

 gen byte worker = !missing(fimnlabgrs_hrclean_CPI_trim_ln_`s') & !missing(tot_work_hours_cond_ln_trim_`s')
 quietly count if worker
 di as err "=== campione-lavoratrici comune (AGE46) = " r(N)
 xtset pidp_`s' wave

 local dvs   "fimnlabgrs_CPI_trim_`s' fimnlabgrs_hrclean_CPI_trim_ln_`s' tot_work_hours_`s' tot_work_hours_cond_ln_trim_`s' employed11_`s'"
 local tags  "earnings wage workhrs workhrs_cond employed"
 local types "U C U C U"
 local nout : word count `tags'

 tempname pf
 postfile `pf' str14 outcome str6 estim byte model byte bin double b double se double t str3 star ///
     using "$rbreg/RB_V15E_AGE46_allcoef.dta", replace

forvalues o = 1/`nout' {
    local dv  : word `o' of `dvs'
    local tag : word `o' of `tags'
    local ty  : word `o' of `types'
    local ssamp ""
    if "`ty'" == "C" local ssamp "& worker"

    quietly xtreg `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `m5' if 1 `ssamp', vce(cluster pidp_`s')
    capture drop cs
    gen byte cs = e(sample)
    quietly count if cs
    di as err "   `tag' (`ty'): N costante = " r(N)

    foreach est in RE TWFE {
        forvalues k = 1/5 {
            if "`est'" == "RE"   quietly xtreg   `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `m`k'' if cs, vce(cluster pidp_`s')
            if "`est'" == "TWFE" quietly reghdfe `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `m`k'' if cs, absorb(pidp_`s' wave) vce(cluster pidp_`s')
            estimates store `est'`k'
            forvalues j = 1/9 {
                if `j' == 2 continue
                local bb = _b[`j'.time_x2_cat4]
                local se = _se[`j'.time_x2_cat4]
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
        capture esttab `est'1 `est'2 `est'3 `est'4 `est'5 using "$rbreg/RB_V15E_AGE46_`tag'_`est'_nested.csv", replace ///
            keep(*.time_x1_cat4 *.time_x2_cat4) b(%9.3f) se(%9.3f) plain star(* 0.10 ** 0.05 *** 0.01) stats(N)
    }
}
postclose `pf'

 preserve
 use "$rbreg/RB_V15E_AGE46_allcoef.dta", clear
 label define binlab 1 "25+ before" 3 "12-1 before" 4 "0-12 after" 5 "13-24 after" ///
     6 "25-36 after" 7 "37-48 after" 8 "49-60 after" 9 "61+ after"
 label values bin binlab
 order outcome estim model bin b se t star
 export excel using "$rbreg/RB_V15E_AGE46_coefficients.xlsx", firstrow(variables) replace
 di as err "=== xlsx scritto: RB_V15E_AGE46_coefficients.xlsx ==="
 restore

 local celab 1 "25+bef" 3 "12-1bef" 4 "0-12" 5 "13-24" 6 "25-36" 7 "37-48" 8 "49-60" 9 "61+"
forvalues o = 1/`nout' {
    local dv  : word `o' of `dvs'
    local tag : word `o' of `tags'
    local ty  : word `o' of `types'
    local ssamp ""
    if "`ty'" == "C" local ssamp "& worker"
    quietly xtreg `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `m5' if 1 `ssamp', vce(cluster pidp_`s')
    capture drop cs
    gen byte cs = e(sample)
    quietly xtreg `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `m1' if cs, vce(cluster pidp_`s')
    capture coefplot, keep(*.time_x2_cat4) vertical yline(0, lcolor(gray%50)) ///
        coeflabels(`celab') xlabel(, labsize(small) angle(30)) ///
        msymbol(O) mcolor(cranberry%75) ciopts(recast(rcap) lcolor(cranberry%45)) ///
        title("`tag' -- v15 AGE46 (<46 at event), RE M1, loss", size(medsmall)) ///
        xtitle("Time relative to pregnancy end", size(small)) ///
        graphregion(color(white)) plotregion(fcolor(white)) name(age46_`tag', replace)
    capture graph export "$rbgra/RB_V15E_AGE46_`tag'_M1.png", replace width(2000)
}
 di as err ""
 di as err "=== output: RB_V15E_AGE46_*_nested.csv | RB_V15E_AGE46_coefficients.xlsx | RB_V15E_AGE46_*_M1.png ==="
 di as result "AGE46 robustness (eta' all'evento < 46) pronto. Confrontare con l'unconstrained RB_V15_* / v15E."
