# Data access

The article uses *Understanding Society*, the UK Household Longitudinal Study, with the harmonised British Household Panel Survey. The data are distributed by the UK Data Service (https://ukdataservice.ac.uk). They cannot be redistributed, and this package contains none: no original file, no intermediate file and no analysis dataset.

## Studies

| Study number | Title | Access | Used for |
|---|---|---|---|
| SN 6614 | Understanding Society: Waves 1-15, 2009-2024 and Harmonised BHPS: Waves 1-18, 1991-2009 | End User Licence | outcomes, covariates, interviews, household composition |
| SN 6931 | Understanding Society and Harmonised BHPS: Special Licence Access | Special Licence | month of birth of respondents and children; the pregnancy history files as read by the code |
| SN 5629 | British Household Panel Survey Consolidated Marital, Cohabitation and Fertility Histories, 1991-2009 | End User Licence | fertility histories of the BHPS sample |

The Special Licence version is required. The timing of each pregnancy and the age of each child rest on month-level dates that the End User Licence files do not carry. A Special Licence application is made through the UK Data Service and is approved by the data owner for a named project and a fixed period.

## Folders the code expects

`config.do` defines `REPL_RAW`, the folder that holds the study folders. Below it, the do-files read the following.

| Folder under `REPL_RAW` | Files | Read by |
|---|---|---|
| `UKDA-6614-stata/stata/stata13_se/ukhls` | `a_indresp` to `o_indresp`, and for wave 15 `o_indall`, `o_egoalt`, `o_hhresp` | `BHPS_UKHLS_background_v6`, `pregnancies_v6`, `BHPS_UKHLS_children_v2`, `Interview_v6` |
| `UKDA-6614-stata-2/stata/stata11_se` | `bhps_w1` to `bhps_w18` (`b*_indresp`, `b*_indall`), `ukhls_w*` (`*_indresp`), `ukhls_wx/xwavedat` | `Interview_v6`, `BHPS_UKHLS_children_v2`, `ukhls_job_v3` |
| `UKDA-6931-stata/stata/stata13_se/ukhls` | `a` to `n`: `*_indresp_protect`, `*_indall_protect`, `*_egoalt_protect`, `*_natchild_protect`, `*_hhresp_protect`; `xwavedat_protect` | `pregnancies_v6`, `bio_child_v6`, `BHPS_UKHLS_background_v6`, `BHPS_UKHLS_children_v2`, `ukhls_job_v3` |
| `UKDA-6931-stata/stata/stata13_se/bhps` | `b*_indresp_protect` | `BHPS_UKHLS_background_v6` |
| `UKDA-5629-stata8/stata8` | `family.dta` | `BHPS_UKHLS_children_v2` |

Three points need attention with a fresh download.

The code was written against two editions of SN 6614. The current edition keeps all waves in one folder per survey (`ukhls`, `bhps`); the earlier one, here `UKDA-6614-stata-2`, had one folder per wave (`bhps_w1`, `ukhls_w1`, `ukhls_wx`). The file names inside are the same. With a single current download, change the folder settings at the top of `Interview_v6.do`, `BHPS_UKHLS_children_v2.do` and `ukhls_job_v3.do`, and the wave subfolder in the `use` lines that carry one.

`ukhls_job_v3.do` reads the wave 15 file `o_indresp` from a second copy of the study, in a folder named `UKDA-6614-stata 2/stata/stata14_se/ukhls`. Point its setting `path15` to your SN 6614 folder.

The Special Licence files used here stop at wave 14. Wave 15 enters from the End User Licence files only, so for that wave the dates of birth of children are those reported in the interview.

## Public series included in `data/`

The construction merges three public series from the Office for National Statistics, included here as downloaded and reproduced under the Open Government Licence v3.0.

| File | Content | Source |
|---|---|---|
| `UK_inflation_ONS_2026.dta` | Consumer prices index, monthly, from January 1988 | ONS series D7BT, https://www.ons.gov.uk/economy/inflationandpriceindices/timeseries/d7bt/mm23 |
| `employment_rate_UK.dta` | Employment rate of women aged 16 to 64, seasonally adjusted, monthly, March 1971 to September 2024 | ONS series LF25, https://www.ons.gov.uk/employmentandlabourmarket/peopleinwork/employmentandemployeetypes/timeseries/lf25/lms |
| `uk_ue1.dta` to `uk_ue12.dta` | Unemployment rate of women by age group, not seasonally adjusted, rolling three-month periods from June-August 2001; one file per region, North East to Northern Ireland | ONS dataset X02, Regional unemployment by age (women's sheets), https://www.ons.gov.uk/employmentandlabourmarket/peoplenotinwork/unemployment/datasets/regionalunemploymentbyagex02 |

The two labour-market series are the editions downloaded for the article, in December 2024 and July 2023. The Office for National Statistics has since revised the estimates from 2019 onwards, so a fresh download differs from these files in the recent years: by at most 0.1 percentage points for the employment rate, by more for the regional rates, which rest on small samples. Up to 2018 the files and the current series are identical.

## Files the full chain writes

`data/Wage/` receives the intermediate files and the analysis dataset `data_wage_v15.dta`. All are individual-level and fall under your own licence. `estimates/` receives aggregate files, with one exception named in the README under "Disclosure control".
