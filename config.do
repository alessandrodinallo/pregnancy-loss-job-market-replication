* config.do -- folder settings of the replication package
*
* Start Stata in the folder that contains this file (or `cd` to it) and run every do-file
* from here, for example:  do code/fig_v15E_AGE46_Figure1_earnings.do
* Each do-file loads this file on its first line.
*
* The only line to edit is REPL_RAW. Use folder names without spaces.

global REPL_ROOT   "`c(pwd)'"

* Folder that holds the UK Data Service study folders, as downloaded
* (UKDA-6614-stata, UKDA-6614-stata-2, UKDA-6931-stata, UKDA-5629-stata8).
* Needed only to rebuild the analysis dataset; see docs/data_access.md.
global REPL_RAW    "CHANGE_ME"

global REPL_CODE   "${REPL_ROOT}/code"
global REPL_DATA   "${REPL_ROOT}/data"        // derived individual-level data: never shared
global REPL_EST    "${REPL_ROOT}/estimates"   // aggregate estimates: included
global REPL_FIG    "${REPL_ROOT}/figures"     // figures written by the fig_* do-files

* Folders named by settings that the original do-files define but never use.
global REPL_OTHER  "${REPL_ROOT}/unused"
global REPL_UNUSED "${REPL_ROOT}/unused"

capture confirm file "${REPL_ROOT}/config.do"
if _rc {
    display as error "config.do not found in the current folder: start Stata in the package folder."
    exit 601
}
