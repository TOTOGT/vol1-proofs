# vol1-proofs

The Lean behind **Principia Orthogona, Volume I: The Mathematics of Generative
Transitions** (Zenodo V7: [10.5281/zenodo.22084842](https://doi.org/10.5281/zenodo.22084842) · concept DOI:
[10.5281/zenodo.19117399](https://doi.org/10.5281/zenodo.19117399)),
in a repo small enough to build.

G6 LLC · Pablo Nogueira Grossi · Newark NJ · 2026

## Why this repo exists

AXLE holds the whole corpus and is too large to build for a single check.
This repo holds one file and answers one question:

> Does the Lean behind the Volume I deposit compile, and is every theorem in
> it really checked by the kernel?

Run it:

```sh
bash tools/run.sh
```

Three stages — build, `#print axioms` probe over every named theorem, then a
gate that refuses on `sorryAx` or on any axiom outside the allowlist.

## Current state (V7)

```
toolchain   leanprover/lean4:v4.14.0
mathlib     v4.14.0  (rev 4bbdccd9c5f862bf90ff12f0a9e2c8be032b9a84)
theorems    58
sorry       0
axioms      propext, Classical.choice, Quot.sound — nothing else
```

## What V7 fixed

V6 described `PrincipiaVol1.lean` as *"30+ facts proved without sorry, 1
scoped sorry at an eigenvalue API boundary."*

Built in August 2026 against the Mathlib revision this repo pins — v4.14.0,
December 2024 — it produced **81 errors**
([`record/v6-build-errors.txt`](record/v6-build-errors.txt)).

That is drift, not neglect. `Ordinal.sup` and `Ordinal.lt_sup` were deprecated
2024-08-27; `Ordinal.IsLimit.add_right` was renamed `isLimit_add` 2024-10-11;
`Set.finite_insert` is the Mathlib-3 spelling of `Set.Finite.insert`. Those are
the names the file uses — current when it was written and run. Mathlib moved,
the pin advanced past the code, later hand-edits were never rebuilt, and with
no CI nothing re-ran the build. The V6 file is kept in
[`record/`](record/PrincipiaVol1-V6-as-deposited.lean.txt) so the two can be
diffed.

V7 brings the file to the pin — structure fields, instance arguments, the
Ordinal API, the club-filter chain, the ℤ carrier — all marked `V7 FIX` in
place. **This repo exists so the next drift is caught the day it happens.**

### The separation theorem

Not mechanical, and the reason this is a V7 rather than a patch.

V6 deposited

```lean
theorem separation_theorem (hn : n < 33) (M) (hM : IsDm3Stable M) :
    M.trace ≠ 33
```

with one `sorry` attributed to a missing Mathlib eigenvalue API (O1, AXLE
issue #12). Two things were wrong with that.

**The statement is false, not unfinished.** `IsDm3Stable` bounds the
transverse diagonal entries and says nothing about `M 0 0`. At `n = 1` it
holds vacuously and the 1×1 matrix `(33)` has trace 33. The refutation is
proved in the file as `v6_separation_statement_is_false`. No amount of
eigenvalue API would have closed it — a hypothesis was missing, not a lemma.

**The intended argument is the sixth power.** Book 2 Theorem 12.2 and both
ancestor files (`main_v7.lean` Part H, `AXLE_v6.lean` Part H) state
`Tr(M⁶) ≠ 33`, with `|Tr − 1| ≤ (n−1)·e⁻¹² < 1/32`. The exponent was dropped
on the way into the deposit, leaving a hypothesis about `M` and an argument
about `M⁶` with nothing joining them. At the first power the numbers do not
work at all: `31·e⁻² ≈ 4.195`, so `|Tr − 1| < 1` is false. At the sixth power
`31·e⁻¹² ≈ 1.9·10⁻⁴`.

V7 proves the true statement, with no `sorry`:

| theorem | content |
|---|---|
| `exp_neg_two_le` | `e⁻² ≤ 1/4`, from `1 + 1 ≤ e` alone |
| `exp_neg_twelve_le` | `e⁻¹² ≤ (1/4)⁶` — the constant V6 asserted and could not prove |
| `transverse_sum_bound` | `\|Σ_{i≠0} λᵢ⁶\| ≤ 31·(1/4)⁶` — the step V6 admitted |
| `spectral_trace_ne_33` | `λ₀ = 1`, `\|λᵢ\| ≤ e⁻²`, `n < 33` ⟹ `Σ λᵢ⁶ ≠ 33` |
| `separation_theorem` | the same for a diagonal matrix: `Tr(M⁶) ≠ 33` |
| `separation_trace_first` | first-power form, with the normalisation V6 omitted |
| `spectral_trace_ne_33_upto` | the same conclusion to `n = 131072` — the bound is sufficient, not necessary |
| `separation_fails_in_high_dimension` | at ~1.7·10⁷ directions the trace does exceed 33 — nor can it be dropped |
| `coherent_directions_realise_33` | 33 *coherent* directions realise 33 — about the coherent count, not `n` |
| `dm3_hypothesis_nonvacuous` | a witness, so the statement is not vacuous |
| `v6_separation_statement_is_false` | the refutation, kept on the record |
| `v6_statement_false_at_dimension_five` | `diag(33,0,0,0,0)` — not a dimension-1 technicality |

**A correction inside the correction.** A draft of V7 named one of these
`separation_sharp_at_33` and read it as a sharpness witness for `n < 33`. It
is not one: its witness has every `λᵢ = 1`, which violates the transverse
hypothesis. `n < 33` is sufficient and far from necessary. The two theorems
above bracket what it is actually worth.

What stays open is the spectral reduction: for a general real `M`,
`Tr(M⁶) = Σ λᵢ⁶` needs diagonalisability. V7 states the theorem where that
reduction has already been performed — on the eigenvalue list, and on a
diagonal matrix. That is a boundary of the *statement*, not a hole in a proof,
and it is what O1 should have said from the start.

## Layout

```
Vol1/PrincipiaVol1.lean   the deposit's Lean, V7
tools/run.sh              build → probe → gate
tools/counts.py           per-section counts, computed; --probe regenerates probe.lean
tools/probe.lean          #print axioms over all 58 theorems
tools/axiom_gate.py       refuses on sorryAx or an off-allowlist axiom
record/                   the V6 file and its 81-error build log
```

## What else V7 found

Beyond the separation theorem, in the editorial pass:

- **`ε₀`'s instantiation does not close (O7).** §22 states
  `ε₀ = |μmax|/[2(1+sup‖Hess V‖)]`, sets `sup‖Hess V‖ = |L₂| = 3`, and computes
  `2/(2·3) = 1/3`. The formula at H = 3 gives **1/4**. The printed arithmetic
  and the Lean both use H = 2. `epsilon0_of_eq_third_iff` proves that under
  this formula `ε₀ = 1/3` iff `H = 2`, so a choice is owed. Logged, not
  silently repaired — `ε₀ = 1/3` is load-bearing corpus-wide.
- **`UnfoldOp.stable_branch` is vacuous** — `n = 0` satisfies it for every map
  on every type (`unfold_stable_branch_is_vacuous`). Theorem D has no content
  beyond Φ-decrease.
- **`CompressionOp.contractive` is non-expansive** — the identity satisfies it
  (`compression_permits_identity`).
- **`g6_equals_schumann` withdrawn** — it was `33 = 33` by `rfl`, an
  unfalsifiable guard asserting an empirical identification.
- **A physical prediction was reported as machine-checked** — the Factor-of-3
  Prediction cited `basin_asymmetry : 1/3 < 4/5` as verification of a bound on
  gravitational decoherence. Withdrawn.
- **`1/3 < 4/5 ≈ r*`** — the corpus's canonical inner boundary is
  `r★ = 0.77594059`; 4/5 is 3% above it. Both comparisons are now theorems.
- **`V(1) + 2 = (q−1)²(q+2)`** in §19 — left side a number, right side a
  function of q. The Lean says `V q + 2`. Typo fixed.
- **`10.5281/zenodo.19117400` was labelled the series root.** It is the version
  DOI of V1. The concept DOI is `19117399`.

## License

MIT (code) · CC BY-NC-ND 4.0 (paper)
