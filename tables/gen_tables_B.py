#!/usr/bin/env python3
"""Appendix Table B1 (covariate balance under entropy balancing), as a LaTeX fragment.
Reads ../estimates/RB_V15E_AGE46_D18_balance.csv, writes to ./_generated.

Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
and pregnancy losses. Social Science Research, 141, 103450.
"""
import warnings; warnings.filterwarnings('ignore')
import pandas as pd, os

RB = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'estimates')
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '_generated')
os.makedirs(OUT, exist_ok=True)

COVLAB = {
    'b_age_f':                 'Age',
    'b_fimnlabgrs_CPI_trim_f': 'Monthly labour income (2015 GBP)',
    'b_employed11_f':          'Employment',
    'b_tot_work_hours_f':      'Weekly work hours',
    'b_income_partner_f':      "Partner's labour income (log)",
}

def cell(x):
    return f'${x:.3f}$' if x >= 0 else f'$-{abs(x):.3f}$'

def B1():
    d = pd.read_csv(f'{RB}/RB_V15E_AGE46_D18_balance.csv')
    body = []
    for _, r in d.iterrows():
        lab = COVLAB.get(r['covar'], r['covar'])
        body.append(f'{lab} & {cell(r.sd_unw)} & {cell(r.sd_wtd)} \\\\')
    L = ['\\begin{threeparttable}', '\\centering',
         '\\caption{Covariate balance before and after entropy balancing '
         '(pre-conception baseline). Women.}',
         '\\label{tab:B1}', '\\footnotesize',
         '\\begin{tabular}{lcc}', '\\toprule',
         'Baseline covariate & Unweighted & Entropy-balanced \\\\',
         ' & \\multicolumn{2}{c}{\\footnotesize std.\\ difference} \\\\',
         '\\midrule']
    L += body
    L += ['\\bottomrule', '\\end{tabular}',
          '\\begin{tablenotes}[flushleft]\\footnotesize',
          '\\item \\textit{Notes.} Standardised differences in pre-conception baseline '
          'means between the pregnancy-loss and live-birth groups, before (unweighted) and '
          'after entropy balancing. Weights equalise the live-birth group\'s baseline means '
          'to the loss group (ATT); no propensity-score model or common-support trimming is '
          'used, so no pregnancy-loss case is dropped. After weighting all standardised '
          'differences are below 0.001.',
          '\\end{tablenotes}', '\\end{threeparttable}']
    with open(f'{OUT}/tableB1_balance.tex', 'w') as f:
        f.write('\n'.join(L) + '\n')
    print('wrote tableB1_balance.tex')

if __name__ == '__main__':
    B1()
