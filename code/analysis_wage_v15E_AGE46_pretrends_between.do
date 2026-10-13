*==============================================================================================
* analysis_wage_v15E_AGE46_pretrends_between.do
*
* Tests that the pre-conception event-time coefficients of the two groups are equal.
* Source of Panel C of Appendix Table A13.
*
* Reads:   analysis dataset data/Wage/data_wage_v15.dta (survey data needed)
* Writes:  estimates/RB_V15E_AGE46_pretrends_between (csv, dta)
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
 postfile `pf' str14 outcome double clean_chi2 double clean_p double joint_chi2 double joint_p ///
     using "$rbreg/RB_V15E_AGE46_pretrends_between.dta", replace

forvalues o = 1/`nout' {
    local dv  : word `o' of `dvs'
    local tag : word `o' of `tags'
    local ty  : word `o' of `types'
    local ss ""
    if "`ty'" == "C" local ss "if worker"
    quietly xtreg `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `m1' `ss', vce(cluster pidp_`s')
    quietly test 1.time_x2_cat4 = 1.time_x1_cat4
    local cc = r(chi2)
    local cp = r(p)
    quietly test (1.time_x2_cat4 = 1.time_x1_cat4) (3.time_x2_cat4 = 3.time_x1_cat4)
    local jc = r(chi2)
    local jp = r(p)
    post `pf' ("`tag'") (`cc') (`cp') (`jc') (`jp')
}
postclose `pf'

 preserve
 use "$rbreg/RB_V15E_AGE46_pretrends_between.dta", clear
 format clean_chi2 joint_chi2 %6.2f
 format clean_p joint_p %6.3f
 di as err "=== BETWEEN-group pre-trend test (alto p = traiettorie parallele) ==="
 di as err "    joint_p = test principale (bin 1 & 3); atteso ~0.42-0.71"
 list outcome clean_chi2 clean_p joint_chi2 joint_p, noobs
 export delimited using "$rbreg/RB_V15E_AGE46_pretrends_between.csv", replace
 di as err "=== output: RB_V15E_AGE46_pretrends_between.csv / .dta ==="
 restore
