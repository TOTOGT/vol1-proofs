#!/usr/bin/env python3
"""Emit the per-section counts, the probe, and N — from the sources, never typed.

The gate compares the probe's output against a number.  If that number is typed
by hand it describes whatever the author believed, not the files.  Every count
failure this repo has had was that shape: N=49 against a 58-theorem file, then
N=65 after a second file's theorems were concatenated in without checking
whether they were already present (all seven were).

    python3 tools/counts.py            # print the table and N
    python3 tools/counts.py --probe    # also regenerate tools/probe.lean

Run it after editing either source, and set N= in tools/run.sh to what it
prints.  Nothing here reads tools/probe.lean, so the two cannot agree by
copying each other.

Note the identifier pattern.  It was `[A-Za-z_0-9]+`, which does not match `Φ`
— so `Φ_pos` vanished from the count and `dΦ_at_threshold` became a probe for
a constant named `d`.  Greek is ordinary in this corpus; the pattern now stops
at whitespace or a delimiter instead of guessing the alphabet.
"""
import re, sys, pathlib

ROOT    = pathlib.Path(__file__).resolve().parent.parent
SOURCES = [("PrincipiaVol1",   "PrincipiaVol1",   ROOT / "PrincipiaVol1.lean"),
           ("AutophagyDm3_v2", "AutophagyDm3",    ROOT / "AutophagyDm3_v2.lean")]

DECL = re.compile(r"^(?:theorem|lemma)\s+([^\s(:{]+)")
SEC  = re.compile(r"-- §(\d+)\s")

def scan(path):
    # `order` is seeded with the pre-banner bucket.  It was not, and any
    # declaration appearing before the first `-- §N` banner was counted into a
    # bucket that was never printed and never summed: AutophagyDm3_v2.lean has
    # no banners at all and reported 0 of its 24 theorems.  A counter that
    # silently omits is the exact failure this script exists to prevent.
    sec, counts, order = "(top)", {}, ["(top)"]
    for line in path.read_text(encoding="utf-8").splitlines():
        m = SEC.match(line)
        if m:
            sec = "§" + m.group(1)
            if sec not in order:
                order.append(sec)
        d = DECL.match(line)
        if d:
            counts.setdefault(sec, []).append(d.group(1))
    return order, counts

def main():
    entries, grand = [], 0
    for module, ns, path in SOURCES:
        if not path.exists():
            print(f"  {module}: MISSING {path}")
            return 1
        order, counts = scan(path)
        names, sub = [], 0
        print(f"{module}:")
        for k in order:
            v = counts.get(k, [])
            if not v:
                continue
            names += v
            sub += len(v)
            print(f"  {k:5s} {len(v):3d}")
        print(f"  {'sub':5s} {sub:3d}")
        dupes = {n for n in names if names.count(n) > 1}
        if dupes:
            print("  DUPLICATE NAMES:", ", ".join(sorted(dupes)))
            return 1
        entries.append((ns, names))
        grand += sub
    print(f"{'TOTAL':7s} {grand:3d}")

    if "--probe" in sys.argv:
        out = ROOT / "tools" / "probe.lean"
        head = out.read_text(encoding="utf-8").split("import ")[0] if out.exists() else ""
        body = head
        for module, _, _ in SOURCES:
            body += f"import {module}\n"
        body += "\n"
        for ns, names in entries:
            for n in names:
                body += f"#print axioms {ns}.{n}\n"
        out.write_text(body, encoding="utf-8")
        print(f"wrote {out.relative_to(ROOT)} — set N={grand} in tools/run.sh")
    return 0

sys.exit(main())
