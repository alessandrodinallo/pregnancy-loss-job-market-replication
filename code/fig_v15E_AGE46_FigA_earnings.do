*==============================================================================================
* fig_v15E_AGE46_FigA_earnings.do
*
* Appendix Figure A9: labour income under two-way fixed effects and under the
* interaction-weighted estimator.
*
* Reads:   estimates/RB_V15E_AGE46_TWFEfig.dta, RB_V15E_AGE46_SAfig.dta
* Writes:  figures/RB_V15E_AGE46_FigA_earnings (png, pdf)
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

 use "$rbreg/RB_V15E_AGE46_TWFEfig.dta", clear
 append using "$rbreg/RB_V15E_AGE46_SAfig.dta"
 keep if outcome=="earnings" & model==1
 foreach e in TWFE SA {
     foreach g in 1 2 {
         local N=_N+1
         set obs `N'
         replace estim="`e'"     in `N'
         replace outcome="earnings" in `N'
         replace model=1         in `N'
         replace grp=`g'          in `N'
         replace bin=2            in `N'
         replace b=0              in `N'
         replace se=0             in `N'
     }
 }
 gen lb = b-1.96*se
 gen ub = b+1.96*se
 gen time = bin + cond(grp==1,-0.05,0.05)

 quietly summ lb
 local lo = r(min)
 quietly summ ub
 local hi = r(max)
 local pad=(`hi'-`lo')*0.06
 local lo=`lo'-`pad'
 local hi=`hi'+`pad'

 local XL xlabel(1 `""25+" "before""' 2 `""13/24" "before""' 3 `""12/1" "before""' 4 `""0/12" "after""' 5 `""13/24" "after""' 6 `""25/36" "after""' 7 `""37/48" "after""' 8 `""49/60" "after""' 9 `""61+" "after""', labsize(medsmall) nogrid)

 local ttl_TWFE "A. Two-way fixed effects"
 local ttl_SA   "B. Sun and Abraham (2021)"
 foreach e in TWFE SA {
     twoway ///
        (rcap    ub lb time if grp==1 & estim=="`e'", lcolor(navy%40) lwidth(medthin)) ///
        (rcap    ub lb time if grp==2 & estim=="`e'", lcolor(cranberry%40) lwidth(medthin)) ///
        (scatter b     time if grp==1 & estim=="`e'", mcolor(navy%55) msymbol(O) msize(2.0)) ///
        (scatter b     time if grp==2 & estim=="`e'", mcolor(cranberry%55) msymbol(D) msize(2.0)) ///
        , yline(0, lcolor(cranberry%20) lwidth(medium) lpattern(solid)) ///
          xline(4, lcolor(gray%18) lwidth(6) lpattern(solid)) ///
          `XL' xscale(range(0.5 9.5)) ///
          ylabel(#6, labsize(medsmall) nogrid) yscale(range(`lo' `hi')) ///
          ytitle("Change (2015 GBP)", size(medsmall)) ///
          xtitle("Months relative to end of pregnancy", size(medsmall)) ///
          title("`ttl_`e''", size(medium)) ///
          legend(order(3 "Live birth" 4 "Pregnancy loss") rows(1) size(medsmall) symxsize(*.6) symysize(*.6) region(color(white))) ///
          graphregion(color(white) margin(l=2 r=2 t=2 b=2)) plotregion(fcolor(white)) ///
          name(fA_`e', replace)
 }
 grc1leg fA_TWFE fA_SA, legendfrom(fA_TWFE) position(6) rows(1) ///
     graphregion(color(white)) imargin(2 2 2 2)
 graph display, xsize(11) ysize(5.2)
 graph export "$rbgra/RB_V15E_AGE46_FigA_earnings.png", replace width(2600)
 graph export "$rbgra/RB_V15E_AGE46_FigA_earnings.pdf", replace
 di as err "=== output: RB_V15E_AGE46_FigA_earnings.png ==="
