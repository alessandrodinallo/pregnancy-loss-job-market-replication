*==============================================================================================
* analysis_wage_v15E_AGE46_D18_ebal.do
*
* Entropy-balancing weights on pre-conception covariates, and the event-study models with
* and without them. Source of Appendix Table B1; Appendix Figures B1 and B2 use the same weights.
*
* Reads:   analysis dataset data/Wage/data_wage_v15.dta (survey data needed)
* Writes:  estimates/RB_V15E_AGE46_D18 (csv, dta) and RB_V15E_AGE46_D18_balance (csv, dta)
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
 drop if treated1==1 & treated2==1
 gen byte worker=!missing(fimnlabgrs_hrclean_CPI_trim_ln_`s') & !missing(tot_work_hours_cond_ln_trim_`s')
 xtset pidp_`s' wave

 gen byte loss = (treated2==1)

 gen byte pre = (treated1==1 & inlist(time_x1_cat4,1,2)) | (treated2==1 & inlist(time_x2_cat4,1,2))
 foreach v in age_`s' fimnlabgrs_CPI_trim_`s' employed11_`s' tot_work_hours_`s' income_partner_`s' {
     gen double `v'_pre = `v' if pre
     bysort pidp_`s': egen b_`v' = mean(`v'_pre)
     drop `v'_pre
 }
 local bcovs b_age_`s' b_fimnlabgrs_CPI_trim_`s' b_employed11_`s' b_tot_work_hours_`s' b_income_partner_`s'
 egen byte nmiss = rowmiss(`bcovs')
 gen byte hasbase = (nmiss==0)
 drop nmiss

 preserve
 egen byte wtag=tag(pidp_`s')
 keep if wtag & hasbase
 di as err "==== N donne per gruppo (has-baseline) ===="
 tab loss
 ebalance loss `bcovs', generate(webal_w)
 keep pidp_`s' webal_w
 tempfile W
 save `W'
 restore
 merge m:1 pidp_`s' using `W', nogen
 rename webal_w webal
 assert !missing(webal) if hasbase

 egen byte wtag=tag(pidp_`s')
 preserve
 keep if wtag & hasbase
 tempname B
 postfile `B' str32 covar double sd_unw double sd_wtd using "$rbreg/RB_V15E_AGE46_D18_balance.dta", replace
 foreach v of local bcovs {
     quietly summ `v' if loss==1
     local m1l=r(mean)
     local v1l=r(Var)
     quietly summ `v' if loss==0
     local m0l=r(mean)
     local v0l=r(Var)
     local sdu = (`m1l'-`m0l')/sqrt((`v1l'+`v0l')/2)
     quietly summ `v' [aw=webal] if loss==0
     local m0w=r(mean)
     local sdw = (`m1l'-`m0w')/sqrt((`v1l'+`v0l')/2)
     post `B' ("`v'") (`sdu') (`sdw')
 }
 postclose `B'
 quietly summ webal if loss==0
 local sw=r(sum)
 gen double w2=webal^2 if loss==0
 quietly summ w2
 local sw2=r(sum)
 local ess = (`sw'^2)/`sw2'
 quietly count if loss==0
 di as err "==== ESS controlli (parti): " %6.1f `ess' " su " r(N) " (frazione " %4.3f `ess'/r(N) ") ===="
 use "$rbreg/RB_V15E_AGE46_D18_balance.dta", clear
 export delimited using "$rbreg/RB_V15E_AGE46_D18_balance.csv", replace
 di as err "==== balance table (std diff pre/post pesi) ===="
 list, noobs
 restore
 drop wtag

 local dvs   "fimnlabgrs_CPI_trim_`s' fimnlabgrs_hrclean_CPI_trim_ln_`s' tot_work_hours_`s' tot_work_hours_cond_ln_trim_`s' employed11_`s'"
 local tags  "earnings wage workhrs workhrs_cond employed"
 local types "U C U C U"

 tempname pf
 postfile `pf' str14 outcome str8 spec byte bin double b double se double t str3 star ///
     using "$rbreg/RB_V15E_AGE46_D18.dta", replace

forvalues o=1/5 {
    local dv : word `o' of `dvs'
    local tag: word `o' of `tags'
    local ty : word `o' of `types'
    local ss ""
    if "`ty'"=="C" local ss "& worker"
    quietly xtreg `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `m5' if hasbase `ss', vce(cluster pidp_`s')
    capture drop cs
    gen byte cs=e(sample)
    foreach k in 1 5 {
        foreach w in UNW EBAL {
            if "`w'"=="UNW"  quietly reghdfe `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `m`k'' if cs, absorb(pidp_`s' wave) vce(cluster pidp_`s')
            if "`w'"=="EBAL" quietly reghdfe `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `m`k'' [pw=webal] if cs, absorb(pidp_`s' wave) vce(cluster pidp_`s')
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
                post `pf' ("`tag'") ("`w'_M`k'") (`j') (`bb') (`se') (`tt') ("`st'")
            }
        }
    }
}
postclose `pf'

 preserve
 use "$rbreg/RB_V15E_AGE46_D18.dta", clear
 export delimited using "$rbreg/RB_V15E_AGE46_D18.csv", replace
 di as err "=== D18: UNW vs EBAL (wage & earnings, 0-12/25-36/61+) ==="
 keep if inlist(bin,4,6,9) & inlist(outcome,"wage","earnings")
 gen bl=cond(bin==4,"0-12",cond(bin==6,"25-36","61+"))
 sort outcome bl spec
 list outcome bl spec b t star, noobs sepby(outcome bl)
 restore
 di as err "=== output: RB_V15E_AGE46_D18.csv/.dta + _balance.csv ==="
