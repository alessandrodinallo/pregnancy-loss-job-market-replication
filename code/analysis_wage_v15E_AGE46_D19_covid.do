*==============================================================================================
* analysis_wage_v15E_AGE46_D19_covid.do
*
* Event-study models on the full sample and on two samples that limit exposure to the
* pandemic period. Source of Appendix Table A14.
*
* Reads:   analysis dataset data/Wage/data_wage_v15.dta (survey data needed)
* Writes:  estimates/RB_V15E_AGE46_D19_* (coefficients, nested tables); figures in figures/
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
 local ncovid 4

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
 keep if x1 !=. & x2 !=. & age_event>=18 & age_event<46 ///
       & (treated1 == 1 | treated2 == 1)                ///
       & first_wave_worked <= min_wave_t & first_wave_worked !=. ///
       & self_employed1_`s' == 0
 gen byte worker = !missing(fimnlabgrs_hrclean_CPI_trim_ln_`s') & !missing(tot_work_hours_cond_ln_trim_`s')
 xtset pidp_`s' wave

 gen      ev_year = year if (x1 == 1 | x2 == 1)
 bysort pidp_`s': egen ev_year_min = min(ev_year)
 gen byte covid_preg = (ev_year_min >= 2020) & !missing(ev_year_min)

 levelsof wave, local(wl)
 local nw    : word count `wl'
 local keepn = `nw' - `ncovid'
 local wcut  : word `keepn' of `wl'
 di as err "OPT1: tengo wave <= `wcut' (tolgo le ultime `ncovid' di `nw')"

 egen wtag = tag(pidp_`s')
 count if wtag==1
 di as err "Donne totali = " r(N)
 count if wtag==1 & covid_preg==1
 di as err "  escluse da OPT2 (evento 2020+) = " r(N)
 count if wtag==1 & covid_preg==1 & treated2==1
 di as err "    di cui perdita = " r(N)
 di as err "  anni degli eventi 2020+:"
 tab ev_year if wtag==1 & ev_year>=2020
 drop wtag

 local dvs   "fimnlabgrs_CPI_trim_`s' fimnlabgrs_hrclean_CPI_trim_ln_`s' tot_work_hours_`s' tot_work_hours_cond_ln_trim_`s' employed11_`s'"
 local tags  "earnings wage workhrs workhrs_cond employed"
 local types "U C U C U"
 local nout : word count `tags'

 tempname pf
 postfile `pf' str14 outcome byte model str5 sample byte bin double b double se double t str3 star ///
     using "$rbreg/RB_V15E_AGE46_D19_allcoef.dta", replace

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
    di as err ">>> `tag' (`ty'): N campione costante = " r(N)

    foreach k in 1 5 {
        local cfull "cs"
        local copt2 "cs & covid_preg==0"
        local copt1 "cs & wave <= `wcut'"
        foreach smp in full opt2 opt1 {
            local cond "`c`smp''"
            quietly xtreg `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `m`k'' if `cond', vce(cluster pidp_`s')
            estimates store `smp'_`k'
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
                post `pf' ("`tag'") (`k') ("`smp'") (`j') (`bb') (`se') (`tt') ("`st'")
            }
        }
        capture esttab full_`k' opt2_`k' opt1_`k' using "$rbreg/RB_V15E_AGE46_D19_`tag'_m`k'.csv", replace ///
            keep(*.time_x2_cat4) b(%9.3f) se(%9.3f) plain star(* 0.10 ** 0.05 *** 0.01) stats(N) ///
            mtitles("Full" "OPT2_exclPreg2020" "OPT1_exclFinal4w")
    }

    capture which coefplot
    if !_rc {
        local celab 1.time_x2_cat4 = "25+ before" 3.time_x2_cat4 = "12-1 before" 4.time_x2_cat4 = "0-12 after" 5.time_x2_cat4 = "13-24 after" 6.time_x2_cat4 = "25-36 after" 7.time_x2_cat4 = "37-48 after" 8.time_x2_cat4 = "49-60 after" 9.time_x2_cat4 = "61+ after"
        coefplot ///
          (full_1, keep(*.time_x2_cat4) msymbol(O) mcolor(navy) ciopts(recast(rcap) lcolor(navy))) ///
          (opt2_1, keep(*.time_x2_cat4) msymbol(D) mcolor(cranberry) ciopts(recast(rcap) lcolor(cranberry))) ///
          , vertical baselevels omitted ///
            coeflabels(`celab', labsize(vsmall) angle(45)) ///
            yline(0, lcolor(gs9) lpattern(dash)) ylabel(, labsize(small)) ///
            xtitle("Time relative to pregnancy end", size(small)) ///
            title("`tag' -- full sample vs excluding pandemic-era pregnancies", size(medsmall)) ///
            legend(order(2 "Full sample" 4 "Excl. pandemic-era pregnancies") rows(1) pos(6) size(small)) ///
            graphregion(color(white)) plotregion(color(white)) name(d19_`tag', replace)
        graph export "$rbgra/RB_V15E_AGE46_D19_`tag'_M1.png", replace width(2000)
    }
}
postclose `pf'

 preserve
 use "$rbreg/RB_V15E_AGE46_D19_allcoef.dta", clear
 label define binlab 1 "25+ before" 3 "12-1 before" 4 "0-12 after" 5 "13-24 after" ///
     6 "25-36 after" 7 "37-48 after" 8 "49-60 after" 9 "61+ after"
 label values bin binlab
 order outcome model sample bin b se t star
 export excel using "$rbreg/RB_V15E_AGE46_D19_coefficients.xlsx", firstrow(variables) replace
 di as err "=== xlsx scritto: RB_V15E_AGE46_D19_coefficients.xlsx ==="
 restore

 di as result "D19 (COVID) su v15 fatto. Output RB_V15E_AGE46_D19_* in Regressions_rebuild/ e Graphs_rebuild/."
