*==============================================================================================
* analysis_wage_v15E_AGE46_pretrends.do
*
* Tests of the pre-conception event-time coefficients within each group.
* Source of Panel B of Appendix Table A13.
*
* Reads:   analysis dataset data/Wage/data_wage_v15.dta (survey data needed)
* Writes:  estimates/RB_V15E_AGE46_pretrends (csv, dta)
*
* Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
* and pregnancy losses. Social Science Research, 141, 103450.
*==============================================================================================

quietly do "config.do"   // folder settings: start Stata in the package folder

clear all
set more off
 global data  ${REPL_DATA}/Wage
 global rbreg ${REPL_EST}
 capture mkdir "$rbreg"
 local s f
 global demo    c.age_`s'##c.age_`s'  c.income_partner_`s'
 global year    ib2011.year i.gor_`s'
 global union   ib1.union_type
 local m1 $year $demo $union

 use "$data/data_wage_v15.dta", clear
 drop if wave == .
 duplicates tag pidp_`s' wave, gen(dup)
 bysort pidp_`s' wave: gen n_pw = _n
 drop if n_pw > 1 & dup > 0
 drop dup n_pw
 keep if x1 !=. & x2 !=. & age_event>=18 & age_event<46 & (treated1==1|treated2==1) ///
       & first_wave_worked <= min_wave_t & first_wave_worked !=. & self_employed1_`s' == 0
 gen byte worker = !missing(fimnlabgrs_hrclean_CPI_trim_ln_`s') & !missing(tot_work_hours_cond_ln_trim_`s')
 xtset pidp_`s' wave

 local dvs   "fimnlabgrs_CPI_trim_`s' fimnlabgrs_hrclean_CPI_trim_ln_`s' tot_work_hours_`s' tot_work_hours_cond_ln_trim_`s' employed11_`s'"
 local tags  "earnings wage workhrs workhrs_cond employed"
 local types "U C U C U"
 local nout : word count `tags'

 tempname pf
 postfile `pf' str14 outcome str10 group double clean_b double clean_se double clean_p ///
     double joint_chi2 double joint_p using "$rbreg/RB_V15E_AGE46_pretrends.dta", replace

forvalues o = 1/`nout' {
    local dv  : word `o' of `dvs'
    local tag : word `o' of `tags'
    local ty  : word `o' of `types'
    local ss ""
    if "`ty'" == "C" local ss "if worker"
    quietly xtreg `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `m1' `ss', vce(cluster pidp_`s')

    foreach g in x1 x2 {
        local gname = cond("`g'"=="x1","live_birth","loss")
        local cb  = _b[1.time_`g'_cat4]
        local cse = _se[1.time_`g'_cat4]
        local cp  = 2*normal(-abs(`cb'/`cse'))
        quietly test 1.time_`g'_cat4 3.time_`g'_cat4
        local jc = r(chi2)
        local jp = r(p)
        post `pf' ("`tag'") ("`gname'") (`cb') (`cse') (`cp') (`jc') (`jp')
    }
}
postclose `pf'

 use "$rbreg/RB_V15E_AGE46_pretrends.dta", clear
 format clean_b clean_se %9.4f
 format clean_p joint_chi2 joint_p %6.3f
 di as err "=== PRE-EVENT COMPARABILITY (M1, full sample). CLEAN lead = '25+ before' (bin1). ==="
 di as err "    high clean_p / joint_p = flat pre-trend. bin3 '12-1 before' e' tarda gravidanza."
 list outcome group clean_b clean_p joint_chi2 joint_p, noobs sepby(outcome)
 export delimited using "$rbreg/RB_V15E_AGE46_pretrends.csv", replace
 di as err "=== output: RB_V15E_AGE46_pretrends.csv / .dta in $rbreg ==="
