*==============================================================================================
* analysis_wage_v15E_AGE46_D15_ipw.do
*
* Attrition: inverse probability weights for remaining in the panel, and the event-study
* models with and without them. Source of Appendix Table A15.
*
* Reads:   analysis dataset data/Wage/data_wage_v15.dta (survey data needed)
* Writes:  estimates/RB_V15E_AGE46_D15_ipw (csv, dta)
*
* Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
* and pregnancy losses. Social Science Research, 141, 103450.
*==============================================================================================

quietly do "config.do"   // folder settings: start Stata in the package folder

clear all
set more off
 global data  ${REPL_DATA}/Wage
 global rbreg ${REPL_EST}
 capture mkdir "$rbreg"
 local s f
 global demo    c.age_`s'##c.age_`s'  c.income_partner_`s'
 global year    ib2011.year i.gor_`s'
 global union   ib1.union_type
 global SES     c.ISEI_`s'##c.ISEI_`s' i.ISEI_miss_`s' ib1.hiqual_`s' soc00_N_wave ib1.private_`s' ib1.nssec5_v2_`s'
 global exp     c.work_exp_`s'##c.work_exp_`s' i.work_exp_miss_`s' c.tenure_`s'##c.tenure_`s' i.tenure_miss_`s'
 global jobend2 c.num_job_end_v2_`s'##c.num_job_end_v2_`s'
 global postj2  i.any_job_end_post_v2_`s'
 global health  c.sf12mcs_std_`s' c.sf12pcs_std_`s'
 local m1 $year $demo $union
 local m5 $year $demo $union $SES $exp $jobend2 $postj2 $health i.time_x3_cat

 use "$data/data_wage_v15.dta", clear
 drop if wave == .
 duplicates tag pidp_`s' wave, gen(dup)
 bysort pidp_`s' wave: gen n_pw = _n
 drop if n_pw > 1 & dup > 0
 drop dup n_pw
 keep if x1 !=. & x2 !=. & age_event>=18 & age_event<46 ///
       & (treated1 == 1 | treated2 == 1) ///
       & first_wave_worked <= min_wave_t & first_wave_worked !=. ///
       & self_employed1_`s' == 0
 gen byte worker = !missing(fimnlabgrs_hrclean_CPI_trim_ln_`s') & !missing(tot_work_hours_cond_ln_trim_`s')
 xtset pidp_`s' wave
 quietly summarize wave
 local wlast = r(max)
 di as err "=== ultima wave panel (wlast) = `wlast' ==="

 bysort pidp_`s' (wave): gen double nextw = wave[_n+1]
 gen byte stay = (nextw == wave+1) if wave < `wlast'
 gen byte loss = (treated2==1)
 gen byte post_event = (treated1==1 & time_x1_cat4>=4) | (treated2==1 & time_x2_cat4>=4)
 gen byte sf12_miss = missing(sf12mcs_std_`s') | missing(sf12pcs_std_`s')
 gen double sf12mcs_a = cond(sf12_miss, 0, sf12mcs_std_`s')
 gen double sf12pcs_a = cond(sf12_miss, 0, sf12pcs_std_`s')
 local attrmod c.age_`s'##c.age_`s' i.employed11_`s' c.ISEI_`s' i.ISEI_miss_`s' ///
               c.tot_work_hours_`s' c.income_partner_`s' c.fimnlabgrs_CPI_trim_`s' ///
               c.sf12mcs_a c.sf12pcs_a i.sf12_miss i.gor_`s' ib2011.year
 quietly logit stay `attrmod' i.loss if wave < `wlast', vce(cluster pidp_`s')
 di as err "=== ATTRIZIONE DIFFERENZIALE (modello ricco: +earnings +SF12 salute): coeff su LOSS ==="
 di as err "   b(loss)=" %6.3f _b[1.loss] "  se=" %6.3f _se[1.loss] ///
     "  z=" %5.2f _b[1.loss]/_se[1.loss] "  p=" %5.3f 2*normal(-abs(_b[1.loss]/_se[1.loss]))
 di as err "   (H0: attrizione NON differenziale per esito ⇔ b(loss)=0)"
 quietly margins loss
 matrix M = r(b)
 di as err "   P(stay) parto=" %5.3f M[1,1] "  perdita=" %5.3f M[1,2] " (retention wave-to-wave CONDIZIONALE)"
 quietly logit stay `attrmod' i.loss##i.post_event if wave < `wlast', vce(cluster pidp_`s')
 di as err "=== USCITA POST-EVENTO: interazione LOSS x POST (le perdite escono di piu' DOPO l'evento?) ==="
 di as err "   b(loss#post)=" %6.3f _b[1.loss#1.post_event] "  se=" %6.3f _se[1.loss#1.post_event] ///
     "  p=" %5.3f 2*normal(-abs(_b[1.loss#1.post_event]/_se[1.loss#1.post_event]))

 quietly logit stay `attrmod' i.loss if wave < `wlast', vce(cluster pidp_`s')
 predict double pstay if wave < `wlast', pr
 replace pstay = 1 if wave == `wlast'
 replace pstay = 1 if missing(pstay) & wave < `wlast'
 quietly logit stay i.loss if wave < `wlast', vce(cluster pidp_`s')
 predict double pstay_s if wave < `wlast', pr
 replace pstay_s = 1 if wave == `wlast'
 replace pstay_s = 1 if missing(pstay_s) & wave < `wlast'
 bysort pidp_`s' (wave): gen double cum_num = 1
 bysort pidp_`s' (wave): gen double cum_den = 1
 bysort pidp_`s' (wave): replace cum_num = cum_num[_n-1]*pstay_s[_n-1] if _n>1
 bysort pidp_`s' (wave): replace cum_den = cum_den[_n-1]*pstay[_n-1] if _n>1
 gen double sw = cum_num/cum_den
 quietly summarize sw, detail
 replace sw = r(p1)  if sw < r(p1)
 replace sw = r(p99) if sw > r(p99)
 quietly summarize sw, detail
 di as err "=== PESI IPCW stabilizzati (post-trim): media=" %5.3f r(mean) " p50=" %5.3f r(p50) " min=" %5.3f r(min) " max=" %5.3f r(max) " ==="
 quietly count
 local n = r(N)
 egen double sumw  = total(sw)
 egen double sumw2 = total(sw^2)
 local ess = sumw[1]^2/sumw2[1]
 di as err "   N=`n'  effective N (ESS)=" %8.0f `ess'

 local dvs   "fimnlabgrs_CPI_trim_`s' fimnlabgrs_hrclean_CPI_trim_ln_`s' tot_work_hours_`s' tot_work_hours_cond_ln_trim_`s' employed11_`s'"
 local tags  "earnings wage workhrs workhrs_cond employed"
 local types "U C U C U"
 tempname pf
 postfile `pf' str14 outcome byte model str8 weight byte bin double b double se double t str3 star ///
     using "$rbreg/RB_V15E_AGE46_D15_ipw.dta", replace
forvalues o = 1/5 {
    local dv  : word `o' of `dvs'
    local tag : word `o' of `tags'
    local ty  : word `o' of `types'
    local ss ""
    if "`ty'" == "C" local ss "& worker"
    quietly xtreg `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `m5' if 1 `ss', vce(cluster pidp_`s')
    capture drop cs
    gen byte cs = e(sample)
    foreach k in 1 5 {
        foreach w in UNW IPCW {
            if "`w'"=="UNW"  quietly reghdfe `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `m`k'' if cs, absorb(pidp_`s' wave) vce(cluster pidp_`s')
            if "`w'"=="IPCW" quietly reghdfe `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `m`k'' [pw=sw] if cs, absorb(pidp_`s' wave) vce(cluster pidp_`s')
            forvalues j = 1/9 {
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
                post `pf' ("`tag'") (`k') ("`w'") (`j') (`bb') (`se') (`tt') ("`st'")
            }
        }
    }
}
postclose `pf'

 preserve
 use "$rbreg/RB_V15E_AGE46_D15_ipw.dta", clear
 export delimited using "$rbreg/RB_V15E_AGE46_D15_ipw.csv", replace
 di as err "=== UNW vs IPCW: wage & earnings, 0-12 & 61+, M1 & M5 ==="
 keep if inlist(bin,4,9) & inlist(outcome,"wage","earnings")
 gen bl = cond(bin==4,"0-12","61+")
 sort outcome bl model weight
 list outcome bl model weight b t star, noobs sepby(outcome bl)
 restore
 di as err ""
 di as err "=== output: RB_V15E_AGE46_D15_ipw.csv/.dta ==="
