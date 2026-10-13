*==============================================================================================
* fig_v15E_AGE46_FigA6_men.do
*
* Appendix Figure A7: the partner's labour-market outcomes around the end of the pregnancy.
*
* Reads:   estimates/RB_V15E_AGE46_A5A6fig.dta
* Writes:  figures/RB_V15E_AGE46_FigA6_men (png, pdf)
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
 keep if fig=="A6"
 foreach o in income employed wage workhrs {
     foreach g in 1 2 {
         local N=_N+1
         set obs `N'
         replace fig="A6"    in `N'
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

 local XL xlabel(1 `""25+" "before""' 2 `""13/24" "before""' 3 `""12/1" "before""' 4 `""0/12" "after""' 5 `""13/24" "after""' 6 `""25/36" "after""' 7 `""37/48" "after""' 8 `""49/60" "after""' 9 `""61+" "after""', labsize(vsmall) nogrid)

 local tags "income employed wage workhrs"
 local ttl_income   "A. Monthly labour income"
 local ttl_employed "B. Employment"
 local ttl_wage     "C. Log hourly wage"
 local ttl_workhrs  "D. Work hours"
 local yt_income   "Change (2015 GBP)"
 local yt_employed "Change (probability)"
 local yt_wage     "Change (log points)"
 local yt_workhrs  "Change (hours/week)"

 foreach tag of local tags {
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
        (scatter b     time if grp==1 & outcome=="`tag'", mcolor(navy%55) msymbol(O) msize(1.0)) ///
        (scatter b     time if grp==2 & outcome=="`tag'", mcolor(cranberry%55) msymbol(D) msize(1.0)) ///
        , yline(0, lcolor(cranberry%20) lwidth(medium) lpattern(solid)) ///
          xline(4, lcolor(gray%18) lwidth(6) lpattern(solid)) ///
          `XL' xscale(range(0.5 9.5)) ///
          ylabel(#5, labsize(vsmall) nogrid) yscale(range(`lo' `hi')) ///
          ytitle("`yt_`tag''", size(vsmall)) ///
          xtitle("Months relative to end of pregnancy", size(vsmall)) ///
          title("`ttl_`tag''", size(small)) ///
          legend(order(3 "Live birth" 4 "Pregnancy loss") rows(1) size(vsmall) symxsize(*.6) symysize(*.6) region(color(white))) ///
          graphregion(color(white) margin(l=2 r=2 t=2 b=2)) plotregion(fcolor(white)) ///
          name(fA6_`tag', replace)
 }
 grc1leg fA6_income fA6_employed fA6_wage fA6_workhrs, ///
     legendfrom(fA6_income) position(6) rows(1) cols(2) ///
     graphregion(color(white)) imargin(2 2 2 2)
 graph display, xsize(10) ysize(8)
 graph export "$rbgra/RB_V15E_AGE46_FigA6_men.png", replace width(2600)
 graph export "$rbgra/RB_V15E_AGE46_FigA6_men.pdf", replace
 di as err "=== output: RB_V15E_AGE46_FigA6_men.png ==="
