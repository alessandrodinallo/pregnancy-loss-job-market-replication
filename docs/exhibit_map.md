# Exhibit map

Each table and figure of the article and of its two appendices, with the script that draws it, the estimates it reads and the do-file that produced those estimates. Scripts are in `tables/` (Python) or `code/` (Stata); estimates are in `estimates/`. All estimates come from the analysis dataset `data/Wage/data_wage_v15.dta`, on the sample of women aged 18 to 45 at the end of the pregnancy.

The names of the LaTeX fragments were fixed before the appendix tables were renumbered, so a file name does not always carry the published number. The first column gives the published number.

## Main text

| Exhibit | Drawn by | Output | Reads | Estimates produced by |
|---|---|---|---|---|
| Table 1. Labour income, both groups, Models 1 to 5 | `gen_tables_main.py` | `table1_earnings.tex` | `RB_V15E_AGE46_TABLE1.csv`, `_TABLE1_N.csv` | `analysis_wage_v15E_AGE46_TABLE1.do` |
| Table 2. Decomposition by block of mechanisms | `gen_tables_main.py` | `table2_decomp.tex` | `RB_V15E_AGE46_TABLE1.csv`, `_TABLEA11.csv`, `_TABLEA11_OTHER.csv` and their `_N` files | `analysis_wage_v15E_AGE46_TABLE1.do`, `..._TABLEA11_blocks.do`, `..._TABLEA11_blocks_other.do` |
| Figure 1. Labour income, unadjusted and fully adjusted | `fig_v15E_AGE46_Figure1_earnings.do` | `RB_V15E_AGE46_Figure1_earnings_M1M5` | `RB_V15E_AGE46_TABLE1.dta` | `analysis_wage_v15E_AGE46_TABLE1.do` |
| Figure 2. Employment, hourly wage, work hours, conditional hours | `fig_v15E_AGE46_Figure2_margins.do` | `RB_V15E_AGE46_Figure2_margins_M1` | `RB_V15E_AGE46_TABLE1.dta` | `analysis_wage_v15E_AGE46_TABLE1.do` |

## Appendix A, tables

| Exhibit | Drawn by | Output | Reads | Estimates produced by |
|---|---|---|---|---|
| Table A1. Variables | written by hand | not in this package | none | none |
| Tables A2 to A5. Descriptive statistics by event time | `gen_tables_descriptives.py` | `tableA2_desc_wlive.tex`, `tableA3_desc_wloss.tex`, `tableA4_desc_mlive.tex`, `tableA5_desc_mloss.tex` | `RB_V15E_AGE46_A2A5_descriptives.csv` | `analysis_wage_v15E_AGE46_A2A5_descriptives.do` |
| Table A6. Labour income | `gen_tables_trajectory.py` | `tableA6_earnings.tex` | `RB_V15E_AGE46_TABLE1.dta`, `_TABLE1_N.csv` | `analysis_wage_v15E_AGE46_TABLE1.do` |
| Table A7. Employment | same | `tableA7_employment.tex` | same | same |
| Table A8. Hourly wage | same | `tableA8_wage.tex` | same | same |
| Table A9. Work hours | same | `tableA9_workhrs.tex` | same | same |
| Table A10. Conditional work hours | same | `tableA10_workhrs_cond.tex` | same | same |
| Table A11. Decomposition by block, labour income | `gen_tables_robustness.py` | `tableA11_decomp.tex` | `RB_V15E_AGE46_TABLEA11.csv` | `analysis_wage_v15E_AGE46_TABLEA11_blocks.do` |
| Table A12. Decomposition by block, hourly wage | `gen_tableA11b_wage.py` | `tableA11b_decomp_wage.tex` | `RB_V15E_AGE46_TABLEA11.csv`, `_TABLEA11_N.csv` | `analysis_wage_v15E_AGE46_TABLEA11_blocks.do` |
| Table A13. Pre-pregnancy comparability | `gen_tables_robustness.py` | `tableA12_balance.tex` | `RB_V15E_AGE46_D21_balance.csv`, `_pretrends.csv`, `_pretrends_between.csv` | `descriptive_stats_wage_v15E_AGE46_D21.do`, `analysis_wage_v15E_AGE46_pretrends.do`, `..._pretrends_between.do` |
| Table A14. Pandemic period | `gen_tables_robustness.py` | `tableA13_covid.tex` | `RB_V15E_AGE46_D19_coefficients.xlsx` | `analysis_wage_v15E_AGE46_D19_covid.do` |
| Table A15. Attrition, inverse probability weights | `gen_tables_robustness.py` | `tableA14_ipw.tex` | `RB_V15E_AGE46_D15_ipw.csv` | `analysis_wage_v15E_AGE46_D15_ipw.do` |
| Table A16. Subsequent pregnancy | `gen_tables_robustness.py` | `tableA15_subseq.tex` | `RB_V15E_AGE46_D16_m1m5.dta` | `analysis_wage_v15E_AGE46_D16_m1m5.do` |
| Table A17. Gestational timing | `gen_tables_robustness.py` | `tableA16_gestational.tex` | `RB_V15E_AGE46_D20_coefficients.xlsx` | `analysis_wage_v15E_AGE46_D20_gestation.do`, then `fig_v15E_AGE46_D20_gestation.do`, which writes the spreadsheet |
| Table A18. Short-run wage across comparison groups | `gen_tables_A17A18.py` | `tableA18_shortrun.tex` | `RB_V15E_AGE46_allcoef.dta`, `_SAcoef.dta`, `_A1NY_wage_RE_nested.csv` | `analysis_wage_v15_age46_robust.do`, `analysis_wage_v15E_AGE46_SA.do`, `..._A1_notyet.do` |
| Table A19. Model 1 without the couple controls | `gen_tableA19_nocouple.py` | `tableA19_nocouple.tex` | `RB_V15E_AGE46_NOCOUPLE.csv`, `_NOCOUPLE_N.csv` | `analysis_wage_v15E_AGE46_nocouple.do` |

## Appendix A, figures

| Exhibit | Drawn by | Output | Reads | Estimates produced by |
|---|---|---|---|---|
| Figures A1 to A4. Distributions of the outcomes | `fig_v15E_AGE46_FigA1A4_hist.do` | `RB_V15E_AGE46_Fig*_hist` | the analysis dataset (survey data needed) | none |
| Figure A5. Pre-pregnancy comparability | `fig_v15E_AGE46_FigA5_profiles.do` | `RB_V15E_AGE46_D21_profiles` | `RB_V15E_AGE46_D21_balance.dta` | `descriptive_stats_wage_v15E_AGE46_D21.do` |
| Figure A6. Mental and physical health | `fig_v15E_AGE46_FigA5_health.do` | `RB_V15E_AGE46_FigA5_health` | `RB_V15E_AGE46_A5A6fig.dta` | `analysis_wage_v15E_AGE46_A5A6fig.do` |
| Figure A7. Partner's outcomes | `fig_v15E_AGE46_FigA6_men.do` | `RB_V15E_AGE46_FigA6_men` | `RB_V15E_AGE46_A5A6fig.dta` | `analysis_wage_v15E_AGE46_A5A6fig.do` |
| Figure A8. Excluding women with a subsequent birth | `fig_v15E_AGE46_FigA8_nobirth.do` | `RB_V15E_AGE46_FigA8_nobirth` | `RB_V15E_AGE46_D17.dta` | `analysis_wage_v15E_AGE46_D17_nofuturebirth.do` |
| Figure A9. Estimator, labour income | `fig_v15E_AGE46_FigA_earnings.do` | `RB_V15E_AGE46_FigA_earnings` | `RB_V15E_AGE46_TWFEfig.dta`, `_SAfig.dta` | `analysis_wage_v15E_AGE46_TWFEfig.do`, `..._SAfig.do` |
| Figure A10. Estimator, four outcomes, two-way fixed effects | `fig_v15E_AGE46_FigB1_TWFE.do` | `RB_V15E_AGE46_FigB1_TWFE` | `RB_V15E_AGE46_TWFEfig.dta` | `analysis_wage_v15E_AGE46_TWFEfig.do` |
| Figure A11. Estimator, four outcomes, interaction-weighted | `fig_v15E_AGE46_FigB2_SA.do` | `RB_V15E_AGE46_FigB2_SA` | `RB_V15E_AGE46_SAfig.dta` | `analysis_wage_v15E_AGE46_SAfig.do` |

## Appendix B

| Exhibit | Drawn by | Output | Reads | Estimates produced by |
|---|---|---|---|---|
| Table B1. Covariate balance, entropy balancing | `gen_tables_B.py` | `tableB1_balance.tex` | `RB_V15E_AGE46_D18_balance.csv` | `analysis_wage_v15E_AGE46_D18_ebal.do` |
| Figures B1 and B2. Unweighted and entropy-balanced, labour income and hourly wage | `fig_v15E_AGE46_D18_ebal_bigfont.do` | `RB_V15E_AGE46_D18_earnings_M1_big`, `..._wage_M1_big` | the analysis dataset (survey data needed); the plotted coefficients are in `RB_V15E_AGE46_D18.dta` | `analysis_wage_v15E_AGE46_D18_ebal.do` |
| Figures B3 and B4. Pregnancy loss and childless women | `fig_v15E_AGE46_B3_childless.do` | `RB_V15E_AGE46_B3_earnings_fig`, `..._wage_fig` | `B3_V15E_AGE46_allcoef.dta` | `did_matching_childless_v3.do` |

## Figure scripts that need no survey data

`fig_v15E_AGE46_Figure1_earnings.do`, `fig_v15E_AGE46_Figure2_margins.do`, `fig_v15E_AGE46_FigA5_profiles.do`, `fig_v15E_AGE46_FigA5_health.do`, `fig_v15E_AGE46_FigA6_men.do`, `fig_v15E_AGE46_FigA8_nobirth.do`, `fig_v15E_AGE46_FigA_earnings.do`, `fig_v15E_AGE46_FigB1_TWFE.do`, `fig_v15E_AGE46_FigB2_SA.do`, `fig_v15E_AGE46_B3_childless.do`.

The numbers in the names of the figure scripts follow an earlier numbering of the appendix: `FigA5_health` draws Figure A6, `FigA6_men` draws Figure A7, and `FigB1_TWFE` and `FigB2_SA` draw Figures A10 and A11.

## Data construction

`masterfile_data_wage_v15.do` calls, in order: `Interview_v6.do` (interview dates), `bio_child_v6.do` (dates of birth of biological children), `pregnancies_v6.do` (pregnancy histories, outcome and timing of each pregnancy), `BHPS_UKHLS_background_v6.do` (covariates, income, health), `ukhls_job_v3.do` (job histories, occupation, tenure), `BHPS_UKHLS_children_v2.do` (children in the household), `harmonization economic data women UK_v3.do` and `harmonization_uk_ue_v2.do` (consumer prices, women's employment, regional unemployment), and `final_v15.do`, which assembles the person-wave file, calls `SOC_ISEI_v2.do` for the occupational status score and writes `data_wage_v15.dta`. `add_age_event_v15.do` adds the age at the end of the pregnancy to an existing dataset without a full rebuild; the full run does not need it.
