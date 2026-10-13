*==============================================================================================
* BHPS_UKHLS_children_v2.do
*
* Children by person and wave: number of children and their dates of birth, from the BHPS
* fertility histories and from the Understanding Society household files.
*
* Reads:   household-member, relationship and natural-children files, BHPS family histories
*          (survey data needed)
* Writes:  data/Wage/BHPS_UKHLS_children_new.dta
*
* Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
* and pregnancy losses. Social Science Research, 141, 103450.
*==============================================================================================

quietly do "config.do"   // folder settings: start Stata in the package folder

 global path1 ${REPL_RAW}/UKDA-6614-stata/stata/stata13_se/ukhls
 global path2 ${REPL_RAW}/UKDA-6931-stata/stata/stata13_se/ukhls

 global path6 ${REPL_RAW}/UKDA-5629-stata8/stata8

 global rawdata  	${REPL_RAW}/BHPS_UKHLS
 global path  	 	${REPL_RAW}/UKDA-6614-stata-2/stata/stata11_se
 global union       ${REPL_RAW}/UKDA-8473-stata/stata/stata13

 global do			${REPL_CODE}
 global data      	${REPL_DATA}/Wage
 global results   	${REPL_OTHER}

set seed 998

foreach x in a b c d e f g h i j k l m n o p q r {

local 	wave = strpos("abcdefghijklmnopqr","`x'")

use pid *hid *hidp *istrtdat* using "${REPL_RAW}/UKDA-6614-stata-2/stata/stata11_se/bhps_w`wave'/b`x'_indresp.dta", clear

rename b`x'_* *

  gen 	wave = strpos("abcdefghijklmnopqr","`x'")
lab var wave "Wave"

tempfile indresp`wave'
save   "`indresp`wave''", replace

}

use "`indresp1'", clear
forvalues w = 2/18{
append using "`indresp`w''"
}
replace istrtdaty = 1991 if wave == 1
capture replace istrtdaty = . if istrtdaty < 0
capture replace istrtdatm = . if istrtdatm < 0
gen 	date_interview = ym(istrtdaty, istrtdatm)
format  date_interview %tm
sort pid wave
keep pid wave date_interview

tempfile  interview
save    "`interview'"

foreach x in a b c d e f g h i j k l m n o p q r {

local 	wave = strpos("abcdefghijklmnopqr","`x'")

use pidp pid *hid *hidp using "${REPL_RAW}/UKDA-6614-stata-2/stata/stata11_se/bhps_w`wave'/b`x'_indall.dta", clear
rename b`x'_* *

  gen 	wave = strpos("abcdefghijklmnopqr","`x'")
lab var wave "Wave"

tempfile indall`wave'
save   "`indall`wave''", replace

}
use "`indall1'", clear
forvalues w = 2/18{
append using "`indall`w''"
}

merge 1:1 pid wave using  "`interview'"
sort wave
by   wave : replace date_interview = date_interview[_n-1] if date_interview == .

keep pidp wave date_interview
sort pidp wave
tempfile  BHPS_hh
save    "`BHPS_hh'"

* BHPS

use "$path6/family.dta", clear

keep pp  childbirth* twin*
rename pp pid

forvalues i = 1/16 {
	local j = `i' + 20
replace childbirth`i' = . if childbirth`i' < 0
replace childbirth`i' = childbirth`i' - 721
format  childbirth`i' %tm
    rename  childbirth`i' dob`i'
}
tempfile BHPS_children
save   "`BHPS_children'", replace

foreach x in a b c d e f g h i j k l m n o p q r {

local 	wave = strpos("abcdefghijklmnopqr","`x'")

use "${REPL_RAW}/UKDA-6614-stata-2/stata/stata11_se/bhps_w`wave'/b`x'_indall.dta", clear

local name ///
sppid_bh hid hidp   // Cross-wave person identifier of spouse
foreach n of local name {
rename b`x'_`n' `n'
}

keep pidp pid
  gen 	wave = strpos("abcdefghijklmnopqr","`x'")
lab var wave "Wave"

tempfile indall`wave'
save   "`indall`wave''", replace

}

use "`indall1'", clear
forvalues w = 2/18{
append using "`indall`w''"
}
bysort pidp: keep if  _n == 1
drop wave

merge 1:1 pid using "`BHPS_children'", nogen
drop pid twin*
sort pidp

tempfile BHPS_children
save   "`BHPS_children'", replace

merge 1:m pidp using "`BHPS_hh'", nogen
sort pidp wave

forvalues i = 1/16 {
gen      birth`i' = dob`i' <= date_interview & date_interview < .
}

egen    N_child = rowtotal(birth*)
gen     N_child_cat = 0 if N_child == 0
replace N_child_cat = 1 if N_child == 1
replace N_child_cat = 2 if N_child >= 2
lab def N_child_cat 0 "No children" 1 "1 child" 2 "2+ children"
lab val N_child_cat N_child_cat
gen     any_child = N_child > 0
lab var any_child "Any children"

order pidp N_child any_child wave date_interview

drop birth*

preserve
use pidp sex sex_dv  using "${REPL_RAW}/UKDA-6931-stata/stata/stata13_se/ukhls/xwavedat_protect", clear
merge 1:1 pidp using  "${REPL_RAW}/UKDA-6614-stata-2/stata/stata11_se/ukhls_wx/xwavedat"   , keepusing(sex sex_dv) nogen

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

foreach g in m f {
	clonevar N_child_`g'    = N_child	  if pidp_`g' !=.
	clonevar N_child_cat_`g'= N_child_cat if pidp_`g' !=.
	clonevar any_child_`g'  = any_child   if pidp_`g' !=.
}

* Dates of births
preserve

keep pidp dob*
drop if dob1 == .
bysort pidp : keep if _n == 1
reshape long dob , i(pidp) j(n)
drop if dob == .
gen source = "BHPS"

tempfile dobs_BHPS
save    `dobs_BHPS'

restore

keep pidp_? pidp N_child* any_chil* wave *_? date_intervie*

tempfile BHPS_children
save    `BHPS_children'

foreach x in a b c d e f g h i j k l m n o {
if "`x'"=="o" use *hidp *hrpid pidp using "$path1/o_indall.dta", clear
else          use *hidp *hrpid pidp using "$path2/`x'_indall_protect", clear

rename `x'_* *

  gen 	wave = strpos("abcdefghijklmno","`x'")
lab var wave "Wave"
local   wave = wave

tempfile indall`wave'
save   "`indall`wave''", replace
}
use "`indall1'", clear
forvalues w = 2/15{
append using "`indall`w''"
}
tempfile indall
save   "`indall'", replace

foreach x in a b c d e f g h i j k l m n o {
if "`x'"=="o" use *hidp *hrpid  *intdat* using "$path1/o_hhresp.dta", clear
else          use *hidp *hrpid  *intdat* using "$path2/`x'_hhresp_protect", clear

rename `x'_* *

  gen 	wave = strpos("abcdefghijklmno","`x'")
lab var wave "Wave"
local   wave = wave
capture replace intdatey = . if intdatey < 0
capture replace intdatem = . if intdatem < 0
gen     date_interview = ym(intdatey,intdatem)
lab var date_interview "Date interview"
format  date_interview %tm
tempfile indall`wave'
save   "`indall`wave''", replace
}

use "`indall1'", clear
forvalues w = 2/15{
append using "`indall`w''"
}

tempfile hhresp
save   "`hhresp'", replace

merge m:m  hrpid wave using "`indall'"
sort  pidp wave
order pidp wave

replace wave = wave
bysort hrpid : replace date_interview = date_interview[_n-1] if date_interview == .

drop _merge intdatey intdatem intdated hidp hrpid
sort  pidp wave

tempfile  UKHLS_hh
save    "`UKHLS_hh'"
sort pidp wave

reshape wide date_interview, i(pidp) j(wave)

forvalues i = 1/15{
sort pidp
replace date_interview`i' = date_interview`i'[_n-1] if date_interview`i' == .
replace date_interview`i' = date_interview`i'[_n+1] if date_interview`i' == .
}

reshape long date_interview, i(pidp) j(wave)

drop if date_interview == .
tempfile interview
save   "`interview'"

* Identifiers of pidp and children (egoalt)
foreach x in a b c d e f g h i j k l m n o {
if "`x'"=="o" use "$path1/o_egoalt.dta", clear
else          use "$path2/`x'_egoalt_protect", clear

local var hidp  pno apno relationship
foreach v of local var {
rename `x'_`v' `v'
}
keep pidp `var' apidp
  gen wave = strpos("abcdefghijklmno","`x'")
local wave = wave

keep if relationship == 9

tempfile egoalt`wave'
save   "`egoalt`wave''", replace
}

use "`egoalt1'", clear
forvalues w = 2/15{
append using "`egoalt`w''"
}

sort pidp wave
by   pidp: egen wave_child_min = min(wave)
by   pidp: egen wave_child_max = max(wave)

sort  pidp wave
order pidp wave
sort  pidp apidp wave
by    pidp apidp: keep if _n ==1

drop hidp pno apno  wave relationship

tempfile  	   pidp_child
save    	 "`pidp_child'"

* Presence of pidp in the waves
foreach x in a b c d e f g h i j k l m n o {
if "`x'"=="o" use "$path1/o_egoalt.dta", clear
else          use "$path2/`x'_egoalt_protect", clear

keep pidp
  gen wave = strpos("abcdefghijklmno","`x'")
local wave = wave

tempfile egoalt`wave'
save   "`egoalt`wave''", replace
}

use "`egoalt1'", clear
forvalues w = 2/15{
append using "`egoalt`w''"
}

sort pidp wave
by   pidp: egen wave_pidp_min = min(wave)
by   pidp: egen wave_pidp_max = max(wave)

order pidp wave
by    pidp : keep if _n ==1

drop wave

tempfile  	   pidp_waves
save    	 "`pidp_waves'"

* Identifiers of partner and children (egoalt)
foreach x in a b c d e f g h i j k l m n o {
if "`x'"=="o" use "$path1/o_egoalt.dta", clear
else          use "$path2/`x'_egoalt_protect", clear

local var hidp  pno apno relationship
foreach v of local var {
rename `x'_`v' `v'
}
keep pidp `var' apidp
  gen wave = strpos("abcdefghijklmno","`x'")
local wave = wave

keep if relationship == 9

tempfile egoalt`wave'
save   "`egoalt`wave''", replace
}

use "`egoalt1'", clear
forvalues w = 2/15{
append using "`egoalt`w''"
}

sort pidp wave
by  pidp: egen wave_partner_min = min(wave)
by  pidp: egen wave_partner_max = max(wave)

sort  pidp wave
order pidp wave
sort  pidp apidp wave
by    pidp apidp: keep if _n ==1
rename pidp partner

drop hidp pno apno  wave relationship

tempfile  	   partner_child
save    	 "`partner_child'"

* Identifiers of pidp and partner (egoalt)

foreach x in a b c d e f g h i j k l m n o {
if "`x'"=="o" use "$path1/o_egoalt.dta", clear
else          use "$path2/`x'_egoalt_protect", clear

local var hidp  pno apno relationship
foreach v of local var {
rename `x'_`v' `v'
}
keep pidp `var' apidp
  gen wave = strpos("abcdefghijklmno","`x'")
local wave = wave

keep if relationship == 2

tempfile egoalt`wave'
save   "`egoalt`wave''", replace
}

use "`egoalt1'", clear
forvalues w = 2/15{
append using "`egoalt`w''"
}

sort pidp wave

sort  pidp wave
order pidp wave
sort  pidp apidp wave
by    pidp apidp: keep if _n ==1
rename apidp partner

drop hidp pno apno  wave relationship

replace  partner = . if partner < 0

gen double pidp2 = pidp^2/1000
gen double ppid2 = partner^2/1000
format pidp2 %17.0g
format ppid2 %17.0g
egen double coupleid = rowtotal(pidp2 ppid2)
format  coupleid %17.0g
replace coupleid = . if pidp == . | partner == .

sort pidp
tempfile  	   pidp_partner
save    	 "`pidp_partner'"

* Pidp - child
use 				 "`pidp_child'", clear
merge m:m pidp using "`pidp_partner'", nogen
tempfile s1
save   "`s1'"

* Partner - child
use 					"`partner_child'", clear
merge m:m partner using "`pidp_partner'", nogen
tempfile s2
save   "`s2'"

use 		 "`s1'",
append using "`s2'"
merge m:1 pidp using "`pidp_waves'"

keep if apidp != . & pidp !=.
keep pidp apidp partner coupleid wave_*
sort  apidp coupleid
order apidp pidp partner coupleid

* Dropping duplicates
duplicates tag  pidp apidp partner, gen(duplicates)
bysort          pidp apidp partner  : gen N = _n
drop if N > 1 & duplicates > 0
drop duplicates N

sort pidp

tempfile child_parent_couple
save   "`child_parent_couple'", replace

* Dates of birth of coresident children (indall)
foreach x in a b c d e f g h i j k l m n o {
if "`x'"=="o" use "$path1/o_indall.dta", clear
else          use "$path2/`x'_indall_protect", clear

local name hidp pno birthy birthm doby_dv dobm_dv *dvage

foreach n of local name {
capture rename `x'_`n' `n'
}
capture confirm variable dobm_dv, exact
if _rc gen dobm_dv = .
capture confirm variable birthm, exact
if _rc gen birthm = .
keep pidp `name'

  gen wave = strpos("abcdefghijklmno","`x'")
local wave = wave

tempfile indall`wave'
save   "`indall`wave''", replace
}

use "`indall1'", clear
forvalues w = 2/15{
append using "`indall`w''"
}
sort pidp wave
rename    pidp apidp
rename    pno  apno
sort apidp wave
by   apidp: keep if _n ==1

tempfile 	 indall
save  	   "`indall'"

use "`child_parent_couple'", clear
merge m:1 apidp         using  "`indall'", keep(3) nogen   // only parent-children dyads

sort  pidp wave apidp
order pidp apidp

capture replace doby_dv = . if doby_dv < 0
capture replace dobm_dv = . if dobm_dv < 0
capture replace birthy  = . if birthy  < 0
capture replace birthm  = . if birthm  < 0
gen byte _impm = 1 + mod(abs(int(apidp)), 12)
gen 	dob   = ym(doby_dv, dobm_dv)
replace dob   = ym(doby_dv, birthm)					 if dob == .
replace dob   = ym(doby_dv, _impm)                   if dob == .
replace dob   = ym(birthy , dobm_dv)				 if dob == .
replace dob   = ym(birthy , _impm)                   if dob == .
drop _impm
 format dob %tm

	preserve
bysort apidp : keep if _n == 1
	count
	restore

keep   pidp partner apidp coupleid dob wave*
drop wave

gen source = "panel"

tempfile parent_children
save   "`parent_children'"	, replace

foreach x in a f {
use "$path2/`x'_natchild_protect", clear

local var hidp pno   ///
lchlv    ///
lchyd4   ///
lchdoby  ///
lchdobm ///
lchal

foreach v of local var {
	rename `x'_`v' `v'
}
keep pidp `var'

  gen wave = strpos("abcdefghijklmno","`x'")
local wave = wave
tempfile child`wave'
save   "`child`wave''", replace
}

use "`child1'", clear
append using "`child6'"
sort pidp wave
keep if lchlv != 1
rename  lchlv  coresident

* Date of birth
capture replace lchdoby = . if lchdoby < 0
capture replace lchdobm = . if lchdobm < 0
capture replace lchal   = . if lchal   < 0
gen byte _impm = 1 + mod(abs(int(pidp)), 12)
generate dob = ym(lchdoby, lchdobm)
replace  dob = ym(lchdoby , _impm)                 if dob == .
drop if coresident == 4
format   dob %tm
order pidp  dob   // childbirth

gen      dol = dob + lchal*12 + _impm
drop _impm
format   dol %tm

gen source = "retrospective"

keep pidp dob dol coresident source

tempfile nat_child
save   "`nat_child'"

use          "`parent_children'", clear
append using "`nat_child'"

sort pidp

lab val coresident a_lchlv

replace coresident = 1 if coresident == .

tempfile    bio
save      "`bio'"

* Final imputations

bysort apidp : replace source = "imputation" if dob == . & dob[_n-1] !=. &  apidp == apidp[_n-1]
bysort apidp : replace source = "imputation" if dob == . & dob[_n+1] !=. &  apidp == apidp[_n+1]

foreach x in dob partner coupleid {
bysort apidp : replace `x' = `x'[_n-1] if `x' ==. & apidp == apidp[_n-1] & `x'[_n-1] !=.
bysort apidp : replace `x' = `x'[_n+1] if `x' ==. & apidp == apidp[_n+1] & `x'[_n+1] !=.
}

keep pidp  dob
sort pidp dob
by   pidp : gen n = _n
reshape wide dob , i(pidp) j(n)

tempfile UKHLS_children
save   "`UKHLS_children'"

merge 1:m pidp using "`interview'", nogen
sort pidp wave

quietly ds dob*
local K : word count `r(varlist)'
forvalues i = 1/`K' {
gen      birth`i' = dob`i' <= date_interview & date_interview < .
}

egen    N_child = rowtotal(birth*)
gen     N_child_cat = 0 if N_child == 0
replace N_child_cat = 1 if N_child == 1
replace N_child_cat = 2 if N_child >= 2
lab def N_child_cat 0 "No children" 1 "1 child" 2 "2+ children"
lab val N_child_cat N_child_cat
gen     any_child = N_child > 0
lab var any_child "Any children"

order pidp N_child any_child wave date_interview

drop birth*
replace wave = wave + 18

preserve
use pidp sex sex_dv  using "${REPL_RAW}/UKDA-6931-stata/stata/stata13_se/ukhls/xwavedat_protect", clear
merge 1:1 pidp 		 using "${REPL_RAW}/UKDA-6614-stata-2/stata/stata11_se/ukhls_wx/xwavedat"   , keepusing(sex sex_dv) nogen

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

foreach g in m f {
	clonevar N_child_`g'    = N_child	  if pidp_`g' !=.
	clonevar N_child_cat_`g'= N_child_cat if pidp_`g' !=.
	clonevar any_child_`g'  = any_child   if pidp_`g' !=.
}

* Dates of births
preserve

keep pidp dob*

drop if dob1 == .
bysort pidp : keep if _n == 1
reshape long dob , i(pidp) j(n)
drop if dob == .
gen source = "UKHLS"
tempfile dobs_UKHLS
save    `dobs_UKHLS'

restore

 keep pidp_? pidp N_child* any_chil* wave *_? sex_dv date_intervie*

tempfile UKHLS_children
save    `UKHLS_children'

use `dobs_UKHLS', clear
merge m:m pidp dob using `dobs_BHPS', nogen
drop n
sort pidp dob
by   pidp : gen n = _n
reshape wide dob source, i(pidp) j(n)
tempfile children
save    `children'

use 					 `UKHLS_children', clear
merge 1:1 pidp wave using `BHPS_children', nogen
merge m:1 pidp 		using      `children', nogen

quietly ds dob*
local K : word count `r(varlist)'
forvalues i = 1/`K' {
	gen doc`i' = dob`i'- 9
format  doc`i' %tm
}
sort pidp wave
drop if pidp == .

* Date of conception for both partners
forvalues i = 1/`K' {
	foreach g in b c {
clonevar do`g'`i'_m = do`g'`i' if pidp_m == pidp
clonevar do`g'`i'_f = do`g'`i' if pidp_f == pidp
}
}
order pidp pidp_?  doc1_? dob1_? doc2_? dob2_? *_? doc1 doc2 doc3
order pidp wave

* Variables' selection
keep pidp pidp_? wave dob* doc* source* date_*
drop do*_?

quietly ds dob*
local K : word count `r(varlist)'
forvalues i = 1/`K' {
gen      birth`i' = dob`i' <= date_interview & date_interview < .
}

egen    N_child = rowtotal(birth*)
gen     N_child_cat = 0 if N_child == 0
replace N_child_cat = 1 if N_child == 1
replace N_child_cat = 2 if N_child >= 2
 lab val N_child_cat N_child_cat
gen     any_child = N_child > 0
lab var any_child "Any children"
drop birth*

save "$data/BHPS_UKHLS_children_new", replace
