*==============================================================================================
* pregnancies_v6.do
*
* Pregnancy histories: outcome, end date and conception date of each reported pregnancy.
* The dates of live births are anchored to the date of birth of the child when it is observed.
*
* Reads:   individual files of each wave (survey data needed), data/Wage/interview.dta and
*          bio.dta
* Writes:  data/Wage/x8.dta and wide_x8.dta
*
* Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
* and pregnancy losses. Social Science Research, 141, 103450.
*==============================================================================================

quietly do "config.do"   // folder settings: start Stata in the package folder

 global path   ${REPL_RAW}/UKDA-6614-stata-2/stata/stata11_se
 global path1  ${REPL_RAW}/UKDA-6614-stata/stata/stata13_se/ukhls
 global path2  ${REPL_RAW}/UKDA-6931-stata/stata/stata13_se/ukhls
 global path15 ${REPL_RAW}/UKDA-6614-stata/stata/stata13_se/ukhls

 global path6 ${REPL_RAW}
 global bio   ${REPL_DATA}/Wage/bio.dta

 global rawdata  	${REPL_RAW}/BHPS_UKHLS
 global data		${REPL_DATA}/Wage
 global do      	${REPL_CODE}

local use_w15       1
local use_bio       1
local run_interview 0
local outstub       x8

local nwaves = cond(`use_w15', 15, 14)   // panel length / last wave

* Interview dates
if `run_interview' {
	preserve
	 do "$do/Interview_v6"
	restore
}

local wletters b c d e f g h i j k l m n
if `use_w15' local wletters `wletters' o

foreach l of local wletters {
	if "`l'" == "o"   use "$path15/o_indresp.dta", clear
	else              use "$path2/`l'_indresp_protect.dta", clear

	capture keep pidp *hidp *pno *endmnth* *pregend* *preg* *nnewborn* *pregfert*
	rename `l'_* *
	forvalues i = 1/5 {
		capture rename pregy4`i' pregy`i'
	}

	capture confirm variable nnewborn
	if _rc gen nnewborn = .
	capture ds pregfert*
	if "`r(varlist)'" == "" gen pregfert1 = .

	keep pidp pregout* pregend* endmnth* pregy* pregm* nnewborn pregfert*
	gen wave = strpos("abcdefghijklmno","`l'")

	local w = strpos("abcdefghijklmno","`l'")
	tempfile birth`w'
	save "`birth`w''", replace
}

use "`birth2'", clear
forvalues w = 3/`nwaves' {
	append using "`birth`w''"
}
sort pidp wave
tempfile births
save   "`births'", replace

* Pregnancy details (Up to the 3rd pregnancy)
local letter  g h i j k l m n
foreach l of local letter {
 use "$path2/`l'_indresp_protect.dta", clear

keep pidp *pregspd* *pregft*
rename `l'_* *

sort pidp
keep pidp  pregspd* pregft*

  tempfile `l'births
  save   "``l'births'"
}

foreach x in  g h i j k l m n {
 use "``x'births'" , clear

  gen wave = strpos("abcdefghijklmn","`x'")
local wave = wave

 tempfile birth`wave'
  save  "`birth`wave''", replace
}

use "`birth7'", clear
forvalues w = 8/14{
append using "`birth`w''"
}
sort pidp wave
order pidp wave

rename pregft1* invitro*
rename pregft2* medication*
rename pregft3* sperm*
rename pregft4* egg*
rename pregft5* insemination*
rename pregft6* other*
rename pregft96* noMAR*

tempfile pregft
save    `pregft' , replace

local letter    b c d e f
foreach l of local letter {
 use "$path2/`l'_indresp_protect.dta", clear

keep pidp *invitro*
rename `l'_* *

sort pidp
keep pidp  invitro*

  tempfile `l'births
  save   "``l'births'"
}

foreach x in  b c d e f {
 use "``x'births'" , clear

  gen wave = strpos("abcdefghijklmn","`x'")
local wave = wave

 tempfile birth`wave'
  save  "`birth`wave''", replace
}

use "`birth2'", clear
forvalues w = 3/6{
append using "`birth`w''"
}
sort  pidp wave
order pidp wave

tempfile invitro
save    `invitro' , replace

use "`births'" , clear
merge 1:1 pidp wave using `invitro', nogen
merge 1:1 pidp wave using `pregft', nogen

drop *fh
drop pregft*

* Selection of cases
order pidp wave *1 *2 *3 *4 *5

 gen keep = .
 forvalues i = 1/5 {
 replace keep = 1 if pregm`i' >= -6 & pregm`i'<.
 replace keep = 1 if pregm`i' == -9
 replace keep = 1 if pregy`i' >= -6 & pregy`i'<.
 replace keep = 1 if pregy`i' == -9
 replace keep = 1 if pregout`i' !=.
 replace keep = 1 if pregend`i' !=.
 }

 foreach x in pregm pregy pregout pregend endmnth  {
	forvalues i = 1/5 {
replace `x'`i' = . if 	`x'`i' == -7
replace `x'`i' = . if 	`x'`i' == -8
replace `x'`i' = . if 	`x'`i' == -9
replace `x'`i' = . if 	`x'`i' == -10
}
}

 keep if keep == 1
 drop keep

reshape long pregm pregy  pregout pregend endmnth pregfert pregspd medication sperm egg insemination other invitro noMAR, i(pidp wave) j(n)

keep if pregm !=. | pregy !=. | pregout !=.| pregend !=. | endmnth !=.

order pidp wave pre*

rename pregfert MAR
drop pregspd medication sperm egg insemination other invitro noMAR

* Ongoing pregnancy at t-1 and outcome at t
sort pidp wave
by   pidp: gen 		ongoing = 	  			 	   pregout 	     == 4 & wave[_n+1] == wave+1
by   pidp: replace  ongoing = 2 		  		if pregout[_n-1] == 4 & wave[_n-1] == wave-1
by   pidp: gen      pregend_fwd = pregend[_n+1] if pregout       == 4 & wave[_n+1] == wave+1
by   pidp: gen	    pregout_fwd = pregout[_n+1] if pregout       == 4 & wave[_n+1] == wave+1
by   pidp: gen	    endmnth_fwd = endmnth[_n+1] if pregout       == 4 & wave[_n+1] == wave+1

by   pidp: replace pregm = pregm[_n-1] 	 			if ongoing == 2 & ongoing[_n-1] == 1 & wave[_n-1] == wave-1
by   pidp: replace pregy = pregy[_n-1] 	 			if ongoing == 2 & ongoing[_n-1] == 1 & wave[_n-1] == wave-1
by   pidp: replace pregend_fwd = pregend_fwd[_n-1]  if ongoing == 2 & ongoing[_n-1] == 1 & wave[_n-1] == wave-1
by   pidp: replace pregout_fwd = pregout_fwd[_n-1]  if ongoing == 2 & ongoing[_n-1] == 1 & wave[_n-1] == wave-1
by   pidp: replace endmnth_fwd = endmnth_fwd[_n-1]  if ongoing == 2 & ongoing[_n-1] == 1 & wave[_n-1] == wave-1

foreach x in pregout pregend endmnth {
	lab val `x' b_`x'5
}

lab val pregend_fwd b_pregend5
lab val pregout_fwd b_pregout5
lab val endmnth_fwd b_endmnth5
lab def ongoing 1 "Current pregnancy" 2 "Ended pregnancy"
lab val ongoing ongoing
sort pidp wave

lab var pregy "Year of pregnancy"
lab var pregm "Month of pregnancy"
lab var pregout "Outcome of pregnancy"
lab var pregend_fwd "End of pregnancy"
lab var pregout_fwd "End of pregnancy"
lab var endmnth_fwd "Length of interrupted pregnancy"
lab var MAR "any fertility treatment"

* Dropping duplicates

sort pidp wave
tempfile temp
save   "`temp'"

count
set seed 1234
drop n

* Date of conception
gen 	date_conception = ym(pregy, pregm)
format  date_conception %tm
replace date_conception = ym(pregy, runiformint(1,12)) if pregm < 0

gen byte dob_source = 0
label define dobsrc 0 "self-report" 1 "observed child DOB", replace
label values dob_source dobsrc
label var  dob_source "Live-birth dating source (1=observed child DOB, 0=self-report)"

if `use_bio' {
	preserve
		use "$bio", clear
		keep pidp childbirth_date
		drop if childbirth_date >= .
		duplicates drop
		rename childbirth_date obs_birth
		tempfile biolook
		save "`biolook'"
	restore

	count
	local _nbefore = r(N)

	gen long _pregid = _n
	gen expected_birth = date_conception + 9
	joinby pidp using "`biolook'", unmatched(master) _merge(_bm)
	gen _absd = abs(obs_birth - expected_birth)
	gsort _pregid _absd
	by _pregid: keep if _n == 1
	replace dob_source     = 1          if inlist(pregout,1,2) & obs_birth < . & _absd <= 3
	replace date_conception = obs_birth - 9 if dob_source == 1
	drop _pregid expected_birth obs_birth _absd _bm

	count
	assert r(N) == `_nbefore'
}

sort pidp wave
by   pidp: gen n = _n
by   pidp: gen N = _N
egen max_N = max(N)
su max_N, meanonly
local maxep = r(max)

tempfile 	wide
save       `wide'
save "$data/wide_`outstub'.dta", replace

preserve
keep if _n == _N
local N8 = max_N
di `N8'
restore

reshape wide wave preg* end* date_conception MAR ongoing nnewborn dob_source, i(pidp) j(n)

expand `nwaves'
sort pidp
by   pidp: gen wave = _n
order pidp wave

tempfile x8
save    `x8', replace

 order pidp wave wave1 date_conception1 pregend1 pregout1 pregm1 pregy1  ///
				 wave2 date_conception2 pregend2 pregout2 pregm2 pregy2  ///
				 wave3 date_conception3 pregend3 pregout3 pregm3 pregy3

merge m:1 pidp 	    using "$data/interview", nogen keep(1 3)

forvalues i = 1/`maxep' {
 gen 	pregnancy_end`i' = date_conception`i' + 9 if pregout`i' == 1 | pregout`i' == 2
replace pregnancy_end`i' = date_conception`i' + 3 if endmnth`i' == 1
replace pregnancy_end`i' = date_conception`i' + 3 if endmnth`i' == . & pregout`i' == 3
replace pregnancy_end`i' = date_conception`i' + 6 if endmnth`i' == 2
replace pregnancy_end`i' = date_conception`i' + 9 if endmnth`i' == 3
replace pregnancy_end`i' = date_conception`i' + 2 if endmnth`i' ==-1 | endmnth`i' ==-2
replace pregnancy_end`i' = date_conception`i' + 3 if pregout`i' ==-1 | pregout`i' ==-2
format  pregnancy_end`i' %tm
lab var pregnancy_end`i' "Earliest date of pregnancy end"
}
 order pidp wave wave1 date_conception1 pregend1 pregout1 pregnancy_end1 ///
				 wave2 date_conception2 pregend2 pregout2 pregnancy_end2 ///
				 wave3 date_conception3 pregend3 pregout3 pregnancy_end3 intdat*
forvalues i = 1/`maxep' {
gen wave_new`i' = .
}
forvalues i = 1/`maxep' {
forvalues x = 2/`nwaves' {
	local j = `x' - 1
 replace wave_new`i' = `x' if pregnancy_end`i' > intdat`j' & pregnancy_end`i' <= intdat`x'  & intdat`j' !=. & intdat`x' !=. & pregnancy_end`i' < .
}
}

forvalues x = 1/`maxep' {
	gen wave_diff`x' = wave_new`x' - wave`x'
}

 order pidp wave wave1 wave_new1 wave_diff1 date_conception1 pregend1 pregout1 pregnancy_end1  ///
				 wave2 wave_new2 wave_diff2 date_conception2 pregend2 pregout2 pregnancy_end2 ///
				 wave3 wave_new3 wave_diff3 date_conception3 pregend3 pregout3 pregnancy_end3 intdat*

forvalues x = 1/`maxep' {
replace wave`x' = wave_new`x' if wave_diff`x' < 0 & wave_new`x' < .
}

* Case 1: live birth (natural delivery / caesarean)
gen 	 x1 = 0
forvalues i = 1/`maxep' {
 replace x1 = 1 if (pregout`i' == 1 | pregout`i' == 2) & wave == wave`i'
}
lab def  x1 1 "Delivery"
lab val  x1 x1

* Case 2: not live birth
gen 	 x2 = 0
forvalues i = 1/`maxep' {
 replace x2 = 1 if (pregend`i' == 1 | pregend`i' == 2) & wave == wave`i'
}
lab def  x2 1 "Miscarriage/Stillbirth"
lab val  x2 x2

* Number of episodes
egen 	N2 = anycount(pregend*), v(1 2)
replace N2 = 0 if x2 == 0

* Case 3: other not live birth (termination / ectopic)
gen 	 x3 = 0
forvalues i = 1/`maxep' {
 replace x3 = 1 if (pregend`i' == 3 | pregend`i' == 4) & wave == wave`i'
}
lab def  x3 1 "Termination/Ectopic/Tubal"
lab val  x3 x3

* Case 4: current pregnancy without known outcome
gen 	 x4 = 0
forvalues i = 1/`maxep' {
 replace x4 = 1 if (pregout`i' == 4 & pregout_fwd`i' == .) & wave == wave`i'
}
lab def  x4 1 "Current pregnancy"
lab val  x4 x4

gen 	 x5 = 0
forvalues i = 1/`maxep' {
 replace x5 = 1 if (pregend`i' == 3 | pregend`i' == 4 | pregend`i' < 0) & wave == wave`i'
}
lab def  x5 1 "Termination/Ectopic/Tubal/Don'tKnow"
lab val  x5 x5

gen 	 x6 = 0
forvalues i = 1/`maxep' {
 replace x6 = 1 if (pregend`i' == 1 | pregend`i' == 2 | pregend`i' == 3 | pregend`i' == 4) & wave == wave`i'
}
lab def  x6 1 "Miscarriage/Stillbirth/Ectopic/Tubal", modify
lab val  x6 x6

gen 	 x7 = 0
forvalues i = 1/`maxep' {
 replace x7 = 1 if (pregend`i' == 1 | pregend`i' == 2 | pregend`i' == 3 | pregend`i' == 4 | pregend`i' < 0) & wave == wave`i'
}
lab def  x7 1 "Miscarriage/Stillbirth/Ectopic/Tubal/Don't Know", modify
lab val  x7 x7

lab var x1 "Live birth (natural delivery / caesarean)"
lab var x2 "Miscarriage/Stillbirth"
lab var x3 "Other not live birth (termination / ectopic)"
lab var x4 "Current pregnancy without known outcome"
lab var x5 "Other not live birth (termination / ectopic / don't know...)"
lab var x6 "Non-live birth (miscarriage / stillbirth / termination / ectopic)"
lab var x7 "Non-live birth (miscarriage / stillbirth / termination / ectopic / don't know...)"

keep  pidp wave x*  N date_conception* preg* end* wave* MAR* nnewborn* dob_source*
order pidp wave x?

forvalues x = 1/7 {
char x`x' [_de_col_width_] 7
}
foreach i in pregend_fwd pregout_fwd {
forvalues x = 1/`maxep' {
char `i'`x' [_de_col_width_] 7
	}
}

save "$data/`outstub'.dta", replace
