*==============================================================================================
* analysis_wage_v15E_AGE46_D17_nofuturebirth.do
*
* Event-study models on the full sample and excluding women with a subsequent birth.
* Source of Appendix Figure A8.
*
* Reads:   analysis dataset data/Wage/data_wage_v15.dta (survey data needed)
* Writes:  estimates/RB_V15E_AGE46_D17 (csv, dta)
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
 local m5nb   $year $demo $union $SES $exp $jobend2 $postj2 $health

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

 bysort pidp_`s': egen byte ever_sb = max(time_x3_cat)

 egen byte wtag=tag(pidp_`s')
 count if wtag
 di as err "=== donne totali (FULL): " r(N)
 count if wtag & ever_sb==0
 di as err "    di cui SENZA parto successivo (NOBIRTH): " r(N)
 count if wtag & treated2==1
 di as err "=== donne gruppo LOSS (FULL): " r(N)
 count if wtag & treated2==1 & ever_sb==0
 di as err "    LOSS senza parto successivo (NOBIRTH): " r(N)
 drop wtag

 local dvs   "fimnlabgrs_CPI_trim_`s' fimnlabgrs_hrclean_CPI_trim_ln_`s' tot_work_hours_`s' tot_work_hours_cond_ln_trim_`s' employed11_`s'"
 local tags  "earnings wage workhrs workhrs_cond employed"
 local types "U C U C U"

 tempname pf
 postfile `pf' str14 outcome str12 spec byte bin double b double se double t str3 star ///
     using "$rbreg/RB_V15E_AGE46_D17.dta", replace

forvalues o=1/5 {
    local dv : word `o' of `dvs'
    local tag: word `o' of `tags'
    local ty : word `o' of `types'
    local ss ""
    if "`ty'"=="C" local ss "& worker"
    foreach samp in FULL NOBIRTH {
        local cond ""
        if "`samp'"=="NOBIRTH" local cond "& ever_sb==0"
        if "`samp'"=="FULL"    local mdem "`m5'"
        if "`samp'"=="NOBIRTH" local mdem "`m5nb'"
        quietly xtreg `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `mdem' if 1 `ss' `cond', vce(cluster pidp_`s')
        capture drop cs
        gen byte cs=e(sample)
        foreach spec in M1 M5 {
            if "`spec'"=="M1"                        local mm "`m1'"
            if "`spec'"=="M5" & "`samp'"=="FULL"     local mm "`m5'"
            if "`spec'"=="M5" & "`samp'"=="NOBIRTH"  local mm "`m5nb'"
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
 use "$rbreg/RB_V15E_AGE46_D17.dta", clear
 export delimited using "$rbreg/RB_V15E_AGE46_D17.csv", replace
 di as err "=== D17: FULL vs NOBIRTH (wage & earnings, 0-12/25-36/61+) ==="
 keep if inlist(bin,4,6,9) & inlist(outcome,"wage","earnings")
 gen bl=cond(bin==4,"0-12",cond(bin==6,"25-36","61+"))
 sort outcome bl spec
 list outcome bl spec b t star, noobs sepby(outcome bl)
 restore
 di as err "=== output: RB_V15E_AGE46_D17.csv/.dta ==="
