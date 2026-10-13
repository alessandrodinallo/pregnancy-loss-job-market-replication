*==============================================================================================
* fig_v15E_AGE46_FigA5_profiles.do
*
* Appendix Figure A5: standardised means of the pre-conception covariates, by group.
*
* Reads:   estimates/RB_V15E_AGE46_D21_balance.dta
* Writes:  figures/RB_V15E_AGE46_D21_profiles (png, pdf)
*
* Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
* and pregnancy losses. Social Science Research, 141, 103450.
*==============================================================================================

quietly do "config.do"   // folder settings: start Stata in the package folder

clear all
set more off
 global des ${REPL_EST}
 local s f

 use "$des/RB_V15E_AGE46_D21_balance.dta", clear
 capture drop absd
 gen absd = abs(stddiff)

 gen str32 lbl = ""
 replace lbl = "Earnings"        if varname=="fimnlabgrs_CPI_trim_`s'"
 replace lbl = "Employed"        if varname=="employed11_`s'"
 replace lbl = "Weekly hours"    if varname=="tot_work_hours_`s'"
 replace lbl = "ISEI"            if varname=="ISEI_`s'"
 replace lbl = "Experience"      if varname=="work_exp_`s'"
 replace lbl = "Tenure"          if varname=="tenure_`s'"
 replace lbl = "Private sector"  if varname=="private_`s'"
 replace lbl = "Age"             if varname=="age_`s'"
 replace lbl = "Partner income"  if varname=="income_partner_`s'"

 gsort absd
 gen order = _n
 capture label drop ordlab
 forvalues i = 1/`=_N' {
     local L = lbl[`i']
     label define ordlab `i' "`L'", add
 }
 label values order ordlab

 gen double zlive = stddiff/2
 gen double zloss = -stddiff/2

 twoway (scatter order zlive, msymbol(O) msize(medlarge) mcolor(navy)) ///
        (scatter order zloss, msymbol(D) msize(medlarge) mcolor(cranberry)) ///
        (pcspike order zlive order zloss, lcolor(gray%45) lwidth(thin)), ///
     xline(0, lcolor(black) lwidth(thin)) ///
     ylabel(1(1)9, valuelabel angle(0) labsize(small) nogrid) ///
     xlabel(-0.15(0.05)0.15, labsize(small)) ///
     xtitle("Standardized group mean (SD units, centered on the midpoint)", size(small)) ///
     ytitle("") ///
     title("Pre-pregnancy comparability of the two groups", size(medsmall)) ///
     subtitle("Overlapping markers = balanced; gap = standardized difference", size(vsmall)) ///
     legend(order(1 "Live birth (N=1,998)" 2 "Pregnancy loss (N=265)") rows(1) position(6) size(small) region(lcolor(white))) ///
     note("Only age differs (loss group ~1 year older, already controlled via age squared). All other |std. diff.| < 0.04.", size(vsmall)) ///
     graphregion(color(white) margin(l=16 r=4 t=4 b=4)) plotregion(fcolor(white)) ///
     xsize(9.5) ysize(5.5) name(d21_profiles, replace)
 graph export "${REPL_FIG}/RB_V15E_AGE46_D21_profiles.png", replace width(2400)
 graph export "${REPL_FIG}/RB_V15E_AGE46_D21_profiles.pdf", replace
 di as err "=== output: RB_V15E_AGE46_D21_profiles.png + .pdf ==="
