*==============================================================================================
* analysis_wage_v15E_AGE46_A2A5_descriptives.do
*
* Descriptive statistics by event-time period, for women and their partners, by group.
* Source of Appendix Tables A2 to A5.
*
* Reads:   analysis dataset data/Wage/data_wage_v15.dta (survey data needed)
* Writes:  estimates/RB_V15E_AGE46_A2A5_descriptives (csv, dta)
*
* Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
* and pregnancy losses. Social Science Research, 141, 103450.
*==============================================================================================

quietly do "config.do"   // folder settings: start Stata in the package folder

clear all
set more off
 global data  ${REPL_DATA}/Wage
 global rbreg ${REPL_EST}

 use "$data/data_wage_v15.dta", clear
 drop if wave==.
 duplicates tag pidp_f wave, gen(dup)
 bysort pidp_f wave: gen n_pw=_n
 drop if n_pw>1 & dup>0
 drop dup n_pw
 keep if x1!=. & x2!=. & age_event>=18 & age_event<46 & (treated1==1|treated2==1) ///
       & first_wave_worked<=min_wave_t & first_wave_worked!=. & self_employed1_f==0

 local rstub "fimnlabnet_CPI fimnlabnet_hrwage_CPI employed1 tot_work_hours FT_uncond maternity sick sf12mcs_std sf12pcs_std age union degree less_edu managers low_skilled work_exp num_job_end_v2 any_job_end_post_v2"
 local rlab  `""Monthly income" "Hourly wage" "Employed" "Work hours" "Full time" "Parental leave" "Sickness leave" "Mental health" "Physical health" "Age" "In partnership" "Tertiary education" "Secondary educ. or less" "Manager" "Low-skilled" "Work experience (years)" "Number of job stops" "Any post-pregnancy job stops""'
 * partner variable stubs + labels
 local pstub "age degree less_edu managers low_skilled unemployed"
 local plab  `""Age" "Tertiary education" "Secondary educ. or less" "Manager" "Low-skilled" "Unemployed""'

 tempname M
 postfile `M' str3 tbl str9 block int ord str42 lab double m1 s1 m2 s2 m3 s3 m4 s4 m5 s5 m6 s6 ///
    using "$rbreg/RB_V15E_AGE46_A2A5_descriptives.dta", replace

 foreach grp in "f 1 A2" "f 2 A3" "m 1 A4" "m 2 A5" {
     gettoken g   rest : grp
     gettoken tr  tbl  : rest
     local tbl = trim("`tbl'")
     local oth = cond("`g'"=="f","m","f")
     * TIME (6 coarse periods) from the relevant event-time cat
     capture drop TIME
     gen byte TIME = time_x`tr'_cat
     replace  TIME = 6 if time_x`tr'_cat>=6 & time_x`tr'_cat<.

     * respondent block
     local ord=0
     local n : word count `rstub'
     forval i=1/`n' {
         local v : word `i' of `rstub'
         local L : word `i' of `rlab'
         local ord=`ord'+1
         capture confirm variable `v'_`g'
         if _rc {
             post `M' ("`tbl'") ("resp") (`ord') ("`L'") (.)(.)(.)(.)(.)(.)(.)(.)(.)(.)(.)(.)
             continue
         }
         local vals ""
         forval t=1/6 {
             quietly su `v'_`g' if TIME==`t' & treated`tr'==1
             local mm = cond(r(N)>0, round(r(mean),0.01), .)
             local ss = cond(r(N)>0, round(r(sd),0.01), .)
             local vals "`vals' (`mm') (`ss')"
         }
         post `M' ("`tbl'") ("resp") (`ord') ("`L'") `vals'
     }
     local ord=`ord'+1
     capture confirm variable time_x3_cat
     if !_rc {
         local vals ""
         forval t=1/6 {
             quietly su time_x3_cat if TIME==`t' & treated`tr'==1
             local mm=cond(r(N)>0,round(r(mean),0.01),.)
             local ss=cond(r(N)>0,round(r(sd),0.01),.)
             local vals "`vals' (`mm') (`ss')"
         }
         post `M' ("`tbl'") ("resp") (`ord') ("A(nother) child") `vals'
     }
     * partner block (the other member)
     local np : word count `pstub'
     forval i=1/`np' {
         local v : word `i' of `pstub'
         local L : word `i' of `plab'
         local ord=`ord'+1
         capture confirm variable `v'_`oth'
         if _rc {
             post `M' ("`tbl'") ("partner") (`ord') ("`L'") (.)(.)(.)(.)(.)(.)(.)(.)(.)(.)(.)(.)
             continue
         }
         local vals ""
         forval t=1/6 {
             quietly su `v'_`oth' if TIME==`t' & treated`tr'==1
             local mm=cond(r(N)>0,round(r(mean),0.01),.)
             local ss=cond(r(N)>0,round(r(sd),0.01),.)
             local vals "`vals' (`mm') (`ss')"
         }
         post `M' ("`tbl'") ("partner") (`ord') ("`L'") `vals'
     }
 }
 postclose `M'
 use "$rbreg/RB_V15E_AGE46_A2A5_descriptives.dta", clear
 export delimited using "$rbreg/RB_V15E_AGE46_A2A5_descriptives.csv", replace
 di as result "=== A2-A5 descriptives DONE: rows=" _N " ==="
 tab tbl
