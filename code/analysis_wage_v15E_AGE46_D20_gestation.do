*==============================================================================================
* analysis_wage_v15E_AGE46_D20_gestation.do
*
* Event-study models for all pregnancy losses and for early losses only.
* Source of Appendix Table A17.
* RB_V15E_AGE46_D20_dist.csv has a category with fewer than 20 women: do not share it.
*
* Reads:   analysis dataset data/Wage/data_wage_v15.dta (survey data needed)
* Writes:  estimates/RB_V15E_AGE46_D20 (csv, dta) and RB_V15E_AGE46_D20_dist.csv
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
 global postj2  i.any_job_end_post_v2_`s'
 global health  c.sf12mcs_std_`s' c.sf12pcs_std_`s'
 local m1     $year $demo $union
 local m5     $year $demo $union $SES $exp $jobend2 $postj2 $health i.time_x3_cat

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

 bysort pidp_`s': egen byte late_loss = max(treated2==1 & gestation==2)

 preserve
 egen byte wtag=tag(pidp_`s')
 keep if wtag & treated2==1
 gen byte gcat = gestation
 replace gcat = 3 if missing(gestation)
 lab def gcat 1 "Less than 3 months (early)" 2 "3 months or more (late)" 3 "Unknown timing", replace
 lab val gcat gcat
 di as err "==== PARTE 1: distribuzione gestation, gruppo LOSS (AGE46) ===="
 tab gcat, m
 contract gcat, freq(nobs) percent(pctobs)
 export delimited using "$rbreg/RB_V15E_AGE46_D20_dist.csv", replace
 restore

 local dvs   "fimnlabgrs_CPI_trim_`s' fimnlabgrs_hrclean_CPI_trim_ln_`s' tot_work_hours_`s' tot_work_hours_cond_ln_trim_`s' employed11_`s'"
 local tags  "earnings wage workhrs workhrs_cond employed"
 local types "U C U C U"

 egen byte wtag2=tag(pidp_`s')
 count if wtag2 & treated2==1
 di as err "=== donne LOSS (FULL): " r(N)
 count if wtag2 & treated2==1 & late_loss==0
 di as err "    LOSS EARLY (escl. tardive confermate): " r(N)
 drop wtag2

 tempname pf
 postfile `pf' str14 outcome str10 spec byte bin double b double se double t str3 star ///
     using "$rbreg/RB_V15E_AGE46_D20.dta", replace

forvalues o=1/5 {
    local dv : word `o' of `dvs'
    local tag: word `o' of `tags'
    local ty : word `o' of `types'
    local ss ""
    if "`ty'"=="C" local ss "& worker"
    foreach samp in FULL EARLY {
        local cond ""
        if "`samp'"=="EARLY" local cond "& late_loss==0"
        quietly xtreg `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `m5' if 1 `ss' `cond', vce(cluster pidp_`s')
        capture drop cs
        gen byte cs=e(sample)
        foreach spec in M1 M5 {
            if "`spec'"=="M1" local mm "`m1'"
            if "`spec'"=="M5" local mm "`m5'"
            quietly xtreg `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `mm' if cs, vce(cluster pidp_`s')
            forvalues j=1/9 {
                if `j'==2 continue
                local bb=_b[`j'.time_x2_cat4]
                local se=_se[`j'.time_x2_cat4]
                local tt=.
                local st=""
                if `se'<. & `se'>0 {
                    local tt=`bb'/`se'
                    if abs(`tt')>1.645 local st "*"
                    if abs(`tt')>1.96  local st "**"
                    if abs(`tt')>2.576 local st "***"
                }
                post `pf' ("`tag'") ("`samp'_`spec'") (`j') (`bb') (`se') (`tt') ("`st'")
            }
        }
    }
}
postclose `pf'

 preserve
 use "$rbreg/RB_V15E_AGE46_D20.dta", clear
 export delimited using "$rbreg/RB_V15E_AGE46_D20.csv", replace
 di as err "=== D20: FULL vs EARLY (wage & earnings, 0-12/25-36/61+) ==="
 keep if inlist(bin,4,6,9) & inlist(outcome,"wage","earnings")
 gen bl=cond(bin==4,"0-12",cond(bin==6,"25-36","61+"))
 sort outcome bl spec
 list outcome bl spec b t star, noobs sepby(outcome bl)
 restore
 di as err "=== output: RB_V15E_AGE46_D20.csv/.dta + _dist.csv ==="
