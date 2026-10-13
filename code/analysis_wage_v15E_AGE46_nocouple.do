*==============================================================================================
* analysis_wage_v15E_AGE46_nocouple.do
*
* Model 1 with and without the controls measured at the level of the couple.
* Source of Appendix Table A19.
*
* Reads:   analysis dataset data/Wage/data_wage_v15.dta (survey data needed)
* Writes:  estimates/RB_V15E_AGE46_NOCOUPLE (csv, dta) and RB_V15E_AGE46_NOCOUPLE_N.csv
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
 global demoNC  c.age_`s'##c.age_`s'
 global year    ib2011.year i.gor_`s'
 global union   ib1.union_type
 local m1    $year $demo $union
 local m1nc  $year $demoNC

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

 local dvs   "fimnlabgrs_CPI_trim_`s' fimnlabgrs_hrclean_CPI_trim_ln_`s'"
 local tags  "earnings wage"
 local types "U C"

 tempname pf pn
 postfile `pf' str14 outcome byte grp str5 spec byte bin double b double se double t str3 star ///
     using "$rbreg/RB_V15E_AGE46_NOCOUPLE.dta", replace
 postfile `pn' str14 outcome long nobs long nwomen ///
     using "$rbreg/RB_V15E_AGE46_NOCOUPLE_N.dta", replace

forvalues o=1/2 {
    local dv : word `o' of `dvs'
    local tag: word `o' of `tags'
    local ty : word `o' of `types'
    local ss ""
    if "`ty'"=="C" local ss "& worker"
    quietly xtreg `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `m1' if 1 `ss', vce(cluster pidp_`s')
    capture drop cs
    gen byte cs=e(sample)
    post `pn' ("`tag'") (e(N)) (e(N_g))
    foreach spec in M1 M1nc {
        if "`spec'"=="M1"   quietly xtreg `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `m1'   if cs, vce(cluster pidp_`s')
        if "`spec'"=="M1nc" quietly xtreg `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `m1nc' if cs, vce(cluster pidp_`s')
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
                post `pf' ("`tag'") (`g') ("`spec'") (`j') (`bb') (`se') (`tt') ("`st'")
            }
        }
    }
}
postclose `pf'
postclose `pn'

 preserve
 use "$rbreg/RB_V15E_AGE46_NOCOUPLE.dta", clear
 export delimited using "$rbreg/RB_V15E_AGE46_NOCOUPLE.csv", replace
 restore
 preserve
 use "$rbreg/RB_V15E_AGE46_NOCOUPLE_N.dta", clear
 export delimited using "$rbreg/RB_V15E_AGE46_NOCOUPLE_N.csv", replace
 restore

 preserve
 use "$rbreg/RB_V15E_AGE46_NOCOUPLE.dta", clear
 keep if grp==2 & inlist(bin,4,6,9)
 gen bl=cond(bin==4,"0-12",cond(bin==6,"25-36","61+"))
 gen str16 cell = string(b,cond(outcome=="wage","%9.3f","%9.2f"))+star
 keep outcome bl bin spec cell
 reshape wide cell, i(outcome bin bl) j(spec) string
 sort outcome bin
 di as err "=== LOSS group: M1 (con coppia) vs M1nc (senza coppia) ==="
 list outcome bl cellM1 cellM1nc, noobs sepby(outcome)
 restore
 di as err "=== output: RB_V15E_AGE46_NOCOUPLE.csv/.dta + _N.csv ==="
