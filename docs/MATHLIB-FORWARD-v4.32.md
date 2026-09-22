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

So the position is: **all four fixes applied, not yet confirmed by a real
kernel.** CI on the next push to `port-v4.32` is what actually judges it, per
R22's own order of operations — a green run there is step 2, not this note.
`[OPEN]` until that run is green and the axiom report still reads 82
theorems / 0 sorry / `propext, Classical.choice, Quot.sound` only.

## 5 · What would close it

- Push this fix, let CI run, read the result — not the log excerpt this
  session could reach, the actual pass/fail.
- If green: confirm the axiom report is unchanged from the v4.14.0 baseline
  (58 `PrincipiaVol1` + 24 `AutophagyDm3` = 82, 0 sorry, same three axioms),
  then the file moves into geometry per R22 and the claims get tagged per R21.
- If not green: the new error list is the next piece of work, and — same
  discipline as before — no replacement name goes in without being read off
  the pinned tree first.
