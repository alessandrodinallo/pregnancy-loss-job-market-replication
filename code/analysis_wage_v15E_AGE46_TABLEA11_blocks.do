*==============================================================================================
* analysis_wage_v15E_AGE46_TABLEA11_blocks.do
*
* Model 1 plus one block of mechanisms at a time, labour income and hourly wage.
* Source of Table 2 and Appendix Tables A11 and A12.
*
* Reads:   analysis dataset data/Wage/data_wage_v15.dta (survey data needed)
* Writes:  estimates/RB_V15E_AGE46_TABLEA11 (csv, dta) and RB_V15E_AGE46_TABLEA11_N.csv
*
* Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
* and pregnancy losses. Social Science Research, 141, 103450.
*==============================================================================================

quietly do "config.do"   // folder settings: start Stata in the package folder

clear all
set more off
 global data  ${REPL_DATA}/Wage
 global rbreg ${REPL_EST}
 local s f
 global demo    c.age_`s'##c.age_`s'  c.income_partner_`s'
 global year    ib2011.year i.gor_`s'
 global union   ib1.union_type
 global SES     c.ISEI_`s'##c.ISEI_`s' i.ISEI_miss_`s' ib1.hiqual_`s' soc00_N_wave ib1.private_`s' ib1.nssec5_v2_`s'
 global exp     c.work_exp_`s'##c.work_exp_`s' i.work_exp_miss_`s' c.tenure_`s'##c.tenure_`s' i.tenure_miss_`s'
 global jobend2 c.num_job_end_v2_`s'##c.num_job_end_v2_`s'
 global postj2 i.any_job_end_post_v2_`s'
 global health  c.sf12mcs_std_`s' c.sf12pcs_std_`s'
 local base   $year $demo $union
 local career $exp $jobend2 $postj2
 local hcap   $SES
 local heal   $health
 local mother i.time_x3_cat
 local b1 `base' `career'
 local b2 `base' `hcap'
 local b3 `base' `heal'
 local b4 `base' `mother'
 local b5 `base' `mother' `career' `hcap' `heal'

 use "$data/data_wage_v15.dta", clear
 drop if wave==.
 duplicates tag pidp_`s' wave, gen(dup)
 bysort pidp_`s' wave: gen n_pw=_n
 drop if n_pw>1 & dup>0
 drop dup n_pw
 keep if x1!=. & x2!=. & age_event>=18 & age_event<46 & (treated1==1|treated2==1) ///
       & first_wave_worked<=min_wave_t & first_wave_worked!=. & self_employed1_`s'==0
 gen byte worker=!missing(fimnlabgrs_hrclean_CPI_trim_ln_`s') & !missing(tot_work_hours_cond_ln_trim_`s')
 xtset pidp_`s' wave

 local dvs   "fimnlabgrs_CPI_trim_`s' fimnlabgrs_hrclean_CPI_trim_ln_`s'"
 local tags  "earnings wage"
 local types "U C"

 tempname pf pn
 postfile `pf' str14 outcome byte grp byte model byte bin double b double se double t str3 star ///
     using "$rbreg/RB_V15E_AGE46_TABLEA11.dta", replace
 postfile `pn' str14 outcome byte model long nobs long nwomen ///
     using "$rbreg/RB_V15E_AGE46_TABLEA11_N.dta", replace

forvalues o=1/2 {
    local dv : word `o' of `dvs'
    local tag: word `o' of `tags'
    local ty : word `o' of `types'
    local ss ""
    if "`ty'"=="C" local ss "& worker"
    quietly xtreg `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `b5' if 1 `ss', vce(cluster pidp_`s')
    capture drop cs
    gen byte cs=e(sample)
    forvalues k=1/5 {
        quietly xtreg `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `b`k'' if cs, vce(cluster pidp_`s')
        post `pn' ("`tag'") (`k') (e(N)) (e(N_g))
        forvalues g=1/2 {
            forvalues j=1/9 {
                if `j'==2 continue
                local bb=_b[`j'.time_x`g'_cat4]
                local se=_se[`j'.time_x`g'_cat4]
                local tt=.
                local st=""
                if `se'<. & `se'>0 {
                    local tt=`bb'/`se'
                    if abs(`tt')>1.645 local st "+"
                    if abs(`tt')>1.96  local st "*"
                    if abs(`tt')>2.576 local st "**"
                    if abs(`tt')>3.291 local st "***"
                }
                post `pf' ("`tag'") (`g') (`k') (`j') (`bb') (`se') (`tt') ("`st'")
            }
        }
    }
}
postclose `pf'
postclose `pn'

 preserve
 use "$rbreg/RB_V15E_AGE46_TABLEA11.dta", clear
 export delimited using "$rbreg/RB_V15E_AGE46_TABLEA11.csv", replace
 restore
 preserve
 use "$rbreg/RB_V15E_AGE46_TABLEA11_N.dta", clear
 export delimited using "$rbreg/RB_V15E_AGE46_TABLEA11_N.csv", replace
 di as err "=== N per modello ==="
 list outcome model nobs nwomen, noobs sepby(outcome)
 restore

 preserve
 use "$rbreg/RB_V15E_AGE46_TABLEA11.dta", clear
 keep if grp==2 & inlist(bin,4,6,9)
 gen bl=cond(bin==4,"0-12",cond(bin==6,"25-36","61+"))
 gen str16 cell = string(b,"%9.3f")+star
 keep outcome bl bin model cell
 reshape wide cell, i(outcome bin bl) j(model)
 sort outcome bin
 di as err "=== LOSS group: (1)+career (2)+hcap (3)+health (4)+mother (5)full ==="
 list outcome bl cell1 cell2 cell3 cell4 cell5, noobs sepby(outcome)
 restore
 di as err "=== output: RB_V15E_AGE46_TABLEA11.csv/.dta + _N.csv ==="
