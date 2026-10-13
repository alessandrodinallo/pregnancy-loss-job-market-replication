*==============================================================================================
* descriptive_stats_wage_v15E_AGE46_D21.do
*
* Balance of the pre-conception covariates between the two groups.
* Source of Panel A of Appendix Table A13 and of Appendix Figure A5.
*
* Reads:   analysis dataset data/Wage/data_wage_v15.dta (survey data needed)
* Writes:  estimates/RB_V15E_AGE46_D21_balance (csv, dta) and a figure
*
* Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
* and pregnancy losses. Social Science Research, 141, 103450.
*==============================================================================================

quietly do "config.do"   // folder settings: start Stata in the package folder

clear all
set more off

 global data ${REPL_DATA}/Wage
 global des  ${REPL_EST}
 capture mkdir "$des"

 use "$data/data_wage_v15.dta", clear
 drop if wave == .
 duplicates tag pidp_f wave, gen(dup)
 bysort pidp_f wave: gen n_pw = _n
 drop if n_pw > 1 & dup > 0
 drop dup n_pw

 local s f

 keep if x1!=. & x2!=. & age_event>=18 & age_event<46 & (treated1==1|treated2==1) ///
       & first_wave_worked<=min_wave_t & first_wave_worked!=. & self_employed1_`s'==0

 drop if treated1==1 & treated2==1

 gen byte group = 1 if treated1==1
 replace  group = 2 if treated2==1
 label define grp 1 "Live birth" 2 "Pregnancy loss"
 label values group grp

 gen byte pre = (treated1==1 & inlist(time_x1_cat4,1,2)) | (treated2==1 & inlist(time_x2_cat4,1,2))
 keep if pre==1

 local vars fimnlabgrs_CPI_trim_`s' employed11_`s' tot_work_hours_`s' ISEI_`s' ///
            work_exp_`s' tenure_`s' private_`s' age_`s' income_partner_`s'
 collapse (mean) `vars' (first) group, by(pidp_`s')
 replace group = round(group)

 di as err "=== N donne per gruppo (v15) ==="
 tab group

 quietly summarize private_`s'
 di as err "private_`s': media=" %5.3f r(mean) "  min=" r(min) "  max=" r(max) "  (se ~1.0 costante -> escludere dalla tabella finale)"

 tempname M
 postfile `M' str28 varname double n_live n_loss mean_live mean_loss stddiff pval ///
   using "$des/RB_V15E_AGE46_D21_balance.dta", replace
 foreach v of local vars {
   quietly summarize `v' if group==1
   local m1 = r(mean)
   local s1 = r(sd)
   local n1 = r(N)
   quietly summarize `v' if group==2
   local m2 = r(mean)
   local s2 = r(sd)
   local n2 = r(N)
   local d  = .
   if (`s1'^2 + `s2'^2) > 0 & !missing(`s1',`s2') local d = (`m1' - `m2') / sqrt((`s1'^2 + `s2'^2)/2)
   quietly ttest `v', by(group)
   local p  = r(p)
   post `M' ("`v'") (`n1') (`n2') (`m1') (`m2') (`d') (`p')
 }
 postclose `M'

 use "$des/RB_V15E_AGE46_D21_balance.dta", clear
 gen absd = abs(stddiff)
 format mean_live mean_loss %9.2f
 format stddiff absd pval %6.3f
 di as err "=== D21 BALANCE su data_wage_v15 (gruppo parto vs perdita) ==="
 list varname mean_live mean_loss stddiff pval, clean noobs
 export delimited using "$des/RB_V15E_AGE46_D21_balance.csv", replace

 di as err ""
 di as err "=== CHECK: quante variabili con |std diff| >= 0.10 (oltre l'eta')? ==="
 count if absd >= 0.10 & varname != "age_`s'"
 di as err "   (pubblicato v23: solo age fuori soglia; tutte le altre |std diff|<0.08)"

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
 graph export "$des/RB_V15E_AGE46_D21_profiles.png", replace width(2400)

 di as err ""
 di as err "=== output: RB_V15E_AGE46_D21_balance.csv / .dta + RB_V15E_AGE46_D21_profiles.png in $des ==="
