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

## 3 · Neither family is repaired here, and that is deliberate

Two of the four replacement names could not be confirmed against the installed
Mathlib. This file carries Book VI Part I's machine-verified claim, which is
the worst possible place to guess at a lemma name — a wrong name that happens
to typecheck changes what was proved without changing what was claimed.

So the position is: **green at the pin, 22 known errors forward, two names
unconfirmed.** `[OPEN]`

## 4 · What would close it

- Confirm all four `nsmul_eq_mul` replacements against a v4.32 checkout.
- Confirm the `Ordinal.sup` / `Ordinal.IsLimit` successors.
- Then either bump the pin, or keep the pin and carry a v4.32 CI job in
  parallel so the two are checked independently.

Until then the pin is the claim, and this file is the asterisk.
