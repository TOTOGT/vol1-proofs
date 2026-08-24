#!/usr/bin/env bash
# Verify the Lean behind the Principia Orthogona Volume I deposit.
#
#   bash tools/run.sh
#
# This is a small repo on purpose.  AXLE is too large to build for one
# check; this one holds a single file and answers a single question:
# does the deposited Lean compile, and is every theorem in it really
# checked by the kernel?
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$ROOT" || exit 1

PROBE="tools/probe.lean"
OUT="tools/axioms.txt"
N=49                                    # theorems named in the probe

command -v lake >/dev/null 2>&1 || {
  echo "lake not found. Install elan first:"
  echo "  curl -sSfL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | sh"
  exit 127; }

echo "toolchain pinned : $(cat lean-toolchain)"
echo "mathlib pinned   : $(python3 -c "import json;print(json.load(open('lake-manifest.json'))['packages'][0]['rev'])" 2>/dev/null || echo '?')"
echo

echo "-- 1/3  lake build --------------------------------------------------"
lake exe cache get || echo "  (mathlib cache miss - this will build from source, slowly)"
lake build Vol1 || {
  echo "BUILD FAILED - the Lean does not compile. Nothing below is meaningful."
  exit 1; }

echo
echo "-- 2/3  kernel axiom probe ------------------------------------------"
lake env lean "$PROBE" > "$OUT" 2>&1
rc=$?
cat "$OUT"
[ "$rc" -ne 0 ] && { echo; echo "PROBE FAILED TO ELABORATE (exit $rc)."; exit 1; }

echo
echo "-- 3/3  axiom gate --------------------------------------------------"
python3 tools/axiom_gate.py "$OUT" "$N"
gate=$?
echo
if [ "$gate" -ne 0 ]; then
  echo "RED - read the report above."
fi
exit $gate
