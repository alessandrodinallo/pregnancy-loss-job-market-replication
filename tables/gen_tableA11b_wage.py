#!/usr/bin/env python3
"""Appendix Table A12 (decomposition by block, hourly wage), as a LaTeX fragment.
Reads ../estimates/RB_V15E_AGE46_TABLEA11.csv and RB_V15E_AGE46_TABLEA11_N.csv,
writes to ./_generated.

Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
and pregnancy losses. Social Science Research, 141, 103450.
"""
import csv, os

HERE = os.path.dirname(os.path.abspath(__file__))
RB = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'estimates')
coef = {}
with open(os.path.join(RB, "RB_V15E_AGE46_TABLEA11.csv")) as f:
    for r in csv.DictReader(f):
        coef[(r["outcome"], int(r["grp"]), int(r["model"]), int(r["bin"]))] = (
            float(r["b"]), float(r["se"]), r["star"])
N = {}
with open(os.path.join(RB, "RB_V15E_AGE46_TABLEA11_N.csv")) as f:
    for r in csv.DictReader(f):
        N[(r["outcome"], int(r["model"]))] = (int(r["nobs"]), int(r["nwomen"]))

STAR = {"": "", "+": r"^{\dagger}", "*": r"^{*}", "**": r"^{**}", "***": r"^{***}"}
BINS = [(4, "0/12 after"), (6, "25/36 after"), (8, "49/60 after"), (9, "61+ after")]

rows = []
for b, lab in BINS:
    cells, ses = [], []
    for m in range(1, 6):
        bb, se, st = coef[("wage", 2, m, b)]
        cells.append(f"${bb:.3f}{STAR[st]}$")
        ses.append(r"{\footnotesize (" + f"{se:.3f}" + ")}")
    rows.append(f"{lab} & " + " & ".join(cells) + r"\\")
    rows.append(" & " + " & ".join(ses) + r"\\")

nobs, nwom = N[("wage", 5)]

tex = r"""\begin{threeparttable}
\centering
\caption{Decomposition of the pregnancy-loss wage decline by mechanism block: blocks entered separately. Women.}
\label{tab:A11b_decomp_wage}
\footnotesize
\begin{tabular}{@{}l*{5}{r}@{}}
\toprule
 & (1) & (2) & (3) & (4) & (5)\\
 & +\,Career & +\,Human cap. & +\,Health & +\,Motherhood & Full set\\
\midrule
""" + "\n".join(rows) + r"""
\bottomrule
\end{tabular}
\begin{tablenotes}[flushleft]\footnotesize
\item \textit{Notes.} Log hourly wage (conditional on positive labour earnings); """ + f"{nobs:,}" + r""" person--waves, """ + f"{nwom:,}" + r""" women (constant sample). Cluster-robust standard errors (by woman) in parentheses. $^{\dagger}\,p<0.1$, $^{*}\,p<0.05$, $^{**}\,p<0.01$, $^{***}\,p<0.001$.
As in the earnings table above, each of columns (1)--(4) adds \emph{one} mechanism block on its own to the baseline controls; column (5) includes the full set. Reference period 24--13 months before. The short-run wage decline (0--12 months) is essentially unchanged by every block taken separately; at longer horizons the human-capital block absorbs the most, followed by the subsequent-motherhood transition.
\end{tablenotes}
\end{threeparttable}
"""

os.makedirs(os.path.join(HERE, "_generated"), exist_ok=True)
out = os.path.join(HERE, "_generated", "tableA11b_decomp_wage.tex")
with open(out, "w") as f:
    f.write(tex)
print("scritto", os.path.relpath(out, HERE))
