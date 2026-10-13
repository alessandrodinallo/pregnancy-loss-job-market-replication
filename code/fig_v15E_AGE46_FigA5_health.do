*==============================================================================================
* fig_v15E_AGE46_FigA5_health.do
*
* Appendix Figure A6: women's mental and physical health around the end of the pregnancy.
*
* Reads:   estimates/RB_V15E_AGE46_A5A6fig.dta
* Writes:  figures/RB_V15E_AGE46_FigA5_health (png, pdf)
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

 use "$rbreg/RB_V15E_AGE46_A5A6fig.dta", clear
 keep if fig=="A5"
 foreach o in mental physical {
     foreach g in 1 2 {
         local N=_N+1
         set obs `N'
         replace fig="A5"    in `N'
         replace outcome="`o'" in `N'
         replace grp=`g'      in `N'
         replace bin=2        in `N'
         replace b=0          in `N'
         replace se=0         in `N'
     }
 }
 gen lb = b-1.96*se
 gen ub = b+1.96*se
 gen time = bin + cond(grp==1,-0.05,0.05)

 local XL xlabel(1 `""25+" "before""' 2 `""13/24" "before""' 3 `""12/1" "before""' 4 `""0/12" "after""' 5 `""13/24" "after""' 6 `""25/36" "after""' 7 `""37/48" "after""' 8 `""49/60" "after""' 9 `""61+" "after""', labsize(medsmall) nogrid)

 local ttl_mental   "A. Mental health"
 local ttl_physical "B. Physical health"
 foreach tag in mental physical {
     quietly summ lb if outcome=="`tag'"
     local ymin=r(min)
     quietly summ ub if outcome=="`tag'"
     local ymax=r(max)
     local pad=(`ymax'-`ymin')*0.06
     local lo=`ymin'-`pad'
     local hi=`ymax'+`pad'
     twoway ///
        (rcap    ub lb time if grp==1 & outcome=="`tag'", lcolor(navy%40) lwidth(medthin)) ///
        (rcap    ub lb time if grp==2 & outcome=="`tag'", lcolor(cranberry%40) lwidth(medthin)) ///
        (scatter b     time if grp==1 & outcome=="`tag'", mcolor(navy%55) msymbol(O) msize(2.0)) ///
        (scatter b     time if grp==2 & outcome=="`tag'", mcolor(cranberry%55) msymbol(D) msize(2.0)) ///
        , yline(0, lcolor(cranberry%20) lwidth(medium) lpattern(solid)) ///
          xline(4, lcolor(gray%18) lwidth(6) lpattern(solid)) ///
          `XL' xscale(range(0.5 9.5)) ///
          ylabel(#6, labsize(medsmall) nogrid) yscale(range(`lo' `hi')) ///
          ytitle("Change (std. deviation)", size(medsmall)) ///
          xtitle("Months relative to end of pregnancy", size(medsmall)) ///
          title("`ttl_`tag''", size(medium)) ///
          legend(order(3 "Live birth" 4 "Pregnancy loss") rows(1) size(medsmall) symxsize(*.6) symysize(*.6) region(color(white))) ///
          graphregion(color(white) margin(l=2 r=2 t=2 b=2)) plotregion(fcolor(white)) ///
          name(fA5_`tag', replace)
 }
 grc1leg fA5_mental fA5_physical, legendfrom(fA5_mental) position(6) rows(1) ///
     graphregion(color(white)) imargin(2 2 2 2)
 graph display, xsize(11) ysize(5.2)
 graph export "$rbgra/RB_V15E_AGE46_FigA5_health.png", replace width(2600)
 graph export "$rbgra/RB_V15E_AGE46_FigA5_health.pdf", replace
 di as err "=== output: RB_V15E_AGE46_FigA5_health.png + .pdf ==="
