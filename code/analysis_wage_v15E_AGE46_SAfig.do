*==============================================================================================
* analysis_wage_v15E_AGE46_SAfig.do
*
* Interaction-weighted estimator of Sun and Abraham (2021), both groups.
* Source of Appendix Figures A9 and A11.
*
* Reads:   analysis dataset data/Wage/data_wage_v15.dta (survey data needed)
* Writes:  estimates/RB_V15E_AGE46_SAfig (csv, dta)
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
 global demo  c.age_`s'##c.age_`s'  c.income_partner_`s'
 global union ib1.union_type

 use "$data/data_wage_v15.dta", clear
 drop if wave==.
 duplicates tag pidp_`s' wave, gen(dup)
 bysort pidp_`s' wave: gen n_pw=_n
 drop if n_pw>1 & dup>0
 drop dup n_pw
 keep if x1!=. & x2!=. & age_event>=18 & age_event<46 & (treated1==1|treated2==1) ///
       & first_wave_worked<=min_wave_t & first_wave_worked!=. & self_employed1_`s'==0
 gen byte worker = !missing(fimnlabgrs_hrclean_CPI_trim_ln_`s') & !missing(tot_work_hours_cond_ln_trim_`s')

 local dvs   "fimnlabgrs_CPI_trim_`s' fimnlabgrs_hrclean_CPI_trim_ln_`s' tot_work_hours_`s' tot_work_hours_cond_ln_trim_`s' employed11_`s'"
 local tags  "earnings wage workhrs workhrs_cond employed"
 local types "U C U C U"

 tempname M
 postfile `M' str6 estim str14 outcome byte model byte grp byte bin double b se ///
     using "$rbreg/RB_V15E_AGE46_SAfig.dta", replace

 foreach grp in 2 1 {
     preserve
     if `grp'==2  gen evw = wave if x2==1
     else         gen evw = wave if x1==1
     bysort pidp_`s': egen ev_wave = min(evw)
     keep if !missing(ev_wave)
     quietly summarize ev_wave
     gen byte ctrl = (ev_wave==r(max))
     gen cohort_sa = ev_wave
     replace cohort_sa = . if ctrl
     gen rel = wave - ev_wave
     gen rel_b = rel
     replace rel_b = -3 if rel<-3 & !missing(rel)
     replace rel_b =  5 if rel> 5 & !missing(rel)
     forvalues k=-3/5 {
         if `k'==-2 continue
         local kk=`k'+3
         gen byte g_`kk' = (rel_b==`k') & !ctrl
         replace  g_`kk' = 0 if ctrl
     }
     local glist g_0 g_2 g_3 g_4 g_5 g_6 g_7 g_8
     xtset pidp_`s' wave
     forvalues o=1/5 {
         local dv  : word `o' of `dvs'
         local tag : word `o' of `tags'
         local ty  : word `o' of `types'
         local ifw ""
         if "`ty'"=="C" local ifw "if worker"
         capture eventstudyinteract `dv' `glist' `ifw', cohort(cohort_sa) control_cohort(ctrl) covariates($demo $union) absorb(i.pidp_`s' i.wave) vce(cluster pidp_`s')
         if _rc {
             di as error "   SA `tag' grp`grp' rc=`=_rc'"
             continue
         }
         matrix B = e(b_iw)
         matrix V = e(V_iw)
         foreach g of local glist {
             local kk = subinstr("`g'","g_","",.)
             local bintrue = `kk' + 1
             local bv = B[1,"`g'"]
             local se = sqrt(V["`g'","`g'"])
             post `M' ("SA") ("`tag'") (1) (`grp') (`bintrue') (`bv') (`se')
         }
     }
     restore
 }
 postclose `M'
 use "$rbreg/RB_V15E_AGE46_SAfig.dta", clear
 export delimited using "$rbreg/RB_V15E_AGE46_SAfig.csv", replace
 di as result "=== SAfig DONE: rows=" _N " ==="
 table outcome grp if bin==9, statistic(mean b)
