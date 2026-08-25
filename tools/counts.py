#!/usr/bin/env python3
"""Emit the per-section counts, the probe, and N — from the source, never typed.

The gate compares the probe's output against a number.  If that number is typed
by hand it describes whatever the author believed, not the file.  Both failures
this repo has had were of exactly that shape: N=49 against a 58-theorem file,
then N=65 after a second file's theorems were concatenated into the probe
without checking whether they were already in it (they were — all seven).

    python3 tools/counts.py            # print the table and N
    python3 tools/counts.py --probe    # also regenerate tools/probe.lean

Run it after editing PrincipiaVol1.lean, and set N= in tools/run.sh to what it
prints.  Nothing here reads tools/probe.lean, so the two cannot agree by
copying each other.
"""
import re, sys, pathlib

ROOT   = pathlib.Path(__file__).resolve().parent.parent
SRC    = ROOT / "PrincipiaVol1.lean"
MODULE = "PrincipiaVol1"

def scan():
    sec, counts, order = "(preamble)", {}, []
    for line in SRC.read_text(encoding="utf-8").splitlines():
        m = re.match(r"-- §(\d+)\s", line)
        if m:
            sec = "§" + m.group(1)
            if sec not in order:
                order.append(sec)
        t = re.match(r"^theorem ([A-Za-z_0-9]+)", line)
        if t:
            counts.setdefault(sec, []).append(t.group(1))
    return order, counts

def main():
    order, counts = scan()
    names, total = [], 0
    for k in order:
        v = counts.get(k, [])
        if not v:
            continue
        names += v
        total += len(v)
        print(f"{k:5s} {len(v):3d}")
    print(f"{'total':5s} {total:3d}")

    dupes = {n for n in names if names.count(n) > 1}
    if dupes:
        print("DUPLICATE THEOREM NAMES:", ", ".join(sorted(dupes)))
        return 1

    if "--probe" in sys.argv:
        out = ROOT / "tools" / "probe.lean"
        head = out.read_text(encoding="utf-8").split("import ")[0] if out.exists() else ""
        body = head + f"import {MODULE}\n\n" + "".join(
            f"#print axioms {MODULE}.{n}\n" for n in names)
        out.write_text(body, encoding="utf-8")
        print(f"wrote {out.relative_to(ROOT)} — set N={total} in tools/run.sh")
    return 0

sys.exit(main())
