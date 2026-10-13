#!/usr/bin/env python3
"""Tables 1 and 2 of the article, as LaTeX fragments.
Reads the estimates in ../estimates, writes to ./_generated.
Usage: python3 gen_tables_main.py [--estimates DIR] [--out DIR] [--force]

Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
and pregnancy losses. Social Science Research, 141, 103450.
"""
import argparse
import math
import os
import sys

import pandas as pd

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_OUT = os.path.join(HERE, '_generated')
DEFAULT_ESTIMATES = os.path.normpath(os.path.join(HERE, '..', 'estimates'))
INPUTS = ['RB_V15E_AGE46_TABLE1.csv', 'RB_V15E_AGE46_TABLE1_N.csv',
          'RB_V15E_AGE46_TABLEA11.csv', 'RB_V15E_AGE46_TABLEA11_N.csv',
          'RB_V15E_AGE46_TABLEA11_OTHER.csv', 'RB_V15E_AGE46_TABLEA11_OTHER_N.csv']

STAR = {'': '', '+': '^{\\dagger}', '*': '^{*}', '**': '^{**}', '***': '^{***}'}
BINS = [(1, '25+ before'), (3, '12/1 before'), (4, '0/12 after'), (5, '13/24 after'),
        (6, '25/36 after'), (7, '37/48 after'), (8, '49/60 after'), (9, '61+ after')]
GRP = [(1, 'live birth'), (2, 'pregnancy loss')]
KEY = ['outcome', 'grp', 'model', 'bin']

T2_OUTCOMES = [('earnings', 'Labour earnings (2015 GBP)', 2),
               ('wage', 'Hourly wage (log)', 3),
               ('employed', 'Employment (probability)', 3),
               ('workhrs', 'Weekly work hours', 2),
               ('workhrs_cond', 'Conditional work hours (log)', 3)]
T2_BINS = [(4, '0/12 after'), (9, '61+ after')]


def star_of(x):
    return '' if pd.isna(x) else str(x).strip()


def cell(b, se, star, dec):
    """Coefficient with significance marker, and its standard error, as strings."""
    assert math.isfinite(b) and math.isfinite(se) and se > 0, f'invalid estimate: b={b}, se={se}'
    b_s = f'{b:.{dec}f}'
    if float(b_s) == 0:
        b_s = b_s.lstrip('-')          # never print a negative zero
    return f'${b_s}{STAR[star_of(star)]}$', f'{se:.{dec}f}'


def se_cell(s):
    return '{\\footnotesize (' + s + ')}'


def one(df, **keys):
    """The single row of df that matches the given column values."""
    m = pd.Series(True, index=df.index)
    for k, v in keys.items():
        m &= df[k] == v
    rows = df[m]
    assert len(rows) == 1, f'expected exactly one row for {keys}, found {len(rows)}'
    return rows.iloc[0]


def load(rb):
    """Read the six input files and check that they describe the same models and samples."""
    t1 = pd.read_csv(os.path.join(rb, INPUTS[0]))
    t1n = pd.read_csv(os.path.join(rb, INPUTS[1]))
    blocks = pd.concat([pd.read_csv(os.path.join(rb, INPUTS[2])),
                        pd.read_csv(os.path.join(rb, INPUTS[4]))], ignore_index=True)
    blocksn = pd.concat([pd.read_csv(os.path.join(rb, INPUTS[3])),
                         pd.read_csv(os.path.join(rb, INPUTS[5]))], ignore_index=True)

    for name, df in (('TABLE1', t1), ('blocks', blocks)):
        assert not df.duplicated(KEY).any(), f'duplicate (outcome, grp, model, bin) in {name}'

    a = t1n.set_index(['outcome', 'model'])[['nobs', 'nwomen']].sort_index()
    b = blocksn.set_index(['outcome', 'model'])[['nobs', 'nwomen']].sort_index()
    assert a.equals(b), 'sample sizes differ between the TABLE1 and the blocks files'

    for m_t1, m_bl in ((5, 5), (2, 4)):
        x = t1[t1.model == m_t1].set_index(['outcome', 'grp', 'bin'])[['b', 'se']].sort_index()
        y = blocks[blocks.model == m_bl].set_index(['outcome', 'grp', 'bin'])[['b', 'se']].sort_index()
        assert x.index.equals(y.index), 'TABLE1 and blocks files cover different cells'
        rel = ((x - y).abs() / x.abs().clip(lower=1e-12)).to_numpy().max()
        assert rel < 1e-8, (f'TABLE1 model {m_t1} and blocks model {m_bl} disagree '
                            f'(max relative difference {rel:.2e}): the files come from different runs')
    return t1, t1n, blocks


def table1(t1, t1n):
    do = t1[t1.outcome == 'earnings']
    no = t1n[t1n.outcome == 'earnings'].set_index('model')
    L = ['% labour-earnings event-study table (generated fragment)',
         '\\begin{threeparttable}',
         '\\centering',
         '\\caption{Trajectories of labour earnings around live births and pregnancy losses. '
         'Coefficients from an event study (both event-time series estimated in a single '
         'model). Women.}',
         '\\label{tab:table1_earnings}',
         '\\footnotesize',
         '\\begin{tabular}{@{}l*{5}{r}@{}}',
         '\\toprule',
         ' & (1) & (2) & (3) & (4) & (5)\\\\',
         '\\midrule']
    for g, gname in GRP:
        L.append(f'\\addlinespace\\multicolumn{{6}}{{@{{}}l}}{{\\textbf{{Months '
                 f'before/after {gname} \\emph{{(reference: 24--13 months before)}}}}}}\\\\')
        for b_, blab in BINS:
            cells, ses = [], []
            for m in range(1, 6):
                r = one(do, grp=g, bin=b_, model=m)
                c, s = cell(r.b, r.se, r.star, 2)
                cells.append(c)
                ses.append(s)
            L.append(f'{blab} & ' + ' & '.join(cells) + '\\\\')
            L.append(' & ' + ' & '.join(se_cell(s) for s in ses) + '\\\\')
    L += ['\\addlinespace\\midrule',
          'Baseline controls & Yes & Yes & Yes & Yes & Yes\\\\',
          '(Another) motherhood transition & No & Yes & Yes & Yes & Yes\\\\',
          'Career characteristics & No & No & Yes & Yes & Yes\\\\',
          'Human capital & No & No & No & Yes & Yes\\\\',
          'Health & No & No & No & No & Yes\\\\']
    obs = ' & '.join(f"${int(no.loc[m, 'nobs']):,}$" for m in range(1, 6))
    nw = ' & '.join(f"${int(no.loc[m, 'nwomen']):,}$" for m in range(1, 6))
    L += [f'Observations & {obs}\\\\',
          f'Number of women & {nw}\\\\',
          '\\bottomrule',
          '\\end{tabular}',
          '\\begin{tablenotes}[flushleft]\\footnotesize',
          '\\item \\textit{Notes.} Cluster-robust standard errors (by woman) in parentheses. '
          'All columns come from a single model per outcome, estimated on the pooled sample '
          'with live births and pregnancy losses entered as separate sets of event-time '
          'indicators; Models 2--5 are nested specifications that add mediator blocks to '
          'Model 1. Health enters only in Model 5, not in the baseline specification.',
          '$^{\\dagger}\\,p<0.1$, $^{*}\\,p<0.05$, $^{**}\\,p<0.01$, $^{***}\\,p<0.001$.',
          'Baseline controls: age (quadratic), marital status, partner income, region, and period.',
          'Model~(1) is unadjusted; models (2)--(5) add mechanism blocks sequentially.',
          '\\end{tablenotes}',
          '\\end{threeparttable}']
    return '\n'.join(L) + '\n'


def table2(t1, blocks):
    L = ['% Table 2 (main) — compact separate-entry decomposition, pregnancy-loss group, '
         'all five outcomes',
         '\\begin{threeparttable}',
         '\\centering',
         '\\caption{Decomposition of the pregnancy-loss trajectory: each mediator block '
         'entered on its own. All five outcomes in the short and long term. Women.}',
         '\\label{tab:decomp_main}',
         '\\footnotesize',
         '\\begin{tabular}{@{}l*{6}{r}@{}}',
         '\\toprule',
         ' & Baseline & +Career & +Human cap. & +Health & +Subs. birth & Full\\\\',
         '\\midrule']
    for i, (out, head, dec) in enumerate(T2_OUTCOMES):
        if i:
            L.append('\\addlinespace')
        L.append(f'\\multicolumn{{7}}{{@{{}}l}}{{\\textbf{{{head}}}}}\\\\')
        for b_, blab in T2_BINS:
            base = one(t1, outcome=out, grp=2, model=1, bin=b_)
            pairs = [cell(base.b, base.se, base.star, dec)]
            for m in range(1, 6):
                r = one(blocks, outcome=out, grp=2, model=m, bin=b_)
                pairs.append(cell(r.b, r.se, r.star, dec))
            L.append(f'{blab} & ' + ' & '.join(c for c, _ in pairs) + '\\\\')
            L.append(' & ' + ' & '.join(se_cell(s) for _, s in pairs) + '\\\\')
    L += ['\\bottomrule',
          '\\end{tabular}',
          '\\begin{tablenotes}[flushleft]\\footnotesize',
          '\\item \\textit{Notes.} Pregnancy-loss coefficients from the single model per '
          'outcome. Short term = 0 to 12 months after the end of the pregnancy; long term = '
          '61 or more months. Baseline adjusts only for background characteristics (Model 1). '
          'Each middle column adds one mediator block to the baseline (career characteristics; '
          'human capital; health; subsequent birth); Full includes all blocks. The blocks '
          'overlap, so the movements are not additive. Live-birth coefficients and all '
          'horizons for labour income and the hourly wage are in Tables A11 and A12. '
          'Cluster-robust standard errors (by woman) in parentheses. '
          '$^{\\dagger}\\,p<0.1$, $^{*}\\,p<0.05$, $^{**}\\,p<0.01$, $^{***}\\,p<0.001$.',
          '\\end{tablenotes}',
          '\\end{threeparttable}']
    return '\n'.join(L) + '\n'


def main():
    ap = argparse.ArgumentParser(description='Generate Table 1 and Table 2 of the article.')
    ap.add_argument('--estimates', help='folder with the aggregate estimates '
                    '(default: ../estimates)')
    ap.add_argument('--out', default=DEFAULT_OUT, help='output folder (default: ./_generated)')
    ap.add_argument('--force', action='store_true',
                    help='allow overwriting files in an output folder other than the default')
    args = ap.parse_args()

    rb = args.estimates or DEFAULT_ESTIMATES
    if not os.path.isdir(rb):
        sys.exit('Estimates folder not found. Pass it with --estimates DIR.')
    missing = [f for f in INPUTS if not os.path.isfile(os.path.join(rb, f))]
    if missing:
        sys.exit(f'Missing input files in {rb}: ' + ', '.join(missing))

    t1, t1n, blocks = load(rb)
    texts = {'table1_earnings.tex': table1(t1, t1n), 'table2_decomp.tex': table2(t1, blocks)}

    out = os.path.abspath(args.out)
    is_default = out == os.path.abspath(DEFAULT_OUT)
    clash = [f for f in texts if os.path.exists(os.path.join(out, f))]
    if clash and not is_default and not args.force:
        sys.exit(f'Refusing to overwrite {", ".join(clash)} in {out}. Use --force to allow it.')

    os.makedirs(out, exist_ok=True)
    for fname, text in texts.items():
        path = os.path.join(out, fname)
        with open(path, 'w', encoding='utf-8', newline='\n') as f:
            f.write(text)
        print('wrote', path)


if __name__ == '__main__':
    main()
