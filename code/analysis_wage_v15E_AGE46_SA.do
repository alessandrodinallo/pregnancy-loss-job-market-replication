*==============================================================================================
* analysis_wage_v15E_AGE46_SA.do
*
* Interaction-weighted estimator of Sun and Abraham (2021) for the five outcomes.
* Source of one row of Appendix Table A18.
* Run it after analysis_wage_v15_age46_robust.do, whose coefficients it reads.
*
* Reads:   analysis dataset data/Wage/data_wage_v15.dta (survey data needed);
*          estimates/RB_V15E_AGE46_allcoef.dta
* Writes:  estimates/RB_V15E_AGE46_SAcoef.dta, nested tables (csv) and
*          RB_V15E_AGE46_coefficients_3est.xlsx
*
* Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
* and pregnancy losses. Social Science Research, 141, 103450.
*==============================================================================================

quietly do "config.do"   // folder settings: start Stata in the package folder

clear all
set more off
 global data   ${REPL_DATA}/Wage
 global rbreg  ${REPL_EST}
 local s f
 global demo    c.age_`s'##c.age_`s'  c.income_partner_`s'
 global union   ib1.union_type
 global SES     c.ISEI_`s'##c.ISEI_`s' i.ISEI_miss_`s' ib1.hiqual_`s' soc00_N_wave ib1.private_`s' ib1.nssec5_v2_`s'
 global exp     c.work_exp_`s'##c.work_exp_`s' i.work_exp_miss_`s' c.tenure_`s'##c.tenure_`s' i.tenure_miss_`s'
 global jobend2 c.num_job_end_v2_`s'##c.num_job_end_v2_`s'
 global postj2  i.any_job_end_post_v2_`s'
 global health  c.sf12mcs_std_`s' c.sf12pcs_std_`s'
 local cov1 "$demo $union"
 local cov2 "$demo $union $SES"
 local cov3 "$demo $union $SES $exp $jobend2 $postj2"
 local cov4 "$demo $union $SES $exp $jobend2 $postj2 $health"
 local cov5 "$demo $union $SES $exp $jobend2 $postj2 $health i.time_x3_cat"

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

 gen evw_loss = wave if x2==1
 bysort pidp_`s': egen loss_wave = min(evw_loss)
 gen byte has_loss = !missing(loss_wave)
 keep if has_loss
 quietly summarize loss_wave
 gen byte ctrl = (loss_wave == r(max))
 gen cohort_sa = loss_wave
 replace cohort_sa = . if ctrl
 gen rel = wave - loss_wave
 gen rel_b = rel
 replace rel_b = -3 if rel < -3 & !missing(rel)
 replace rel_b =  5 if rel >  5 & !missing(rel)
 forvalues k = -3/5 {
     if `k' == -2 continue
     local kk = `k' + 3
     gen byte g_`kk' = (rel_b == `k') & !ctrl
     replace  g_`kk' = 0 if ctrl
 }
 local glist g_0 g_2 g_3 g_4 g_5 g_6 g_7 g_8
 xtset pidp_`s' wave

 local dvs   "fimnlabgrs_CPI_trim_`s' fimnlabgrs_hrclean_CPI_trim_ln_`s' tot_work_hours_`s' tot_work_hours_cond_ln_trim_`s' employed11_`s'"
 local tags  "earnings wage workhrs workhrs_cond employed"
 local types "U C U C U"

 tempname pf
 postfile `pf' str14 outcome str6 estim byte model byte bin double b double se double t str3 star ///
     using "$rbreg/RB_V15E_AGE46_SAcoef.dta", replace
 local map3 1
 local map6 5
 local map9 9

forvalues o = 1/5 {
    local dv  : word `o' of `dvs'
    local tag : word `o' of `tags'
    local ty  : word `o' of `types'
    local ifw ""
    if "`ty'" == "C" local ifw "if worker"

    tempname ef
    postfile `ef' str12 bin byte model double b double se using "$rbreg/RB_V15E_AGE46_`tag'_SA_long.dta", replace
    local B0 1
    forvalues m = 1/5 {
        capture eventstudyinteract `dv' `glist' `ifw', cohort(cohort_sa) control_cohort(ctrl) covariates(`cov`m'') absorb(i.pidp_`s' i.wave) vce(cluster pidp_`s')
        if _rc {
            di as error "   SA `tag' M`m' rc=`=_rc'"
            continue
        }
        matrix B = e(b_iw)
        matrix V = e(V_iw)
        foreach g of local glist {
            local kk = subinstr("`g'","g_","",.)
            local bintrue = `kk' + 1
            local bv = B[1,"`g'"]
            local vv = V["`g'","`g'"]
            local se = sqrt(`vv')
            post `ef' ("bin`bintrue'") (`m') (`bv') (`se')
            local t = .
            local st ""
            if `se'<. & `se'>0 {
                local t = `bv'/`se'
                if abs(`t')>1.645 local st "*"
                if abs(`t')>1.96  local st "**"
                if abs(`t')>2.576 local st "***"
            }
            post `pf' ("`tag'") ("SA") (`m') (`bintrue') (`bv') (`se') (`t') ("`st'")
        }
    }
    postclose `ef'
    preserve
    use "$rbreg/RB_V15E_AGE46_`tag'_SA_long.dta", clear
    export delimited using "$rbreg/RB_V15E_AGE46_`tag'_SA_nested.csv", replace
    restore
}
postclose `pf'

 preserve
 use "$rbreg/RB_V15E_AGE46_allcoef.dta", clear
 append using "$rbreg/RB_V15E_AGE46_SAcoef.dta"
 label define binlab 1 "25+ before" 3 "12-1 before" 4 "0-12 after" 5 "13-24 after" ///
     6 "25-36 after" 7 "37-48 after" 8 "49-60 after" 9 "61+ after"
 label values bin binlab
 order outcome estim model bin b se t star
 sort outcome estim model bin
 export excel using "$rbreg/RB_V15E_AGE46_coefficients_3est.xlsx", firstrow(variables) replace
 di as err "=== xlsx a 3 stimatori: RB_V15E_AGE46_coefficients_3est.xlsx ==="
 restore
 di as err "=== output: RB_V15E_AGE46_<outcome>_SA_nested.csv (5) + xlsx 3 estim ==="
