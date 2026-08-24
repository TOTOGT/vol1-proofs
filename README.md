# vol1-proofs

The Lean behind **Principia Orthogona, Volume I: The Mathematics of Generative
Transitions** (Zenodo [10.5281/zenodo.19117400](https://doi.org/10.5281/zenodo.19117400)),
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
theorems    49
sorry       0
axioms      propext, Classical.choice, Quot.sound — nothing else
```

## What V7 fixed

V6 of the deposit described `PrincipiaVol1.lean` as *"30+ facts proved without
sorry, 1 scoped sorry at an eigenvalue API boundary."*

The first real build of that file — August 2026, the run recorded verbatim in
[`record/v6-build-errors.txt`](record/v6-build-errors.txt) — reported **81
errors**. It did not compile. Nothing claimed about it had been checked by
anything. The file as deposited is kept in
[`record/PrincipiaVol1-V6-as-deposited.lean.txt`](record/PrincipiaVol1-V6-as-deposited.lean.txt)
so the two can be diffed.

The mechanical faults were structure fields separated by `;` (so `Dm3Triple`
had exactly one field, and every `canonicalTriple.mu_max` was an unknown
field), a `MetricSpace` passed where a `Dist` was expected, `(0 : Fin n)` with
no `[NeZero n]`, four Ordinal lemmas that do not exist under that name, a
club-filter chain built on `Function.iterate` whose lemmas were not provable in
that form, and a carrier type that never unfolded to `ℤ`. All are fixed in
place and marked `V7 FIX`.

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
| `separation_sharp_at_33` | `n = 33` realises 33 — the threshold is load-bearing |
| `dm3_hypothesis_nonvacuous` | a witness, so the statement is not vacuous |
| `v6_separation_statement_is_false` | the refutation, kept on the record |

What stays open is the spectral reduction: for a general real `M`,
`Tr(M⁶) = Σ λᵢ⁶` needs diagonalisability. V7 states the theorem where that
reduction has already been performed — on the eigenvalue list, and on a
diagonal matrix. That is a boundary of the *statement*, not a hole in a proof,
and it is what O1 should have said from the start.

## Layout

```
Vol1/PrincipiaVol1.lean   the deposit's Lean, V7
tools/run.sh              build → probe → gate
tools/probe.lean          #print axioms over all 49 theorems
tools/axiom_gate.py       refuses on sorryAx or an off-allowlist axiom
record/                   the V6 file and its 81-error build log
```

## License

MIT (code) · CC BY-NC-ND 4.0 (paper)
