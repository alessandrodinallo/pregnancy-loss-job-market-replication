*==============================================================================================
* final_v15.do
*
* Assembles the person-wave analysis dataset: merges the component files, builds the
* event-time variables around the end of the first pregnancy, the outcomes (labour income,
* hourly wage, work hours, employment) and the sample-eligibility variables.
*
* Reads:   the files written by the other construction do-files
* Writes:  data/Wage/data_wage_v15.dta
*
* Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
* and pregnancy losses. Social Science Research, 141, 103450.
*==============================================================================================

quietly do "config.do"   // folder settings: start Stata in the package folder

 global path1 ${REPL_RAW}/UKDA-6614-stata/stata/stata13_se/ukhls
 global path2 ${REPL_RAW}/UKDA-6931-stata/stata/stata13_se/ukhls

 global path6 ${REPL_RAW}

 global rawdata  	${REPL_RAW}/BHPS_UKHLS
 global path  	 	${REPL_RAW}/UKDA-6614-stata-2/stata/stata11_se
 global union       ${REPL_RAW}/UKDA-8473-stata/stata/stata13

 global do			${REPL_CODE}
 global data      	${REPL_DATA}/Wage
 global data2		${REPL_DATA}

 global results   	${REPL_OTHER}
 global regressions ${REPL_OTHER}/Regressions
 global margins   	${REPL_OTHER}/Margins

 global today 2025_1_1

use "$data/x8.dta", clear
order pidp wave x* N
keep pidp x* N wave wave* pregm* pregy* pregout* pregend* endmnt* date_conception* MAR*
replace wave = wave + 18
forvalues i = 1/11 {
	replace wave`i' = wave`i' + 18
}

		 * Pregnancy outcomes: duration of pregnancy
		 replace	endmnth1 = endmnth_fwd1 if endmnth1 == .
		 gen 		gestation = .
		 replace    gestation = endmnth1 if endmnth1 == 1
		 replace    gestation = 2 		 if endmnth1 == 2 | endmnth1 == 3
		 lab def 	gestation 1 "Less than 3 months" 2 "More than/equal to 3 months", modify
		 lab val    gestation gestation
		 lab var 	gestation "Gestational length"

tempfile x8
save    `x8', replace

merge 1:1 pidp wave using `x8' , nogen keep(1 3)

merge 1:1 pidp wave using "$data/BHPS_UKHLS_covariates", nogen keepusing(cohort dob doby_dv ethnicity scgh* sf12* family* fimn* gor hiqual cj* employ* jb* ovtrate basrate own_wave sex sex_dv marstat soc00_N_wave partner)
sort pidp wave

order pidp wave partner

preserve
use  "$data/BHPS_UKHLS_covariates", clear
keep pidp wave sex_dv cohort dob doby_dv ethnicity scgh* sf12* family*  fimn* gor hiqual jb* cj* employ* ovtrate basrate own_wave sex sex_dv marstat
replace sex_dv 		   = sex 		 if sex_dv == . 		& sex != . 		   & sex > 0
rename * *_partner
rename pidp_partner partner
rename wave_partner wave
keep if partner !=.
drop if wave == .
tempfile partner
save 	`partner', replace
restore

merge m:1 partner wave using "`partner'", nogen keep (1 3)

drop if partner != . & pidp == .
drop if wave == .
sort pidp wave

merge 1:1 pidp wave using "$data/interview_long",  keep(1 3)  nogen

preserve
use  "$data/interview_long", clear
keep pidp wave date_interview
rename pidp partner
rename date_interview date_interview_partner
keep if partner !=.
drop if wave == .
tempfile partner
save 	`partner', replace
restore
merge m:1 partner wave using `partner', nogen keep(1 3)

* Sex - filling missing values
egen coupleid=group(pidp partner)
clonevar  pidp_m = pidp
clonevar  pidp_f = pidp

sort pidp wave
by   pidp  : egen sex_dv_ = min(sex_dv)
by   pidp  : egen sex_    = min(sex)
replace sex_dv = sex_dv_ if sex_dv == . & pidp !=.
replace sex    = sex_ 	 if sex    == . & pidp !=.
replace sex_dv 		   = sex 		 if sex_dv == . 		& sex != . 		   & sex > 0
order pidp wave partner coupleid sex sex_dv sex_ sex_dv_

sort partner wave
by   partner  : egen sex_dv_partner_ = min(sex_dv_partner)
by   partner  : egen sex_partner_    = min(sex_partner)
replace sex_dv_partner = sex_dv_partner_ if sex_dv_partner == . & partner !=.
replace sex_partner    = sex_partner_ 	 if sex_partner    == . & partner !=.
replace sex_dv_partner = sex_partner 	 if sex_dv_partner == . & sex_partner != . & sex_partner > 0

drop sex*_

replace  pidp_m = . if sex_dv == 2
replace  pidp_f = . if sex_dv == 1
replace  pidp_m = pidp if sex_dv == 1
replace  pidp_f = pidp if sex_dv == 2
replace  pidp_m = partner if sex_dv_partner == 1
replace  pidp_f = partner if sex_dv_partner == 2

sort  coupleid pidp_m wave
order pidp wave partner coupleid sex sex_partner  sex_dv sex_dv_partner pidp_m pidp_f

foreach x in cohort doby_dv dob ethnicity family16_v3  own_wave  {
sort pidp wave
by   pidp  : egen `x'_ = min(`x')
sort partner wave
by   partner  : egen `x'_partner_ = min(`x'_partner)
replace `x' 		   = `x'_ 	      if `x' == .
replace `x'_partner    = `x'_partner_ if `x'_partner == .
}
drop *_

* Time varying age
gen age	  		= (date_interview - dob)	/ 12
gen age_partner = (date_interview - dob_partner) / 12
lab var age "Age"
lab var age_partner "Partner's age"

* Add children

preserve
use "$data/BHPS_UKHLS_children_new", clear
keep pidp wave dob* doc* N_child N_child_cat
tempfile child
save 	`child' , replace
restore

merge m:1 pidp wave using `child' , keep(1 3)  nogen

preserve
use `child' ,clear
keep   pidp wave N_child N_child_cat do*
rename pidp      	 	   		partner
rename N_child 			N_child_partner
rename N_child_cat 	N_child_cat_partner
rename do* 		   		    do*_partner
tempfile child
save   "`child'"
restore

merge m:1 partner wave using "`child'", keep(1 3)  nogen

preserve
keep if pidp != . & partner !=.
keep if sex_dv == 1 & sex_dv_partner == 1
bysort coupleid wave: keep if _n == _N
count
count if wave>18
ta N_child
restore

preserve
keep if pidp != . & partner !=.
keep if sex_dv == 1 & sex_dv_partner == 1
bysort coupleid wave: keep if _n == 1
count
count if wave>18
ta N_child
restore

 preserve
 use "$data/UKHLS_unemployment_wide", clear
 order pidp wave
 keep pidp wave  jobloss* date*
 rename *  *_f
 rename pidp_f pidp
 rename wave_f wave
 tempfile ue
 save    `ue'
 restore

 merge 1:1 pidp wave using `ue', nogen keep(1 3) force

 preserve
 use "$data/UKHLS_unemployment_wide", clear
 order pidp wave
 keep   pidp wave  jobloss* date*
 rename * *_m
 rename pidp_m partner
 rename wave_m wave
 keep if partner !=.
 tempfile ue
 save    `ue'
 restore

 merge m:1 partner wave using `ue', nogen keep(1 3) force

 drop if pidp == .

keep if sex_dv == 2
keep if wave > 18
keep if age > 10 & age <= 50

sort coupleid wave
by   coupleid wave     : replace date_interview = date_interview[_n-1] if wave[_n-1] == wave & wave == .
by   coupleid wave     : replace date_interview = date_interview[_n+1] if wave[_n+1] == wave & wave == .
sort pidp     wave
by   pidp: 				 replace date_interview = date_interview_partner if date_interview == .
by   pidp: 				 replace date_interview = date_interview[_n-1] + 12 if wave[_n-1] == wave-1 & wave == .
by   pidp: 				 replace date_interview = date_interview[_n+1] - 12 if wave[_n+1] == wave+1 & wave == .

set seed 	1234
forvalues x = 1(1)35 {
local q  = 12*`x'
local y  = 360 + `q'
gen    q`x' = 360 + `q' + round(runiform(1,12),1)
format q`x' %tm
}
order pidp wave date_interview q1 q10 q20 q30
forvalues x = 1(1)35{
replace date_interview = q`x' if date_interview == . & wave == `x'
}
sort pidp wave
 by pidp :      replace date_interview_lag = date_interview    - 12 if date_interview_lag == .
 by pidp :      replace date_interview 	  = date_interview_lag + 12 if date_interview     == .
	             format date_interview_lag %tm
order pidp wave date_intervie*

gen     date  = dofm(date_interview)
format  date  %d
gen     year  = year(date)
lab var year "Year FE"
gen     month  = month(date)
lab var month "Month FE"

* Quarter of conception
gen 	 date_conception = ym(pregy1, pregm1)
format   date_conception %tm
replace  date_conception = ym(pregy1, 6)     if pregm1 < 0 | pregm1 == .
gen      quarter = .
replace  quarter = 1 if month <= 3
replace  quarter = 2 if month >= 4 & month <= 6
replace  quarter = 3 if month >= 7 & month <= 9
replace  quarter = 4 if month >= 10& month <=12

gen     date_c = dofm(date_conception)
format  date_c  %d
gen     year_c  = year(date_c)
lab var year_c "Year (conception) FE"
gen     month_c  = month(date_c)
lab var month_c "Month (conception) FE"
drop    date_c

* Distance btw conception and interview
  sort pidp wave
	by pidp : gen 	  first_conception = 1 if  N_child == 1 & N_child[_n-1] == 0
	by pidp : replace first_conception = 1 if  N_child == 2 & N_child[_n-1] == 0
	by pidp : replace first_conception = 1 if  N_child == 3 & N_child[_n-1] == 0
			  replace first_conception = date_interview + round(runiform(1,12),1) - 9 if first_conception == 1
	by pidp : egen    date_conception_ = min(first_conception)
			  replace date_conception = date_conception_ if date_conception == .
			  drop    date_conception_ first_conception
		gen entry_LM =date_interview -  date_conception

gen 	distance_conception = .
replace distance_conception = 1 if entry_LM >=-1000 & entry_LM < -36
replace distance_conception = 2 if entry_LM >=-  36 & entry_LM < -24
replace distance_conception = 3 if entry_LM >=-  24 & entry_LM < -12
replace distance_conception = 4 if entry_LM >=-  12 & entry_LM <   0
replace distance_conception = 5 if entry_LM >=    0 & entry_LM <  12
replace distance_conception = 6 if entry_LM >=   12 & entry_LM <  24
replace distance_conception = 7 if entry_LM >=   24 & entry_LM <  36
replace distance_conception = 8 if entry_LM >=   36 & entry_LM <=-1000
replace distance_conception = 9 if distance_conception== .
lab def distance_conception  1 "-60/-36" 2 "-36/-24" 3 "-24/12" 4 "-12/0" 5 "0/12" 6 "12/24" 7 "24/36" 8 "36/48"  9 "Missing"
lab val distance_conception distance_conception

* Additional data
  merge m:1 month  year 	   using "$data2/employment_women_UK.dta", nogen keep(1 3)
  merge m:1 month   		  year 	   using "$data2/inflation_UK.dta",        nogen keep(1 3)
quietly count if missing(CPI) & !missing(year) & !missing(month)
if r(N) > 0 di as error "WARNING final_v13: " r(N) " person-waves have NO CPI (interview month outside deflator coverage) -> real DVs missing. Refresh inflation_UK from ONS d7bt."
  merge m:1 month   		  year gor using "$data/uk_ue_women",              nogen keep(1 3)

  sort pidp
  by   pidp : egen any_child 	  = min(N_child)
  by   pidp : egen ever_childless = min(any_child)

* Motherhood state / Pregnancy loss (cum)
gen mother = any_child > 0 & any_child <.
	gen wave_mother = wave if x1 == 1
	sort pidp wave
	by   pidp : egen min_wave_mother = min (wave_mother)
	order pidp date_int* wave any_child x1 x2 N_child mother min_wave_mother
replace mother = 1 if wave >= min_wave_mother & mother == 0 & any_child !=.
lab var mother "Mother"

	gen wave_loss = wave if x2 == 1
	sort pidp wave
	by   pidp : egen min_wave_loss = min (wave_loss)
	order pidp date_int* wave any_child x1 x2 N_child mother min_wave_*
gen  	pregnancy_loss = wave >= min_wave_loss & x2 != .
lab var pregnancy_loss "Any pregnancy loss"
	order pidp date_int* wave any_child x1 x2 N_child mother pregnancy_loss min_wave_*

* First wave of parenthood/miscarriage
forvalues x = 1/2 {
 gen wave_x`x'_ = wave if x`x' == 1
by pidp : egen wave_x`x' = min(wave_x`x'_)
}
drop wave_x*_

sort coupleid wave

capture confirm variable jbsoc00, exact
if _rc  di as error "[v14] WARNING: jbsoc00 absent -> wave-33 ISEI restore skipped"
else    replace jbsoc00_cc = jbsoc00 if wave==33 & (missing(jbsoc00_cc)|jbsoc00_cc<=0) & !missing(jbsoc00) & jbsoc00>0

gen byte   _soc_emp  = jbstat==1 | jbstat==2 | jbhas==1 | jboffy==3 | jboffy==97 | (fimnlabnet<. & fimnlabnet>0)
gen double _soc_jy   = jbbgy
replace    _soc_jy   = . if _soc_jy < 0
gen double _soc_jm   = jbbgm
replace    _soc_jm   = 6 if _soc_jm < 0 & _soc_jy < .
gen double _soc_djob = ym(_soc_jy, _soc_jm)   // this wave's job-start date (spell id)
gen double _soc_occ  = jbsoc00_cc if !missing(jbsoc00_cc) & jbsoc00_cc>0
gen double _soc_sdj  = _soc_djob  if !missing(jbsoc00_cc) & jbsoc00_cc>0
gen int    _soc_run  = 0          if !missing(jbsoc00_cc) & jbsoc00_cc>0
sort pidp wave
by pidp: replace _soc_occ = _soc_occ[_n-1]   if missing(_soc_occ) & (missing(jbsoc00_cc)|jbsoc00_cc<=0) & wave>=19 & _soc_emp & wave==wave[_n-1]+1
by pidp: replace _soc_sdj = _soc_sdj[_n-1]   if missing(_soc_sdj) & (missing(jbsoc00_cc)|jbsoc00_cc<=0) & wave>=19 & _soc_emp & wave==wave[_n-1]+1
by pidp: replace _soc_run = _soc_run[_n-1]+1 if missing(_soc_run) & (missing(jbsoc00_cc)|jbsoc00_cc<=0) & wave>=19 & _soc_emp & wave==wave[_n-1]+1
replace jbsoc00_cc = _soc_occ if (missing(jbsoc00_cc)|jbsoc00_cc<=0) & !missing(_soc_occ) & _soc_emp & wave>=19 ///
     & !missing(_soc_run) & _soc_run <= 2 ///
     & !( !missing(_soc_djob) & !missing(_soc_sdj) & _soc_djob != _soc_sdj )
drop _soc_emp _soc_jy _soc_jm _soc_djob _soc_occ _soc_sdj _soc_run

foreach var in dob age fimnlabgrs fimngrs  fimnlabnet fimnnet gor hiqual jbnssec jbnssec3 jbnssec5 jbnssec8 cjob employ jbsemp jbseg jbstat ///
jbhrs jbotpd ovtrate basrate jbhas jboff jboffy jbmngr jbsect jbsectpub jbsize jbbgm jbbgy jbbgdatm jbbgdaty jbsoc00_cc  ///
cohort N_child N_child_cat scghq1 scghq2 sf12pcs sf12mcs ///
 {
 clonevar `var'_m=`var' if sex_dv==1
 clonevar `var'_f=`var' if sex_dv==2
  replace `var'_f=`var'_partner if sex_dv_partner == 2
  replace `var'_m=`var'_partner if sex_dv_partner == 1
  }

* Date of birth
foreach var in dob doc {
forvalues i = 1/20 {
 clonevar `var'`i'_m=`var'`i' if sex_dv==1
 clonevar `var'`i'_f=`var'`i' if sex_dv==2
  replace `var'`i'_f=`var'`i'_partner if sex_dv_partner == 2
  replace `var'`i'_m=`var'`i'_partner if sex_dv_partner == 1
  }
  }

foreach g in m f {
forvalues i = 1/2 {
replace scghq`i'_`g'  = . if scghq`i'_`g'  < 0
sum     scghq`i'_`g' , det
local max = `r(max)'
di   `max'
gen     outcome`i'_`g'  = `max' - scghq`i'_`g'
local lbl`i' : variable label scghq`i'_`g'
lab var outcome`i'_`g' `"`lbl`i''"'
}

	clonevar wellbeing_`g'  = scghq1_`g'
	su wellbeing_`g', det
	local mean = r(mean)
	local sd   = r(sd)
	di `mean'
	di `sd'
	gen wellbeing_std_`g' = (wellbeing_`g' - `mean')/`sd'
}

* 1b. Mental/Physical health
foreach x in m p {
foreach g in m f {
ta  	sf12`x'cs_`g' 	  if sf12`x'cs_`g' < 0
gen 	sf12`x'cs_`g'_miss = sf12`x'cs_`g' < 0
lab var sf12`x'cs_`g'_miss  "sf12`x'cs missing"
replace sf12`x'cs_`g' =.  if sf12`x'cs_`g' < 0

su sf12`x'cs_`g'
local mean = r(mean)
local sd   = r(sd)
di `mean'
di `sd'
gen sf12`x'cs_std_`g' = (sf12`x'cs_`g' - `mean')/`sd'
}
}

* Independent variable

gen 	ethnicity_homo =  ethnicity == ethnicity_partner
lab var ethnicity_homo "Same ethnicity"
gen 	ethnicity_hete =  ethnicity != ethnicity_partner
lab var ethnicity_hete "Different ethnicity"
gen 	ethnicity_miss = (ethnicity == 0 | ethnicity_partner  == 0)
lab var ethnicity_miss "Missing ethnicity"

drop	ethnicity ethnicity_partner
gen     ethnicity = 1 if ethnicity_homo == 1
replace ethnicity = 2 if ethnicity_hete == 1
replace ethnicity = 3 if ethnicity_miss == 1
lab def ethnicity 1 "Same ethnicity" 2 "Different ethnicity" 3 "No/missing ethnicity", modify
lab val ethnicity ethnicity
lab var ethnicity "Ethnicity"

* Age
foreach g in m f {
gen     age_cat_`g' = 1 if age_`g' < 20
replace age_cat_`g' = 2 if age_`g' >=20 & age_`g' < 25
replace age_cat_`g' = 3 if age_`g' >=25 & age_`g' < 30
replace age_cat_`g' = 4 if age_`g' >=30 & age_`g' < 35
replace age_cat_`g' = 5 if age_`g' >=35 & age_`g' < 40
replace age_cat_`g' = 6 if age_`g' >=40 & age_`g' < 45
replace age_cat_`g' = 7 if age_`g' >=45 & age_`g' < 50
replace age_cat_`g' = 8 if age_`g' >=50 & age_`g' < 55
replace age_cat_`g' = 9 if age_`g' >=55 & age_`g' < 60
replace age_cat_`g' =10 if age_`g' >=60 & age_`g' < 65
replace age_cat_`g' =11 if age_`g' >=65
lab var age_cat_`g' "Age at start of partnership (ref.= 20-24)"
lab def age_cat_`g' 1 "< 20 years" 2 "20-24" 3 "25-29" 4 "30-34" 5 "35-39" 6 "40-44" 7 "45-49" 8 "50-54" 9 "55-59" 10 "60-64" 11 "65+"
lab val age_cat_`g' age_cat_`g'
}

* Age difference
gen      age_homo = 1 if abs(age_f - age_m) <= 2
replace  age_homo = 2 if 	 age_f - age_m  >  2
replace  age_homo = 3 if     age_m - age_f  >  2
lab var  age_homo "Age difference"
lab def  age_homo 1 "Same age" 2 "Woman older" 3 "Man older"
lab val  age_homo age_homo

* Union type
gen 	union_type = 1 if marstat == 1
replace union_type = 2 if marstat == 2
replace union_type = 3 if marstat >= 3 & marstat <= 6
replace union_type = 2 if union_type == . & partner !=.
replace union_type = 3 if union_type == . & partner ==.
lab def union_type 1 "Married" 2 "Cohabiting" 3 "Single"
lab val union_type union_type
lab var union_type "Type of union"

* Education

sort pidp wave
foreach g in m f {
by   pidp : replace hiqual_`g' = hiqual_`g'[_n-1] if hiqual_`g' == .
by   pidp : replace hiqual_`g' = hiqual_`g'[_n-2] if hiqual_`g' == . & hiqual_`g'[_n-1] == .
by   pidp : replace hiqual_`g' = hiqual_`g'[_n-3] if hiqual_`g' == . & hiqual_`g'[_n-1] == . & hiqual_`g'[_n-2] == .

by   pidp : replace hiqual_`g' = hiqual_`g'[_n+1] if hiqual_`g' == .
by   pidp : replace hiqual_`g' = hiqual_`g'[_n+1] if hiqual_`g' == .
by   pidp : replace hiqual_`g' = hiqual_`g'[_n+1] if hiqual_`g' == .
by   pidp : replace hiqual_`g' = hiqual_`g'[_n+1] if hiqual_`g' == .
by   pidp : replace hiqual_`g' = hiqual_`g'[_n+1] if hiqual_`g' == .
by   pidp : replace hiqual_`g' = hiqual_`g'[_n+1] if hiqual_`g' == .
by   pidp : replace hiqual_`g' = hiqual_`g'[_n+1] if hiqual_`g' == .
by   pidp : replace hiqual_`g' = hiqual_`g'[_n+1] if hiqual_`g' == .
by   pidp : replace hiqual_`g' = hiqual_`g'[_n+1] if hiqual_`g' == .
by   pidp : replace hiqual_`g' = hiqual_`g'[_n+1] if hiqual_`g' == .
by   pidp : replace hiqual_`g' = hiqual_`g'[_n+1] if hiqual_`g' == .
			replace hiqual_`g' = 0 				  if hiqual_`g'	 < 0 	|  hiqual_`g' == .
}

foreach g in m f {
replace hiqual_`g'  =99  if hiqual_`g' <0 | hiqual_`g' ==.
}
egen    education =   rowmin(hiqual_m   hiqual_f)
lab val education a_hiqual_dv
replace education =  0 if education == .
gen 	education_homo = 1 if     hiqual_m ==hiqual_f
replace education_homo = 2 if     hiqual_m < hiqual_f
replace education_homo = 3 if     hiqual_m > hiqual_f
replace education_homo = 4 if     hiqual_m == 99 | hiqual_f == 99

lab var education_homo "Education homogamy"
lab def education_homo 1 "Same education" 2 "Man higher education" 3 "Woman higher education" 4 "Missing"
lab val education_homo education_homo

* Job
replace jbnssec8_m = 0 if jbnssec8_m < 0 | jbnssec8_m == .
replace jbnssec8_f = 0 if jbnssec8_f < 0 | jbnssec8_f == .
gen 	jb5_miss = (jbnssec8_m == 0 | jbnssec8_f == 0)
lab var jb5_miss "partners' ISCO missing"
gen     jb5_homo = jbnssec8_m == jbnssec8_f & jbnssec8_m != 0 & jbnssec8_f != 0
lab var jb5_homo "Same ISCO"
gen 	jb5_hete =  jbnssec8_m != jbnssec8_f & (jbnssec8_m != 0 & jbnssec8_f != 0)
lab var jb5_hete "Different ISCO"

gen     jb5_diff = 1 if jbnssec8_m < jbnssec8_f & (jbnssec8_m > 0 & jbnssec8_m !=.) ///
												& (jbnssec8_f > 0 & jbnssec8_f !=.)
replace jb5_diff = 2 if jbnssec8_f < jbnssec8_m & (jbnssec8_m > 0 & jbnssec8_m !=.) ///
												& (jbnssec8_f > 0 & jbnssec8_f !=.)
replace jb5_diff = 3 if jbnssec8_f ==jbnssec8_m & (jbnssec8_m > 0 & jbnssec8_m !=.) ///
												& (jbnssec8_f > 0 & jbnssec8_f !=.)
replace jb5_diff = 4 if (jbnssec8_m > 0 & jbnssec8_m !=.)  & (jbnssec8_f == 0 | jbnssec8_f ==.)
replace jb5_diff = 5 if (jbnssec8_f > 0 & jbnssec8_f !=.)  & (jbnssec8_m == 0 | jbnssec8_m ==.)
replace jb5_diff = 6 if  jbnssec8_f==     jbnssec8_m       & (jbnssec8_m == 0 & jbnssec8_f == 0)
replace jb5_diff = 7 if (jbnssec8_f== 0 & jbnssec8_m ==.)  | (jbnssec8_m == 0 & jbnssec8_f == .)
lab var jb5_diff "Job difference"
lab def jb5_diff 1 "Job Male higher" 2 "Job Female higher" 3 "Same job" ///
				 4 "Job Male higher - Female OLF/miss" 5 "Job Male higher - Male OLF/miss" ///
				 6 "Same missing" 7 "One missing", modify
lab val jb5_diff jb5_diff

gen 	job = 1 if	jb5_diff == 3
replace job = 2 if  jb5_diff == 1 | jb5_diff == 2 | jb5_diff == 4 | jb5_diff == 5
replace job = 3 if  jb5_diff == 6 | jb5_diff == 7

lab var job "Job status homogamy"
lab def job 1 "Same class" 2 "Different class" 3 "No/missing job"
lab val job job

* ISEI (socio-economic prestige)
do "$do/SOC_ISEI_v2"

foreach g in m f {
gen byte ISEI_miss_`g' = missing(ISEI_`g')
lab var  ISEI_miss_`g' "ISEI missing (non-employed / unmapped occupation)"
replace  ISEI_`g' = 0 if ISEI_miss_`g' == 1
}

  global mother     any_* N_child N_child_cat ever_childless mother pregnancy_loss  gest*
  global x          x1 x2 x3 x4 x5 MAR1  endmnth1 endmnth_fwd1 pregend1 pregend_fwd1 pregm1 pregy1 date_conception1 distance_conception
  global jm			  soc00_N_wave  CPI
  global union		year month union_type marstat

 keep pidp partner wave $union $mother $x $jm *_m *_f date_interv*
 drop doc* dob*

 compress
 save "$data/temp"  , replace

use "$data/temp", clear

 order pidp date_interv* wave any_child     x? N_child*

 * Childless and miscarriage
 sort  pidp wave
 by    pidp: gen wave_t2  = ever_childless == 0 & x2 == 1   // Childless up to the prior year
 order pidp date_interv* wave any_child   x1 x2 ever_childless wave_t2

 * Childless and mother
 sort  pidp wave
 by    pidp: gen wave_t1  = ever_childless == 0 & x1 == 1   // Childless up to the prior year
 order pidp date_interv* wave any_child   x1 x2 ever_childless wave_t?

 forvalues i = 1/2 {
 gen wave_t`i'_ = wave if wave_t`i' == 1
 }
  order pidp date_interv* wave any_child   x1 x2  wave_t?

  forvalues i = 1/2 {
  by pidp : egen min_wave_t`i' = min(wave_t`i'_)
   }

  egen min_wave_t = rowmin(min_wave_t?)

  forvalues i = 1/2 {
  gen t`i' = wave == min_wave_t & x`i' == 1
  }
  gen drop = t1 == 1 & t2 == 1
  forvalues i = 1/2 {
  replace t`i' = 0 if drop == 1
  }

  order pidp date_interv* wave ever_childless x1 x2 t? wave_t? min_wave_t? min_wave_t wave_t?_

 forvalues i = 1/2 {
 by pidp : egen treated`i' = max(t`i')
 }
    order pidp date_interv* wave ever_childless x1 x2 t? treated? wave_t? min_wave_t? min_wave_t wave_t?_
 drop wave_t?_

 forvalues i = 1/2 {
 gen	 time_x`i'_cat = .
 sort pidp wave

  forvalues x = 4/12 {
 by   pidp   : replace time_x`i'_cat = -3   if t`i'[_n+`x'] == 1
 }

 forvalues x = 1/3 {
 by   pidp   : replace time_x`i'_cat = -`x' if t`i'[_n+`x'] == 1
 }

			   replace time_x`i'_cat = 0    if t`i' == 1

 forvalues x = 1/4 {
 by   pidp   : replace time_x`i'_cat =  `x' if t`i'[_n-`x'] == 1
 }

  forvalues x = 5/12 {
 by   pidp   : replace time_x`i'_cat =  4   if t`i'[_n-`x'] == 1
 }

  }
     order pidp date_interv* wave ever_childless x1 x2 t? wave_t? time_x?_cat min_wave_t? min_wave_t

* Recoding
forvalues i = 1/2 {
 replace time_x`i'_cat = time_x`i'_cat + 4
 lab def time_x`i'_cat  1 "25+ before" 2 "24/13 before" 3 "12/1 before" 4 "0/12 after" 5 "13/24 after" 6 "25/36 after" 7 "37/48 after" 8 "49+ after", modify
 lab val time_x`i'_cat time_x`i'_cat
 replace time_x`i'_cat = 1 if time_x`i'_cat  == . & (x1 !=. | x2 !=.)
 }

 forvalues i = 1/2 {
 clonevar time_x`i'_cat1 = time_x`i'_cat
 }

 forvalues i = 1/2 {
 gen	 time_x`i'_cat2 = .
 sort pidp wave

  forvalues x = 4/12 {
 by   pidp   : replace time_x`i'_cat2 = -4   if t`i'[_n+`x'] == 1
 }

 forvalues x = 1/3 {
 by   pidp   : replace time_x`i'_cat2 = -`x' if t`i'[_n+`x'] == 1
 }

			   replace time_x`i'_cat2 = 0    if t`i' == 1

 forvalues x = 1/2 {
 by   pidp   : replace time_x`i'_cat2 =  `x' if t`i'[_n-`x'] == 1
 }

  forvalues x = 3/12 {
 by   pidp   : replace time_x`i'_cat2 =  3   if t`i'[_n-`x'] == 1
 }
 }

 * Recoding
forvalues i = 1/2 {
 replace time_x`i'_cat2 = time_x`i'_cat2 + 5
 lab def time_x`i'_cat2  1 "37+ before" 2 "36/25 before" 3 "24/13 before" 4 "12/1 before" 5 "0/12 after" 6 "13/24 after" 7 "25/36 after" 8 "37+ after" , modify
 lab val time_x`i'_cat2 time_x`i'_cat2
 replace time_x`i'_cat2 = 1 if time_x`i'_cat2  == . & (x1 !=. | x2 !=.)
 }

 forvalues i = 1/2 {
 gen	 time_x`i'_cat3 = .
 sort pidp wave

  forvalues x = 2/12 {
 by   pidp   : replace time_x`i'_cat3 = -2   if t`i'[_n+`x'] == 1
 }

 forvalues x = 1/1 {
 by   pidp   : replace time_x`i'_cat3 = -`x' if t`i'[_n+`x'] == 1
 }

			   replace time_x`i'_cat3 = 0    if t`i' == 1

 forvalues x = 1/2 {
 by   pidp   : replace time_x`i'_cat3 =  `x' if t`i'[_n-`x'] == 1
 }

  forvalues x = 3/12 {
 by   pidp   : replace time_x`i'_cat3 =  3   if t`i'[_n-`x'] == 1
 }
 }

 * Recoding
forvalues i = 1/2 {
 replace time_x`i'_cat3 = time_x`i'_cat3 + 3
 lab def time_x`i'_cat3 0 "No event" 1 "13+ before" 2 "12/1 before" 3 "0/12 after" 4 "13/24 after" 5 "25/36 after" 6 "37+ after" , modify
 lab val time_x`i'_cat3 time_x`i'_cat3
 replace time_x`i'_cat3 = 1 if time_x`i'_cat3  == . & (x1 !=. | x2 !=.)
 }

 forvalues i = 1/2 {
 gen	 time_x`i'_cat4 = .
 sort pidp wave

  forvalues x = 4/12 {
 by   pidp   : replace time_x`i'_cat4 = -3   if t`i'[_n+`x'] == 1
 }

 forvalues x = 1/3 {
 by   pidp   : replace time_x`i'_cat4 = -`x' if t`i'[_n+`x'] == 1
 }

			   replace time_x`i'_cat4 = 0    if t`i' == 1

 forvalues x = 1/4 {
 by   pidp   : replace time_x`i'_cat4 =  `x' if t`i'[_n-`x'] == 1
 }

 forvalues x = 5/12 {
 by   pidp   : replace time_x`i'_cat4 =  5   if t`i'[_n-`x'] == 1
 }

 }

* Recoding
forvalues i = 1/2 {
 replace time_x`i'_cat4 = time_x`i'_cat4 + 4
 lab def time_x`i'_cat4  1 "25+ before" 2 "24/13 before" 3 "12/1 before" 4 "0/12 after" 5 "13/24 after" 6 "25/36 after" 7 "37/48 after" 8 "49/60 after" 9 "61+ after", modify
 lab val time_x`i'_cat4 time_x`i'_cat4
 replace time_x`i'_cat4 = 1 if time_x`i'_cat4  == . & (x1 !=. | x2 !=.)
 }

clonevar time_x1_cat5 = time_x1_cat4
clonevar time_x2_cat5 = time_x2_cat4
replace  time_x2_cat5 = time_x2_cat5 + 10 if gestation == 2 & time_x2_cat5 > 1
lab def  time_x2_cat5  1 "25+ before (<3m)"  2 "24/13 before (<3m)"  3 "12/1 befor (<3m)"  4 "0/12 after (<3m)"  5 "13/24 after (<3m)"  6 "25/36 after (<3m)"  7 "37/48 after (<3m)"  8 "49/60 after (<3m)"  9 "61+ after (<3m)" ///
					  11 "25+ before (>3m)" 12 "24/13 before (>3m)" 13 "12/1 befor (>3m)" 14 "0/12 after (>3m)" 15 "13/24 after (>3m)" 16 "25/36 after (>3m)" 17 "37/48 after (>3m)" 18 "49/60 after (>3m)" 19 "61+ after (>3m)" , modify
lab val  time_x2_cat5   time_x2_cat5

 * Transition to second child (for those who have 1)
 preserve
 keep pidp wave x1 treated?
 keep if x1 == 1
 by   pidp : gen n = _n
 drop x1

 gen  first_birth_ = wave if n == 1
 gen second_birth_ = wave if n == 2
 gen  third_birth_ = wave if n == 3
 gen higher_birth_ = wave if n >= 2
 gen  first_birth_m_=wave if n >= 1 & treated2 == 1

 foreach x in first second third higher {
by pidp : egen `x'_birth = min(`x'_birth_)
 }
by pidp : egen first_birth_m = min(first_birth_m_)
 drop *_

 tempfile birth
 save    `birth'
 restore

 * Transition to first child (for those who have none)

 merge m:m pidp using `birth', keep (1 3)
 order pidp date_interv* wave ever_childless x1 x2 t? wave_t? time_x?_cat *_birt* min_wave_t? min_wave_t
 sort pidp wave
 by   pidp:  gen    time_x3_cat = 0
 by   pidp: replace time_x3_cat = 1 if wave >= second_birth  & treated1 ==1
 by   pidp: replace time_x3_cat = 1 if wave >= first_birth_m & treated2 ==1
 order pidp date_interv* wave ever_childless x1 x2 t? wave_t? time_x?_cat min_wave_t? min_wave_t
 lab def time_x3_cat 1 "A(nother) child" , modify
 lab val time_x3_cat time_x3_cat

 * Transition to motherhood
 sort pidp wave
 by   pidp:     gen time_x4_cat = 0
 by   pidp: replace time_x4_cat = 1 if wave >= first_birth_m & treated2 ==1
		    lab def time_x4_cat 1 "Mother" 0 "Childless" , modify
		    lab val time_x4_cat time_x4_cat
 order pidp date_interv* wave ever_childless x1 x2 t? wave_t? time_x?_cat min_wave_t? min_wave_t

 foreach g in m f {
 	forvalues i = 1/4 {
 	clonevar time_x`i'_cat_`g' = time_x`i'_cat
 }
 }

gen 	treated = 0 if treated1 == 1
replace treated = 1 if treated2 == 1
lab def treated 0 "Live birth" 1 "Non-live birth"
lab val treated treated

* Time to event
gen 	time_x_cat = .
replace time_x_cat = time_x1_cat if treated1 == 1
replace time_x_cat = time_x2_cat if treated2 == 1
lab val time_x_cat time_x1_cat
lab var time_x_cat "Time before/to event"

forvalues x = 1/4 {
clonevar time_x_cat`x' = time_x_cat
	}

replace  time_x_cat2 = 6 if time_x_cat2 > 6 & time_x_cat < .
lab def  time_x_cat2 1 "25+ before" 2 "24/13 before" 3 "12/1 before" 4 "0/12 after" 5 "13/24 after" 6 "25+ after" , modify
lab val  time_x_cat2 time_x_cat2

replace  time_x_cat3 = 5 if time_x_cat1 > 5 & time_x_cat < .
lab def  time_x_cat3 1 "25+ before" 2 "24/13 before" 3 "12/1 before" 4 "0/12 after" 5 "13+ after", modify
lab val  time_x_cat3 time_x_cat3

replace  time_x_cat4 = 4 if time_x_cat4 > 4 & time_x_cat < .
lab def  time_x_cat4 1 "25+ before" 2 "24/13 before" 3 "12/1 before" 4 "0/12 after", modify
lab val  time_x_cat4 time_x_cat4

forvalues x = 1/4 {
	local j = `x' + 4
clonevar time_x_cat`j' = 	  time_x_cat`x'
replace  time_x_cat`j' = 2 if time_x_cat`x' < 2 & time_x_cat < .
	}

lab def  time_x_cat5 2 "13+ before" 3 "12/1 before" 4 "0/12 after" 5 "13/24 after" 6 "25/36 after" 7 "37/48 after" 8 "49+ after"  , modify
lab val  time_x_cat5 time_x_cat5
lab def  time_x_cat6 2 "13+ before" 3 "12/1 before" 4 "0/12 after" 5 "13/24 after" 6 "25+ after" , modify
lab val  time_x_cat6 time_x_cat6
lab def  time_x_cat7 2 "13+ before" 3 "12/1 before" 4 "0/12 after" 5 "13+ after" , modify
lab val  time_x_cat7 time_x_cat7
lab def  time_x_cat8 2 "13+ before" 3 "12/1 before" 4 "0+ after", modify
lab val  time_x_cat8 time_x_cat8

sort 	pidp  wave
bysort 	pidp (wave) : gen pregnancy_loss_N = sum(x2)
				 clonevar pregnancy_loss_N_cat = pregnancy_loss_N
				 replace  pregnancy_loss_N_cat = 2 if pregnancy_loss_N > 2
				 lab def  pregnancy_loss_N_cat 0 "None" 1 "1 pregnancy loss" 2 "2+ pregnancy losses"
				 lab val  pregnancy_loss_N_cat pregnancy_loss_N_cat

* Wave of the event
gen 	t = .
replace t = t1 if treated1 == 1
replace t = t2 if treated2 == 1
gen 	wave_t_= wave if t == 1
sort pidp_f wave
by 	 pidp_f : egen wave_t = min(wave_t_)
lab var wave_t "Wave of the event"
drop wave_t_

* Childbirth after the first pregnancy
bysort 	pidp_f  (wave) : gen cum_delivery   = sum(x1)
gen cum_delivery_min_ = wave if cum_delivery == 1
sort 	pidp_f 	 wave
bysort 	pidp_f 		 :  egen wave_delivery   = min(cum_delivery_min_)
drop cum_delivery_min_

* Time to first birth (continuous)
gen 	time_to_first_birth = wave_delivery - wave_t
lab var time_to_first_birth "Time between the first pregnancy and the first live birth (years)"

forvalues x = 1/3 {
clonevar time_to_first_birth_cat`x' = time_to_first_birth
}
* Time to first birth (categorical) /1
replace time_to_first_birth_cat1 = 4 if time_to_first_birth > 3 & time_to_first_birth < .
replace time_to_first_birth_cat1 = 4 if time_to_first_birth == . & treated2 == 1
lab var time_to_first_birth_cat1 "Time between the first pregnancy and the first live birth (years, cat)"
lab def time_to_first_birth_cat1 0 "Live birth t0" 1 "Live birth t1" 2 "Live birth t2" 3 "Live birth t3" 4 "Live birth t4+/No live birth reported" , modify
lab val time_to_first_birth_cat1  time_to_first_birth_cat1

* Time to first birth (categorical) /2
replace time_to_first_birth_cat2 = 3 if time_to_first_birth > 2 & time_to_first_birth < .
replace time_to_first_birth_cat2 = 3 if time_to_first_birth == . & treated2 == 1
lab var time_to_first_birth_cat2 "Time between the first pregnancy and the first live birth (years, cat)"
lab def time_to_first_birth_cat2 0 "Live birth t0" 1 "Live birth t1" 2 "Live birth t2" 3 "Live birth t3+/No live birth reported" , modify
lab val time_to_first_birth_cat2  time_to_first_birth_cat2

* Time to first birth (categorical) /3
replace time_to_first_birth_cat3 = 2 if time_to_first_birth > 1 & time_to_first_birth < .
replace time_to_first_birth_cat3 = 2 if time_to_first_birth == . & treated2 == 1
lab var time_to_first_birth_cat3 "Time between the first pregnancy and the first live birth (years, cat)"
lab def time_to_first_birth_cat3 0 "Live birth t0" 1 "Live birth t1" 2 "Live birth t2+/No live birth reported" , modify
lab val time_to_first_birth_cat3  time_to_first_birth_cat3

forvalues x = 1/3 {
	local j = `x' + 3
gen time_to_first_birth_cat`j' = time_to_first_birth
}
replace time_to_first_birth_cat4 = 4 if time_to_first_birth > 3 & time_to_first_birth < .
replace time_to_first_birth_cat4 = 5 if time_to_first_birth == . & treated2 == 1
lab var time_to_first_birth_cat4 "Time between the first pregnancy and the first live birth (years, cat)"
lab def time_to_first_birth_cat4 0 "Live birth t0" 1 "Live birth t1" 2 "Live birth t2" 3 "Live birth t3" 4 "Live birth t4+" 5 "No live birth reported" , modify
lab val time_to_first_birth_cat4  time_to_first_birth_cat4

replace time_to_first_birth_cat5 = 3 if time_to_first_birth > 2 & time_to_first_birth < .
replace time_to_first_birth_cat5 = 4 if time_to_first_birth == . & treated2 == 1
lab var time_to_first_birth_cat5 "Time between the first pregnancy and the first live birth (years, cat)"
lab def time_to_first_birth_cat5 0 "Live birth t0" 1 "Live birth t1" 2 "Live birth t2" 3 "Live birth t3+" 4 "No live birth reported" , modify
lab val time_to_first_birth_cat5  time_to_first_birth_cat5

replace time_to_first_birth_cat6 = 2 if time_to_first_birth > 1 & time_to_first_birth < .
replace time_to_first_birth_cat6 = 3 if time_to_first_birth == . & treated2 == 1
lab var time_to_first_birth_cat6 "Time between the first pregnancy and the first live birth (years, cat)"
lab def time_to_first_birth_cat6 0 "Live birth t0" 1 "Live birth t1" 2 "Live birth t2+" 3 "No live birth reported" , modify
lab val time_to_first_birth_cat6  time_to_first_birth_cat6

* Time before/to pregnancy + Outcome of pregnancy/ies
ta time_x_cat6
ta time_to_first_birth_cat2
 gen 		trial = .
 replace	trial = 0 if time_x_cat6 == 2   // 13+ before
 replace 	trial = 1 if time_x_cat6 == 3 & time_to_first_birth_cat2 == 0   // 12/1 before & Live birth t0
 replace 	trial = 2 if time_x_cat6 == 4 & time_to_first_birth_cat2 == 0   // 0/12 after & Live birth t0
 replace 	trial = 3 if time_x_cat6 == 5 & time_to_first_birth_cat2 == 0   // 13/24 after & Live birth t0
 replace 	trial = 4 if time_x_cat6 == 6 & time_to_first_birth_cat2 == 0   // 25+ after & Live birth t0

 replace 	trial = 5 if time_x_cat6 == 3 & time_to_first_birth_cat2 == 1   // 12/1 before & Live birth t1
 replace 	trial = 6 if time_x_cat6 == 4 & time_to_first_birth_cat2 == 1   // 0/12 after & Live birth t1
 replace 	trial = 7 if time_x_cat6 == 5 & time_to_first_birth_cat2 == 1   // 13/24 after & Live birth t1
 replace 	trial = 8 if time_x_cat6 == 6 & time_to_first_birth_cat2 == 1   // 25+ after & Live birth t1

 replace 	trial = 9 if time_x_cat6 == 3 & time_to_first_birth_cat2 == 2   // 12/1 before & Live birth t2
 replace 	trial =10 if time_x_cat6 == 4 & time_to_first_birth_cat2 == 2   // 0/12 after & Live birth t2
 replace 	trial =11 if time_x_cat6 == 5 & time_to_first_birth_cat2 == 2   // 13/24 after & Live birth t2
 replace 	trial =12 if time_x_cat6 == 6 & time_to_first_birth_cat2 == 2   // 25+ after & Live birth t2

 replace 	trial =13 if time_x_cat6 == 3 & time_to_first_birth_cat2 == 3   // 12/1 before & Live birth t3
 replace 	trial =14 if time_x_cat6 == 4 & time_to_first_birth_cat2 == 3   // 0/12 after & Live birth t3
 replace 	trial =15 if time_x_cat6 == 5 & time_to_first_birth_cat2 == 3   // 13/24 after & Live birth t3
 replace 	trial =16 if time_x_cat6 == 6 & time_to_first_birth_cat2 == 3   // 25+ after & Live birth t3/No

 lab def    trial 0 "13+ before" ///
				  1 "12/1 before/Birth t0"  2 "0/12 after/Birth t0"  3 "13/24 after/Birth t0"  4 "25+ after/Birth t0" ///
				  5 "12/1 before/Birth t1"  6 "0/12 after/Birth t1"  7 "13/24 after/Birth t1"  8 "25+ after/Birth t1" ///
				  9 "12/1 before/Birth t2" 10 "0/12 after/Birth t2" 11 "13/24 after/Birth t2" 12 "25+ after/Birth t2" ///
				 13 "12/1 before/Birth t3+"14 "0/12 after/Birth t3+"15 "13/24 after/Birth t3+"16 "25+ after/Birth t3+" , modify
 lab val 	trial trial

 gen 		trial2 = .
 replace	trial2 = 0 if time_x_cat6 == 2 & time_to_first_birth_cat2 == 0   // 13+ before & Live birth t0
 replace 	trial2 = 1 if time_x_cat6 == 3 & time_to_first_birth_cat2 == 0   // 12/1 before & Live birth t0
 replace 	trial2 = 2 if time_x_cat6 == 4 & time_to_first_birth_cat2 == 0   // 0/12 after & Live birth t0
 replace 	trial2 = 3 if time_x_cat6 == 5 & time_to_first_birth_cat2 == 0   // 13/24 after & Live birth t0
 replace 	trial2 = 4 if time_x_cat6 == 6 & time_to_first_birth_cat2 == 0   // 25+ after & Live birth t0

 replace 	trial2 = 5 if time_x_cat6 == 2 & time_to_first_birth_cat2 == 1   // 13+ before & Live birth t1
 replace 	trial2 = 6 if time_x_cat6 == 3 & time_to_first_birth_cat2 == 1   // 12/1 before & Live birth t1
 replace 	trial2 = 7 if time_x_cat6 == 4 & time_to_first_birth_cat2 == 1   // 0/12 after & Live birth t1
 replace 	trial2 = 8 if time_x_cat6 == 5 & time_to_first_birth_cat2 == 1   // 13/24 after & Live birth t1
 replace 	trial2 = 9 if time_x_cat6 == 6 & time_to_first_birth_cat2 == 1   // 25+ after & Live birth t1

 replace 	trial2 = 5 if time_x_cat6 == 2 & time_to_first_birth_cat2 == 2   // 13+ before & Live birth t2
 replace 	trial2 =10 if time_x_cat6 == 3 & time_to_first_birth_cat2 == 2   // 12/1 before & Live birth t2
 replace 	trial2 =11 if time_x_cat6 == 4 & time_to_first_birth_cat2 == 2   // 0/12 after & Live birth t2
 replace 	trial2 =12 if time_x_cat6 == 5 & time_to_first_birth_cat2 == 2   // 13/24 after & Live birth t2
 replace 	trial2 =13 if time_x_cat6 == 6 & time_to_first_birth_cat2 == 2   // 25+ after & Live birth t2

 replace 	trial2 = 5 if time_x_cat6 == 2 & time_to_first_birth_cat2 == 3   // 13+ before & Live birth t3
 replace 	trial2 =14 if time_x_cat6 == 3 & time_to_first_birth_cat2 == 3   // 12/1 before & Live birth t3
 replace 	trial2 =15 if time_x_cat6 == 4 & time_to_first_birth_cat2 == 3   // 0/12 after & Live birth t3
 replace 	trial2 =16 if time_x_cat6 == 5 & time_to_first_birth_cat2 == 3   // 13/24 after & Live birth t3
 replace 	trial2 =17 if time_x_cat6 == 6 & time_to_first_birth_cat2 == 3   // 25+ after & Live birth t3/No

  lab def   trial2  ///
				  0 "13+ before/Birth t0"   1 "12/1 before/Birth t0"  2 "0/12 after/Birth t0"  3 "13/24 after/Birth t0"  4 "25+ after/Birth t0" ///
				  5 "13+ before/Birth t1+"  6 "12/1 before/Birth t1"  7 "0/12 after/Birth t1"  8 "13/24 after/Birth t1"  9 "25+ after/Birth t1" ///
										   10 "12/1 before/Birth t2" 11 "0/12 after/Birth t2" 12 "13/24 after/Birth t2" 13 "25+ after/Birth t2" ///
										   14 "12/1 before/Birth t3+"15 "0/12 after/Birth t3+"16 "13/24 after/Birth t3+"17 "25+ after/Birth t3+" , modify
 lab val 	trial2 trial2

* Shorter time span before/to birth
ta time_x_cat6
ta time_to_first_birth_cat5
 gen 		trial3 = .
 replace	trial3 = 0 if time_x_cat6 == 2 & time_to_first_birth_cat5 == 0   // 13+ before & Live birth t0
 replace 	trial3 = 1 if time_x_cat6 == 3 & time_to_first_birth_cat5 == 0   // 12/1 before & Live birth t0
 replace 	trial3 = 2 if time_x_cat6 == 4 & time_to_first_birth_cat5 == 0   // 0/12 after & Live birth t0
 replace 	trial3 = 3 if time_x_cat6 == 5 & time_to_first_birth_cat5 == 0   // 13/24 after & Live birth t0
 replace 	trial3 = 4 if time_x_cat6 == 6 & time_to_first_birth_cat5 == 0   // 25+ after & Live birth t0

 replace 	trial3 = 5 if time_x_cat6 == 3 & time_to_first_birth_cat5 == 1   // 12/1 before & Live birth t1
 replace 	trial3 = 6 if time_x_cat6 == 4 & time_to_first_birth_cat5 == 1   // 0/12 after & Live birth t1
 replace 	trial3 = 7 if time_x_cat6 == 5 & time_to_first_birth_cat5 == 1   // 13/24 after & Live birth t1
 replace 	trial3 = 8 if time_x_cat6 == 6 & time_to_first_birth_cat5 == 1   // 25+ after & Live birth t1

 replace 	trial3 = 9 if time_x_cat6 == 3 & time_to_first_birth_cat5 == 2   // 12/1 before & Live birth t2
 replace 	trial3 =10 if time_x_cat6 == 4 & time_to_first_birth_cat5 == 2   // 0/12 after & Live birth t2
 replace 	trial3 =11 if time_x_cat6 == 5 & time_to_first_birth_cat5 == 2   // 13/24 after & Live birth t2
 replace 	trial3 =12 if time_x_cat6 == 6 & time_to_first_birth_cat5 == 2   // 25+ after & Live birth t2

 replace 	trial3 =13 if time_x_cat6 == 3 & time_to_first_birth_cat5 == 3   // 12/1 before & No live birth reported
 replace 	trial3 =14 if time_x_cat6 == 4 & time_to_first_birth_cat5 == 3   // 0/12 after & No live birth reported
 replace 	trial3 =15 if time_x_cat6 == 5 & time_to_first_birth_cat5 == 3   // 13/24 after & No live birth reported
 replace 	trial3 =16 if time_x_cat6 == 6 & time_to_first_birth_cat5 == 3   // 25+ after & No live birth reported

 lab def    trial3 0 "13+ before" ///
				   1 "12/1 before/Birth t0"   2 "0/12 after/Birth t0"   3 "13/24 after/Birth t0"   4 "25+ after/Birth t0" ///
				   5 "12/1 before/Birth t1"   6 "0/12 after/Birth t1"   7 "13/24 after/Birth t1"   8 "25+ after/Birth t1" ///
				   9 "12/1 before/Birth t2+" 10 "0/12 after/Birth t2+" 11 "13/24 after/Birth t2+" 12 "25+ after/Birth t2+" ///
				  13 "12/1 before/No birth"  14 "0/12 after/No birth"  15 "13/24 after/No birth"  16 "25+ after/No birth" , modify
 lab val 	trial3 trial3

 * Shorter time span before/to birth
 ta time_x_cat6
ta time_to_first_birth_cat3

 gen 		trial4 = .
 replace	trial4 = 0 if time_x_cat6 == 2   // 13+ before
 replace 	trial4 = 1 if time_x_cat6 == 3 & time_to_first_birth_cat3 == 0   // 12/1 before & Live birth t0
 replace 	trial4 = 2 if time_x_cat6 == 4 & time_to_first_birth_cat3 == 0   // 0/12 after & Live birth t0
 replace 	trial4 = 3 if time_x_cat6 == 5 & time_to_first_birth_cat3 == 0   // 13/24 after & Live birth t0
 replace 	trial4 = 4 if time_x_cat6 == 6 & time_to_first_birth_cat3 == 0   // 25+ after & Live birth t0

 replace 	trial4 = 5 if time_x_cat6 == 3 & time_to_first_birth_cat3 == 1   // 12/1 before & Live birth t1
 replace 	trial4 = 6 if time_x_cat6 == 4 & time_to_first_birth_cat3 == 1   // 0/12 after & Live birth t1
 replace 	trial4 = 7 if time_x_cat6 == 5 & time_to_first_birth_cat3 == 1   // 13/24 after & Live birth t1
 replace 	trial4 = 8 if time_x_cat6 == 6 & time_to_first_birth_cat3 == 1   // 25+ after & Live birth t1

 replace 	trial4 = 9 if time_x_cat6 == 3 & time_to_first_birth_cat3 == 2   // 12/1 before & Live birth t2
 replace 	trial4 =10 if time_x_cat6 == 4 & time_to_first_birth_cat3 == 2   // 0/12 after & Live birth t2
 replace 	trial4 =11 if time_x_cat6 == 5 & time_to_first_birth_cat3 == 2   // 13/24 after & Live birth t2
 replace 	trial4 =12 if time_x_cat6 == 6 & time_to_first_birth_cat3 == 2   // 25+ after & Live birth t2

 lab def    trial4 0 "13+ before" ///
				   1 "12/1 before/Birth t0"   2 "0/12 after/Birth t0"   3 "13/24 after/Birth t0"   4 "25+ after/Birth t0" ///
				   5 "12/1 before/Birth t1"   6 "0/12 after/Birth t1"   7 "13/24 after/Birth t1"   8 "25+ after/Birth t1" ///
				   9 "12/1 before/Birth t2+" 10 "0/12 after/Birth t2+" 11 "13/24 after/Birth t2+" 12 "25+ after/Birth t2+" , modify
 lab val 	trial4 trial4
 clonevar   time1 = trial4

 gen 		trial5 = .
 replace	trial5 = 0 if time_x_cat6 == 2 & time_to_first_birth_cat3 == 0   // 13+ before & Live birth t0
 replace 	trial5 = 1 if time_x_cat6 == 3 & time_to_first_birth_cat3 == 0   // 12/1 before & Live birth t0
 replace 	trial5 = 2 if time_x_cat6 == 4 & time_to_first_birth_cat3 == 0   // 0/12 after & Live birth t0
 replace 	trial5 = 3 if time_x_cat6 == 5 & time_to_first_birth_cat3 == 0   // 13/24 after & Live birth t0
 replace 	trial5 = 4 if time_x_cat6 == 6 & time_to_first_birth_cat3 == 0   // 25+ after & Live birth t0

 replace 	trial5 = 5 if time_x_cat6 == 2 & time_to_first_birth_cat3 == 1   // 13+ before & Live birth t1
 replace 	trial5 = 6 if time_x_cat6 == 3 & time_to_first_birth_cat3 == 1   // 12/1 before & Live birth t1
 replace 	trial5 = 7 if time_x_cat6 == 4 & time_to_first_birth_cat3 == 1   // 0/12 after & Live birth t1
 replace 	trial5 = 8 if time_x_cat6 == 5 & time_to_first_birth_cat3 == 1   // 13/24 after & Live birth t1
 replace 	trial5 = 9 if time_x_cat6 == 6 & time_to_first_birth_cat3 == 1   // 25+ after & Live birth t1

 replace 	trial5 =10 if time_x_cat6 == 2 & time_to_first_birth_cat3 == 2   // 13+ before & Live birth t2
 replace 	trial5 =11 if time_x_cat6 == 3 & time_to_first_birth_cat3 == 2   // 12/1 before & Live birth t2
 replace 	trial5 =12 if time_x_cat6 == 4 & time_to_first_birth_cat3 == 2   // 0/12 after & Live birth t2
 replace 	trial5 =13 if time_x_cat6 == 5 & time_to_first_birth_cat3 == 2   // 13/24 after & Live birth t2
 replace 	trial5 =14 if time_x_cat6 == 6 & time_to_first_birth_cat3 == 2   // 25+ after & Live birth t2
 lab def    trial5 	 			 ///
				   0 "13+ before/Birth t0"   1 "12/1 before/Birth t0"   2 "0/12 after/Birth t0"   3 "13/24 after/Birth t0"   4 "25+ after/Birth t0" ///
				   5 "13+ before/Birth t1" 	 6 "12/1 before/Birth t1"   7 "0/12 after/Birth t1"   8 "13/24 after/Birth t1"   9 "25+ after/Birth t1" ///
				  10 "13+ before/Birth t2+" 11 "12/1 before/Birth t2+" 12 "0/12 after/Birth t2+" 13 "13/24 after/Birth t2+" 14 "25+ after/Birth t2+" , modify
 lab val 	trial5 trial5
 clonevar   time2 = trial5

 * Shorter time span before/to birth
 ta time_x_cat6
ta time_to_first_birth_cat6
 gen 		trial6 = .
 replace	trial6 = 0 if time_x_cat6 == 2   // 13+ before
 replace 	trial6 = 1 if time_x_cat6 == 3 & time_to_first_birth_cat6 == 0   // 12/1 before & Live birth t0
 replace 	trial6 = 2 if time_x_cat6 == 4 & time_to_first_birth_cat6 == 0   // 0/12 after & Live birth t0
 replace 	trial6 = 3 if time_x_cat6 == 5 & time_to_first_birth_cat6 == 0   // 13/24 after & Live birth t0
 replace 	trial6 = 4 if time_x_cat6 == 6 & time_to_first_birth_cat6 == 0   // 25+ after & Live birth t0

 replace 	trial6 = 5 if time_x_cat6 == 3 & time_to_first_birth_cat6 == 1   // 12/1 before & Live birth t1
 replace 	trial6 = 6 if time_x_cat6 == 4 & time_to_first_birth_cat6 == 1   // 0/12 after & Live birth t1
 replace 	trial6 = 7 if time_x_cat6 == 5 & time_to_first_birth_cat6 == 1   // 13/24 after & Live birth t1
 replace 	trial6 = 8 if time_x_cat6 == 6 & time_to_first_birth_cat6 == 1   // 25+ after & Live birth t1

 replace 	trial6 = 9 if time_x_cat6 == 3 & time_to_first_birth_cat6 == 2   // 12/1 before & Live birth t2
 replace 	trial6 =10 if time_x_cat6 == 4 & time_to_first_birth_cat6 == 2   // 0/12 after & Live birth t2
 replace 	trial6 =11 if time_x_cat6 == 5 & time_to_first_birth_cat6 == 2   // 13/24 after & Live birth t2
 replace 	trial6 =12 if time_x_cat6 == 6 & time_to_first_birth_cat6 == 2   // 25+ after & Live birth t2

 replace 	trial6 =13 if time_x_cat6 == 3 & time_to_first_birth_cat6 == 3   // 12/1 before & Live birth t3+
 replace 	trial6 =14 if time_x_cat6 == 4 & time_to_first_birth_cat6 == 3   // 0/12 after & Live birth t3+
 replace 	trial6 =15 if time_x_cat6 == 5 & time_to_first_birth_cat6 == 3   // 13/24 after & Live birth t3+
 replace 	trial6 =16 if time_x_cat6 == 6 & time_to_first_birth_cat6 == 3   // 25+ after & Live birth t3+

 lab def    trial6 	 			 ///
				   0 "13+ before/Birth t0"  ///
				   1 "12/1 before/Birth t0"    2 "0/12 after/Birth t0"     3 "13/24 after/Birth t0"    4 "25+ after/Birth t0" ///
				   5 "12/1 before/Birth t1"    6 "0/12 after/Birth t1"     7 "13/24 after/Birth t1"    8 "25+ after/Birth t1" ///
				   9 "12/1 before/Birth t2"   10 "0/12 after/Birth t2"    11 "13/24 after/Birth t2"   12 "25+ after/Birth t2" ///
				  13 "12/1 before/Birth t3+"  14 "0/12 after/Birth t3+"   15 "13/24 after/Birth t3+"  16 "25+ after/Birth t3+"  , modify
 lab val 	trial6 trial6

* Labour market variables
sort pidp wave
* Ever worked / ever worked before pregnancy
gen  ever_worked  = wave if (jbstat_f >= 1 & jbstat_f <=3) | (fimnlabnet_f > 0)
by pidp : egen first_wave_worked = min(ever_worked)
  order pidp wave fimnlabnet* first_wave_worked

* Employed

foreach g in m f {
gen 	employed1_`g' 	     = jbstat_`g'  == 1 | jbstat_`g'  == 2 | fimnlabnet_`g' > 0 | jboffy_`g' == 97 | jboffy_`g' == 3 | jbhas_`g' == 1
lab var employed1_`g'  "employed/self-employed,(ft/pt), some income, has job but temp off"
gen 	employed2_`g' 	     = jbstat_`g'  == 1 | jbstat_`g'  == 2 | fimnlabnet_`g' > 0 | jboffy_`g' == 97 | jboffy_`g' == 3 | jbhas_`g' == 1
lab var employed2_`g'  "employed/self-employed, paid employed(ft/pt), some income, has job but temp off"
gen 	employed3_`g' 	     = jbstat_`g'  == 1 | jbstat_`g'  == 2 | fimnlabnet_`g' > 0
lab var employed3_`g'  "employed/self-employed, paid employed(ft/pt), some income"
gen 	employed4_`g' 	     = jbstat_`g'  == 1 | jbstat_`g'  == 2 | fimnlabnet_`g' > 0
replace employed4_`g' 		 = 0 if 			  jboffy_`g'  == 1 | jboffy_`g'  == 5
lab var employed4_`g'  "paid employed(ft/pt), some income, no maternity leave"
gen 	employed5_`g' 	     = 	(jbstat_`g'  == 2 | (jbnssec5_`g' >=1 & jbnssec5_`g' <=5)) | fimnlabnet_`g' > 0
replace employed5_`g' 		 = 0 if 			  jboffy_`g'  == 1 | jboffy_`g'  == 5
lab var employed5_`g'  "paid employed(ft/pt), some occupation & some income, no maternity leave"
gen 	employed6_`g' 	     = 	(jbstat_`g'  == 2 | (jbnssec5_`g' >=1 & jbnssec5_`g' <=5)) & fimnlabnet_`g' > 0
replace employed6_`g' 		 = 0 if 			  jboffy_`g'  == 1 | jboffy_`g'  == 5
lab var employed6_`g'  "paid employed(ft/pt), some occupation & some income, no maternity leave"

gen 	employed7_`g' 		 = jbhas_`g' == 1
lab var employed7_`g'  "Had paid job last week"

gen     employed8_`g' = (jbnssec5_`g' >=1 & jbnssec5_`g' <=5)
lab var employed8_`g'  "Job in NSSEC5"

gen 	employed9_`g' 		 = jbstat_`g'  == 1 | jbstat_`g'  == 2
lab var employed9_`g'  "Self-employed or Paid employment"

gen 	employed10_`g' 		 = fimnlabnet_`g'  > 0
lab var employed10_`g'  "Some labour income"

gen 	employed11_`g' 		 = fimnlabnet_`g'  > 100
lab var employed11_`g'  "Some labour income (>100)"

gen 	employed12_`g' 		 = fimnlabnet_`g'  > 200
lab var employed12_`g'  "Some labour income (>200)"

gen 	employed13_`g' 		 = fimnlabnet_`g'  > 300
lab var employed13_`g'  "Some labour income (>300)"

gen 	employed14_`g' 		 = fimnlabnet_`g'  > 400
lab var employed14_`g'  "Some labour income (>400)"

gen 	employed15_`g' 		 = jbstat_`g'  == 2
lab var employed15_`g'  "Paid employment"

gen 	employed16_`g' 		 = jbhas_`g'  == 1
lab var employed16_`g'  "did paid work last week"

gen 	employed17_`g'		= employ_`g'  == 1
lab var employed17_`g'  "in paid employment"

gen     employed18_`g'		= cjob_`g' == 1
lab var employed18_`g'	"current job indicator"

gen 	employed19_`g'		= jbsemp_`g' == 1 | jbsemp_`g' == 2
lab var employed19_`g'	"current job: employed or self-employed"

gen 	employed20_`g'	    = employ_`g'  == 1 | cjob_`g' == 1
lab var employed20_`g'  "in paid employment \ current job indicator"

gen 	employed21_`g'	    = 		employ_`g'  == 1
replace employed21_`g'		= 1 if 	employ_`g'  <  0 & cjob_`g' == 1
lab var employed21_`g'  "in paid employment \ current job indicator"

gen 	employed22_`g'	    = employ_`g'  == 1
replace employed22_`g'		= 1 if  cjob_`g' == 1 & (employ_`g'  == -9 | employ_`g'  == -8 | employ_`g'  == -2 | employ_`g'  == -1)
lab var employed22_`g'  "in paid employment \ current job indicator"

}

* Job class

foreach g in m f {
clonevar job_status_`g' = jbstat_`g'
replace  job_status_`g' = 9 if jbstat_`g' == 0
clonevar nssec5_`g' = jbnssec5_`g'
replace  nssec5_`g' = job_status_`g' + 5 if nssec5_`g' < 1  & job_status_`g' > 0

lab def  nssec5_`g' 1 "Management & professional" 2 "Intermediate" 3 "Small employers & own account" 4 "Lower supervisory & technical" 5 "Semi-routine & routine" 6 "self employed" 7 "Unspecified paid employment" 8 "Unemployed" 9 "Retired" 10 "On maternity leave" 11 "Family leave" 12 "FT education" 13 "LT sickness leave" 14 "Unspecified", modify
lab val  nssec5_`g' nssec5_`g'

replace  jbnssec5_`g'  = 6 if jbnssec5_`g'  < 1
lab def  jbnssec5_`g' 1 "Management & professional" 2 "Intermediate" 3 "Small employers & own account" 4 "Lower supervisory & technical" 5 "Semi-routine & routine" 6 "Missing", modify
lab val  jbnssec5_`g' jbnssec5_`g'

clonevar nssec5_v2_`g' = nssec5_`g'
replace  nssec5_v2_`g' = 3 if nssec5_`g' == 6   // self-employed
replace  nssec5_v2_`g' = 9 if nssec5_`g' >= 9  & nssec5_`g' <= 13
lab def  nssec5_v2_`g' 1 "Management & professional" 2 "Intermediate" 3 "Small employers & own account" 4 "Lower supervisory & technical" 5 "Semi-routine & routine" 7 "Unspecified paid employment" 8 "Unemployed" 9 "OLF"  14 "Unspecified", modify
lab val  nssec5_v2_`g' nssec5_v2_`g'

clonevar nssec5_v3_`g' = nssec5_`g'
replace  nssec5_v3_`g' = 3 if nssec5_`g' == 6   // self-employed
replace  nssec5_v3_`g' = 7 if nssec5_`g' >= 7  & nssec5_`g' <= 14
lab def  nssec5_v3_`g' 1 "Management & professional" 2 "Intermediate" 3 "Small employers & own account" 4 "Lower supervisory & technical" 5 "Semi-routine & routine" 7 "Other", modify
lab val  nssec5_v3_`g' nssec5_v3_`g'

clonevar nssec5_v1_`g' = nssec5_`g'
drop job_status_`g'
}

* Working hours / unconditional
foreach g in m f {
clonevar   work_hours_`g' = jbhrs_`g'
replace    work_hours_`g' = 0 if jbhrs_`g'< 0
}

 foreach g in m f {
 gen     work_hours_ln_`g' = ln(1+work_hours_`g')
 lab var work_hours_ln_`g' "Work hours (ln)"
 replace work_hours_ln_`g' = 0  if work_hours_`g'<0.0001 & work_hours_ln_`g'== .
 }

foreach g in m f {
	gen tot_work_hours_`g' = jbhrs_`g' + jbotpd_`g' if jbhrs_`g' > 0 & jbhrs_`g' < . & jbotpd_`g' > 0 & jbotpd_`g' < .
replace tot_work_hours_`g' = jbhrs_`g' 				if jbhrs_`g' > 0 & jbhrs_`g' < . &(jbotpd_`g' ==. | jbotpd_`g' <= 0)
replace tot_work_hours_`g' = 0 						if tot_work_hours_`g' == . & jbstat_`g' < .
}

 foreach g in m f {
 gen     tot_work_hours_ln_`g' = ln(1+tot_work_hours_`g')
 lab var tot_work_hours_ln_`g' "Work hours (ln)"
 replace tot_work_hours_ln_`g' = 0  if tot_work_hours_`g'<0.0001 & tot_work_hours_ln_`g'== .
 }

foreach g in m f {
	foreach x in 2 3 4 5 10 15 20 30 40 {
gen 	work_hours_`x'_`g' = jbhrs_`g' >= `x' & jbhrs_`g' < .
lab var work_hours_`x'_`g'   "At least `x' hrs/week"
lab def work_hours_`x'_`g' 1 "At least `x' hrs/week"
lab val work_hours_`x'_`g'  work_hours_`x'_`g'
 }
 }

foreach g in m f {
	foreach x in 2 3 4 5 10 15 20 30 40 {
gen 	tot_work_hours_`x'_`g' = tot_work_hours_`g' >= `x' & tot_work_hours_`g' < .
lab var tot_work_hours_`x'_`g'   "At least `x' hrs/week"
lab def tot_work_hours_`x'_`g' 1 "At least `x' hrs/week"
lab val tot_work_hours_`x'_`g'  tot_work_hours_`x'_`g'
 }
 }

* Working hours / conditional
foreach g in m f {
clonevar   work_hours_cond_`g' =   	  jbhrs_`g'
replace    work_hours_cond_`g' = . 					 if work_hours_cond_`g' <= 0

}

 foreach g in m f {
 gen     work_hours_cond_ln_`g' = ln(1+work_hours_cond_`g')
 lab var work_hours_cond_ln_`g' "Work hours (ln)"
 }

* Total Working hours / conditional
foreach g in m f {
	gen tot_work_hours_cond_`g' = jbhrs_`g' + jbotpd_`g' if jbhrs_`g' > 0 & jbhrs_`g' < . & jbotpd_`g' > 0 & jbotpd_`g' < .
replace tot_work_hours_cond_`g' = jbhrs_`g' 			 if jbhrs_`g' > 0 & jbhrs_`g' < . &(jbotpd_`g' ==. | jbotpd_`g' <= 0)
replace tot_work_hours_cond_`g' = . 					 if tot_work_hours_cond_`g' <= 0
}

foreach g in m f {
 gen       tot_work_hours_cond_ln_`g' = ln(1+ tot_work_hours_cond_`g')
 lab var   tot_work_hours_cond_ln_`g' "Work hours (ln)"
 }

* Full / part time

foreach g in m f {
sort pidp wave
by   pidp :   gen FT_uncond_`g' = work_hours_`g' >= 33	     & work_hours_`g' < .   // Definition Morgan & Arthurs 2005
		  replace FT_uncond_`g' = . 					   if  work_hours_`g' == .
		  lab var FT_uncond_`g'   "Full time "
		  lab def FT_uncond_`g' 1 "Full time"
		  lab val FT_uncond_`g'  FT_uncond_`g'
		  }

foreach g in m f {
sort pidp wave
by   pidp :   gen FT_`g' = work_hours_`g' >= 30	     & work_hours_`g' < .
		  replace FT_`g' = . 					   if  work_hours_`g' == .
		  lab var FT_`g'   "Full time "
		  lab def FT_`g' 1 "Full time" 0 "Part time (at most)"
		  lab val FT_`g'  FT_`g'
		  }

foreach g in m f {
sort pidp wave
by   pidp :   gen PT_`g' = work_hours_`g' > 0 	     & work_hours_`g' < 30
		  replace PT_`g' = . 					   if  work_hours_`g' == .	|  	work_hours_`g' == 0
		  lab var PT_`g'   "Part time "
		  lab def PT_`g' 1 "Part time" , modify
		  lab val PT_`g'  PT_`g'
		  }

foreach g in m f {
sort pidp wave
by   pidp :   gen FT1_`g' = work_hours_`g' >= 30	 & work_hours_`g' < .
		  replace FT1_`g' = . 					   if  work_hours_`g' == .
		  lab var FT1_`g'   "Full time "
		  lab def FT1_`g' 1 "Full time" 0 "Part time (at most)"
		  lab val FT1_`g'  FT1_`g'
by   pidp :   gen FT2_`g' = tot_work_hours_`g' >= 30 & tot_work_hours_`g' < .
		  replace FT2_`g' = . 					   if  tot_work_hours_`g' == .
		  lab var FT2_`g'   "Full time "
		  lab def FT2_`g' 1 "Full time" 0 "Part time (at most)"
		  lab val FT2_`g'  FT2_`g'
		  }

foreach g in m f {
sort pidp wave
by   pidp :   gen PT1_`g' = work_hours_`g' > 0 	     & work_hours_`g' < 30
		  replace PT1_`g' = . 					   if  work_hours_`g' == .
	 	  lab var PT1_`g'   "Part time "
		  lab def PT1_`g' 1 "Part time" , modify
		  lab val PT1_`g'  PT1_`g'
by   pidp :   gen PT2_`g' = work_hours_`g' > 0 	     & work_hours_`g' < 30
		  replace PT2_`g' = . 					   if  work_hours_`g' == .
		  replace PT2_`g' = 2 					   if  work_hours_`g' == 0
	 	  lab var PT2_`g'   "Part time "
		  lab def PT2_`g' 1 "Part time" 2 "No job" , modify
		  lab val PT2_`g'  PT2_`g'
by   pidp :   gen PT3_`g' = tot_work_hours_`g' >= 0  & tot_work_hours_`g' < 30   // including 0 hours of work
		  replace PT3_`g' = . 					   if  tot_work_hours_`g' == .
	 	  lab var PT3_`g'   "Part time "
		  lab def PT3_`g' 1 "30hrs/less" 0 ""  , modify
		  lab val PT3_`g'  PT3_`g'
by   pidp :   gen PT4_`g' = tot_work_hours_`g' >= 0  & tot_work_hours_`g' < 16   // including 0 hours of work
		  replace PT4_`g' = . 					   if  tot_work_hours_`g' == .
	 	  lab var PT4_`g'   "Part time "
		  lab def PT4_`g' 1 "15hrs/less" 0 ""  , modify
		  lab val PT4_`g'  PT4_`g'
by   pidp :   gen PT5_`g' = tot_work_hours_`g' > 0 	 & tot_work_hours_`g' < 30
		  replace PT5_`g' = . 					   if  tot_work_hours_`g' == .
		  replace PT5_`g' = 2 					   if  tot_work_hours_`g' == 0
	 	  lab var PT5_`g'   "Part time "
		  lab def PT5_`g' 1 "Part time" 2 "No job" , modify
		  lab val PT5_`g'  PT5_`g'
by   pidp :   gen PT6_`g' = 0 if tot_work_hours_`g' ==0
		  replace PT6_`g' = 1 if tot_work_hours_`g' > 0 & tot_work_hours_`g' < 16
		  replace PT6_`g' = 2 if tot_work_hours_`g' >15 & tot_work_hours_`g' < 30
		  replace PT6_`g' = 3 if tot_work_hours_`g' >29 & tot_work_hours_`g' < .
	 	  lab var PT6_`g'   "Part time "
		  lab def PT6_`g' 0 "0 hours" 1 "1-15h" 2 "15-29h" 3 "30+hr" , modify
		  lab val PT6_`g'  PT6_`g'
		  }

* Public/Private sector
foreach g in m f {
gen 	private_`g' = jbsect_`g' == 1 | jbsectpub_`g' == 7 | jbsectpub_`g' == 9
replace private_`g' = 2 if jbsect_`g' < 0 | jbsect_`g' == .
lab var private_`g' "Private sector"
lab def private_`g' 1 "Private sector" 0 "Public sector" 2 "None", modify
lab val private_`g' private_`g'
	}

foreach g in m f {
clonevar job_status_`g' = jbstat_`g'
replace  job_status_`g' = 1 if jbstat_`g' != 1 & jbnssec5_`g' == 3
replace  job_status_`g' = 2 if jbstat_`g' != 1 & jbnssec5_`g' == 1 | jbnssec5_`g' == 2 & jbnssec5_`g' == 4 | jbnssec5_`g' == 5
}

* Self-employed / manager
foreach g in m f {
gen 	 self_employed_`g' = jbstat_`g' == 1 | jbnssec5_`g' == 3
lab def  self_employed_`g' 1 "Small employer/self-employed", modify
lab val  self_employed_`g' self_employed_`g'
replace  self_employed_`g' = . 				if   jbstat_`g' == . & jbnssec5_`g' == .
clonevar manager_`g' = jbmngr_`g'
replace  manager_`g' = 1 if jbnssec5_`g' == 1 & jbmngr_`g' < 0
replace  manager_`g' = 2 if manager_`g'   < 0 & manager_`g' !=. & jbnssec5_`g' == 4
replace  manager_`g' = 3 if manager_`g'   < 0 & manager_`g' !=. & jbnssec5_`g' == 5
replace  manager_`g' = 0 if manager_`g'   < 0 & jbstat_`g' != . & jbnssec5_`g' != .
}

* Self-employed / Own account
foreach g in m f {
	gen self_employed1_`g' = jbstat_`g' == 1 | jbnssec5_`g' == 3
	gen self_employed2_`g' = jbstat_`g' == 1
	gen self_employed3_`g' =				   jbnssec5_`g' == 3
	forvalues z = 1/3 {
lab def self_employed`z'_`g' 1 "Small employer/self-employed", modify
lab val self_employed`z'_`g' self_employed`z'_`g'
}
}
* Ever self-employed
foreach g in m f {
sort pidp_`g' wave
forvalues z = 1/3 {
by pidp_`g' : egen ever_self_employed`z'_`g' = max(self_employed`z'_`g')
lab def ever_self_employed`z'_`g' 1 "Small employer/self-employed", modify
lab val ever_self_employed`z'_`g' ever_self_employed`z'_`g'
}
}
foreach g in m f {
gen 	mgmt_`g' = manager_`g' == 1
lab var mgmt_`g' "Manager"
}

* Comprehensive variable
foreach g in m f {
gen 	job_`g' = .
replace job_`g' = 1 if job_status_`g' == 1   // self-employed
replace job_`g' = 2 if job_status_`g' == 2 & manager_`g' == 1  & job_`g' !=1   // manager
replace job_`g' = 3 if job_status_`g' == 2 & manager_`g' == 2  & job_`g' ==.   // foreman/supervisor
replace job_`g' = 4 if job_status_`g' == 2 & manager_`g' == 3  & job_`g' ==.   // not manager or supervisor
replace job_`g' = 5 if job_status_`g' == 3 					   & job_`g' ==.   // unemployed
replace job_`g' = 6 if job_status_`g' >= 4 					   & job_`g' ==.   // out of labour force
replace job_`g' = 6 if job_status_`g' != . 				       & job_`g' ==.   // out of labour force
replace job_`g' = . if fimnlabnet_`g' == . | work_hours_`g' == .   // Missing information on work status
lab var job_`g' "Job condition"
lab def job_`g' 1 "self-employed" 2 "manager" 3 "foreman/supervisor" 4 "not manager or supervisor" 5 "unemployed" 6 "out of labour force", modify
lab val job_`g' job_`g'
}

foreach g in m f {
gen 	maternity_`g' = jboffy_`g' == 1 | jbstat_`g' == 5
lab var maternity_`g' "On maternity leave"
gen     sick_`g' 		= jboffy_`g' == 3 | jbstat_`g' == 8
lab var sick_`g' "Sickness"
}

* Unemployment
foreach g in m f {
	sort pidp_`g' wave
gen 	unemployed_`g' = jboffy_`g' == 5 | jbstat_`g' == 3
lab var unemployed_`g' "Unemployment / dismissed"
 }

* Number of workers within firm
foreach g in m f {
	replace jbsize_`g' = 0 if jbsize_`g' < 0 & (job_status_`g' != . | fimnlabnet_`g' != .)
}

* Tenure / Work experience
foreach g in m f {
sort pidp_`g' wave
replace jbbgm_`g' = 6 if jbbgm_`g' < 0 & jbbgy_`g' > 0 & jbbgy_`g' <.
replace jbbgm_`g' = 6 if jbbgm_`g' < 0 & jbbgy_`g' > 0 & jbbgy_`g' <.
gen    date_job_`g' = ym(jbbgy_`g', jbbgm_`g')
format date_job_`g' %tm
gen    date_job_other_`g'= ym(jbbgdaty_`g', jbbgdatm_`g')
forvalues i = 19/33 {
sort pidp_`g' wave
		   gen date_job`i'_`g'  = 			date_job_`g' 		if wave == `i'
sort pidp_`g' wave
by   pidp_`g' : egen date_job`i'__`g' = 		min(date_job`i'_`g')
		   gen date_job_other`i'_`g'  =     date_job_other_`g' 	if wave == `i'
sort pidp_`g' wave
by   pidp_`g' : egen date_job_other`i'__`g' = min(date_job_other`i'_`g')
}
format date_job*__`g' %tm
}

foreach g in m f {
forvalues i = 19/33 {
replace date_job_`g' 		 = date_job`i'__`g' 		if  date_interview >= date_job`i'__`g'  & wave >= `i'
replace date_job_`g' 		 = date_job_other`i'__`g'   if  date_interview >= date_job_other`i'__`g' &  date_job`i'__`g' == . & wave >= `i'
}
}

foreach g in m f {
egen 	career_start_`g' = rowmin(date_job*__`g')
format  career_start_`g' %tm
lab var career_start_`g'  "First reported job date (Not accurate)"
}

foreach g in m f {
gen 	work_exp_`g' = (date_interview - career_start_`g')/12
lab var work_exp_`g'  "Work experience"
gen 	tenure_`g' = (date_interview - date_job_`g')/12
lab var tenure_`g'  "Tenure with current employer"
foreach x in tenure work_exp {
gen     `x'_miss_`g' = `x'_`g' == . | `x'_`g' < 0
replace `x'_`g' = 0 if `x'_`g' == . | `x'_`g' < 0
}
}

* Any Job end
foreach g in m f {
egen 	any_job_end_v1_`g' = anymatch(jobloss*_`g'), v(2 3 4 5 6 7 8 9 10 11 97 99)
lab var any_job_end_v1_`g' "Any job end reported during the year"

egen 	any_job_end_v2_`g' = anymatch(jobloss*_`g'), v(2 3 4 5 97 99)
lab var any_job_end_v2_`g' "Any job end reported during the year"

* Number of job ends
egen 	num_job_end_v1_`g' = anycount(jobloss*_`g'), v(2 3 4 5 6 7 8 9 10 11 97 99)
lab var num_job_end_v1_`g' "# job ends reported during the year"

egen 	num_job_end_v2_`g' = anycount(jobloss*_`g'), v(2 3 4 5 97 99)
lab var num_job_end_v2_`g' "# job ends reported during the year"
}

 foreach g in m f {
 foreach x in num any {
 	forvalues i = 1/2 {
 clonevar `x'_job_end_post_v`i'_`g' = `x'_job_end_v`i'_`g'
 replace  `x'_job_end_post_v`i'_`g' = 0 if time_x1_cat < 4 & treated1 == 1
 replace  `x'_job_end_post_v`i'_`g' = 0 if time_x2_cat < 4 & treated2 == 1
 }
 }
 }

* Income
gen     income_miss = fimnnet_f == . | fimnnet_m ==  .
gen double _fnf = fimnnet_f
gen double _fnm = fimnnet_m
replace _fnf = . if _fnf < 0
replace _fnm = . if _fnm < 0
egen    income   = rowtotal(_fnf _fnm)
drop    _fnf _fnm
replace income_miss = 1 if (fimnnet_f < 0 | fimnnet_f == .) | (fimnnet_m < 0 | fimnnet_m == .)
replace income   = 1 if income == 0
replace income   = 1 if income <  0
replace income   = ln(income)

* Income in logarithm
foreach g in m f {
 foreach x in fimnnet fimnlabnet fimnlabgrs fimngrs {
 gen 	  	 `x'_ln_`g'   =  ln(1+`x'_`g') 		if `x'_`g'>0
 replace     `x'_ln_`g'   = 0  if `x'_`g'<0.0001 & `x'_ln_`g'==.
}
}

 foreach x in fimnnet fimnlabnet fimnlabgrs fimngrs {
 	foreach g in m f {
 gen 	    `x'_hrwage_`g'=      `x'_`g'  / (4.33 * work_hours_`g')
 replace    `x'_hrwage_`g'= 0 if `x'_`g'==0|work_hours_`g'== 0
 gen     	`x'_hrwage_ln_`g'= ln(1+`x'_hrwage_`g')
 replace    `x'_hrwage_ln_`g'= 0 if `x'_hrwage_ln_`g'< 0
 lab var    `x'_hrwage_ln_`g'"hourly wage (ln)"
 }
 }

  foreach x in fimnnet fimnlabnet fimnlabgrs fimngrs {
 	foreach g in m f {
 clonevar   `x'_hrwage2_ln_`g' = 		 `x'_hrwage_ln_`g'
 replace    `x'_hrwage2_ln_`g' = . if     tot_work_hours_`g'== 0 &  `x'_`g' > 0 & `x'_`g' < .
 lab var    `x'_hrwage2_ln_`g'"hourly wage (ln) (work hours miss)"
 }
 }

 * CONDITIONAL hrwage
   foreach x in fimnnet fimnlabnet fimnlabgrs fimngrs {
 	foreach g in m f {
 clonevar   `x'_hrwage3_ln_`g' = 		 `x'_hrwage_ln_`g'
 replace    `x'_hrwage3_ln_`g' = . if    `x'_`g' == 0
 lab var    `x'_hrwage3_ln_`g'"hourly wage (ln) (conditional)"
 }
 }

 foreach x in fimnnet fimnlabnet fimnlabgrs fimngrs {
 	foreach g in m f {
 gen 	    `x'_hrwage_CPI_`g'=      `x'_`g'/ CPI  / (4.33 * work_hours_`g')
 replace    `x'_hrwage_CPI_`g'= 0 if `x'_`g'==0|work_hours_`g'== 0
 gen     	`x'_hrwage_CPI_ln_`g'= ln(1+`x'_hrwage_CPI_`g')
 replace    `x'_hrwage_CPI_ln_`g'= 0 if `x'_hrwage_CPI_ln_`g'< 0
 lab var    `x'_hrwage_CPI_ln_`g'"hourly wage (ln)"
 }
 }

  foreach x in fimnnet fimnlabnet fimnlabgrs fimngrs {
 	foreach g in m f {
 clonevar   `x'_hrwage2_CPI_ln_`g' = 		 `x'_hrwage_CPI_ln_`g'
 replace    `x'_hrwage2_CPI_ln_`g' = . if     tot_work_hours_`g'== 0 &  `x'_`g' > 0 & `x'_`g' < .
 lab var    `x'_hrwage2_CPI_ln_`g'"hourly wage (ln) (work hours miss)"
 }
 }

 * CONDITIONAL hrwage
 foreach x in fimnnet fimnlabnet fimnlabgrs fimngrs {
 	foreach g in m f {
 clonevar   `x'_hrwage3_CPI_ln_`g' = 		 `x'_hrwage_CPI_ln_`g'
 replace    `x'_hrwage3_CPI_ln_`g' = . if    `x'_`g' == 0 | `x'_`g' == .
 lab var    `x'_hrwage3_CPI_ln_`g'"hourly wage (ln) (conditional)"
 }
 }

 foreach x in fimnnet fimnlabnet fimnlabgrs fimngrs {
 	foreach g in m f {
 gen 	    `x'_CPI_`g'=      `x'_`g'/ CPI
 replace    `x'_CPI_`g'= 0 if `x'_`g'==0
 gen     	`x'_CPI_ln_`g'= ln(1+`x'_CPI_`g')
 replace    `x'_CPI_ln_`g'= 0 if `x'_CPI_ln_`g'< 0
 lab var    `x'_CPI_ln_`g'"Income (ln)"
 }
 }

 * Income of the partner
clonevar income_partner_m = fimnlabnet_ln_f
replace  income_partner_m = 1 if income_partner_m == . & partner !=.
clonevar income_partner_f = fimnlabnet_ln_m
replace  income_partner_f = 1 if income_partner_f == . & pidp !=.

 	foreach g in m f {
	gen avgrate_`g' = basrate_`g' if basrate_`g' == ovtrate_`g' &  basrate_`g' > 0 & basrate_`g' < . & ovtrate_`g' > 0 & ovtrate_`g' < .
replace avgrate_`g' = basrate_`g'*jbhrs_`g'/tot_work_hours_`g' + ovtrate_`g'*jbotpd_`g'/tot_work_hours_`g' if basrate_`g' > 0 & basrate_`g' < . & ovtrate_`g' > 0 & ovtrate_`g' < . & tot_work_hours_`g' > 0 & tot_work_hours_`g'< . & jbotpd_`g' > 0 & jbotpd_`g' <.
replace avgrate_`g' = basrate_`g' if  		   					   basrate_`g' > 0 & basrate_`g' < . & avgrate_`g' == .
	}

 foreach x in  fimnlabnet fimnlabgrs fimngrs {
 	foreach g in m f {
 gen 	  `x'_hrpay1_`g'=      `x'_`g' / (4.33 * tot_work_hours_`g')
 replace  `x'_hrpay1_`g'= 0 if `x'_`g'==0|tot_work_hours_`g'== 0
clonevar  `x'_hrpay2_`g'=`x'_hrpay1_`g'
replace   `x'_hrpay2_`g'=   basrate_`g' if (`x'_hrpay2_`g' == 0 | `x'_hrpay2_`g' == .) & basrate_`g'> 0 & basrate_`g' < .
clonevar  `x'_hrpay3_`g'=`x'_hrpay1_`g'
replace   `x'_hrpay3_`g'=   basrate_`g' if 												 basrate_`g'> 0 & basrate_`g' < .
clonevar  `x'_hrpay4_`g'=`x'_hrpay1_`g'
replace   `x'_hrpay4_`g'=   basrate_`g' if 												 avgrate_`g'> 0 & avgrate_`g' < .
 }
 }

* CPI
 foreach x in  fimnlabnet fimnlabgrs fimngrs {
 	foreach g in m f {
		forvalues n = 1/4 {
 gen     	`x'_hrpay`n'_ln_`g'= ln(1+`x'_hrpay`n'_`g')
 replace    `x'_hrpay`n'_ln_`g'= 0 if `x'_hrpay`n'_`g'< 0
 lab var    `x'_hrpay`n'_ln_`g'"hourly wage (ln)"
  gen     	`x'_hrpay`n'_CPI_ln_`g' = 	ln(1+`x'_hrpay`n'_`g'/CPI)
 replace    `x'_hrpay`n'_CPI_ln_`g' = 0 if `x'_hrpay`n'_`g'< 0
 }
 }
 }

* CPI / cond

 foreach x in  fimnlabnet fimnlabgrs fimngrs {
 	foreach g in m f {
		forvalues n = 1/4 {
 gen     	`x'_hrpay`n'_cond_ln_`g'= ln(1+`x'_hrpay`n'_`g')
 replace    `x'_hrpay`n'_cond_ln_`g'= . if `x'_hrpay`n'_`g'<= 0
 lab var    `x'_hrpay`n'_cond_ln_`g'"hourly wage (ln)"
  gen     	`x'_hrpay`n'_CPI_cond_ln_`g' = 	ln(1+`x'_hrpay`n'_`g'/CPI)
 replace    `x'_hrpay`n'_CPI_cond_ln_`g' = . if `x'_hrpay`n'_`g'<= 0
 }
 }
 }

foreach g in m f {
 local ecap_f = 6979.0630
 local ecap_m = 15869.7217

 gen double _hrcl_`g' = fimnlabgrs_`g' / (4.33 * tot_work_hours_`g')
 replace    _hrcl_`g' = 0 if fimnlabgrs_`g'==0 | tot_work_hours_`g'==0
 replace    _hrcl_`g' = . if tot_work_hours_`g' > 0 & tot_work_hours_`g' < 5   // floor 5 weekly hours
 replace    _hrcl_`g' = avgrate_`g' if avgrate_`g' > 0 & avgrate_`g' < .
 gen double _rw_`g'   = _hrcl_`g' / CPI
 gen double fimnlabgrs_hrclean_CPI_trim_ln_`g' = ln(1 + _rw_`g')
 replace    fimnlabgrs_hrclean_CPI_trim_ln_`g' = . if _hrcl_`g' <= 0
 replace    fimnlabgrs_hrclean_CPI_trim_ln_`g' = . if _rw_`g' < 1 | _rw_`g' > 100
 lab var    fimnlabgrs_hrclean_CPI_trim_ln_`g' "Hourly wage (ln, clean recon + trim)"
 drop _hrcl_`g' _rw_`g'

 gen double fimnlabgrs_CPI_trim_`g' = fimnlabgrs_CPI_`g'
 replace    fimnlabgrs_CPI_trim_`g' = `ecap_`g'' if fimnlabgrs_CPI_`g' > `ecap_`g'' & !missing(fimnlabgrs_CPI_`g')
 lab var    fimnlabgrs_CPI_trim_`g' "Real earnings (winsor top p99.5)"

 gen double tot_work_hours_cond_ln_trim_`g' = tot_work_hours_cond_ln_`g'
 replace    tot_work_hours_cond_ln_trim_`g' = . if tot_work_hours_`g' > 0 & tot_work_hours_`g' < 5
 lab var    tot_work_hours_cond_ln_trim_`g' "Work hours cond (ln, 5h floor)"
}

gen 	unpartnered_f    = partner == .
lab var unpartnered_f "Unpartnered"

* Age of the partner
clonevar age_partner_m 			 = age_f
gen  	 age_partner_miss_m =      age_f == . | pidp_f ==.
replace  age_partner_m =   0 if    age_partner_miss_m == 1
clonevar age_partner_f 			 = age_m
gen		 age_partner_miss_f =	   age_m == . | pidp_m ==.
replace  age_partner_f =   0 if    age_partner_miss_f == 1

gen 	 age_p_m = age_f	 if age_f > 0 & age_f < .
gen 	 age_p_f = age_m 	 if age_m > 0 & age_m < .

* Definition of independent variables in categorical format
foreach g in m f {
 gen union_`g' 		= union_type == 1 | union_type == 2
 gen degree_`g'  	= hiqual_`g' == 1
 gen less_edu_`g'   = hiqual_`g' >= 3
 gen managers_`g' 	= jbnssec5_`g' == 1
 gen low_skilled_`g'= jbnssec5_`g' == 4 | jbnssec5_`g' == 5
 gen OLF_`g'        = jbstat_`g' >  3
 gen MAR_`g' 		= MAR1   == 1
 }

gen degree_p_m 		= hiqual_f == 1
gen degree_p_f 		= hiqual_m == 1
gen less_edu_p_m    = hiqual_f >= 3
gen less_edu_p_f    = hiqual_m >= 3
gen managers_p_m 	= jbnssec5_f == 1
gen managers_p_f 	= jbnssec5_m == 1
gen low_skilled_p_m = jbnssec5_f == 4 | jbnssec5_f == 5
gen low_skilled_p_f = jbnssec5_m == 4 | jbnssec5_m == 5
gen unemployed_p_m  = jbstat_f == 3
gen unemployed_p_f  = jbstat_m == 3

sort pidp wave

* Pre-conception covariates

foreach t in 1 2 4 {
clonevar time_cat`t' = time_x1_cat`t'
replace  time_cat`t' = .
forvalues i = 1/2 {
replace  time_cat`t' = time_x`i'_cat`t' if treated`i' == 1
}
}

forvalues t = 1/3 {
gen 	time_L`t'_ = .
}
replace time_L1_ = wave if time_cat2 == 4
replace time_L2_ = wave if time_cat2 == 3
replace time_L3_ = wave if time_cat2 == 2

sort pidp_f wave
forvalues t = 1/3 {
bysort pidp_f : egen  time_L`t' = min(time_L`t'_)
}
drop time_L*_

foreach y in hiqual ISEI nssec5_v2 income_partner work_exp work_exp_miss tenure tenure_miss num_job_end_v2 private {
foreach g in  f {
forvalues t = 1/3 {
   gen  `y'_L`t'_`g'_ = `y'_`g' 	 if time_L`t' == wave
bysort pidp_f : egen `y'_L`t'_`g' = min(`y'_L`t'_`g'_)
   copydesc  `y'_`g' `y'_L`t'_`g'
   drop              `y'_L`t'_`g'_
bysort pidp_f :  gen `y'_L`t'_miss_`g'= `y'_L`t'_`g' == .
		 	 replace `y'_L`t'_`g' =0 if `y'_L`t'_`g' == .
}
}
}

* Time from/to pregnancy # education (very granular)
ta time_cat4, nola
gen 	hiqual_L1_time_cat4_f = .
replace hiqual_L1_time_cat4_f = 1 if hiqual_L1_f == 0 & time_cat4 == 1   // Missing & 25+ before
replace hiqual_L1_time_cat4_f = 2 if hiqual_L1_f == 0 & time_cat4 == 2   // Missing & 24/13 before
replace hiqual_L1_time_cat4_f = 3 if hiqual_L1_f == 0 & time_cat4 == 3   // Missing & 12/1 before
replace hiqual_L1_time_cat4_f = 4 if hiqual_L1_f == 0 & time_cat4 == 4   // Missing & 0/12 after
replace hiqual_L1_time_cat4_f = 5 if hiqual_L1_f == 0 & time_cat4 == 5   // Missing & 13/24 after
replace hiqual_L1_time_cat4_f = 6 if hiqual_L1_f == 0 & time_cat4 == 6   // Missing & 25/36 after
replace hiqual_L1_time_cat4_f = 7 if hiqual_L1_f == 0 & time_cat4 == 7   // Missing & 37/48 after
replace hiqual_L1_time_cat4_f = 8 if hiqual_L1_f == 0 & time_cat4 == 8   // Missing & 49/60 after
replace hiqual_L1_time_cat4_f = 9 if hiqual_L1_f == 0 & time_cat4 == 9   // Missing & 61+ after

foreach e in 1 2 3 4 5 6 9 {   // education
forvalues t = 1/9 {   // time before/after pregnancy
replace hiqual_L1_time_cat4_f = `e'`t' if hiqual_L1_f == `e' & time_cat4 == `t'
}
}

* Time from/to pregnancy # education (rough)
gen 	hiqual_L1_time_cat_f = .
replace hiqual_L1_time_cat_f = 1 if hiqual_L1_f == 0 & time_cat4 >= 1 & time_cat4 <= 3   // Missing & 25+ & 12/1 before
replace hiqual_L1_time_cat_f = 2 if hiqual_L1_f == 0 & time_cat4 >= 4 & time_cat4 <= 5   // Missing & 0/12 & 13/24 after
replace hiqual_L1_time_cat_f = 3 if hiqual_L1_f == 0 & time_cat4 >= 6 & time_cat4 <=10   // Missing & 25/36& 61+ after

foreach e in 1 2 3 4 5 6 9 {   // education
replace hiqual_L1_time_cat_f = `e'1 if hiqual_L1_f == `e' & time_cat4 >= 1 & time_cat4 <= 3
replace hiqual_L1_time_cat_f = `e'2 if hiqual_L1_f == `e' & time_cat4 >= 4 & time_cat4 <= 5
replace hiqual_L1_time_cat_f = `e'3 if hiqual_L1_f == `e' & time_cat4 >= 6 & time_cat4 <=10
}

* SELECTION OF VARIABLES
keep pidp wave partner n ///
endmnt* gest* preg* time* x1 x2 t t? treated treated? MAR*  mother pregnancy_loss cum_delivery N_chil* any_child ever_childless tria* distance_conception ///
fimn* sf12*  wellbein*  *mployed_?   ///
 age*  *_worked  min_wave* ///
union_type*  *_job* date_interv* year month *_? soc00_N_wave  gor*  hiqua*  jbnssec* job* jbstat* tenure* work_*  *L?*
 drop jbbg*_? jbbgdat*_? jbsoc*
 drop date*_? jobloss*_?

 gen double age_ev_tmp = age_f if (x1==1 | x2==1)
 bysort pidp_f (wave): egen double age_event = min(age_ev_tmp)
 drop age_ev_tmp
 label var age_event "Age (f) at pregnancy-end event (x1|x2==1) -- event-based eligibility"
 gen byte elig_ageev = (age_event>=18) if !missing(age_event)
 label var elig_ageev "1 if age at event >=18 (event-based eligibility, no upper cap: max N; SSR R&R)"

 save "$data/data_wage_v15.dta", replace
