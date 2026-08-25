/-
  tools/vacuity_fixtures.lean — proof that the vacuity scan fires.

  A gate that has never rejected anything is not known to work. This file
  declares the exact shapes taken from AutophagyDm3_v2.lean, plus the ledger's
  first row, and asserts the scan flags them. If a future edit makes the scan
  silent, this file is what notices.

  Expected: FLAGGED: 5 out of 6 — everything except `honest_content`.
-/
import Lean
import Mathlib
open Lean Elab Command Meta

namespace VacuityFixture

/-- ledger row 1 shape: `hexgrid_collapse_resistance_superior : True := trivial` -/
theorem bare_true : True := by trivial

/-- AutophagyDm3_v2 `omega_limit_nonempty`: binders, conclusion True. -/
theorem true_under_binders (r₀ : ℝ) (_h : r₀ ∈ Set.Icc (1/3 : ℝ) 2) : True := by trivial

/-- AutophagyDm3_v2 `whitneyFold_conditional`: a real hypothesis, `∃ _, True`. -/
theorem exists_true (σ : ℝ → ℝ) (_hσ : σ 0 = 0) : ∃ _φ : ℝ → ℝ, True :=
  ⟨id, trivial⟩

/-- nested: `∃ a, ∃ b, True` -/
theorem exists_exists_true : ∃ _a : ℕ, ∃ _b : ℕ, True := ⟨0, 0, trivial⟩

/-- conjunction of two vacuities -/
theorem and_of_trues : True ∧ ∃ _n : ℕ, True := ⟨trivial, 0, trivial⟩

/-- NOT vacuous — the control. Must not be flagged. -/
theorem honest_content : (2 : ℕ) + 2 = 4 := by norm_num

end VacuityFixture

partial def isTriviallyInhabited (t : Expr) : MetaM Bool :=
  forallTelescopeReducing t fun _ body => do
    let body ← whnf body
    if body.isConstOf ``True then return true
    match body.getAppFnArgs with
    | (``Exists, #[_, p]) =>
        lambdaTelescope p fun _ inner => isTriviallyInhabited inner
    | (``And, #[a, b]) =>
        return (← isTriviallyInhabited a) && (← isTriviallyInhabited b)
    | _ => return false

elab "#vacuity_scan " pfx:str : command => do
  let env ← getEnv
  let prefixStr := pfx.getString
  let mut flagged := 0
  let mut total := 0
  for (name, info) in env.constants.toList do
    unless name.isInternal do
    if (name.toString).startsWith prefixStr then
      match info with
      | .thmInfo ti =>
          total := total + 1
          let vac ← liftTermElabM <| MetaM.run' (isTriviallyInhabited ti.type)
          if vac then
            flagged := flagged + 1
            logInfo m!"VACUOUS: {name}"
      | _ => pure ()
  logInfo m!"SCANNED: {total} theorems under {prefixStr}"
  logInfo m!"FLAGGED: {flagged}"

#vacuity_scan "VacuityFixture."
