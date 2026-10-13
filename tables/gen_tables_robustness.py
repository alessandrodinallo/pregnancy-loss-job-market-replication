#!/usr/bin/env python3
"""Appendix Tables A11 and A13 to A17, as LaTeX fragments.
Reads the estimates in ../estimates, writes to ./_generated.

Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
and pregnancy losses. Social Science Research, 141, 103450.
"""
import warnings; warnings.filterwarnings('ignore')
import pandas as pd, os, numpy as np

RB = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'estimates')
DES = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'estimates')
MF = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'estimates')
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '_generated')
os.makedirs(OUT, exist_ok=True)

OLAB = {'earnings':'Labour income','employed':'Employment','wage':'Hourly wage (log)',
        'workhrs':'Work hours','workhrs_cond':'Conditional work hours (log)'}
ODEC = {'earnings':2,'employed':3,'wage':3,'workhrs':2,'workhrs_cond':3}
OUTS = ['earnings','employed','wage','workhrs','workhrs_cond']
BINLAB = {1:'25+ before',3:'12/1 before',4:'0/12 after',5:'13/24 after',
          6:'25/36 after',7:'37/48 after',8:'49/60 after',9:'61+ after'}

def star(t):
    a = abs(t)
    if a > 3.291: return '^{***}'
    if a > 2.576: return '^{**}'
    if a > 1.96:  return '^{*}'
    if a > 1.645: return '^{\\dagger}'
    return ''

def C(b, se, dec):
    """coefficient cell with star (from t) + se string"""
    if pd.isna(b) or pd.isna(se) or se == 0:
        return '.', '.'
    st = star(b/se)
    bs = f'{b:.{dec}f}'
    coef = f'$-{bs[1:]}{st}$' if bs.startswith('-') else f'${bs}{st}$'
    return coef, f'{se:.{dec}f}'

def wrap(caption, label, colspec, header, body, notes):
    L = ['\\begin{threeparttable}', '\\centering',
         f'\\caption{{{caption}}}', f'\\label{{tab:{label}}}', '\\footnotesize',
         f'\\begin{{tabular}}{{{colspec}}}', '\\toprule', header, '\\midrule']
    L += body
    L += ['\\bottomrule', '\\end{tabular}',
          '\\begin{tablenotes}[flushleft]\\footnotesize',
          '\\item \\textit{Notes.} Cluster-robust standard errors (by woman) in parentheses. '
          '$^{\\dagger}\\,p<0.1$, $^{*}\\,p<0.05$, $^{**}\\,p<0.01$, $^{***}\\,p<0.001$.',
          notes, '\\end{tablenotes}', '\\end{threeparttable}']
    return '\n'.join(L) + '\n'

def coefrow(label, cells, ses, ncol):
    r1 = f'{label} & ' + ' & '.join(cells) + '\\\\'
    r2 = ' & ' + ' & '.join('{\\footnotesize (' + s + ')}' for s in ses) + '\\\\'
    return [r1, r2]

def A11():
    d = pd.read_csv(f'{RB}/RB_V15E_AGE46_TABLEA11.csv')
    e = d[(d.outcome=='earnings') & (d.grp==2)]
    body = []
    for b_ in [4,6,8,9]:
        cells, ses = [], []
        for m in range(1,6):
            row = e[(e.bin==b_)&(e.model==m)].iloc[0]
            c,s = C(row.b, row.se, 2); cells.append(c); ses.append(s)
        body += coefrow(BINLAB[b_], cells, ses, 5)
    header = ' & (1) & (2) & (3) & (4) & (5)\\\\\n & +\\,Career & +\\,Human cap. & +\\,Health & +\\,Motherhood & Full set\\\\'
    notes = ('Each of columns (1)--(4) adds \\emph{one} mechanism block on its own to the '
             'baseline controls; column (5) includes the full set. Reference period 24--13 '
             'months before. Entered alone, the human-capital block moves the long-run '
             'labour-income decline the most, followed by the subsequent-motherhood '
             'transition; the blocks overlap, so the movements are not additive.')
    return wrap('Decomposition of the pregnancy-loss labour-income decline by mechanism block: blocks entered separately. Women.',
                'A11_decomp', '@{}l*{5}{r}@{}', header, body, notes)

def A12():
    bal = pd.read_csv(f'{DES}/RB_V15E_AGE46_D21_balance.csv')
    VLAB = {'fimnlabgrs_CPI_trim_f':'Monthly labour income','employed11_f':'Employed',
            'tot_work_hours_f':'Weekly work hours','ISEI_f':'Occupational status (ISEI)',
            'work_exp_f':'Work experience','tenure_f':'Job tenure','age_f':'Age',
            'private_f':'Private sector','income_partner_f':'Partner income'}
    body = ['\\addlinespace\\multicolumn{5}{@{}l}{\\textbf{Panel A. Pre-conception covariate balance}}\\\\',
            'Variable & Live birth & Pregnancy loss & Std.\\ diff. & $p$-value\\\\', '\\midrule']
    for _,r in bal.iterrows():
        lab = VLAB.get(r['varname'], r['varname'].replace('_f','').replace('_',' '))
        ml = f'{r.mean_live:.2f}'; mp = f'{r.mean_loss:.2f}'
        sd = f'{r.stddiff:.3f}'; sd = ('$-' + sd[1:] + '$') if sd.startswith('-') else f'${sd}$'
        body.append(f'{lab} & {ml} & {mp} & {sd} & {r.pval:.2f}\\\\')
    # pre-trends
    pt = pd.read_csv(f'{RB}/RB_V15E_AGE46_pretrends.csv')
    body += ['\\addlinespace\\midrule',
             '\\addlinespace\\multicolumn{5}{@{}l}{\\textbf{Panel B. Pre-conception (clean) lead and joint pre-trend test}}\\\\',
             'Outcome (group) & Lead coef. & \\ & Joint $\\chi^2$ & Joint $p$\\\\', '\\midrule']
    for _,r in pt.iterrows():
        grp = 'live birth' if r.group=='live_birth' else 'pregnancy loss'
        lab = f'{OLAB.get(r.outcome,r.outcome)} ({grp})'
        dec = ODEC.get(r.outcome,3)
        cb = f'{r.clean_b:.{dec}f}'; cb = ('$-'+cb[1:]+star(r.clean_b/r.clean_se)+'$') if cb.startswith('-') else f'${cb}{star(r.clean_b/r.clean_se)}$'
        body.append(f'{lab} & {cb} & & ${r.joint_chi2:.2f}$ & {r.joint_p:.3f}\\\\')
    bg = pd.read_csv(f'{RB}/RB_V15E_AGE46_pretrends_between.csv')
    body += ['\\addlinespace\\midrule',
             '\\addlinespace\\multicolumn{5}{@{}l}{\\textbf{Panel C. Between-group difference in pre-trends (joint test)}}\\\\',
             'Outcome & & & Joint $\\chi^2$ & Joint $p$\\\\', '\\midrule']
    for _,r in bg.iterrows():
        body.append(f'{OLAB.get(r.outcome,r.outcome)} & & & ${r.joint_chi2:.2f}$ & {r.joint_p:.3f}\\\\')
    header = ' & \\multicolumn{4}{c}{ }\\\\'
    notes = ('Panel A: standardised means of pre-conception covariates by group, the standardised '
             'difference, and the $p$-value of a group-mean test. Only age differs appreciably. '
             'Panel B: the coefficient on the clean pre-conception lead (25+ months before, relative '
             'to 24--13 months before) and a within-group joint test that all pre-conception leads (25+ and 12--1 months before) are zero, by '
             'outcome and group. The loss group shows no significant pre-trend on any outcome. '
             "Panel C: a joint test that the two groups' pre-conception leads are equal, by outcome "
             "(2 degrees of freedom). None differs significantly, so the two groups' pre-conception "
             'trajectories are parallel.')
    return wrap('Pre-pregnancy comparability of the two groups. Women.',
                'A12_balance', '@{}l r r r r@{}', header, body, notes)

def rob_table(df_get, cols, caption, label, notes, horizons=(4,9)):
    """df_get(outcome,bin,colkey) -> (b,se). cols = list of (colkey, header)."""
    ncol = len(cols)
    header = 'Outcome & Horizon & ' + ' & '.join(h for _,h in cols) + '\\\\'
    body = []
    for o in OUTS:
        dec = ODEC[o]
        for i,b_ in enumerate(horizons):
            olab = OLAB[o] if i==0 else ''
            cells, ses = [], []
            for ck,_ in cols:
                b,se = df_get(o,b_,ck)
                c,s = C(b,se,dec); cells.append(c); ses.append(s)
            r1 = f'{olab} & {BINLAB[b_]} & ' + ' & '.join(cells) + '\\\\'
            r2 = ' & & ' + ' & '.join('{\\footnotesize ('+s+')}' for s in ses) + '\\\\'
            body += [r1, r2]
        body.append('\\addlinespace')
    colspec = '@{}l l' + 'r'*ncol + '@{}'
    return wrap(caption, label, colspec, header, body, notes)

def A13():
    a = pd.read_excel(f'{RB}/RB_V15E_AGE46_D19_coefficients.xlsx')
    a['binn'] = a['bin'].map({v:k for k,v in {1:'25+ before',3:'12-1 before',4:'0-12 after',5:'13-24 after',6:'25-36 after',7:'37-48 after',8:'49-60 after',9:'61+ after'}.items()})
    def g(o,b,ck):
        r = a[(a.outcome==o)&(a['sample']==ck)&(a.model==5)&(a.binn==b)]
        return (r.b.iloc[0], r.se.iloc[0]) if len(r) else (np.nan,np.nan)
    cols = [('full','Full sample'),('opt1','Excl.\\ final waves'),('opt2','Excl.\\ pandemic')]
    notes = ('Pregnancy-loss coefficients, fully adjusted model (Model~5), on the full sample and '
             'on samples that (i) drop the final survey waves and (ii) drop pregnancies ending during '
             'the pandemic. The estimates are stable across samples.')
    return rob_table(g, cols, 'Robustness to the pandemic period. Women, pregnancy-loss group.', 'A13_covid', notes)

def A14():
    a = pd.read_csv(f'{RB}/RB_V15E_AGE46_D15_ipw.csv')
    def get(o,b,w,m):
        r = a[(a.outcome==o)&(a.weight==w)&(a.model==m)&(a.bin==b)]
        return (r.b.iloc[0], r.se.iloc[0]) if len(r) else (None,None)
    header = ('Outcome & Horizon & \\multicolumn{2}{c}{Unadjusted (Model~1)} & '
              '\\multicolumn{2}{c}{Fully adjusted (Model~5)}\\\\\n'
              '\\cmidrule(lr){3-4}\\cmidrule(l){5-6}\n'
              ' & & Unweighted & IP-weighted & Unweighted & IP-weighted\\\\')
    body = []
    for o in OUTS:
        dec = ODEC[o]
        for i,b_ in enumerate([4,9]):
            olab = OLAB[o] if i==0 else ''
            cells, ses = [], []
            for w,m in [('UNW',1),('IPCW',1),('UNW',5),('IPCW',5)]:
                bb,ss = get(o,b_,w,m)
                c,s = C(bb,ss,dec); cells.append(c); ses.append(s)
            body.append(f'{olab} & {BINLAB[b_]} & ' + ' & '.join(cells) + '\\\\')
            body.append(' & & ' + ' & '.join('{\\footnotesize ('+s+')}' for s in ses) + '\\\\')
        body.append('\\addlinespace')
    notes = ('Pregnancy-loss coefficients, unweighted and with inverse-probability-of-censoring '
             'weights addressing panel attrition, in the unadjusted (Model~1) and fully adjusted '
             '(Model~5) specifications. The weighted and unweighted estimates are nearly identical.')
    return wrap('Robustness to panel attrition (inverse-probability weighting). Women, pregnancy-loss group.',
                'A14_ipw', '@{}l l r r r r@{}', header, body, notes)

def A15():
    a = pd.read_stata(f'{RB}/RB_V15E_AGE46_D16_m1m5.dta', convert_categoricals=False)
    def get(o,b,sp):
        r = a[(a.outcome==o)&(a.spec==sp)&(a.bin==b)]
        return (r.b.iloc[0], r.se.iloc[0]) if len(r) else (None,None)
    header = ('Outcome & Horizon & \\multicolumn{2}{c}{Unadjusted (Model~1)} & '
              '\\multicolumn{2}{c}{Fully adjusted (Model~5)}\\\\\n'
              '\\cmidrule(lr){3-4}\\cmidrule(l){5-6}\n'
              ' & & Baseline & $+$\\,Subseq.\\ preg. & Baseline & $+$\\,Subseq.\\ preg.\\\\')
    body = []
    for o in OUTS:
        dec = ODEC[o]
        for i,b_ in enumerate([4,9]):
            olab = OLAB[o] if i==0 else ''
            cells, ses = [], []
            for sp in ['M1','M1sp','M5','M5sp']:
                bb,ss = get(o,b_,sp); c,s = C(bb,ss,dec); cells.append(c); ses.append(s)
            body.append(f'{olab} & {BINLAB[b_]} & ' + ' & '.join(cells) + '\\\\')
            body.append(' & & ' + ' & '.join('{\\footnotesize ('+s+')}' for s in ses) + '\\\\')
        body.append('\\addlinespace')
    notes = ('Pregnancy-loss coefficients without and with a control for a subsequent pregnancy, in '
             'the unadjusted (Model~1) and fully adjusted (Model~5) specifications. A subsequent '
             'pregnancy here is one that has not (yet) ended in a birth. Adding the control changes '
             'little: the operative channel is the subsequent \\emph{birth}, already in Model~5.')
    return wrap('Robustness to subsequent-pregnancy status. Women, pregnancy-loss group.',
                'A15_subseq', '@{}l l r r r r@{}', header, body, notes)

def A16():
    a = pd.read_excel(f'{RB}/RB_V15E_AGE46_D20_coefficients.xlsx')
    def g(o,b,ck):
        r = a[(a.outcome==o)&(a.bin==b)]
        if not len(r): return (np.nan,np.nan)
        return (r['b'+ck].iloc[0], r['se'+ck].iloc[0])
    cols = [('FULL_M1','All: M1'),('FULL_M5','All: M5'),('EARLY_M1','Early: M1'),('EARLY_M5','Early: M5')]
    notes = ('Pregnancy-loss coefficients for all losses versus early losses (ended under three months), '
             'unadjusted (M1) and fully adjusted (M5). Of all losses, 78\\% are early (about 80\\% of those with known timing). '
             'Restricting to early losses leaves the picture unchanged.')
    return rob_table(g, cols, 'Robustness to gestational timing. Women, pregnancy-loss group.', 'A16_gestational', notes)

TABLES = {'tableA11_decomp.tex':A11,'tableA12_balance.tex':A12,'tableA13_covid.tex':A13,
          'tableA14_ipw.tex':A14,'tableA15_subseq.tex':A15,'tableA16_gestational.tex':A16}
for fn, fun in TABLES.items():
    with open(os.path.join(OUT, fn), 'w') as f:
        f.write(fun())
    print('WROTE', fn)
