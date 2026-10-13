#!/usr/bin/env python3
"""Appendix Table A19 (Model 1 without the couple controls), as a LaTeX fragment.
Reads ../estimates/RB_V15E_AGE46_NOCOUPLE.csv and RB_V15E_AGE46_NOCOUPLE_N.csv,
writes to ./_generated.

Replication package for: Di Nallo, A. (2026). Women's job market outcomes around live births
and pregnancy losses. Social Science Research, 141, 103450.
"""
import csv, os
HERE = os.path.dirname(os.path.abspath(__file__))
RB = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'estimates')
coef = {}
with open(os.path.join(RB, "RB_V15E_AGE46_NOCOUPLE.csv")) as f:
    for r in csv.DictReader(f):
        coef[(r["outcome"], int(r["grp"]), r["spec"], int(r["bin"]))] = (
            float(r["b"]), float(r["se"]), r["star"])
N = {}
with open(os.path.join(RB, "RB_V15E_AGE46_NOCOUPLE_N.csv")) as f:
    for r in csv.DictReader(f):
        N[r["outcome"]] = (int(r["nobs"]), int(r["nwomen"]))

STAR = {"": "", "+": r"^{\dagger}", "*": r"^{*}", "**": r"^{**}", "***": r"^{***}"}
BINS = [(1,"25+ before"),(3,"12/1 before"),(4,"0/12 after"),(5,"13/24 after"),
        (6,"25/36 after"),(7,"37/48 after"),(8,"49/60 after"),(9,"61+ after")]

def cell(out, spec, b):
    bb, se, st = coef[(out, 2, spec, b)]
    d = 3 if out == "wage" else 2
    return f"${bb:.{d}f}{STAR[st]}$", r"{\footnotesize (" + f"{se:.{d}f}" + ")}"

rows = []
for b, lab in BINS:
    cs = [cell("earnings","M1",b), cell("earnings","M1nc",b),
          cell("wage","M1",b), cell("wage","M1nc",b)]
    rows.append(f"{lab} & " + " & ".join(c[0] for c in cs) + r"\\")
    rows.append(" & " + " & ".join(c[1] for c in cs) + r"\\")

nob_e, nw_e = N["earnings"]; nob_w, nw_w = N["wage"]

tex = r"""\begin{threeparttable}
\centering
\caption{Baseline (unadjusted) model without the partnership controls: pregnancy-loss group. Women.}
\label{tab:A19_nocouple}
\footnotesize
\begin{tabular}{@{}l*{4}{r}@{}}
\toprule
 & \multicolumn{2}{c}{Labour income} & \multicolumn{2}{c}{Log hourly wage}\\
\cmidrule(lr){2-3}\cmidrule(lr){4-5}
 & Baseline & No couple & Baseline & No couple\\
\midrule
""" + "\n".join(rows) + r"""
\bottomrule
\end{tabular}
\begin{tablenotes}[flushleft]\footnotesize
\item \textit{Notes.} Pregnancy-loss coefficients from the baseline model (age, region, calendar period, and the partnership context: partnership status and the partner's lagged earnings) versus the same model with the two partnership controls removed (``No couple''). Labour income: """ + f"{nob_e:,}" + r""" person--waves, """ + f"{nw_e:,}" + r""" women; log hourly wage (conditional on positive earnings): """ + f"{nob_w:,}" + r""" person--waves, """ + f"{nw_w:,}" + r""" women. Cluster-robust standard errors (by woman) in parentheses. $^{\dagger}\,p<0.1$, $^{*}\,p<0.05$, $^{**}\,p<0.01$, $^{***}\,p<0.001$. Reference period 24--13 months before. Dropping the partnership controls leaves the estimates essentially unchanged, so the baseline result does not rest on conditioning on partnership status (which a pregnancy loss could in principle affect).
\end{tablenotes}
\end{threeparttable}
"""
os.makedirs(os.path.join(HERE, "_generated"), exist_ok=True)
out = os.path.join(HERE, "_generated", "tableA19_nocouple.tex")
with open(out, "w") as f:
    f.write(tex)
print("scritto", os.path.relpath(out, HERE))
