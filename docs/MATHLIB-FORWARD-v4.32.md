# Forward compatibility: Mathlib v4.32.0

This repository is **pinned to `leanprover/lean4:v4.14.0`** with Mathlib at
`4bbdccd9c5f862bf90ff12f0a9e2c8be032b9a84` (December 2024). At that pin the
build is green and the axiom report is clean. This file records what happens
at a much newer Mathlib, so the debt is visible rather than discovered.

Probed 2026-09-13 against **v4.32.0**.

## 1 · One module moved

```
v4.14.0   Mathlib.Data.Complex.ExponentialBounds       <- what this repo imports
v4.32.0   Mathlib.Analysis.Complex.ExponentialBounds
```

`Real.exp_one_lt_d9` lives in the second by v4.32. The path was read off the
installed tree, not recalled.

**This matters more than a renamed module usually would.** A failed import
stops elaboration, so a run against v4.32 reported `FAIL (1 error)` — which
means *one error before the stop*, not one error in the file. The count was an
artifact of the failure mode.

## 2 · With the import resolved, 22 errors appear, in two families

| family | count | what it is |
|---|---|---|
| `nsmul_eq_mul` shadowing | 4 | `open Ordinal` brings an `Ordinal` lemma into scope that is selected for a **real-valued** goal, so the rewrite picks the wrong lemma |
| ordinal API renames | 18 | `Ordinal.sup` and `Ordinal.IsLimit` were renamed upstream |

## 3 · The names are now confirmed — 2026-09-18

This section previously said two of the four replacement names could not be
confirmed. **All four are now confirmed**, read off geometry's vendored v4.32
tree rather than recalled:

| broken | replacement | confirmed at |
|---|---|---|
| `nsmul_eq_mul` under `open Ordinal` | `_root_.nsmul_eq_mul` | `Ordinal/Arithmetic.lean:653` declares the shadowing Ordinal lemma |
| `Ordinal.sup` | `⨆` / `iSup` — `Ordinal.le_iSup`, `Ordinal.iSup_le` | `Ordinal/Family.lean`; `sup` deprecated 2025-12-25, `bsup` 2026-04-05 |
| `Ordinal.IsLimit` | `Order.IsSuccLimit` | `Ordinal/Arithmetic.lean:39`, `isSuccLimit_iff` at :126 |
| `Mathlib.Data.Complex.ExponentialBounds` | `Mathlib.Analysis.Complex.ExponentialBounds` | applied at the pin's inverse; see §1 |

**Nothing in the port requires a guess any more.** What remains is mechanical.

## 3b · Why it was still not repaired on 2026-09-13

At that date two of the four could not be confirmed. This file carries Book VI Part I's machine-verified claim, which is
the worst possible place to guess at a lemma name — a wrong name that happens
to typecheck changes what was proved without changing what was claimed.

## 4 · The port, and the one family it missed — 2026-09-18 through 2026-09-22

0ba9503 (2026-09-18) applied three of the four confirmed replacements — the
`nsmul_eq_mul` shadowing fix (4 sites), the `Ordinal.sup`/`Ordinal.lt_sup`
family (→ `⨆`/`Ordinal.lt_iSup_iff`), and `Ordinal.IsLimit` → `Order.IsSuccLimit`.
It bumped `lean-toolchain` and `lakefile.toml` to v4.32.0 / Mathlib 81a5d257c8
(geometry's exact pin) and pushed the branch for CI to judge, exactly as R22
in geometry's CLAUDE.md asks.

**It did not touch the `Mathlib.Data.Complex.ExponentialBounds` import** —
row 1 of this document, the one family that was never in doubt (§1 confirmed
it 2026-09-13). CI run #9 on that commit (5e49766, the header-restore commit
immediately after) failed in the `Verify (gate self-test, build, probe,
gate)` step. The full log is behind GitHub sign-in and was not reachable from
this session; what confirms the cause instead is checking geometry's own
vendored Mathlib tree at the exact pinned revision directly —
`Mathlib/Analysis/Complex/ExponentialBounds.lean` exists there,
`Mathlib/Data/Complex/ExponentialBounds.lean` does not. An unresolved import
stops elaboration before anything else in the file runs, which matches §1's
own note that a failed import here reports as one error, not the real count.

**Fixed 2026-09-22**, same branch (`port-v4.32`): the import now reads
`Mathlib.Analysis.Complex.ExponentialBounds`. All four families are now
applied in the code. Delimiter/bracket balance was checked as a sanity pass
(no local toolchain here either) — that is not a compile.

So the position was: all four fixes applied, not yet confirmed. **Pushed
2026-09-22 (`fc2b49b`), and it did not close the loop -- CI run #11 failed
again, in 45s.** That is faster than run #9's 1m8s (the pre-fix failure), not
slower, which does not fit "the same import problem, now one line further
into the file" -- it fits something failing even earlier than `lake build`
reaching `PrincipiaVol1.lean` at all.

**Found by reading the dependency files, not the log (still sign-in-gated):**
`lake-manifest.json` -- the lockfile `lake` actually resolves `.lake/packages`
against -- was never updated when `0ba9503` bumped `lakefile.toml`'s mathlib
`rev` to `81a5d257c8`. It still reads `4bbdccd9c5f8` (the v4.14.0 rev), and
every transitive dependency with it: `importGraph`, `aesop`, `batteries` all
still pinned to their `v4.14.0` tags, `proofwidgets` to `v0.0.47` -- the whole
v4.14.0-era dependency set, untouched. `lakefile.toml` and `lake-manifest.json`
now name two different Mathlib revisions for the same build. Lake does not
silently split that difference: either it refuses outright ("manifest out of
date," a fast, clean error) or it builds against whatever the manifest says
-- the old rev -- in which case an import written for the new rev (this
session's `Mathlib.Analysis.Complex.ExponentialBounds` fix, correct at
`81a5d257c8`, wrong at `4bbdccd9c5f8`) fails to resolve for the same reason
the old import used to. Either mechanism produces exactly what was observed:
a fast failure, without needing a second Lean-level bug. **This is inference
from the manifest's own content, stated as inference -- the actual GitHub
Actions log for run #11 was not read, only its duration and the step it
failed on.**

`[OPEN]`, and differently open than it looked a few hours earlier: the four
named families were real and are genuinely fixed, but they were never
sufficient on their own, because the lockfile was never regenerated for the
new pin. That regeneration is `lake update` (or `lake update mathlib`),
which needs an actual Lake/Lean install to resolve a mutually-compatible
revision set for `mathlib`, `aesop`, `batteries`, `importGraph`,
`proofwidgets`, `Qq`, `plausible`, `LeanSearchClient`, `Cli` at v4.32.0 -- not
something to hand-edit. Guessing eight interdependent revisions into a JSON
file so it "looks resolved" is exactly the failure mode this project exists
to catch; better to leave it `[OPEN]` and named than to paper over it.

## 5 · What would close it

- **Run `lake update` (or `lake update mathlib`) against `lakefile.toml`'s
  `81a5d257c8` pin, on a machine with a real Lake/Lean install, and commit the
  regenerated `lake-manifest.json`.** This is the actual blocking step now --
  everything else in this document is already done.
- Then push, let CI run, and this time read the actual result -- not a
  duration and a step name, the real pass/fail and, if it fails, the real
  error text.
- If green: confirm the axiom report is unchanged from the v4.14.0 baseline
  (58 `PrincipiaVol1` + 24 `AutophagyDm3` = 82, 0 sorry, same three axioms),
  then the file moves into geometry per R22 and the claims get tagged per R21.
- If not green: the new error list is the next piece of work, same discipline
  as before -- no replacement name goes in without being read off the pinned
  tree first.
