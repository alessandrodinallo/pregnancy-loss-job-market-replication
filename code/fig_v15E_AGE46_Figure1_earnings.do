*==============================================================================================
* fig_v15E_AGE46_Figure1_earnings.do
*
* Figure 1: labour income around the end of the pregnancy, unadjusted and fully adjusted
* models, both groups.
*
* Reads:   estimates/RB_V15E_AGE46_TABLE1.dta
* Writes:  figures/RB_V15E_AGE46_Figure1_earnings_M1M5 (png, pdf)
*
* Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
* and pregnancy losses. Social Science Research, 141, 103450.
*==============================================================================================

quietly do "config.do"   // folder settings: start Stata in the package folder

clear all
set more off
 capture which grc1leg
 if _rc capture ssc install grc1leg, replace
 global rbreg ${REPL_EST}
 global rbgra ${REPL_FIG}

 use "$rbreg/RB_V15E_AGE46_TABLE1.dta", clear
 keep if outcome=="earnings" & inlist(model,1,5)
 foreach m in 1 5 {
     foreach g in 1 2 {
         local N=_N+1
         set obs `N'
         replace outcome="earnings" in `N'
         replace model=`m' in `N'
         replace grp=`g'   in `N'
         replace bin=2     in `N'
         replace b=0       in `N'
         replace se=0      in `N'
     }
 }
 gen lb = b-1.96*se
 gen ub = b+1.96*se
 gen time = bin + cond(grp==1,-0.05,0.05)

 local XL xlabel(1 `""25+" "before""' 2 `""13/24" "before""' 3 `""12/1" "before""' 4 `""0/12" "after""' 5 `""13/24" "after""' 6 `""25/36" "after""' 7 `""37/48" "after""' 8 `""49/60" "after""' 9 `""61+" "after""', labsize(medsmall) nogrid)

 foreach m in 1 5 {
     local sub = cond(`m'==1,"Unadjusted model","Fully adjusted model")
     twoway ///
        (rcap    ub lb time if grp==1 & model==`m', lcolor(navy%40) lwidth(medthin)) ///
        (rcap    ub lb time if grp==2 & model==`m', lcolor(cranberry%40) lwidth(medthin)) ///
        (scatter b     time if grp==1 & model==`m', mcolor(navy%55) msymbol(O) msize(2)) ///
        (scatter b     time if grp==2 & model==`m', mcolor(cranberry%55) msymbol(D) msize(2)) ///
        , yline(0, lcolor(cranberry%20) lwidth(medium) lpattern(solid)) ///
          xline(4, lcolor(gray%18) lwidth(9) lpattern(solid)) ///
          `XL' xscale(range(0.5 9.5)) ///
          ylabel(-1000(200)0, labsize(medsmall) nogrid) yscale(range(-1080 30)) ///
          ytitle("Change (2015 GBP)", size(medsmall)) ///
          xtitle("Months relative to end of pregnancy", size(medsmall)) ///
          subtitle("`sub'", size(medium)) ///
          legend(order(3 "Live birth" 4 "Pregnancy loss") rows(1) size(medsmall) symxsize(*.6) symysize(*.6) region(color(white))) ///
          graphregion(color(white) margin(l=3 r=3 t=3 b=3)) plotregion(fcolor(white)) ///
          name(f1_m`m', replace)
 }
 grc1leg f1_m1 f1_m5, legendfrom(f1_m1) position(6) rows(1) ycommon ///
     title("Labour income", size(medlarge)) ///
     graphregion(color(white)) imargin(2 2 2 2)
 graph display, xsize(11) ysize(5.2)
 graph export "$rbgra/RB_V15E_AGE46_Figure1_earnings_M1M5.png", replace width(2600)
 graph export "$rbgra/RB_V15E_AGE46_Figure1_earnings_M1M5.pdf", replace
 di as err "=== output: RB_V15E_AGE46_Figure1_earnings_M1M5.png ==="
