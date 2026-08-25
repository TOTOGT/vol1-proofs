import Lean
import PrincipiaVol1
import AutophagyDm3_v2
open Lean Elab Command Meta

partial def isTriviallyInhabited (t : Expr) : MetaM Bool :=
  forallTelescopeReducing t fun _ body => do
    let body ← whnf body
    if body.isConstOf ``True then return true
    match body.getAppFnArgs with
    | (``Exists, #[_, p]) => lambdaTelescope p fun _ inner => isTriviallyInhabited inner
    | (``And, #[a, b]) => return (← isTriviallyInhabited a) && (← isTriviallyInhabited b)
    | _ => return false

elab "#vacuity_scan " pfx:str : command => do
  let env ← getEnv
  let mut flagged := 0
  let mut total := 0
  for (name, info) in env.constants.toList do
    unless name.isInternal do
    if (name.toString).startsWith pfx.getString then
      match info with
      | .thmInfo ti =>
          total := total + 1
          if ← liftTermElabM <| MetaM.run' (isTriviallyInhabited ti.type) then
            flagged := flagged + 1
            logInfo m!"VACUOUS: {name}"
      | _ => pure ()
  logInfo m!"THEOREMS SCANNED: {total}   VACUOUS: {flagged}"

elab "#unused_param_scan " pfx:str : command => do
  let env ← getEnv
  let mut flagged := 0
  let mut total := 0
  for (name, info) in env.constants.toList do
    unless name.isInternal do
    if (name.toString).startsWith pfx.getString then
      match info with
      | .defnInfo di =>
          let isProp ← liftTermElabM <| MetaM.run' do
            forallTelescopeReducing di.type fun _ b => return (← whnf b).isProp
          if isProp then
            total := total + 1
            let bad ← liftTermElabM <| MetaM.run' do
              lambdaTelescope di.value fun args body => do
                let mut miss := #[]
                for a in args do
                  let d ← a.fvarId!.getDecl
                  if d.binderInfo.isExplicit && !(body.containsFVar a.fvarId!) then
                    miss := miss.push d.userName
                return miss
            if bad.size > 0 then
              flagged := flagged + 1
              logInfo m!"IGNORES-ITS-ARGUMENT: {name} never mentions {bad}"
      | _ => pure ()
  logInfo m!"PROP-DEFS SCANNED: {total}   IGNORING AN ARGUMENT: {flagged}"

#vacuity_scan "PrincipiaVol1."
#vacuity_scan "AutophagyDm3."
#unused_param_scan "PrincipiaVol1."
#unused_param_scan "AutophagyDm3."
