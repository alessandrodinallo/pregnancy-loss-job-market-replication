*==============================================================================================
* analysis_wage_v15E_AGE46_TABLE1.do
*
* Event-study models for the five outcomes, both groups, Models 1 to 5.
* Source of Tables 1 and 2, Figures 1 and 2 and Appendix Tables A6 to A10.
*
* Reads:   analysis dataset data/Wage/data_wage_v15.dta (survey data needed)
* Writes:  estimates/RB_V15E_AGE46_TABLE1 (csv, dta) and RB_V15E_AGE46_TABLE1_N.csv
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
 local mother i.time_x3_cat
 local career $exp $jobend2 $postj2
 local hcap   $SES
 local prod   $health
 local m1 $year $demo $union
 local m2 $year $demo $union `mother'
 local m3 $year $demo $union `mother' `career'
 local m4 $year $demo $union `mother' `career' `hcap'
 local m5 $year $demo $union `mother' `career' `hcap' `prod'

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

 local dvs   "fimnlabgrs_CPI_trim_`s' fimnlabgrs_hrclean_CPI_trim_ln_`s' tot_work_hours_`s' tot_work_hours_cond_ln_trim_`s' employed11_`s'"
 local tags  "earnings wage workhrs workhrs_cond employed"
 local types "U C U C U"

 tempname pf pn
 postfile `pf' str14 outcome byte grp byte model byte bin double b double se double t str3 star ///
     using "$rbreg/RB_V15E_AGE46_TABLE1.dta", replace
 postfile `pn' str14 outcome byte model long nobs long nwomen ///
     using "$rbreg/RB_V15E_AGE46_TABLE1_N.dta", replace

forvalues o=1/5 {
    local dv : word `o' of `dvs'
    local tag: word `o' of `tags'
    local ty : word `o' of `types'
    local ss ""
    if "`ty'"=="C" local ss "& worker"
    quietly xtreg `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `m5' if 1 `ss', vce(cluster pidp_`s')
    capture drop cs
    gen byte cs=e(sample)
    forvalues k=1/5 {
        quietly xtreg `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `m`k'' if cs, vce(cluster pidp_`s')
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
 use "$rbreg/RB_V15E_AGE46_TABLE1.dta", clear
 export delimited using "$rbreg/RB_V15E_AGE46_TABLE1.csv", replace
 restore
 preserve
 use "$rbreg/RB_V15E_AGE46_TABLE1_N.dta", clear
 export delimited using "$rbreg/RB_V15E_AGE46_TABLE1_N.csv", replace
 di as err "=== N per modello (earnings) ==="
 list model nobs nwomen if outcome=="earnings", noobs
 restore

 preserve
 use "$rbreg/RB_V15E_AGE46_TABLE1.dta", clear
 keep if outcome=="earnings"
 gen str12 blab = ""
 replace blab="25+ before"  if bin==1
 replace blab="12/1 before" if bin==3
 replace blab="0/12 after"  if bin==4
 replace blab="13/24 after" if bin==5
 replace blab="25/36 after" if bin==6
 replace blab="37/48 after" if bin==7
 replace blab="49/60 after" if bin==8
 replace blab="61+ after"   if bin==9
 gen str16 cell = string(b,"%9.2f")+star
 keep grp bin blab model cell
 reshape wide cell, i(grp bin blab) j(model)
 sort grp bin
 di as err "=== TABLE 1 (earnings) grp1=live birth, grp2=loss : b+star per M1..M5 ==="
 list grp blab cell1 cell2 cell3 cell4 cell5, noobs sepby(grp)
 restore
 di as err "=== output: RB_V15E_AGE46_TABLE1.csv/.dta + _N.csv ==="
