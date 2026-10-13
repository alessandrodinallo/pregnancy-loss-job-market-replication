*==============================================================================================
* analysis_wage_v15E_AGE46_A5A6fig.do
*
* Event-study models for women's mental and physical health and for the partner's
* labour-market outcomes. Source of Appendix Figures A6 and A7.
*
* Reads:   analysis dataset data/Wage/data_wage_v15.dta (survey data needed)
* Writes:  estimates/RB_V15E_AGE46_A5A6fig (csv, dta)
*
* Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
* and pregnancy losses. Social Science Research, 141, 103450.
*==============================================================================================

quietly do "config.do"   // folder settings: start Stata in the package folder

clear all
set more off
 global data  ${REPL_DATA}/Wage
 global rbreg ${REPL_EST}
 global union ib1.union_type

 use "$data/data_wage_v15.dta", clear
 drop if wave==.
 duplicates tag pidp_f wave, gen(dup)
 bysort pidp_f wave: gen n_pw=_n
 drop if n_pw>1 & dup>0
 drop dup n_pw
 keep if x1!=. & x2!=. & age_event>=18 & age_event<46 & (treated1==1|treated2==1) ///
       & first_wave_worked<=min_wave_t & first_wave_worked!=. & self_employed1_f==0
 xtset pidp_f wave

 tempname M
 postfile `M' str3 fig str14 outcome byte grp byte bin double b se ///
     using "$rbreg/RB_V15E_AGE46_A5A6fig.dta", replace

 global demo_f  c.age_f##c.age_f c.income_partner_f
 global year_f  ib2011.year i.gor_f
 global SES_f   c.ISEI_f##c.ISEI_f i.ISEI_miss_f ib1.hiqual_f soc00_N_wave ib1.private_f ib1.nssec5_v2_f
 global exp_f   c.work_exp_f##c.work_exp_f i.work_exp_miss_f c.tenure_f##c.tenure_f i.tenure_miss_f
 global jend_f  c.num_job_end_v2_f##c.num_job_end_v2_f
 capture confirm variable any_job_end_post_f, exact
 if !_rc global postj_f i.any_job_end_post_f
 else    global postj_f i.any_job_end_post_v2_f
 local m5h $year_f $demo_f $union $SES_f $exp_f $jend_f $postj_f i.time_x3_cat

 local h_dvs  "sf12mcs_std_f sf12pcs_std_f"
 local h_tags "mental physical"
 forvalues o=1/2 {
     local dv  : word `o' of `h_dvs'
     local tag : word `o' of `h_tags'
     quietly xtreg `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `m5h', vce(cluster pidp_f)
     di as err "   A5 `tag': N = " e(N)
     forvalues g=1/2 {
         local V = cond(`g'==1,"time_x1_cat4","time_x2_cat4")
         forvalues j=1/9 {
             if `j'==2 continue
             post `M' ("A5") ("`tag'") (`g') (`j') (_b[`j'.`V']) (_se[`j'.`V'])
         }
     }
 }

 global demo_m  c.age_m##c.age_m c.income_partner_m
 global year_m  ib2011.year i.gor_m
 global SES_m   c.ISEI_m##c.ISEI_m i.ISEI_miss_m ib1.hiqual_m ib1.private_m ib1.nssec5_v2_m
 global exp_m   c.work_exp_m##c.work_exp_m i.work_exp_miss_m c.tenure_m##c.tenure_m i.tenure_miss_m
 global jend_m  c.num_job_end_v2_m##c.num_job_end_v2_m
 global postj_m i.any_job_end_post_v2_m
 global health_m c.sf12mcs_std_m c.sf12pcs_std_m
 local m5m $year_m $demo_m $union $SES_m $exp_m $jend_m $postj_m $health_m i.time_x3_cat

 gen byte workerm = !missing(fimnlabgrs_hrclean_CPI_trim_ln_m) & !missing(tot_work_hours_cond_ln_trim_m)

 local m_dvs  "fimnlabgrs_CPI_trim_m employed11_m fimnlabgrs_hrclean_CPI_trim_ln_m tot_work_hours_m"
 local m_tags "income employed wage workhrs"
 local m_type "U U C U"
 forvalues o=1/4 {
     local dv  : word `o' of `m_dvs'
     local tag : word `o' of `m_tags'
     local ty  : word `o' of `m_type'
     local ssamp ""
     if "`ty'"=="C" local ssamp "if workerm"
     quietly xtreg `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `m5m' `ssamp', vce(cluster pidp_f)
     di as err "   A6 `tag': N = " e(N)
     forvalues g=1/2 {
         local V = cond(`g'==1,"time_x1_cat4","time_x2_cat4")
         forvalues j=1/9 {
             if `j'==2 continue
             post `M' ("A6") ("`tag'") (`g') (`j') (_b[`j'.`V']) (_se[`j'.`V'])
         }
     }
 }
 postclose `M'

 use "$rbreg/RB_V15E_AGE46_A5A6fig.dta", clear
 export delimited using "$rbreg/RB_V15E_AGE46_A5A6fig.csv", replace
 di as result "=== A5A6fig DONE: rows=" _N " ==="
 table fig outcome if bin==9 & grp==2, statistic(mean b)
