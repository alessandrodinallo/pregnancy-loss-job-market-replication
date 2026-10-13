# Replication package

**Di Nallo, A. (2026). Women's job market outcomes around live births and pregnancy losses. *Social Science Research*, 141, 103450.** https://doi.org/10.1016/j.ssresearch.2026.103450

This repository holds the code behind the article and its two supplementary appendices, together with the aggregate estimates the code produced. The survey data are not included: they are distributed by the UK Data Service under licence and cannot be shared, in original or in derived form.

## What you can reproduce

**Without the survey data.** The folder `estimates/` contains the coefficients, standard errors and sample sizes behind every table and behind eleven of the seventeen figures. The scripts in `tables/` and the figure scripts in `code/` turn them into the published exhibits. Run from this package, the table scripts give LaTeX fragments identical, character for character, to those typeset in the article and appendices (21 tables), and the figure scripts give the published figures.

**With the survey data.** The files in `code/` rebuild the analysis dataset from the original Understanding Society files and estimate every model. You need your own access to the data, including the Special Licence version (see `docs/data_access.md`). Six figures can be drawn only at this level: the four outcome distributions (Appendix Figures A1 to A4) and the two entropy-balancing figures (Appendix Figures B1 and B2).

`docs/exhibit_map.md` lists, for each table and figure, the script that draws it, the estimates it reads and the do-file that produced those estimates.

## Folder structure

```
config.do     folder settings, loaded by every do-file
code/         Stata do-files: data construction, estimation, figures
tables/       Python scripts that write the tables as LaTeX fragments
estimates/    aggregate results: coefficients, standard errors, sample sizes
data/         public macroeconomic series; the survey-derived files are written here and never shared
figures/      output folder of the figure scripts
docs/         exhibit map, data access, changes from the original files
```

## How to run

Start Stata in the package folder, or `cd` to it. Every do-file loads `config.do` on its first line and expects to be called from there.

Tables, with Python 3:

```
python3 tables/gen_tables_main.py          # Tables 1 and 2
python3 tables/gen_tables_trajectory.py    # Appendix Tables A6 to A10
```

and likewise for the other scripts in `tables/`. The output goes to `tables/_generated/`.

Figures that need no survey data, in Stata:

```
do code/fig_v15E_AGE46_Figure1_earnings.do
do code/fig_v15E_AGE46_Figure2_margins.do
```

and likewise for the other figure files marked "estimates only" in `docs/exhibit_map.md`. The output goes to `figures/`.

The full chain, with the survey data:

1. In `config.do`, set `REPL_RAW` to the folder that holds the UK Data Service study folders. `docs/data_access.md` describes the folders and files the code expects.
2. Open `code/masterfile_data_wage_v15.do`, set `local RUN = 1` and run it. With the default `RUN = 0` it only lists the steps. It writes the analysis dataset `data/Wage/data_wage_v15.dta`.
3. Run the `analysis_*`, `descriptive_stats_*` and `did_matching_*` files in `code/`. Each writes to `estimates/`, replacing the files included here. The order is free, with one exception: `analysis_wage_v15E_AGE46_SA.do` reads the coefficients written by `analysis_wage_v15_age46_robust.do` and runs after it.
4. Run the figure files and the table scripts.

## Software

Stata 19.5 (StataNow) with the user-written packages `reghdfe` and `ftools`, `eventstudyinteract` and `avar`, `ebalance`, `psmatch2`, `coefplot`, `estout`, `grc1leg` and `unique`. Python 3 with `pandas`, `numpy` and `openpyxl`.

## How this package relates to the files used for the article

The do-files and table scripts are copies of the files that produced the article. Their comments were rewritten for this package: one header per file and short labels. The code differs from the originals in the folder paths, now set in `config.do`, and in the few further points listed file by file in `docs/changes_from_original.md`: one unused construction step is omitted, and four table scripts are aligned with the fragments as published. The Stata files in `estimates/` and `data/` were rewritten with clean headers; their values are unchanged.

Everything that runs without the survey data was run from this package and compared with the article: the tables, the eleven figures and the two files that prepare the macroeconomic series. The data construction and estimation files were run in their original form for the article. Their copies here were not run again after the path changes. If a path fails on your system, the settings at the top of the file concerned are the place to look.

## Reproducibility notes

The sample is women who had no children when they entered the panel, were employed before their first reported pregnancy and were aged 18 to 45 when it ended: 23,883 person-wave observations from 2,654 women, of whom 2,333 had a live birth and 321 a pregnancy loss. Outcomes defined only for the employed (hourly wage, conditional hours) use 18,066 observations from 2,459 women.

The construction is deterministic. A missing month of birth of a child is filled by a fixed formula of the record's identifiers, and the remaining random draws use a fixed seed and a stable sort order. Two complete runs from the original files gave identical analysis datasets.

## Disclosure control

The files in `estimates/` are aggregate: coefficients, standard errors, test statistics, means and sample sizes, the same numbers as in the published tables and figures. None contains individual records or a geography below the region. If you run the full chain, some files that the code writes to your disk are not aggregate in this sense. `RB_V15E_AGE46_D20_dist.csv` and the figure of the distribution of gestational timing include a category with fewer than 20 women, and everything under `data/` is individual-level. Keep those files under the terms of your own licence. The `.gitignore` of this repository excludes them.

## Licence and citation

Code: MIT licence. Documentation and aggregate estimates: CC BY 4.0. The macroeconomic series in `data/` come from the Office for National Statistics and are reproduced under the Open Government Licence v3.0.

If you use this package, please cite the article above.

## Acknowledgements

`code/ukhls_job_v3.do`, which builds the job histories, is adapted from data-preparation code written by Lewis Anderson and is included with his permission.

## Funding

European Research Council, Synergy Grant BIOSFER (grant agreement 101071773), and Understanding Society Fellowship (University of Essex, ESRC ES/S007253/1).

## Contact

Alessandro Di Nallo, Universitat Pompeu Fabra, alessandro.dinallo@upf.edu
