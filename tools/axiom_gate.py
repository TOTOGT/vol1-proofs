#!/usr/bin/env python3
"""Axiom gate for the Volume I deposit.

Reads the output of `lake env lean tools/probe.lean` and refuses unless
every named theorem is kernel-checked, none depends on sorryAx, and every
axiom named is on the allowlist.  Exit 0 = green, 1 = red.
"""
import re, sys

ALLOW = {"propext", "Classical.choice", "Quot.sound"}

def main(path, expected):
    txt = open(path, encoding="utf-8").read()
    if "error:" in txt:
        print("RED — the probe did not elaborate:")
        print(txt[:2000]); return 1
    lines = [l for l in txt.splitlines() if l.startswith("'")]
    if len(lines) != expected:
        print(f"RED — expected {expected} theorems, the probe reported {len(lines)}.")
        print("      Either a theorem was renamed/removed or the probe is stale.")
        return 1
    bad = []
    for l in lines:
        name = l.split("'")[1]
        if "sorryAx" in l:
            bad.append((name, "ADMITTED (sorryAx)")); continue
        m = re.search(r"axioms: \[(.*)\]", l)
        axs = {a.strip() for a in m.group(1).split(",")} if m else set()
        extra = axs - ALLOW
        if extra:
            bad.append((name, "axiom outside allowlist: " + ", ".join(sorted(extra))))
    if bad:
        print("RED — the gate refused:")
        for n, why in bad:
            print(f"  {n}: {why}")
        return 1
    print(f"GREEN — {expected} theorems, every one kernel-checked.")
    print("        No sorryAx.  No axiom beyond propext / Classical.choice / Quot.sound.")
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1], int(sys.argv[2])))
