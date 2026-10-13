*==============================================================================================
* fig_v15E_AGE46_B3_childless.do
*
* Appendix Figures B3 and B4: women with a pregnancy loss and women who remain childless,
* labour income and hourly wage.
*
* Reads:   estimates/B3_V15E_AGE46_allcoef.dta
* Writes:  figures/RB_V15E_AGE46_B3_*_fig (png, pdf)
*
* Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
* and pregnancy losses. Social Science Research, 141, 103450.
*==============================================================================================

quietly do "config.do"   // folder settings: start Stata in the package folder

clear all
set more off
 global rbreg ${REPL_EST}
 global rbgra ${REPL_FIG}

 local outs "earnings wage"
 local elab_earnings "Difference in monthly labour income (2015 GBP)"
 local elab_wage     "Difference in log hourly wage"

foreach o of local outs {
    use "$rbreg/B3_V15E_AGE46_allcoef.dta", clear
    keep if outcome == "`o'"

    gen et = bin - 6
    gen lb = b - 1.96*se
    gen ub = b + 1.96*se

    local N = _N + 1
    set obs `N'
    replace et = -4 in `N'
    replace b  = 0  in `N'
    replace lb = 0  in `N'
    replace ub = 0  in `N'
    sort et

    quietly summarize ub
    local ymax = r(max)
    quietly summarize lb
    local ymin = r(min)

    gen _blo = `ymin'
    gen _bhi = `ymax'

    local ytit "`elab_`o''"

    #delimit ;
    twoway
        (rarea _blo _bhi et if et<0, color(gray%10) lwidth(none))    
        (rcap  lb ub et, lcolor(cranberry%45) lwidth(medthin))       
        (scatter b et, mcolor(cranberry%80) msymbol(O) msize(medium)),
        yline(0, lcolor(gray%55) lwidth(medthin))
        xline(0, lcolor(gray%55) lpattern(dash))                     
        xlabel(-6 "-6" -5 "-5" -4 "-4 (ref.)" -3 "-3" -2 "-2" -1 "-1"
               0 "0 (loss)" 1 "+1" 2 "+2", labsize(medium) angle(0))
        ylabel(, angle(0) labsize(medium))
        xtitle("Years relative to the pregnancy loss", size(medium))
        ytitle("`ytit'", size(medium))
        title("Pregnancy loss vs. childless women", size(medlarge))
        subtitle("Difference-in-differences (unadjusted)", size(medium))
        legend(off)
        graphregion(color(white)) plotregion(fcolor(white))
        name(b3_`o', replace);
    #delimit cr
    graph export "$rbgra/RB_V15E_AGE46_B3_`o'_fig.png", replace width(2200)
    graph export "$rbgra/RB_V15E_AGE46_B3_`o'_fig.pdf", replace
    di as result "=== scritto RB_V15E_AGE46_B3_`o'_fig.png/.pdf ==="
}
 di as result "Figure B3: il gap loss-vs-childless e' gia' aperto nei bin PRIMA della perdita (et<0) = selezione, non effetto. Banda grigia = finestra pre-evento."
