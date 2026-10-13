*==============================================================================================
* BHPS_UKHLS_background_v6.do
*
* Covariates by person and wave: region, education, income, health, job characteristics,
* identifier of the partner.
*
* Reads:   individual files of each wave and the cross-wave file (survey data needed)
* Writes:  data/Wage/BHPS_UKHLS_covariates.dta
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
 global protect_bhps  ${REPL_RAW}/UKDA-6931-stata/stata/stata13_se/bhps
 global protect_ukhls ${REPL_RAW}/UKDA-6931-stata/stata/stata13_se/ukhls

 global do			${REPL_CODE}
 global data      	${REPL_DATA}/Wage
 global results   	${REPL_OTHER}

{

foreach w in a b c d e f g h i j k l m n o p q r {

local wave = strpos("abcdefghijklmnopqr","`w'")

use pidp  *gor* *scghq* *mastat* *jbstat* *jbnssec* *jbseg* *jbsize* *jbbg* *hiqua* *fimn* *fimngrs* *hlprbh* *hlprbf* *hlprbe* *isced* using  "$protect_bhps/b`w'_indresp_protect.dta", clear

rename b`w'_* *
rename *_dv *

clonevar fimnnet = fimngrs
replace hiqualb = hiqual if hiqual < 0 | hiqual == .
drop    hiqual fimngrs
rename  hiqualb hiqual
gen health_breathing = hlprbe == 1
gen health_diabetes  = hlprbh == 1
gen health_heart	 = hlprbf == 1
drop hl*
gen wave = `wave'

order pidp wave
tempfile   temp`wave'
save     "`temp`wave''"
}
}

use 		 "`temp1'", clear
forvalues w = 2/18{
append using "`temp`w''"
}
sort pidp wave

tempfile bhps
save   "`bhps'", replace

{

foreach w in f g h i j   l m n o p q r {

local wave = strpos("abcdefghijklmnopqr","`w'")

use pidp *lfsat*  using  "$protect_bhps/b`w'_indresp_protect.dta", clear

rename b`w'_* *

gen wave = `wave'
clonevar sclfsato = lfsato
order pidp wave
tempfile   temp`wave'
save     "`temp`wave''"
}
}
use 		 "`temp6'", clear
forvalues w = 7/10{
append using "`temp`w''"
}
forvalues w = 12/18{
append using "`temp`w''"
}
sort pidp wave
tempfile bhps2
save   "`bhps2'", replace

foreach x in a b c d e f g h i j k l m n o {
use pidp *ppid *marstat using "$path1/`x'_indresp", clear

rename `x'_* *

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
replace ppid = sppid if ppid < 0 & sppid > 0
clonevar partner = ppid
keep pidp marstat ppid partner wave

replace wave = wave + 18

tempfile ukhls_partner
save 	`ukhls_partner', replace

foreach x in a b c d e f g h i j k l m n o {
if "`x'" == "o" local src "$path1/`x'_indresp"
else            local src "$protect_ukhls/`x'_indresp_protect"
use pidp *ppid *basr* *basns* *extrate* *ovt* *paytyp* *jbot* *scghq* *sclfsato* *sclfsat7* *marstat *cjob* *employ* *jbseg* *jbsemp* *jbsize* *jssize* *jbnssec* *jbstat* *jbft* *jbhrs *jshrs* *jbbg? *jbmngr* *jbsect* *jbsectpub* *jbotpd* *jbhas* *jboff* *jboffy* *dat* *hiqua* *fimn* *fimngrs* *gor* *hcond* *sf12mcs* *sf12pcs* *isco* *soc* *sic* *ovtrate* *basrate*  using "`src'", clear

rename `x'_* *
rename *_dv *

if "`x'" == "o" {
 foreach s in jbsoc00 jbsoc10 jlsoc00 jlsoc10 {
  capture confirm variable `s', exact
  if _rc {
   capture confirm variable `s'_cc, exact
   if !_rc rename `s'_cc `s'
  }
 }
}

  gen wave = strpos("abcdefghijklmno","`x'")
local wave = wave

tempfile egoalt`wave'
save   "`egoalt`wave''", replace
}

use "`egoalt1'", clear
forvalues w = 2/15{
append using "`egoalt`w''"
}

gen health_breathing = hcond1  == 1 | hcondn1  == 1 | hcond8 == 1 | hcondn8 == 1 | hcond11 == 1 | hcondn11 == 1
gen health_diabetes  = hcond14 == 1 | hcondn14 == 1
gen health_heart	 = hcond3  == 1 | hcondn3  == 1 | hcond4 == 1 | hcondn4 == 1 | hcond5 == 1 | hcondn5 == 1  | hcond6 == 1 | hcondn6 == 1  | hcond7 == 1 | hcondn7 == 1
drop hcond*

sort  pidp wave

* job status
recode jbstat (-9/-1 9/97= 0)

* workplace size
replace jbsize = jssize if jssize > 0 & jssize < . & jbsize < 0
replace jbhrs  = jshrs  if jshrs  > 0 & jshrs  < . & jbhrs  < 0
foreach z in 0 1 {
foreach x in l b {
tostring j`x'soc`z'0, gen(j`x'soc`z'0_string)
generate j`x'soc`z'0_4dig_string = substr(j`x'soc`z'0_string, 1, 2)
destring j`x'soc`z'0_4dig_string ,    gen(j`x'soc`z'0_2dig)
drop *string
}
}

* Geolocalization
sort pidp wave, stable
by   pidp : replace gor = gor[_n-1] if gor < 0
set seed 1234
replace  gor = round(runiform(1,10),1) if gor == .

replace wave = wave + 18
tempfile    ukhls
save      "`ukhls'", replace

foreach x in a   c   e   g   i   k   m   o  {
if "`x'" == "o" local src "$path1/`x'_indresp"
else            local src "$protect_ukhls/`x'_indresp_protect"
use pidp  *screl* using "`src'", clear

rename `x'_* *

  gen wave = strpos("abcdefghijklmno","`x'")
local wave = wave

tempfile egoalt`wave'
save   "`egoalt`wave''", replace
}

use "`egoalt1'", clear
forvalues w = 3(2)15{
append using "`egoalt`w''"
}
replace wave = wave + 18

tempfile ukhls2
save    `ukhls2', replace

merge 1:1 pidp wave using `ukhls'
tab _merge
drop _merge
merge 1:1 pidp wave using `ukhls_partner'
tab _merge
drop _merge

append using "`bhps'"
merge 1:1 pidp wave using "`bhps2'"
tab _merge
drop _merge

sort  pidp wave

drop fimnpi-fimnsel
drop ff* fimnb fimni fimninvnet fimnmisc fimnnl fimnp fimnpen fimnprben fimnsben fimnt
drop *chk jssize jshrs *_tc *_if
drop j1* j2*  maj* paj* ops* soccont socialkid socweb streammusic ypsocweb yas* *asoc* jl*88* jl*07*  jl*90* jbsic*
drop istr* ien* scdata

replace sclfsato =  lfsato if  sclfsato == .

* job status
recode jbstat (-9/-1 9/97= 0)

replace jbnssec5 = 1 if jbnssec >= 1  & jbnssec <= 12 & jbnssec5 == .
replace jbnssec5 = 2 if jbnssec >= 13 & jbnssec <= 16 & jbnssec5 == .
replace jbnssec5 = 3 if jbnssec >= 17 & jbnssec <= 20 & jbnssec5 == .
replace jbnssec5 = 4 if jbnssec >= 21 & jbnssec <= 23 & jbnssec5 == .
replace jbnssec5 = 5 if jbnssec >= 24 & jbnssec <= 35 & jbnssec5 == .

replace jbnssec3 = 1 if jbnssec >= 1  & jbnssec <= 12 & jbnssec3 == .
replace jbnssec3 = 2 if jbnssec >= 13 & jbnssec <= 20 & jbnssec3 == .
replace jbnssec3 = 3 if jbnssec >= 21 & jbnssec <= 35 & jbnssec3 == .

sort pidp wave
by   pidp : egen min_wave = min(wave)

gen 	 own_wave_ = wave - min_wave + 1
gen 	 own_wave = own_wave_ if own_wave_ == 1
replace  own_wave = own_wave_ if own_wave_ == 2
replace  own_wave = own_wave_ if own_wave_ == 3
replace  own_wave = 4		  if own_wave_ >= 4
lab def  own_wave 1 "1st wave" 2 "2nd wave" 3 "3rd wave" 4 "4th/higher wave"
lab val  own_wave own_wave
drop min_wave own_*_

* Filling the gaps between waves
foreach x in screlhappy screlparar screlparcd screlpards screlparei screlparir screlparks screlparrg screlparwt lfsat4 lfsato {
	replace `x' = . if `x' < 0
 }

keep pidp ppid partner wave fimn* jbstat jb* cj* employ gor hiqual scghq1 scghq2 own_wave  ovtrate basrate sf12* lfsat4 lfsato marstat
tempfile covariates
save    `covariates'

* PERSONAL BACKGROUND

 use pidp dob*_dv birth* sex sex_dv eth* lvag16 lvag14  ynlp14 race* scend_dv feend_dv using "$path2/xwavedat_protect.dta", clear

* Date of birth
replace sex 	= sex_dv if sex == .    | sex < 0
replace sex_dv  = sex    if sex_dv == . | sex_dv < 0

* Date of birth
gen     dob = ym(doby_dv,dobm_dv)
replace dob = ym(doby_dv,birthm)  if dob == .
replace dob = ym(birthy ,dobm_dv) if dob == .
replace dob = ym(birthy ,birthm)  if dob == .
replace dob = ym(doby_dv,6)       if dob == .
format  dob %tm
drop dobm_dv birthm
replace doby_dv = birthy if doby_dv == . |  doby_dv < 1800
drop if doby_dv < 0
drop if doby_dv > 3000

egen    cohort=cut(doby_dv), at(1895(5)2025)
lab var cohort "Cohort (cat.)"

* Own ethnicity
recode  racel_dv (-20/-1 = 0) (1/2=1) (4=2) (5/8=3) (9=4) (10=5) (11=6) (12/13=7) (14/16=8) (3 17 97 = 9),gen(ethnicity)
lab def ethnicity 0 "No information" 1 "British/Irish" 2 "European/Other White" 3 "Mixed: White & Other" 4 "Indian" 5 "Pakistani" 6 "Bangladeshi" 7 "Other Asian/Asian British" 8 "Black/African/Caribbean/Black British" 9 "Other" , modify
lab val ethnicity ethnicity
lab var ethnicity  "Ethnicity"

* Family composition

clonevar family16_v1 = lvag16
recode   family16_v1 (-20/-1 . = 1)
replace  family16_v1 = 2 if lvag14 > 2 & lvag14 !=. & family16_v1 == 1
lab var  family16_v1 "Family status at 16"

clonevar family16_v3 = family16_v1
replace  family16_v3 = 3 if ynlp14 == 2   // One of parents died
replace  family16_v3 = 3 if ynlp14 ==97   // Other (adopted)
lab def  family16_v3 1 "Intact" 2 "Non intact" 3 "One or both parents died/Other"
lab val  family16_v3 family16_v3
lab var  family16_v3 "Family status at 16"

keep pidp sex sex_dv famil* dob doby_dv cohort ethnicity

tempfile background
save    `background' , replace

use `covariates', clear
merge m:1 pidp 		using `background'
tab _merge
drop _merge

* Gendered identifiers
clonevar pidp_m = pidp
clonevar pidp_f = pidp
replace  pidp_m = . if sex_dv == 2
replace  pidp_f = . if sex_dv == 1

* Variables selection
keep pidp wave sex sex_dv *

* Number of women working in the same field
preserve
keep if sex == 2
keep pidp wave	jbsoc00_2dig
	  sort wave jbsoc00_2dig
	  sort wave
	  by   wave : gen wave_N = _N
	  sort wave jbsoc00_2dig
	  by   wave jbsoc00_2dig : gen soc00_N = _N
	  gen soc00_N_wave = soc00_N / wave_N
drop pidp
bysort wave jbsoc00_2dig: keep if _n == 1
  keep wave soc00_N_wave jbsoc00_2dig
  tempfile soc00
  save    `soc00', replace
  restore

merge m:1 wave jbsoc00_2dig using `soc00', keep(1 3)
tab _merge
drop _merge

* Dropping duplicates
duplicates tag  pidp wave  , gen(duplicates)
bysort          pidp wave    : gen N = _n
drop if N > 1 & duplicates > 0
drop duplicates N

tempfile vars
save    `vars', replace
save "$data/BHPS_UKHLS_covariates", replace
