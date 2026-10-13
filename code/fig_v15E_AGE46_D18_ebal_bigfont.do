*==============================================================================================
* fig_v15E_AGE46_D18_ebal_bigfont.do
*
* Appendix Figures B1 and B2: labour income and hourly wage, unweighted and entropy-balanced.
*
* Reads:   analysis dataset data/Wage/data_wage_v15.dta (survey data needed)
* Writes:  figures/RB_V15E_AGE46_D18_*_M1_big (png, pdf)
*
* Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
* and pregnancy losses. Social Science Research, 141, 103450.
*==============================================================================================

quietly do "config.do"   // folder settings: start Stata in the package folder

clear all
set more off
 global data  ${REPL_DATA}/Wage
 global rbgra ${REPL_FIG}
 local s f
 global demo    c.age_`s'##c.age_`s'  c.income_partner_`s'
 global year    ib2011.year i.gor_`s'
 global union   ib1.union_type
 local m1     $year $demo $union

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

 local CL 1.time_x2_cat4 = `""25+" "before""' 2.time_x2_cat4 = `""13-24" "before (ref)""' 3.time_x2_cat4 = `""12-1" "before""' 4.time_x2_cat4 = `""0-12" "after""' 5.time_x2_cat4 = `""13-24" "after""' 6.time_x2_cat4 = `""25-36" "after""' 7.time_x2_cat4 = `""37-48" "after""' 8.time_x2_cat4 = `""49-60" "after""' 9.time_x2_cat4 = `""61+" "after""'

 local dvs   "fimnlabgrs_CPI_trim_`s' fimnlabgrs_hrclean_CPI_trim_ln_`s'"
 local tags  "earnings wage"
 local types "U C"
 local tl_earnings "Labour earnings"
 local tl_wage "Hourly wage"
 local yt_earnings "Change (GBP/month)"
 local yt_wage "Change (log points)"

forvalues o=1/2 {
    local dv : word `o' of `dvs'
    local tag: word `o' of `tags'
    local ty : word `o' of `types'
    local ss ""
    if "`ty'"=="C" local ss "& worker"
    quietly xtreg `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 $year $demo $union c.ISEI_`s'##c.ISEI_`s' i.ISEI_miss_`s' ib1.hiqual_`s' if hasbase `ss', vce(cluster pidp_`s')
    capture drop cs
    gen byte cs=e(sample)
    * M1 (unadjusted)
    quietly reghdfe `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `m1' if cs, absorb(pidp_`s' wave) vce(cluster pidp_`s')
    estimates store unw
    quietly reghdfe `dv' ib2.time_x1_cat4 ib2.time_x2_cat4 `m1' [pw=webal] if cs, absorb(pidp_`s' wave) vce(cluster pidp_`s')
    estimates store ebal
    capture coefplot ///
        (unw,  keep(*.time_x2_cat4) msymbol(O) mcolor(navy%70) msize(medium) ciopts(recast(rcap) lcolor(navy%40) lwidth(medthin)) offset(-0.10) label("Unweighted")) ///
        (ebal, keep(*.time_x2_cat4) msymbol(D) mcolor(cranberry%70) msize(medium) ciopts(recast(rcap) lcolor(cranberry%40) lwidth(medthin)) offset(0.10) label("Entropy-balanced on baseline characteristics")) ///
        , baselevels vertical yline(0, lcolor(gray%50)) ///
        xline(4, lcolor(gray%18) lwidth(15) lpattern(solid)) ///
        coeflabels(`CL') xlabel(, labsize(medium)) ylabel(, labsize(medium)) ///
        title("`tl_`tag''", size(medlarge)) subtitle("Pregnancy-loss group, unadjusted", size(medium)) ///
        xtitle("Months relative to end of pregnancy", size(medium)) ytitle("`yt_`tag''", size(medium)) ///
        legend(rows(1) position(6) size(medium) region(lcolor(white))) ///
        graphregion(color(white) margin(l=4 r=4 t=4 b=4)) plotregion(fcolor(white)) ///
        xsize(9.5) ysize(5.5) name(d18big_`tag', replace)
    capture graph export "$rbgra/RB_V15E_AGE46_D18_`tag'_M1_big.png", replace width(2400)
    capture graph export "$rbgra/RB_V15E_AGE46_D18_`tag'_M1_big.pdf", replace
    di as result "  fatto (big font, png+pdf): `tag'"
}
 di as result "=== D18 figure big-font (UNW vs EBAL) generate: RB_V15E_AGE46_D18_{earnings,wage}_M1_big.png ==="
