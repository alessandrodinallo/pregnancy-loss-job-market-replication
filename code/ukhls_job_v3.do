*==============================================================================================
* ukhls_job_v3.do
*
* Job histories by person and wave: employment spells, job endings and their reasons,
* occupation, class, work experience and tenure.
*
* Adapted from data-preparation code written by Lewis Anderson (2018) and used with
* his permission.
*
* Reads:   individual files of each wave and the cross-wave file (survey data needed)
* Writes:  data/Wage/UKHLS_unemployment_wide.dta and UKHLS_unemployment_long.dta
*
* Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
* and pregnancy losses. Social Science Research, 141, 103450.
*==============================================================================================

quietly do "config.do"   // folder settings: start Stata in the package folder

clear all
macro drop _all
quietly do "config.do"   // loads the folder settings again
version 14.2
set linesize 120
set varabbrev off
set more off, perm
set seed 1524

* Paths
    global rawdata   ${REPL_RAW}/UKDA-6614-stata-2/stata/stata11_se
	global protect   ${REPL_RAW}/UKDA-6931-stata/stata/stata13_se/ukhls

 global do			${REPL_CODE}
 global data      	${REPL_DATA}/Wage
 global data2		${REPL_DATA}

global path15 "${REPL_RAW}/UKDA-6614-stata 2/stata/stata14_se/ukhls"
local use_w15 0
local uw_main a b c d e f g h i j k l m n
if `use_w15' local uw_main `uw_main' o
local n_main = cond(`use_w15', 15, 14)
local n_prot = 14

foreach w of local uw_main {

if "`w'"=="o" local src "$path15/o_indresp.dta"
else          local src "$protect/`w'_indresp_protect"

use pidp `w'_sex_dv `w'_age_dv `w'_jbstat `w'_mastat_dv `w'_marstat `w'_jbnssec8_dv `w'_hiqual_dv  `w'_nchild_dv `w'_jbnssec5_dv `w'_jlnssec8_dv ///
`w'_jbhad `w'_intdatd_dv `w'_intdatm_dv `w'_intdaty_dv `w'_jlendm `w'_jlendy `w'_pno `w'_ppno `w'_hidp using ///
"`src'", clear

rename `w'_* *

gen partnum=cond(pno < ppno, pno, ppno) if ppno>0 & !missing(ppno)
lab var partnum "Partnership identifier, within household"

bysort hidp partnum: egen numinpart = total(ppno > 0 & !missing(ppno))
lab var numinpart "# respondents from partnership (max 2)"

bysort hidp partnum: gen sp_age_dv = cond(_n==2,age_dv[1],age_dv[2],.) if partnum <.
lab val sp_age_dv age_dv

bysort hidp partnum: gen sp_sex_dv = cond(_n==2,sex_dv[1],sex_dv[2],.) if partnum <.
lab val sp_sex_dv sex_dv

bysort hidp partnum: gen sp_jbstat = cond(_n==2,jbstat[1],jbstat[2],.) if partnum <.
lab val sp_jbstat jbstat

bysort hidp partnum: gen sp_hiqual_dv = cond(_n==2,hiqual_dv[1],hiqual_dv[2],.) if partnum <.
lab val sp_hiqual_dv hiqual_dv

gen wave = strpos("abcdefghijklmno","`w'")

recode jbstat (10 11=97)
recode sp_jbstat (10 11=97)

local wave = wave

tempfile temp`wave'
save   "`temp`wave''", replace

}

 use "`temp1'", clear
forvalues w  = 2/`n_main' {
 append using "`temp`w''"
 }

tempfile 		base_lewis
save   		  "`base_lewis'"

order pidp wave jbstat
sort  pidp wave

foreach w in b c d e f g h i j k l m n {

use pidp `w'_nunmpsp_dv `w'_nmpsp_dv `w'_empstendd `w'_empstendm `w'_empstendy4 `w'_nxtstendd `w'_nxtstendm `w'_nxtstendy4 `w'_nxtjbendd `w'_jbendm `w'_jbendy4 `w'_nxtjbendm `w'_nxtjbendy4 ///
 `w'_statendd* `w'_statendm* `w'_statendy4* `w'_notempchk `w'_nxtstelse `w'_cstat `w'_nextelse* `w'_nextstat* `w'_nextjob* `w'_currstat* `w'_currjob* `w'_nxtst `w'_relup ///
 `w'_ff_ivlolw `w'_cohab `w'_mstatsam `w'_mstatsamn `w'_statcm* `w'_statcy4* `w'_lmspm* `w'_lmspy4* `w'_mstatch* `w'_currpart* ///
 using "$protect/`w'_indresp_protect", clear

rename `w'_* *

gen wave = strpos("abcdefghijklmno","`w'")

local wave = wave

tempfile temp`wave'
save   "`temp`wave''", replace
}

use "`temp1'", clear

forvalues w = 2/`n_prot'{
append using "`temp`w''"
}

tempfile   CEp2data_b
save     "`CEp2data_b'", replace

 use "`base_lewis'" , clear
 merge 1:1 pidp wave using "`CEp2data_b'", nogen
				  tempfile   CEp2data_b
				      save "`CEp2data_b'", replace

{

foreach w in b c d e f  {

use pidp `w'_stendreas `w'_jbendreas `w'_reasend*  ///
 using "$protect/`w'_indresp_protect", clear

rename `w'_* *

gen wave = strpos("abcdefghijklmno","`w'")

local wave = wave
tempfile temp`wave'
save   "`temp`wave''",
}

  use "`temp2'", clear
forvalues w = 3/6{
 append using "`temp`w''"
}
merge 1:1 pidp wave using  "`CEp2data_b'", nogen

				  tempfile   CEp2data_b
				      save "`CEp2data_b'", replace
}

{

foreach w in e f {

use pidp `w'_nxtendreas ///
using "$protect/`w'_indresp_protect", clear

rename `w'_* *

gen wave = strpos("abcdefghijklmno","`w'")

local wave = wave

tempfile temp`wave'
save   "`temp`wave''"
}
  use        "`temp5'", clear
append using "`temp6'"
merge 1:1 pidp wave using "`CEp2data_b'", nogen

tempfile 	  CEp2data_b
save  		"`CEp2data_b'", replace

}

{

foreach w in g h i j k l m n {

use pidp `w'_stendreas* `w'_jbendreas* `w'_reasend*_* `w'_nxtendreas* ///
using "$protect/`w'_indresp_protect", clear

rename `w'_* *

gen wave = strpos("abcdefghijklmno","`w'")

local wave = wave

tempfile temp`wave'
save   "`temp`wave''"
}

  use        "`temp7'", clear
  forvalues w = 8/`n_prot'{
append using "`temp`w''"
}
merge 1:1 pidp wave using "`CEp2data_b'", nogen

tempfile 	  CEp2data_b
save  		"`CEp2data_b'", replace
}

* adding in xwavedat
merge m:1 pidp using "$protect/xwavedat_protect", keepusing(xwdat_dv hhorig memorig psu strata birthy lvag14 ynlp14 maedqf paedqf maju paju) keep (1 3)

tempfile 	  CEp2data_b
save  		"`CEp2data_b'", replace

sort  pidp wave
order pidp wave _merge

* economic status (& partner's)

		recode jbstat ///
		(-9 -8 -7 -2 -1 = .) ///
		(1 2 = 1 "Employed") ///
		(3 = 2 "Unemployed") ///
		(4 = 3 "Retired") ///
		(7 = 4 "Student") ///
		(8 = 5 "LT sick/disabled") ///
		(5 6 9 10 97 = 6 "Other OLF"), ///
		into(econstat)
		label variable econstat "Economic status (6 categories)"

		recode sp_jbstat ///
		(-9 -8 -7 -2 -1 = .) ///
		(1 2 = 1 "Employed") ///
		(3 = 2 "Unemployed") ///
		(4 = 3 "Retired") ///
		(7 = 4 "Student") ///
		(8 = 5 "LT sick/disabled") ///
		(5 6 9 10 97 = 6 "Other OLF"), ///
		into(sp_econstat)
		label variable sp_econstat "Partner's economic status (6 categories)"

* economic status (& partner's) (3 categories)

		recode econstat ///
		(1 = 1 "Employed") ///
		(2 = 2 "Unemployed") ///
		(3 4 5 6 = 3 "OLF"), ///
		into(E)

		label variable E "Economic status (3 categories)"

	clonevar ec = E

		recode sp_econstat ///
		(1 = 1 "Employed") ///
		(2 = 2 "Unemployed") ///
		(3 4 5 6 = 3 "OLF"), ///
		into(sp_ec)

		label variable sp_ec "Partner's economic status (3 categories)"

* education (& partner's)

		recode hiqual_dv (-9 -8 -7 -2 -1 = .)(9 = 6), into(edu)

		label define edu ///
		1 "Degree" ///
		2 "Other higher degree" ///
		3 "A-level etc." ///
		4 "GCSE etc." ///
		5 "Other qualification" ///
		6 "No qualification"
		label values edu edu

		label variable edu "Education - highest qualification (6 categories)"

		drop hiqual_dv

		recode sp_hiqual_dv (-9 -8 -7 -2 -1 = .)(9 = 6), into(sp_edu)
		label values sp_edu edu
		label variable sp_edu "Partner's education - highest qualification (6 categories)"
		drop sp_hiqual_dv

		recode edu (5 6 = 5), into(ed)
		recode sp_edu (5 6 = 5), into(sp_ed)

		label define ed ///
		1 "Degree" ///
		2 "Other higher degree" ///
		3 "A-level etc." ///
		4 "GCSE etc." ///
		5 "<GCSE"

		label values ed ed
		label values sp_ed ed

		label variable ed "Education - highest qualification (5 categories)"
		label variable sp_ed "Partner's education - highest qualification (5 categories)"

* educational homo/heterogamy

		gen eddiff = .

		label define eddiff ///
		1 "R more educated" ///
		2 "equally educated" ///
		3 "R less educated"

		replace eddiff = 1 if ed < sp_ed  & ed !=. & sp_ed !=.
		replace eddiff = 2 if ed == sp_ed & ed !=. & sp_ed !=.
		replace eddiff = 3 if ed > sp_ed  & ed !=. & sp_ed !=.

		label values eddiff eddiff

* kids dummy

		recode nchild_dv (1/10 = 1 "Yes")(0 = 0 "No"), into(haskids)
		label variable haskids "Number of own children in household >0"

* NS-SEC, current job

		recode jbnssec8_dv (-9 -8 -1 = .), into(nssec8)
		label variable nssec8 "current job: 8-class NS-SEC"

		label define nssec8 ///
		1 "Large employers & higher management" ///
		2 "Higher professional" ///
		3 "Lower management & professional" ///
		4 "Intermediate" ///
		5 "Small employers & own account" ///
		6 "Lower supervisory & technical" ///
		7 "Semi-routine" ///
		8 "Routine"
		label values nssec8 nssec8

		gen nssec3 = .
		replace nssec3 = 1 if inrange(nssec8,1,3)
		replace nssec3 = 2 if inrange(nssec8,4,6)
		replace nssec3 = 3 if inrange(nssec8,7,8)
		label variable nssec3 "current job: 3-class NS-SEC"

		label define nssec3 ///
		1 "Managerial and professional" ///
		2 "Intermediate" ///
		3 "Routine and manual"
		label values nssec3 nssec3

		gen nssec5 = .
		replace nssec5 = 1 if inrange(nssec8,1,2)
		replace nssec5 = 2 if inrange(nssec8,3,3)
		replace nssec5 = 3 if inrange(nssec8,4,6)
		replace nssec5 = 4 if inrange(nssec8,7,7)
		replace nssec5 = 5 if inrange(nssec8,8,8)
		label variable nssec5 "current job: 5-class NS-SEC"

		label define nssec5 ///
		1 "Large emp./higher man./pro." ///
		2 "Lower man./pro." ///
		3 "Intermed./small emp./lower sup./tech." ///
		4 "Semi-routine" ///
		5 "Routine and manual"
		label values nssec5 nssec5

		recode nunmpsp_dv (-9 -8 -7 =.)(0=0)(1 2 3 4 5 6 =1), into(unmpspl)
		label variable unmpspl "Indicates had an unemployment spell since last interview"
		drop nunmpsp_dv

* period/survey control

		recode memorig ///
		(3 4 5 6 14 15 16 = 1 "BHPS") ///
		(1 2 7 8 = 2 "UKHLS"), ///
		into(whichsurvey)

* interview date

		mvdecode intdatd_dv intdatm_dv intdaty_dv , mv(-9 = .)

		gen intdat    = mdy(intdatm_dv,intdatd_dv,intdaty_dv)
		gen intdat_ym =  ym(intdaty_dv,intdatm_dv)
	 format intdat_ym %tm

		mvdecode empstendd empstendm empstendy4 nxtstendd nxtstendm nxtstendy4 nxtjbendd nxtjbendm nxtjbendy4 jbendm jbendy4, mv(-10 -9 -8 -7 -2 -1 = .)

		mvdecode statend*, mv(-10 -8 -7 -2 -1 = .)

		forvalues i=1/10 {
		replace statendd`i' = 1 if statendd`i' ==. & statendy4`i' !=.
		}

		gen empstend = mdy(empstendm,empstendd,empstendy4)
		gen nxtstend = mdy(nxtstendm,nxtstendd,nxtstendy4)
		gen nxtjbend = mdy(nxtjbendm,nxtjbendd,nxtjbendy4)
		format empstend nxtstend nxtjbend %td

		forvalues i=1/10 {
		gen statend`i' = mdy(statendm`i',statendd`i',statendy4`i')
		format statend`i' %td
		}

* USoc: date left last job (if not previously interviewed)

		mvdecode jlendm jlendy, mv(-9 -8 -7 -2 -1 = .)

		gen     jlendd = 1 if jlendy !=. & inrange(wave,1,`n_main')

		gen jlend = mdy(jlendm,jlendd,jlendy)
		format jlend %td

* USoc: continuously unemployed since last interview

        xtset pidp wave
		gen contunemp = .
		replace contunemp = 1 if jbstat ==3 & L.jbstat ==3 & notempchk ==1 & inrange(wave,1,`n_main')  ///
		*inrange(wave,20,27)

replace ec =1 if ec ==. & nssec8 !=.

drop if ec ==.

drop if ec ==1 & nssec8 ==.

tempfile     CEp2data_b
save       "`CEp2data_b'"	, replace

* unemployment dummy

		gen ue = .
		replace ue = 0 if ec ==1
		replace ue = 1 if ec ==2

		label variable ue "unemployed =1, employed =0, OLF missing"

{

clonevar ecD3 = ec
label variable ecD3 "econ. stat., 3 cat., d/ward mob. (NSSEC-3) relative to prev. year incl. with unemployed"

replace ecD3	= 2 if ecD3 ==1 & ((L.nssec3 < nssec3) & !missing(L.nssec3,nssec3))
}

			clonevar ecDc = ec
			label variable ecDc "econ. stat., d/ward mob. (NSSEC-3; relative to prev. year) incl. with unemployed"

			replace ecDc	= 2 if ecDc ==1 & ((L.nssec3 < nssec3) & !missing(L.nssec3,nssec3))

			gen miss 		= 1 if ecDc ==1 & L.nssec3 ==. & L.ec !=2 & L.ec !=3
			replace miss 	= 1 if ecDc ==1 & nssec3 ==.
			replace ecDc	= . if ecDc ==1 & miss ==1
			drop miss

		* jobloss_c
			gen jobloss_c = .
			replace jobloss_c = 1 if L.ec ==1 & ecDc ==2
			replace jobloss_c = 0 if L.ec ==1 & ecDc ==1
			label variable jobloss_c "job loss outcome, consecutive waves only"

			clonevar ecDg = ec
			label variable ecDg "econ. stat., d/ward mob. (NSSEC-3; relative to prev. OBS.) incl. with unemployed"

			bysort pidp (wave): gen first = 1 if _n ==1
			label variable first "First observation for each individual"

			replace ecDg	= 2 if ecDg ==1 & (nssec3[_n-1] < nssec3) & !missing(nssec3[_n-1],nssec3) & first !=1

			gen miss 	 	= 1 if ecDg ==1 & first ==1
			replace miss 	= 1 if ecDg ==1 & nssec3 ==.
			replace miss 	= 1 if ecDg ==1 & nssec3[_n-1] ==. & ec[_n-1] !=2 & ec[_n-1] !=3 & first !=1
			replace ecDg	= . if ecDg ==1 & miss ==1
			drop miss
		* jobloss_g
			gen jobloss_g = .
			replace jobloss_g = 1 if ec[_n-1] ==1 & ecDg ==2 & first !=1
			replace jobloss_g = 0 if ec[_n-1] ==1 & ecDg ==1 & first !=1
			label variable jobloss_g "job loss outcome, including between gaps (missing waves)"

		gen jobloss_cs = .
		replace jobloss_cs = 1 if L.ec ==1 & ec ==2
		replace jobloss_cs = 0 if L.ec ==1 & ec ==1

		* jobloss_cl
		gen jobloss_cl = .
		replace jobloss_cl = 0 if L.ec ==1 & ec ==1
		replace jobloss_cl = 1 if L.ec ==1 & ec ==2
		replace jobloss_cl = 1 if L.ec ==1 & ec ==1 & L.nssec3 ==1 & nssec3 ==3

		* jobloss_d
		gen jobloss_d = .
		replace jobloss_d = 0 if L.ec ==1 & ec ==1
		replace jobloss_d = 1 if L.ec ==1 & ec ==2
		replace jobloss_d = 1 if L.ec ==1 & (unmpspl ==1 )

		* jobloss_e
		gen jobloss_e = .
		replace jobloss_e = 0 if L.ec ==1 & ecDc ==1
		replace jobloss_e = 1 if L.ec ==1 & ecDc ==2
		replace jobloss_e = 1 if L.ec ==1 & (unmpspl ==1 )

		* jobloss_el
		gen jobloss_el = .
		replace jobloss_el = 0 if L.ec ==1 & ec ==1
		replace jobloss_el = 1 if L.ec ==1 & ec ==2
		replace jobloss_el = 1 if L.ec ==1 & ec ==1 & L.nssec3 ==1 & nssec3 ==3
		replace jobloss_el = 1 if L.ec ==1 & (unmpspl ==1 )

		* jobloss_gs
		gen jobloss_gs = .
		replace jobloss_gs = 1 if ec[_n-1] ==1 & ec ==2 & first !=1
		replace jobloss_gs = 0 if ec[_n-1] ==1 & ec ==1 & first !=1

gen worked = .
replace worked = 0 if  nmpsp_dv ==0
replace worked = 1 if  inrange(nmpsp_dv,1,7)
label variable worked "at least one employment spell in previous year"

* Replacing missing (N/A, inapplicable, proxy)
foreach v in jbendreas stendreas nxtendreas {
replace `v' = . if `v' <= 0
}

foreach v in jbendreas stendreas nxtendreas  {
foreach i in 1 2 3 4 5 6 7 8 9 10 11 97 {
	replace `v'`i' = . if `v'`i' <=0
	}
}

foreach v in reasend  {
foreach i in 1 2 3 4 5 6 7 8 9 10 11 97 {
forvalues x = 1/9{
	replace `v'`i'_`x' = . if `v'`i'_`x' <=0
	}
}
}

foreach v in reasend  {
forvalues x = 1/10{
	replace `v'`x' = . if `v'`x' <=0
	}
}

gen     jobloss_345 = .
replace jobloss_345 = 0 if worked ==1

replace jobloss_345 = 1 if inrange(jbendreas,3,5) |  inrange(stendreas,3,5) | inrange(nxtendreas,3,5)

foreach v in jbendreas stendreas nxtendreas {
replace jobloss_345 = 1 if `v'3 ==1 | `v'4 ==1 | `v'5 ==1
}

forvalues i=1/9 {
replace jobloss_345 = 1 if inrange(reasend`i',3,5) |  reasend3_`i' ==1 | reasend4_`i' ==1 | reasend5_`i' ==1
}

label variable jobloss_345 "JL since last interview b/c made redundant, dismissed/sacked, or temporary job ended"

* 1/ jbendreas
gen 	jbend = .
foreach i in 1 2 3 4 5 6 7 8 9 10 11 97 {
replace jbend = `i' if jbendreas == `i'
replace jbend = `i' if jbendreas`i' ==1
}
lab def ue 3 "Made redundant" 4 "Dismissed/sacked" 5 "Temporary job ended" 97 "Other"
lab val jbend ue

gen     jbend_unknown = 0
replace jbend_unknown  = (jbendy4 != . | jbendm !=.)
replace jbend_unknown = 0 if jbendreas != .
foreach i in 1 2 3 4 5 6 7 8 9 10 11 97 {
replace jbend_unknown = 0 if jbendreas`i' !=.
}

* 2/ stendreas
gen 	stend = .
foreach i in 1 2 3 4 5 6 7 8 9 10 11 97 {
replace stend = `i' if stendreas == `i'
replace stend = `i' if stendreas`i' ==1
}
lab val stend ue

gen     stend_unknown = 0
replace stend_unknown  = (empstendy4 != . | empstendm !=.)
replace stend_unknown = 0 if stendreas != .
foreach i in 1 2 3 4 5 6 7 8 9 10 11 97 {
replace stend_unknown = 0 if stendreas`i' !=.
}

* 3/ nxtendreas
gen 	nxtend = .
foreach i in 1 2 3 4 5 6 7 8 9 10 11 97 {
replace nxtend = `i' if nxtendreas == `i'
replace nxtend = `i' if nxtendreas`i' ==1
}
lab val nxtend ue

gen     nxtend_unknown = 0
replace nxtend_unknown = 1 if nxtjbendy4 != .| nxtjbendm !=.
replace nxtend_unknown = 0 if nxtendreas != .
foreach i in 1 2 3 4 5 6 7 8 9 10 11 97 {
replace nxtend_unknown = 0 if nxtendreas`i' !=.
}

* 4/ reasend
forvalues i = 1/9{
foreach x in 1 2 3 4 5 6 7 8 9 10 11 97 {
replace reasend`i' = `x' if reasend`x'_`i' == 1
}
}

forvalues i = 1/10{
replace reasend`i' = 97 if reasend`i' == 97
}
forvalues i = 1/9{
	foreach x in   3 4  {
replace reasend`i' = `x' if reasend`x'_`i' == 1
}
}

forvalues x = 1/9{
gen     reasend_unknown`x' = 0
replace reasend_unknown`x' = 1 if statendy4`x' != .| statendm`x' !=.
replace reasend_unknown`x' = 0 if reasend`x' != .
foreach i in 1 2 3 4 5 6 7 8 9 10 11 97 {
replace reasend_unknown`x' = 0 if reasend`i'_`x' !=.
}
}

* B. "Other causes of job loss"
foreach i in 1 2 3 4 5 6 7 8 9 10 11 97 {
gen 	jobloss_`i' = .
replace jobloss_`i' = 0 if worked ==1

replace jobloss_`i' = 1 if jbendreas ==`i' |  stendreas ==`i' | nxtendreas ==`i'

foreach v in jbendreas stendreas nxtendreas {
replace jobloss_`i' = 1 if `v'`i' ==1
}

forvalues j=1/9 {
replace jobloss_`i' = 1 if reasend`j' ==`i' |  reasend`i'_`j' ==1
}
}

label variable jobloss_1 "JL since last interview b/c Promoted"
label variable jobloss_2 "JL since last interview b/c Left for better job"
label variable jobloss_3 "JL since last interview b/c Made redundant"
label variable jobloss_4 "JL since last interview b/c Dismissed/sacked"
label variable jobloss_5 "JL since last interview b/c Temporary job ended"
label variable jobloss_6 "JL since last interview b/c Took retirement"
label variable jobloss_7 "JL since last interview b/c Health reasons"
label variable jobloss_8 "JL since last interview b/c Left to have baby"
label variable jobloss_9 "JL since last interview b/c Look after family"
label variable jobloss_10 "JL since last interview b/c Look after other person"
label variable jobloss_11 "JL since last interview b/c Moved area"
label variable jobloss_97 "JL since last interview b/c Other reason"

gen jobloss_m = .
replace jobloss_m = 0 if worked ==1
foreach i in 3 4 5 7 9 10 11 97 {
replace jobloss_m = 1 if jobloss_`i' ==1
}
label variable jobloss_m "JL since last interview, multiple reasons included"

gen     jobloss_other = .
replace jobloss_other = 1 if inrange(jbendreas,1,2) | inrange(jbendreas,6,16) |  ///
						     inrange(stendreas,1,2) | inrange(stendreas,6,16) | ///
							 inrange(nxtendreas,1,2)| inrange(nxtendreas,6,16)

foreach v in jbendreas stendreas nxtendreas {
replace jobloss_other = 1 if `v'1 ==1 | `v'2 ==1 | `v'6 ==1 | `v'7 ==1 | `v'8 ==1 | `v'9 ==1 | `v'10 ==1 | `v'11 ==1
}
forvalues i=1/9 {
replace jobloss_other = 1 if inrange(reasend`i',1,2) |  inrange(reasend`i',6,16)
replace jobloss_other = 1 if reasend1_`i' ==1 | reasend2_`i' ==1 | reasend6_`i' ==1 | reasend7_`i' ==1 | reasend8_`i' ==1 | reasend9_`i' ==1 | reasend10_`i' ==1 | reasend11_`i' ==1
}
label variable jobloss_other "JL since last interview b/c of other causes"

drop _merge
drop reasendoth_c*

 tempfile base_lewis
 save 	 `base_lewis', replace

* 1/ jbendreas/jbend
preserve
keep pidp wave jbend jbendy4 jbendm
keep if jbend ==3  | jbend == 4 | jbend == 5 | jbend == 97
rename jbendy4 jbendy

foreach x in 3 4 5 97 {
gen     unemployed_date`x' = .
replace unemployed_date`x' = ym(jbendy  , jbendm ) if 	 jbend ==`x'
format  unemployed_date`x' % tm
}

rename jbend  jobloss
rename jbendm month
rename jbendy year

tempfile jbend
save   "`jbend'", replace
restore

* 2/ stendreas
preserve
keep pidp wave empstendm empstendy4 stend
keep if stend ==3  | stend == 4 | stend == 5 | stend == 97
rename empstendy4 empstendy

foreach x in 3 4 5 97 {
gen     unemployed_date`x' = .
replace unemployed_date`x' = ym(empstendy  , empstendm ) if 	 stend ==`x'
format  unemployed_date`x' % tm
}

rename stend 	 jobloss
rename empstendm month
rename empstendy year

tempfile stend
save   "`stend'", replace
restore

* 3/ nxtendreas
preserve
keep pidp wave nxtjbendm nxtjbendy4 nxtend nxtst
keep if nxtend ==3  | nxtend == 4 | nxtend == 5 | nxtend == 97
drop if nxtst == 1
rename nxtjbendy4 nxtjbendy

foreach x in 3 4 5 {
gen     unemployed_date`x' = .
replace unemployed_date`x' = ym(nxtjbendy  , nxtjbendm) if 	 nxtend ==`x'
format  unemployed_date`x' % tm
}

gen     unemployed_date97 = .
replace unemployed_date97 = ym(nxtjbendy  , nxtjbendm) if 	 nxtend ==97 & nxtst !=1
format  unemployed_date97 % tm
drop nxtst
rename nxtend 	 jobloss
rename nxtjbendm month
rename nxtjbendy year

tempfile nxtend
save   "`nxtend'", replace
restore

* 4/ reasend
preserve
keep pidp wave statendm* statendy*  reasend*
gen keep = .
forvalues i = 1/10 {
replace keep = 1 if reasend`i' == 3 | reasend`i' == 4 | reasend`i' == 5 | reasend`i' == 97
}
keep if keep == 1
drop reasend*_*
forvalues i = 1/10 {
rename statendy4`i' statendy`i'
}
drop keep

reshape long statendy statendm reasend, i(pidp wave) j(n)
keep if statendy !=. |  statendm !=. | reasend !=.
sort pidp wave
drop n

rename reasend  jobloss
rename statendm month
rename statendy year

tempfile reasend
save   "`reasend'", replace
restore

use           "`jbend'", clear
append using  "`stend'"
append using  "`nxtend'"
append using  "`reasend'"
keep if jobloss == 3 | jobloss ==4 | jobloss == 5 | jobloss == 97
sort pidp wave
gen unemployed_date = .
foreach i in 3 4 5 97{
replace unemployed_date = unemployed_date`i'  if unemployed_date`i' != .
}
replace unemployed_date = ym(year, month) if unemployed_date == .
format  unemployed_date %tm

tempfile ue1
save   "`ue1'", replace

 use 	    `base_lewis' , clear

* 1/ jbendreas/jbend
preserve
keep pidp wave jbend jbendy4 jbendm jbend_unknown
keep if jbend_unknown == 1
rename jbendy4 jbendy

gen 	unemployed_date  = ym(jbendy  , jbendm )
format  unemployed_date % tm
replace jbend = 99
rename  jbend  jobloss
rename  jbendm month
rename  jbendy year
drop *unknown
tempfile jbend
save   "`jbend'", replace
restore

* 2/ stendreas
preserve
keep pidp wave stend empstendm empstendy4 stend_unknown

keep if stend_unknown == 1
rename empstendy4 empstendy

gen     unemployed_date  = ym(empstendy  , empstendm )
format  unemployed_date % tm
replace stend = 99
rename  stend  jobloss
rename  empstendm month
rename  empstendy year
drop *unknown
tempfile stend
save   "`stend'", replace
restore

* 4/ reasend
preserve
keep pidp wave statendm* statendy* reasend*
gen keep = .
forvalues i = 1/9 {
replace keep = 1 if reasend_unknown`i' == 1
}
keep if keep == 1
drop keep
drop reasend*_*

gen drop = .
forvalues i = 1/9 {
replace drop = 1 if reasend`i' != .
}
drop if drop ==1
drop drop
drop reasend*

forvalues i = 1/10 {
rename statendy4`i' statendy`i'
}

reshape long statendy statendm reasend, i(pidp wave) j(n)
keep if statendy !=. |  statendm !=. | reasend !=.
sort pidp wave
drop n

rename reasend  jobloss
rename statendm month
rename statendy year
gen     unemployed_date  = ym(year  , month )
format  unemployed_date % tm

tempfile reasend
save   "`reasend'", replace
restore

use           "`jbend'", clear
append using  "`stend'"
append using  "`reasend'"
tempfile ue2
save   "`ue2'"

use    		 "`ue1'"
append using "`ue2'"
sort pidp wave

replace jobloss = 99 if jobloss == .

gen source = "UKHLS"
replace wave = wave + 18

preserve
use pidp sex sex_dv  using "${REPL_RAW}/UKDA-6931-stata/stata/stata13_se/ukhls/xwavedat_protect", clear
merge 1:1 pidp using       "${REPL_RAW}/UKDA-6614-stata-2/stata/stata11_se/ukhls_wx/xwavedat"   , keepusing(sex sex_dv) nogen

replace sex 	= sex_dv if sex == .    | sex < 0
replace sex_dv  = sex    if sex_dv == . | sex_dv < 0

* Gendered identifiers
clonevar pidp_m = pidp
clonevar pidp_f = pidp
replace  pidp_m = . if sex_dv == 2
replace  pidp_f = . if sex_dv == 1

tempfile gender
save    `gender'

restore
merge m:1 pidp using `gender', keep(1 3) nogen

gen ever_ue = 1
lab var ever_ue "Ever experienced unemployment"
lab def ever_ue 1 "Any job loss" 0 "No job loss", modify
lab val ever_ue ever_ue

clonevar unemployed_date6 = unemployed_date97
replace  unemployed_date6 = unemployed_date   if jobloss == 99
save "$data/UKHLS_unemployment_long",replace
 use "$data/UKHLS_unemployment_long", clear

drop unemployed_dat*3 unemployed_dat*4 unemployed_dat*5 unemployed_dat*97 unemployed_dat*6
rename unemployed_date date

clonevar jl = jobloss
replace  jl = 6 if jobloss == 97 | jobloss == 99

sort pidp wave
by   pidp wave     : gen n = _n
su n, meanonly
local nmax = r(max)

reshape wide  month year jobloss jl date, i(pidp wave) j(n)

foreach i in 3 4 5 97 99 {
gen     ever_ue`i' = .
	forvalues x = 1/`nmax' {
replace ever_ue`i' = 1  if jobloss`x' == `i'
lab var ever_ue`i' "Ever experienced ue `i'"
 }
replace  ever_ue`i' = 0  if ever_ue`i' == .
 }

foreach i in 6 {
gen     ever_ue`i' = .
	forvalues x = 1/`nmax' {
replace ever_ue`i' = 1  if jl`x' == `i'
lab var ever_ue`i' "Ever experienced ue `i'"
 }
replace  ever_ue`i' = 0  if ever_ue`i' == .
 }
lab var  ever_ue6 "Ever experienced ue 6"

save "$data/UKHLS_unemployment_wide",replace
use  "$data/UKHLS_unemployment_wide", clear
