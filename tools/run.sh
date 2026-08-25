#!/usr/bin/env bash
# Verify the Lean behind the Principia Orthogona Volume I deposit.
#
#   bash tools/run.sh
#
# This is a small repo on purpose.  AXLE is too large to build for one
# check; this one holds the deposited Lean and answers a single question:
# does it compile, and is every theorem in it really checked by the kernel?
#
# CHANGED 2026-08-25, three defects, all of the same shape -- a check whose
# scope was set by the thing being checked:
#
#   1. N was 49, "theorems named in the probe".  The file declares 58.  The
#      gate compared the probe's output to a number describing the probe, so
#      nine V7 theorems were never asked about and the gate went green
#      anyway.  N now describes the FILE, and tools/counts.py emits both the
#      probe and the number from the source so they cannot disagree again.
#
#   2. lake build Vol1 built a target named for the library, not the module.
#      `lake build` with no argument now builds every default target.
#
#   3. tools/axiom_gate.py failed OPEN on Lean's wrapped output: a theorem
#      whose axiom list spanned lines had its continuation lines dropped
#      before the sorryAx check, and its bracket regex never matched, so an
#      admitted theorem passed.  Replaced with the fixtured gate from the
#      geometry repository, which has the run #245 output as a regression case.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$ROOT" || exit 1

PROBE="tools/probe.lean"
OUT="tools/axioms.txt"
N=58                                    # theorems declared in PrincipiaVol1.lean

command -v lake >/dev/null 2>&1 || {
  echo "lake not found. Install elan first:"
  echo "  curl -sSfL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | sh"
  exit 127; }

echo "toolchain pinned : $(cat lean-toolchain)"
echo "mathlib pinned   : $(python3 -c "import json;print(json.load(open('lake-manifest.json'))['packages'][0]['rev'])" 2>/dev/null || echo '?')"
echo

echo "-- 0/4  gate self-test -----------------------------------------------"
# The gate is a claim about the artifact it guards, and is subject to the same
# rule as any other claim here: it has to be checked.  Run it on its fixtures
# BEFORE trusting its verdict below.
python3 tools/test_axiom_gate.py || {
  echo "GATE SELF-TEST FAILED - the instrument is broken. Nothing below counts."
  exit 1; }

echo
echo "-- 1/4  lake build ---------------------------------------------------"
lake exe cache get || echo "  (mathlib cache miss - this will build from source, slowly)"
lake build 2>&1 | tee tools/build.log || true
if ! grep -q "Build completed successfully" tools/build.log; then
  echo "BUILD FAILED - the Lean does not compile. Nothing below is meaningful."
  exit 1
fi

echo
echo "-- 2/4  informational: sorry warnings ---------------------------------"
# Lean writes: declaration uses `sorry`  -- BACKTICKS, not quotes. A grep
# written as 'sorry' matches nothing and prints 0, which reads as clean.
# Reported, never gating: `lake build` exits 0 with sorrys present.
grep -n 'declaration uses' tools/build.log || echo "  (none)"

echo
echo "-- 3/4  kernel axiom probe -------------------------------------------"
lake env lean "$PROBE" > "$OUT" 2>&1
rc=$?
cat "$OUT"
[ "$rc" -ne 0 ] && { echo; echo "PROBE FAILED TO ELABORATE (exit $rc)."; exit 1; }

echo
echo "-- 4/4  axiom gate ---------------------------------------------------"
python3 tools/axiom_gate.py "$OUT" "$N"
gate=$?
echo
if [ "$gate" -ne 0 ]; then
  echo "RED - read the report above."
else
  echo "GREEN - $N theorems, kernel-checked, no sorryAx, allowlist clean."
fi
exit $gate
