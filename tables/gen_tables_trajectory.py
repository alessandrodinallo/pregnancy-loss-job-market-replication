#!/usr/bin/env python3
"""Appendix Tables A6 to A10 (event-study estimates by outcome), as LaTeX fragments.
Reads ../estimates/RB_V15E_AGE46_TABLE1.dta and RB_V15E_AGE46_TABLE1_N.csv,
writes to ./_generated.

Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
and pregnancy losses. Social Science Research, 141, 103450.
"""
import warnings; warnings.filterwarnings('ignore')
import pandas as pd, os

RB = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'estimates')
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '_generated')
os.makedirs(OUT, exist_ok=True)

d = pd.read_stata(f'{RB}/RB_V15E_AGE46_TABLE1.dta', convert_categoricals=False)
N = pd.read_csv(f'{RB}/RB_V15E_AGE46_TABLE1_N.csv')

BINS = [(1,'25+ before'),(3,'12/1 before'),(4,'0/12 after'),(5,'13/24 after'),
        (6,'25/36 after'),(7,'37/48 after'),(8,'49/60 after'),(9,'61+ after')]
STAR = {'':'', '+':'^{\\dagger}', '*':'^{*}', '**':'^{**}', '***':'^{***}'}

CFG = {
 'earnings':     ('labour earnings',                        'A6_earnings',      2, False, 'tableA6_earnings.tex',      False),
 'employed':     ('employment',                             'A7_employment',    3, False, 'tableA7_employment.tex',    False),
 'wage':         ('the hourly wage (in logs)',              'A8_wage',          3, True,  'tableA8_wage.tex',          False),
 'workhrs':      ('weekly work hours',                      'A9_workhrs',       2, False, 'tableA9_workhrs.tex',       False),
 'workhrs_cond': ('conditional weekly work hours (in logs)','A10_workhrs_cond', 3, True,  'tableA10_workhrs_cond.tex', False),
}
GRP = [(1,'live birth'),(2,'pregnancy loss')]

def cell(b, se, star, dec):
    st = STAR.get(str(star) if pd.notna(star) else '', '')
    b_s  = f'{b:.{dec}f}'
    se_s = f'{se:.{dec}f}'
    return f'$-{b_s[1:]}{st}$' if b_s.startswith('-') else f'${b_s}{st}$', se_s

def fmt_int(x):
    return f'{int(round(x)):,}'

def build(outcome):
    phrase, label, dec, cond, fname, valonly = CFG[outcome]
    do = d[d.outcome == outcome]
    no = N[N.outcome == outcome].set_index('model')
    L = []
    L.append(f"% {'labour-earnings' if outcome == 'earnings' else outcome} event-study table (generated fragment)")
    L.append('\\begin{threeparttable}')
    L.append('\\centering')
    condcap = ' Estimated on employed person-waves.' if cond else ''
    L.append(f'\\caption{{Trajectories of {phrase} around live births and pregnancy '
             f'losses. Coefficients from an event study (both event-time series estimated '
             f'in a single model).{condcap} Women.}}')
    L.append(f'\\label{{tab:{label}}}')
    L.append('\\footnotesize')
    L.append('\\begin{tabular}{@{}l*{5}{r}@{}}')
    L.append('\\toprule')
    L.append(' & (1) & (2) & (3) & (4) & (5)\\\\')
    L.append('\\midrule')
    for g, gname in GRP:
        L.append(f'\\addlinespace\\multicolumn{{6}}{{@{{}}l}}{{\\textbf{{Months '
                 f'before/after {gname} \\emph{{(reference: 24--13 months before)}}}}}}\\\\')
        for b_, blab in BINS:
            cells, ses = [], []
            for m in range(1, 6):
                row = do[(do.grp == g) & (do.bin == b_) & (do.model == m)].iloc[0]
                c, s = cell(row.b, row.se, row.star, dec)
                cells.append(c); ses.append(s)
            L.append(f'{blab} & ' + ' & '.join(cells) + '\\\\')
            L.append(' & ' + ' & '.join('{\\footnotesize (' + s + ')}' for s in ses) + '\\\\')
    L.append('\\addlinespace\\midrule')
    L.append('Baseline controls & Yes & Yes & Yes & Yes & Yes\\\\')
    L.append('(Another) motherhood transition & No & Yes & Yes & Yes & Yes\\\\')
    L.append('Career characteristics & No & No & Yes & Yes & Yes\\\\')
    L.append('Human capital & No & No & No & Yes & Yes\\\\')
    L.append('Health & No & No & No & No & Yes\\\\')
    obs = ' & '.join('$' + fmt_int(no.loc[m, 'nobs']) + '$' for m in range(1, 6))
    nw  = ' & '.join('$' + fmt_int(no.loc[m, 'nwomen']) + '$' for m in range(1, 6))
    L.append(f'Observations & {obs}\\\\')
    L.append(f'Number of women & {nw}\\\\')
    L.append('\\bottomrule')
    L.append('\\end{tabular}')
    L.append('\\begin{tablenotes}[flushleft]\\footnotesize')
    L.append('\\item \\textit{Notes.} Cluster-robust standard errors (by woman) in parentheses.')
    L.append('$^{\\dagger}\\,p<0.1$, $^{*}\\,p<0.05$, $^{**}\\,p<0.01$, $^{***}\\,p<0.001$.')
    L.append('Baseline controls: age (quadratic), marital status, partner income, region, and period.')
    L.append('Model~(1) is unadjusted; models (2)--(5) add mechanism blocks sequentially.')
    L.append('\\end{tablenotes}')
    L.append('\\end{threeparttable}')
    return '\n'.join(L) + '\n'

for outcome, cfg in CFG.items():
    fname, valonly = cfg[4], cfg[5]
    tex = build(outcome)
    if valonly:
        with open(os.path.join(OUT, '_validate_' + fname), 'w') as f:
            f.write(tex)
        print(f'VALIDATE  -> _validate_{fname}')
    else:
        with open(os.path.join(OUT, fname), 'w') as f:
            f.write(tex)
        print(f'WROTE     -> {fname}')
