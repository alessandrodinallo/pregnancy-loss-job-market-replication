*==============================================================================================
* analysis_wage_v15E_AGE46_TWFEfig.do
*
* Two-way fixed-effects event-study models, both groups.
* Source of Appendix Figures A9 and A10.
*
* Reads:   analysis dataset data/Wage/data_wage_v15.dta (survey data needed)
* Writes:  estimates/RB_V15E_AGE46_TWFEfig (csv, dta)
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
 capture confirm variable any_job_end_post_`s'
 if !_rc  global postj2 i.any_job_end_post_`s'
 else     global postj2 i.any_job_end_post_v2_`s'
 global health  c.sf12mcs_std_`s' c.sf12pcs_std_`s'
 local m1 $year $demo $union
 local m5 $year $demo $union $SES $exp $jobend2 $postj2 $health i.time_x3_cat

 use "$data/data_wage_v15.dta", clear
 drop if wave==.
 duplicates tag pidp_`s' wave, gen(dup)
 bysort pidp_`s' wave: gen n_pw=_n
 drop if n_pw>1 & dup>0
 drop dup n_pw
 keep if x1!=. & x2!=. & age_event>=18 & age_event<46 & (treated1==1|treated2==1) ///
       & first_wave_worked<=min_wave_t & first_wave_worked!=. & self_employed1_`s'==0
 xtset pidp_`s' wave

 local dvs   "fimnlabgrs_CPI_trim_`s' fimnlabgrs_hrclean_CPI_trim_ln_`s' tot_work_hours_`s' tot_work_hours_cond_ln_trim_`s' employed11_`s'"
 local names "earnings wage workhrs workhrs_cond employed"

 tempname M
 postfile `M' str6 estim str14 outcome byte model byte grp byte bin double b se ///
    using "$rbreg/RB_V15E_AGE46_TWFEfig.dta", replace

 local no : word count `dvs'
 forval o=1/`no' {
     local dv  : word `o' of `dvs'
     local nm  : word `o' of `names'
     quietly reghdfe `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `m5', absorb(pidp_`s' wave) vce(cluster pidp_`s')
     capture drop cs
     gen byte cs = e(sample)
     foreach k in 1 5 {
         quietly reghdfe `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `m`k'' if cs, absorb(pidp_`s' wave) vce(cluster pidp_`s')
         forval bb=1/9 {
             foreach gg in 1 2 {
                 capture local bcoef = _b[`bb'.time_x`gg'_cat4]
                 if !_rc {
                     local scoef = _se[`bb'.time_x`gg'_cat4]
                     post `M' ("TWFE") ("`nm'") (`k') (`gg') (`bb') (`bcoef') (`scoef')
                 }
             }
         }
     }
 }
 postclose `M'
 use "$rbreg/RB_V15E_AGE46_TWFEfig.dta", clear
 export delimited using "$rbreg/RB_V15E_AGE46_TWFEfig.csv", replace
 di as result "=== TWFEfig DONE: rows=" _N " ==="
 table outcome model if grp==2 & bin==9, statistic(mean b)
