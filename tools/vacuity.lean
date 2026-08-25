/-
  tools/vacuity.lean — the check `#print axioms` cannot make.

  The kernel certifies that a proof establishes its stated proposition. It
  has nothing to say about whether the proposition asserts anything. So a
  declaration like

      theorem limitCycle_exists_auto : True := by trivial

  passes every gate this repository had: it compiles, it carries no `sorry`,
  and `#print axioms` reports the three Mathlib axioms and nothing else. A
  sorry count scores it as complete. It says nothing.

  This file scans a module and reports every theorem whose statement is
  trivially inhabited — conclusion `True`, or `∃ _, True`, or `Nonempty α`
  for an inhabited α, after stripping binders. Those are the shapes that have
  actually occurred in this corpus: `hexgrid_collapse_resistance_superior`
  (ledger row 1), and in AutophagyDm3_v2.lean `whitneyFold_conditional`
  (`∃ φ : ℝ → ℝ, True`), `omega_limit_nonempty` and `limitCycle_exists_auto`.

  It is a necessary check, not a sufficient one. A statement can be
  non-vacuous by this test and still be uninteresting, or true of the wrong
  object — `dm3_basin_compact : IsCompact (Set.Icc (1/3) 2)` passes here and
  is Heine–Borel wearing a dm³ name. No machine decides that one.

  Usage:  lake env lean tools/vacuity.lean
  Exit is always 0; the gate reads the VACUOUS: lines.
-/
import Lean
import PrincipiaVol1

open Lean Elab Command Meta

/-- Is this proposition discharged by triviality alone, after ∀-binders? -/
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

/-- Scan every theorem whose name starts with the given prefix. -/
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

#vacuity_scan "PrincipiaVol1."
