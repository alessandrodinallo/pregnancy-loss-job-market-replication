#!/usr/bin/env python3
"""Appendix Tables A2 to A5 (descriptive statistics), as LaTeX fragments.
Reads ../estimates/RB_V15E_AGE46_A2A5_descriptives.csv, writes to ./_generated.

Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
and pregnancy losses. Social Science Research, 141, 103450.
"""
import warnings; warnings.filterwarnings('ignore')
import pandas as pd, os, numpy as np

RB = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'estimates')
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '_generated')
os.makedirs(OUT, exist_ok=True)
d = pd.read_csv(f'{RB}/RB_V15E_AGE46_A2A5_descriptives.csv')

P = ['25+ before','13--24 before','1--12 before','0--12 after','13--24 after','25+ after']
CAP = {
 'A2':('A2_desc_wlive', 'women with a live birth and their co-resident partners'),
 'A3':('A3_desc_wloss', 'women with a pregnancy loss and their co-resident partners'),
 'A4':('A4_desc_mlive', 'men whose partner had a live birth, and their co-resident partners'),
 'A5':('A5_desc_mloss', 'men whose partner had a pregnancy loss, and their co-resident partners'),
}

def num(x):
    if pd.isna(x): return ''
    x = float(x)
    if abs(x) >= 100: return f'{x:,.0f}'
    return f'{x:.2f}'

def build(tbl):
    label, phrase = CAP[tbl]
    sub = d[d.tbl == tbl].sort_values('ord')
    L = []
    L.append('{\\footnotesize')
    L.append('\\begin{longtable}{@{}l*{6}{r}@{}}')
    L.append(f'\\caption{{Descriptive statistics by event-time period: {phrase}. '
             f'Means, with standard deviations in parentheses.}}\\label{{tab:{label}}}\\\\')
    head = ' & ' + ' & '.join(P) + '\\\\'
    L.append('\\toprule')
    L.append(' & \\multicolumn{6}{c}{\\footnotesize Months relative to end of pregnancy}\\\\')
    L.append('\\cmidrule(l){2-7}')
    L.append(head)
    L.append('\\midrule')
    L.append('\\endfirsthead')
    L.append('\\multicolumn{7}{@{}l}{\\footnotesize\\emph{(Table '
             + label.split('_')[0] + ' continued)}}\\\\')
    L.append('\\toprule')
    L.append(' & \\multicolumn{6}{c}{\\footnotesize Months relative to end of pregnancy}\\\\')
    L.append('\\cmidrule(l){2-7}')
    L.append(head)
    L.append('\\midrule')
    L.append('\\endhead')
    L.append('\\midrule\\multicolumn{7}{r@{}}{\\footnotesize\\emph{continued on next page}}\\\\')
    L.append('\\endfoot')
    L.append('\\bottomrule')
    L.append('\\endlastfoot')
    for block, title in [('resp','Respondent'), ('partner','Co-resident partner')]:
        bl = sub[sub.block == block]
        if bl.empty: continue
        L.append(f'\\addlinespace\\multicolumn{{7}}{{@{{}}l}}{{\\textbf{{{title}}}}}\\\\')
        for _, r in bl.iterrows():
            means = ' & '.join(num(r[f'm{i}']) for i in range(1, 7))
            sds   = ' & '.join(('' if pd.isna(r[f's{i}']) else '{\\footnotesize (' + num(r[f's{i}']) + ')}') for i in range(1, 7))
            L.append(f'{r.lab} & {means}\\\\')
            L.append(f' & {sds}\\\\')
    L.append('\\multicolumn{7}{@{}p{0.95\\linewidth}}{\\footnotesize\\textit{Notes.} '
             'Periods are coarse event-time windows around the end of pregnancy. '
             'Binary variables are proportions. Empty partner cells indicate variables '
             'not defined for the partner.}\\\\')
    L.append('\\end{longtable}')
    L.append('}')
    return '\n'.join(L) + '\n'

for tbl in ['A2','A3','A4','A5']:
    fn = f'table{tbl}_' + CAP[tbl][0].split("_",1)[1] + '.tex'
    with open(os.path.join(OUT, fn), 'w') as f:
        f.write(build(tbl))
    print('WROTE', fn)
