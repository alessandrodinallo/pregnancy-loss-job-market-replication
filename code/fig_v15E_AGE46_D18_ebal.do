*==============================================================================================
* fig_v15E_AGE46_D18_ebal.do
*
* Unweighted and entropy-balanced event-study estimates: one figure per outcome and model,
* and a spreadsheet of the plotted coefficients.
*
* Reads:   analysis dataset data/Wage/data_wage_v15.dta (survey data needed);
*          estimates/RB_V15E_AGE46_D18.dta
* Writes:  figures/RB_V15E_AGE46_D18_* (png), estimates/RB_V15E_AGE46_D18_coefficients.xlsx
*
* Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
* and pregnancy losses. Social Science Research, 141, 103450.
*==============================================================================================

quietly do "config.do"   // folder settings: start Stata in the package folder

clear all
set more off
 global data  ${REPL_DATA}/Wage
 global rbreg ${REPL_EST}
 global rbgra ${REPL_FIG}
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
 ebalance loss `bcovs', generate(webal_w)
 keep pidp_`s' webal_w
 tempfile W
 save `W'
 restore
 merge m:1 pidp_`s' using `W', nogen
 rename webal_w webal

 preserve
 use "$rbreg/RB_V15E_AGE46_D18.dta", clear
 gen str12 blab = ""
 replace blab = "25+ before"  if bin==1
 replace blab = "12-1 before" if bin==3
 replace blab = "0-12 after"  if bin==4
 replace blab = "13-24 after" if bin==5
 replace blab = "25-36 after" if bin==6
 replace blab = "37-48 after" if bin==7
 replace blab = "49-60 after" if bin==8
 replace blab = "61+ after"   if bin==9
 keep outcome spec bin blab b se star
 reshape wide b se star, i(outcome bin blab) j(spec) string
 order outcome bin blab bUNW_M1 seUNW_M1 starUNW_M1 bUNW_M5 seUNW_M5 starUNW_M5 ///
       bEBAL_M1 seEBAL_M1 starEBAL_M1 bEBAL_M5 seEBAL_M5 starEBAL_M5
 sort outcome bin
 export excel using "$rbreg/RB_V15E_AGE46_D18_coefficients.xlsx", firstrow(variables) replace
 di as err "=== tabella xlsx salvata ==="
 restore

 local CL 1.time_x2_cat4 = `""25+" "before""' 2.time_x2_cat4 = `""13-24" "before (ref)""' 3.time_x2_cat4 = `""12-1" "before""' 4.time_x2_cat4 = `""0-12" "after""' 5.time_x2_cat4 = `""13-24" "after""' 6.time_x2_cat4 = `""25-36" "after""' 7.time_x2_cat4 = `""37-48" "after""' 8.time_x2_cat4 = `""49-60" "after""' 9.time_x2_cat4 = `""61+" "after""'

 local dvs   "fimnlabgrs_CPI_trim_`s' fimnlabgrs_hrclean_CPI_trim_ln_`s' tot_work_hours_`s' tot_work_hours_cond_ln_trim_`s' employed11_`s'"
 local tags  "earnings wage workhrs workhrs_cond employed"
 local types "U C U C U"
 local tl_earnings "Labour earnings"
 local tl_wage "Hourly wage"
 local tl_workhrs "Weekly work hours"
 local tl_workhrs_cond "Conditional work hours"
 local tl_employed "Employment"
 local yt_earnings "Change (GBP/month)"
 local yt_wage "Change (log points)"
 local yt_workhrs "Change (hours/week)"
 local yt_workhrs_cond "Change (log points)"
 local yt_employed "Change (probability)"

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
        local sub = cond(`k'==1,"Pregnancy-loss group, unadjusted","Pregnancy-loss group, fully adjusted")
        quietly reghdfe `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `m`k'' if cs, absorb(pidp_`s' wave) vce(cluster pidp_`s')
        estimates store unw
        quietly reghdfe `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `m`k'' [pw=webal] if cs, absorb(pidp_`s' wave) vce(cluster pidp_`s')
        estimates store ebal
        capture coefplot ///
            (unw,  keep(*.time_x2_cat4) msymbol(O) mcolor(navy%70) msize(small) ciopts(recast(rcap) lcolor(navy%40) lwidth(medthin)) offset(-0.10) label("Unweighted")) ///
            (ebal, keep(*.time_x2_cat4) msymbol(D) mcolor(cranberry%70) msize(small) ciopts(recast(rcap) lcolor(cranberry%40) lwidth(medthin)) offset(0.10) label("Entropy-balanced on baseline characteristics")) ///
            , baselevels vertical yline(0, lcolor(gray%50)) ///
            xline(4, lcolor(gray%18) lwidth(15) lpattern(solid)) ///
            coeflabels(`CL') xlabel(, labsize(small)) ///
            title("`tl_`tag''", size(medsmall)) subtitle("`sub'", size(small)) ///
            xtitle("Months relative to end of pregnancy", size(small)) ytitle("`yt_`tag''", size(small)) ///
            legend(rows(1) position(6) size(vsmall) region(lcolor(white))) ///
            graphregion(color(white) margin(l=4 r=4 t=4 b=4)) plotregion(fcolor(white)) ///
            xsize(9.5) ysize(5.5) name(d18_`tag'_M`k', replace)
        capture graph export "$rbgra/RB_V15E_AGE46_D18_`tag'_M`k'.png", replace width(2400)
    }
    di as err "  fatto: `tag'"
}
 di as err "=== D18 figure a 2 serie (UNW vs EBAL) + tabella xlsx generate ==="
