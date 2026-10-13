*==============================================================================================
* fig_v15E_AGE46_FigA8_nobirth.do
*
* Appendix Figure A8: pregnancy-loss estimates on the full sample and excluding women with
* a subsequent birth.
*
* Reads:   estimates/RB_V15E_AGE46_D17.dta
* Writes:  figures/RB_V15E_AGE46_FigA8_nobirth (png, pdf)
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

 use "$rbreg/RB_V15E_AGE46_D17.dta", clear
 keep if spec=="FULL_M5" | spec=="NOBIRTH_M5"
 gen byte s = (spec=="NOBIRTH_M5")
 levelsof outcome, local(outs)
 foreach o of local outs {
     foreach ss in 0 1 {
         local N=_N+1
         set obs `N'
         replace outcome="`o'" in `N'
         replace s=`ss'       in `N'
         replace bin=2        in `N'
         replace b=0          in `N'
         replace se=0         in `N'
     }
 }
 gen lb = b-1.96*se
 gen ub = b+1.96*se
 gen time = bin + cond(s==0,-0.05,0.05)

 local XL xlabel(1 `""25+" "before""' 2 `""13/24" "before""' 3 `""12/1" "before""' 4 `""0/12" "after""' 5 `""13/24" "after""' 6 `""25/36" "after""' 7 `""37/48" "after""' 8 `""49/60" "after""' 9 `""61+" "after""', labsize(vsmall) nogrid)

 local tags "earnings employed wage workhrs workhrs_cond"
 local ttl_earnings     "A. Labour income"
 local ttl_employed     "B. Employment"
 local ttl_wage         "C. Log hourly wage"
 local ttl_workhrs      "D. Work hours"
 local ttl_workhrs_cond "E. Conditional work hours (log)"
 local yt_earnings     "Change (2015 GBP)"
 local yt_employed     "Change (probability)"
 local yt_wage         "Change (log points)"
 local yt_workhrs      "Change (hours/week)"
 local yt_workhrs_cond "Change (log points)"

 foreach tag of local tags {
     quietly summ lb if outcome=="`tag'"
     local ymin=r(min)
     quietly summ ub if outcome=="`tag'"
     local ymax=r(max)
     local pad=(`ymax'-`ymin')*0.06
     local lo=`ymin'-`pad'
     local hi=`ymax'+`pad'
     twoway ///
        (rcap    ub lb time if s==0 & outcome=="`tag'", lcolor(navy%35) lwidth(medthin)) ///
        (rcap    ub lb time if s==1 & outcome=="`tag'", lcolor(navy%35) lwidth(medthin)) ///
        (scatter b     time if s==0 & outcome=="`tag'", mcolor(navy%70) msymbol(O)  msize(1.0)) ///
        (scatter b     time if s==1 & outcome=="`tag'", mcolor(navy%70) msymbol(Oh) msize(1.2)) ///
        , yline(0, lcolor(cranberry%20) lwidth(medium) lpattern(solid)) ///
          xline(4, lcolor(gray%18) lwidth(6) lpattern(solid)) ///
          `XL' xscale(range(0.5 9.5)) ///
          ylabel(#5, labsize(vsmall) nogrid) yscale(range(`lo' `hi')) ///
          ytitle("`yt_`tag''", size(vsmall)) ///
          xtitle("Months relative to end of pregnancy", size(vsmall)) ///
          title("`ttl_`tag''", size(small)) ///
          legend(order(3 "All women" 4 "Excluding subsequent birth") rows(1) size(vsmall) symxsize(*.6) symysize(*.6) region(color(white))) ///
          graphregion(color(white) margin(l=2 r=2 t=2 b=2)) plotregion(fcolor(white)) ///
          name(fA8_`tag', replace)
 }
 grc1leg fA8_earnings fA8_employed fA8_wage fA8_workhrs fA8_workhrs_cond, ///
     legendfrom(fA8_earnings) position(6) rows(2) cols(3) ///
     graphregion(color(white)) imargin(2 2 2 2)
 graph display, xsize(12) ysize(7.5)
 graph export "$rbgra/RB_V15E_AGE46_FigA8_nobirth.png", replace width(2800)
 graph export "$rbgra/RB_V15E_AGE46_FigA8_nobirth.pdf", replace
 di as err "=== output: RB_V15E_AGE46_FigA8_nobirth.png ==="
