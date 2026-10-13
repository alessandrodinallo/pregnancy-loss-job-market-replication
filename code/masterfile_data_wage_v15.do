*==============================================================================================
* masterfile_data_wage_v15.do
*
* Runs the data construction, step by step, and writes the analysis dataset.
* With RUN = 0 it only lists the steps; set RUN = 1 to execute them.
*
* Reads:   the do-files of the construction, in code/
* Writes:  data/Wage/data_wage_v15.dta
*
* Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
* and pregnancy losses. Social Science Research, 141, 103450.
*==============================================================================================

quietly do "config.do"   // folder settings: start Stata in the package folder

clear all
set more off

local RUN = 0

global do      ${REPL_CODE}
global rootdo  ${REPL_CODE}

if `RUN' do "code/Interview_v6.do"
else     di as txt "[dry] 1a  Interview_v6            -> interview_{,_wide,_long}.dta"

if `RUN' do "code/bio_child_v6.do"
else     di as txt "[dry] 1b  bio_child_v6           -> bio.dta"

if `RUN' do "code/pregnancies_v6.do"
else     di as txt "[dry] 1c  pregnancies_v6         -> x8.dta            [needs 1a,1b]"

if `RUN' do "code/BHPS_UKHLS_background_v6.do"
else     di as txt "[dry] 1d  BHPS_UKHLS_background_v6 -> BHPS_UKHLS_covariates.dta"

if `RUN' do "code/ukhls_job_v3.do"
else     di as txt "[dry] 1e  ukhls_job_v3           -> UKHLS_unemployment_wide.dta"

if `RUN' do "code/BHPS_UKHLS_children_v2.do"
else     di as txt "[dry] 1f  BHPS_UKHLS_children_v2 -> BHPS_UKHLS_children_new.dta"

if `RUN' do "code/harmonization economic data women UK_v3.do"
else     di as txt "[dry] 1h  harmonization econ. women UK_v3 -> inflation_UK.dta + employment_women_UK.dta (root Data)"

if `RUN' do "code/harmonization_uk_ue_v2.do"
else     di as txt "[dry] 1i  harmonization_uk_ue_v2 -> uk_ue_women.dta"

if `RUN' do "code/final_v15.do"
else     di as txt "[dry] 2   final_v15 (trimmed DVs + age_event/elig_ageev; SOC_ISEI_v2 inline) -> data_wage_v15.dta"

di as result _n "masterfile_data_wage_v15: " cond(`RUN', "REBUILD COMPLETE.", "dry run (RUN=0): no files written. Set local RUN = 1 to rebuild.")
