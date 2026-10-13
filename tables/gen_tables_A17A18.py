#!/usr/bin/env python3
"""Appendix Table A18 (short-run wage across comparison groups), as a LaTeX fragment.
Reads the estimates in ../estimates, writes to ./_generated.

Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
and pregnancy losses. Social Science Research, 141, 103450.
"""
import warnings; warnings.filterwarnings('ignore')
import pandas as pd, os, re, csv

RB = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'estimates')
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '_generated')
os.makedirs(OUT, exist_ok=True)

def star(t):
    a = abs(t)
    return '^{***}' if a>3.291 else '^{**}' if a>2.576 else '^{*}' if a>1.96 else '^{\\dagger}' if a>1.645 else ''

def cell(b, se, dec):
    if b is None or se is None or se==0: return '.'
    bs=f'{b:.{dec}f}'; st=star(b/se)
    return f'$-{bs[1:]}{st}$' if bs.startswith('-') else f'${bs}{st}$'

def se_s(se,dec): return '' if se is None else f'{{\\footnotesize ({se:.{dec}f})}}'

def parse_esttab(path):
    rows=list(csv.reader(open(path)))
    out={}
    i=0
    while i < len(rows)-1:
        r=rows[i]
        if r and re.match(r'^\d+\.time_x\d_cat4$', r[0]):
            name=r[0]; se_row=rows[i+1]
            for c in range(1,len(r)):
                bval=r[c].strip(); sval=se_row[c].strip() if c<len(se_row) else ''
                if bval in ('','.','0.000'):
                    b=None
                else:
                    b=float(re.sub(r'[^0-9.\-]','',bval))
                s=None if sval in ('','.') else float(re.sub(r'[^0-9.\-]','',sval))
                out[(name,c)]=(b,s)
            i+=2
        else:
            i+=1
    return out

def A18():
    ac=pd.read_stata(f'{RB}/RB_V15E_AGE46_allcoef.dta',convert_categoricals=False)
    sa=pd.read_stata(f'{RB}/RB_V15E_AGE46_SAcoef.dta',convert_categoricals=False)
    a1=parse_esttab(f'{RB}/RB_V15E_AGE46_A1NY_wage_RE_nested.csv')
    def live(m):
        r=ac[(ac.outcome=='wage')&(ac.estim=='RE')&(ac.bin==4)&(ac.model==m)].iloc[0]; return r.b,r.se
    def cohort(m):
        r=sa[(sa.outcome=='wage')&(sa.bin==4)&(sa.model==m)].iloc[0]; return r.b,r.se
    def notyet(m):
        return a1.get(('4.time_x2_cat4',m),(None,None))
    rows=[('Live birth (main comparison)',live),
          ('Not-yet-treated women',notyet),
          ('Later pregnancy-loss cohort',cohort)]
    body=[' & Unadjusted & Fully adjusted\\\\',' & (Model 1) & (Model 5)\\\\','\\midrule']
    for lab,fn in rows:
        b1,s1=fn(1); b5,s5=fn(5)
        body.append(f'{lab} & {cell(b1,s1,3)} & {cell(b5,s5,3)}\\\\')
        body.append(f' & {se_s(s1,3)} & {se_s(s5,3)}\\\\')
    L=['\\begin{threeparttable}','\\centering',
       '\\caption{Short-run hourly-wage decline (0--12 months after) across comparison '
       'groups. Pregnancy-loss coefficient, women.}','\\label{tab:A18_shortrun}','\\footnotesize',
       '\\begin{tabular}{@{}l r r@{}}','\\toprule',
       'Comparison group & \\multicolumn{2}{c}{Wage change, 0--12 after}\\\\',
       '\\cmidrule(l){2-3}']+body+[
       '\\bottomrule','\\end{tabular}',
       '\\begin{tablenotes}[flushleft]\\footnotesize',
       '\\item \\textit{Notes.} Cluster-robust standard errors (by woman) in parentheses. '
       '$^{\\dagger}\\,p<0.1$, $^{*}\\,p<0.05$, $^{**}\\,p<0.01$, $^{***}\\,p<0.001$. '
       'The short-run log-hourly-wage decline for the pregnancy-loss group is negative and '
       'significant against all three comparison groups: the live-birth group (main analysis), '
       'women not yet treated at the same event time, and the cohort of women who experience a '
       'loss later (interaction-weighted estimator).','\\end{tablenotes}','\\end{threeparttable}']
    return '\n'.join(L)+'\n'

for fn,fun in [('tableA18_shortrun.tex',A18)]:
    with open(os.path.join(OUT,fn),'w') as f: f.write(fun())
    print('WROTE',fn)
