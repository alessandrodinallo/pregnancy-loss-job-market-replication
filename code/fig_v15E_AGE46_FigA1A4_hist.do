*==============================================================================================
* fig_v15E_AGE46_FigA1A4_hist.do
*
* Appendix Figures A1 to A4: distributions of the four continuous outcomes, by group, at
* three windows around the end of the pregnancy.
*
* Reads:   analysis dataset data/Wage/data_wage_v15.dta (survey data needed)
* Writes:  figures/RB_V15E_AGE46_Fig*_hist (png, pdf)
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

 use "$data/data_wage_v15.dta", clear
 drop if wave==.
 duplicates tag pidp_`s' wave, gen(dup)
 bysort pidp_`s' wave: gen n_pw=_n
 drop if n_pw>1 & dup>0
 drop dup n_pw
 keep if x1!=. & x2!=. & age_event>=18 & age_event<46 & (treated1==1|treated2==1) ///
       & first_wave_worked<=min_wave_t & first_wave_worked!=. & self_employed1_`s'==0

 gen y_earn = fimnlabgrs_CPI_trim_`s'/1000
 rename fimnlabgrs_hrclean_CPI_trim_ln_`s' y_wage
 rename tot_work_hours_`s'                  y_hrs
 rename tot_work_hours_cond_ln_trim_`s'     y_hrsln

 local vars "y_earn y_wage y_hrs y_hrsln"
 local labs "A1 A2 A3 A4"
 local o_y_earn  "0.1  0(1)7     0(1)3.5   0.5  3.30 3.05"
 local o_y_wage  "0.2  0(1)4     0(.5)1.7  0.2  1.55 1.42"
 local o_y_hrs   "2    0(20)60   0(.05).2  11   .185 .172"
 local o_y_hrsln "0.2  1(1)4     0(.5)3.7  1.2  3.50 3.25"

 local periods "2 4 6"
 local ttl2 "13-24 months before"
 local ttl4 "0-12 months after"
 local ttl6 "25-36 months after"

 local i 0
 foreach v of local vars {
     local i = `i'+1
     local fl : word `i' of `labs'
     local pp "`o_`v''"
     local w   : word 1 of `pp'
     local xlb : word 2 of `pp'
     local ylb : word 3 of `pp'
     local tx  : word 4 of `pp'
     local tyP : word 5 of `pp'
     local tyL : word 6 of `pp'
     foreach t of local periods {
         quietly su `v' if time_x1_cat==`t'
         local mL : di %4.2f r(mean)
         local sL : di %4.2f r(sd)
         quietly su `v' if time_x2_cat==`t'
         local mP : di %4.2f r(mean)
         local sP : di %4.2f r(sd)
         twoway ///
            (hist `v' if time_x1_cat==`t', width(`w') fcolor(navy%12)      lcolor(navy%35)      lw(vthin)) ///
            (hist `v' if time_x2_cat==`t', width(`w') fcolor(cranberry%12) lcolor(cranberry%40) lw(vthin)) ///
            , title("`ttl`t''", size(medlarge)) subtitle("pregnancy end", size(medium)) ///
              ytitle("Density", size(medium)) xtitle("") ///
              ylabel(`ylb', angle(0) labsize(medium) nogrid) xlabel(`xlb', labsize(medium) nogrid) ///
              text(`tyP' `tx' "{it:Mean}: `mP', {it:sd}: `sP'", place(e) size(medium) color(cranberry%80)) ///
              text(`tyL' `tx' "{it:Mean}: `mL', {it:sd}: `sL'", place(e) size(medium) color(navy%80)) ///
              legend(order(1 "Live birth" 2 "Pregnancy loss") ring(0) position(1) ///
                     rows(1) region(color(white)) size(medium) symxsize(*.6)) ///
              graphregion(color(white)) plotregion(fcolor(white)) ///
              name(h_`t', replace) nodraw
     }
     grc1leg h_2 h_4 h_6, rows(1) legendfrom(h_2) position(6) ///
         graphregion(color(white)) imargin(2 2 2 2)
     graph display, xsize(12) ysize(4.6)
     graph export "$rbgra/RB_V15E_AGE46_Fig`fl'_hist.png", replace width(2800)
     graph export "$rbgra/RB_V15E_AGE46_Fig`fl'_hist.pdf", replace
     di as err "=== output: RB_V15E_AGE46_Fig`fl'_hist.png (`v') ==="
 }
