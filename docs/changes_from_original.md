# Changes from the files used for the article

The do-files and table scripts in this package are copies of the files that produced the article. In every file the comments were replaced by a header and short labels; the code is the same except as listed here. For the do-files the count is the number of commands that differ from the original, out of the commands of the original file, comments excluded; for the table scripts it is the number of lines.

| File | Changed | Of | What changed in the code |
|---|---|---|---|
| `masterfile_data_wage_v15.do` | 14 | 26 | personal folder paths replaced by the globals of config.do; the steps are called by relative path (code/...), from the package folder; step 1g (union histories) omitted: built but never used by the analysis; first line added: loads config.do |
| `Interview_v6.do` | 8 | 191 | personal folder paths replaced by the globals of config.do; text of a warning message shortened; text of a warning message shortened; text of a warning message shortened; first line added: loads config.do |
| `bio_child_v6.do` | 4 | 135 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `pregnancies_v6.do` | 10 | 310 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `BHPS_UKHLS_background_v6.do` | 13 | 253 | personal folder paths replaced by the globals of config.do; 2 unused folder setting(s) of other projects removed; first line added: loads config.do |
| `ukhls_job_v3.do` | 10 | 606 | personal folder paths replaced by the globals of config.do; config.do loaded again after `macro drop _all`, which erases every global; first line added: loads config.do |
| `BHPS_UKHLS_children_v2.do` | 18 | 526 | personal folder paths replaced by the globals of config.do; 2 unused folder setting(s) of other projects removed; first line added: loads config.do |
| `harmonization_uk_ue_v2.do` | 3 | 47 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `final_v15.do` | 17 | 1385 | personal folder paths replaced by the globals of config.do; exploratory lines after the final save omitted (they opened an earlier dataset); 2 unused folder setting(s) of other projects removed; 2 superseded Windows folder setting(s) removed (redefined just below); first line added: loads config.do |
| `SOC_ISEI_v2.do` | 1 | 6 | first line added: loads config.do |
| `add_age_event_v15.do` | 2 | 23 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `harmonization economic data women UK_v3.do` | 4 | 34 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `analysis_wage_v15E_AGE46_TABLE1.do` | 3 | 100 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `analysis_wage_v15E_AGE46_TABLEA11_blocks.do` | 3 | 93 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `analysis_wage_v15E_AGE46_TABLEA11_blocks_other.do` | 3 | 93 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `analysis_wage_v15_age46_robust.do` | 4 | 114 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `analysis_wage_v15E_AGE46_SA.do` | 3 | 106 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `analysis_wage_v15E_AGE46_A1_notyet.do` | 3 | 126 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `analysis_wage_v15E_AGE46_pretrends.do` | 3 | 52 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `analysis_wage_v15E_AGE46_pretrends_between.do` | 3 | 51 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `descriptive_stats_wage_v15E_AGE46_D21.do` | 3 | 80 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `analysis_wage_v15E_AGE46_A2A5_descriptives.do` | 3 | 82 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `analysis_wage_v15E_AGE46_A5A6fig.do` | 3 | 72 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `analysis_wage_v15E_AGE46_TWFEfig.do` | 3 | 54 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `analysis_wage_v15E_AGE46_SAfig.do` | 3 | 70 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `analysis_wage_v15E_AGE46_D15_ipw.do` | 3 | 117 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `analysis_wage_v15E_AGE46_D16_m1m5.do` | 3 | 74 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `analysis_wage_v15E_AGE46_D17_nofuturebirth.do` | 3 | 88 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `analysis_wage_v15E_AGE46_D18_ebal.do` | 3 | 128 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `analysis_wage_v15E_AGE46_D19_covid.do` | 4 | 107 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `analysis_wage_v15E_AGE46_D20_gestation.do` | 3 | 92 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `analysis_wage_v15E_AGE46_nocouple.do` | 3 | 81 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `did_matching_childless_v3.do` | 4 | 108 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `fig_v15E_AGE46_Figure1_earnings.do` | 4 | 32 | personal folder paths replaced by the globals of config.do; vector PDF export added next to the PNG export; first line added: loads config.do |
| `fig_v15E_AGE46_Figure2_margins.do` | 4 | 48 | personal folder paths replaced by the globals of config.do; vector PDF export added next to the PNG export; first line added: loads config.do |
| `fig_v15E_AGE46_FigA1A4_hist.do` | 3 | 52 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `fig_v15E_AGE46_FigA5_profiles.do` | 4 | 31 | personal folder paths replaced by the globals of config.do; figure written to figures/ instead of the estimates folder; first line added: loads config.do |
| `fig_v15E_AGE46_FigA5_health.do` | 3 | 41 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `fig_v15E_AGE46_FigA6_men.do` | 3 | 48 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `fig_v15E_AGE46_FigA8_nobirth.do` | 3 | 51 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `fig_v15E_AGE46_FigA_earnings.do` | 3 | 43 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `fig_v15E_AGE46_FigB1_TWFE.do` | 3 | 49 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `fig_v15E_AGE46_FigB2_SA.do` | 3 | 49 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `fig_v15E_AGE46_D18_ebal.do` | 4 | 100 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `fig_v15E_AGE46_D18_ebal_bigfont.do` | 3 | 67 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `fig_v15E_AGE46_D20_gestation.do` | 4 | 89 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `fig_v15E_AGE46_B3_childless.do` | 3 | 50 | personal folder paths replaced by the globals of config.do; first line added: loads config.do |
| `gen_tables_descriptives.py` | 3 | 75 | 1 absolute folder constant(s) -> ../estimates; output folder tables/ -> _generated/; creates the output folder if missing |
| `gen_tables_trajectory.py` | 4 | 101 | 1 absolute folder constant(s) -> ../estimates; output folder tables/ -> _generated/; labour-income trajectory table is written like the other four (it was only validated) |
| `gen_tables_robustness.py` | 21 | 220 | 3 absolute folder constant(s) -> ../estimates; output folder tables/ -> _generated/; creates the output folder if missing; Panel C of the comparability table, from the between-group pre-trend tests; comparability table note as published (Panel B); comparability table note as published (Panel C); pandemic table reads the analysis output under its own name (the project read an identical renamed copy); attrition table reads the analysis output under its own name (identical renamed copy); gestational-timing table reads the analysis output under its own name (identical renamed copy); gestational-timing table note as published |
| `gen_tables_A17A18.py` | 41 | 116 | 1 absolute folder constant(s) -> ../estimates; output folder tables/ -> _generated/; creates the output folder if missing; age-eligibility table removed: it is not in the published appendix; writes only the short-run wage table; header describes what the file now does |
| `gen_tableA11b_wage.py` | 5 | 63 | 1 absolute folder constant(s) -> ../estimates; output folder tables/ -> _generated/; creates the output folder if missing; table note as published |
| `gen_tableA19_nocouple.py` | 4 | 63 | 1 absolute folder constant(s) -> ../estimates; output folder tables/ -> _generated/; creates the output folder if missing |
| `gen_tables_B.py` | 2 | 55 | 1 absolute folder constant(s) -> ../estimates; output folder tables/ -> _generated/ |

The Stata files in `estimates/` and `data/` were rewritten so that their headers carry nothing but the data: same variables and values, strings stored at their actual width, default display formats.

The two files `RB_V15E_AGE46_D21_balance` (csv and dta) are copied without the columns `n_live` and `n_loss`, which no script reads.
