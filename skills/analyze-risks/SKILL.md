---
name: analyze-risks
description: ISO 14971 risk analysis interview - identify hazards, hazardous situations, and harms; evaluate against the acceptability matrix; mint risk controls that become requirements. Use when adding/changing functionality that could affect safety, or when the risk management file is incomplete.
---

# Analyze Risks

**Announce at start:** "Using the analyze-risks skill for ISO 14971 risk analysis."

## Preconditions

- You are in a change worktree (`worktree-discipline`). The change is
  integrated with `merge-change`.
- The risk management ledger is `doc_rmf` in `.guardrails/config.yaml`.
  Update it as the analysis proceeds, not at the end.
- New HAZ and RC items and new derived assessments go into this change's draft
  file, `docs/risk/DRAFT-<branch>-<slug>.md`. Amend an existing item in the
  dated file that defines it.

## Steps

Ask one question at a time, and state your recommended answer with each.

For the capability under analysis, walk the ISO 14971 chain in this order:

1. **Hazard.** Ask what source of harm the capability could create or fail to
   prevent. Probe each of: wrong output or dose, missing alarm, stale data, a
   race on shared state, power loss mid-operation, foreseeable misuse, and
   degraded SOUP behavior.
2. **Hazardous situation.** Ask for the circumstances that expose people to
   the hazard. Propose concrete scenarios, and make the user state where each
   one begins and ends.
3. **Harm.** Ask for the worst credible harm, its **severity** (S1 negligible,
   S2 non-serious injury, S3 serious injury or death) and its **probability**
   (P1 improbable, P2 occasional, P3 frequent).
4. **Class check.** Do this as soon as a severity is stated, before any
   control is minted. The severity answers justify the project's IEC 62304
   class (`safety_class` in config). If a harm exceeds what the current class
   assumes (for example S3 in a Class B project), stop and report it: the
   classification must change, not only the RMF. Rerun the `ratchet`
   safety-class interview and record an ADR (`grill-requirements`, "ADRs").
5. **Evaluate** the severity and probability against the acceptability matrix
   in the RMF. Where the risk is unacceptable, controls are mandatory, chosen in
   ISO 14971 priority order: inherent safety by design, then protective
   measures (alarms, interlocks), then information for safety (labeling).
6. **Risk controls.** Mint each RC item with
   `.guardrails/scripts/new-id.sh RC` as you write it. For each control, ask
   "what does this control break?" and analyze any new hazard it introduces
   before you move on.
7. **Residual risk.** Re-estimate severity and probability with the controls in
   place, and record whether the residual risk is acceptable.
8. **Hand off controls.** Send each software RC to `grill-requirements`, which
   turns it into a testable requirement containing `(implements: RC-…)` in the
   SRS. For a control outside software (a hardware interlock, labeling),
   record in the RMF that its implementation is outside this codebase.

Write items in the grammar `check-trace.sh` parses:

- `**HAZ-…**: <hazard>, <hazardous situation>, <harm>. Severity: S_. Probability: P_.`
- `**RC-…**: <control measure>. mitigates: HAZ-…`
- Get each new ID from `.guardrails/scripts/new-id.sh HAZ` (or `RC`) as you
  write the item. Never write an ID by hand.
- Every HAZ needs at least one RC that mitigates it. Every RC needs at least
  one requirement that implements it.

**Derived-requirements intake.** `grill-requirements` and
`design-architecture` send you every REQ or LLR marked `satisfies: derived`:
a requirement that exists because of a design decision, not a system need. For
each one:

1. Assess whether it introduces a new hazard, affects an existing hazardous
   situation, or changes the effectiveness of a risk control.
2. Write the assessment in the RMF under "Derived requirements assessment".
   "No hazard impact because <reason>" is a valid assessment; no assessment is
   not.
3. Declare the items the assessment covers on a line of its own:
   `assesses: REQ-…, LLR-…`. `check-trace.sh` reports UNANALYZED-DERIVED for
   any derived item that no `assesses:` line declares. An ID in a table or a
   sentence does not count, because an author can write one without assessing
   anything.

## Red flags

| Thought | Reality |
|---|---|
| "The derived REQ is in the assessment table, so it is covered" | Only an `assesses:` line declares it. Add the line. |
| "This control obviously introduces nothing new" | Ask "what does this control break?" and record the answer (step 6). |
| "S3 is possible, but the project is Class B; I'll note it in the RMF" | Stop and report it. The class changes first (step 4). |
| "I'll pick the next free HAZ number" | Run `new-id.sh`. A hand-written ID is not minted. |
| "Labeling covers it" | Labeling is last. Consider design and protective measures first (step 5). |

## Done when

- Every analyzed hazard has controls and a residual-risk statement, or a
  recorded acceptability rationale.
- Every software RC has been grilled into a REQ item.
- Every derived item sent to you is named on an `assesses:` line.
- `check-trace.sh` reports no UNMITIGATED-HAZARD, UNIMPLEMENTED-CONTROL or
  UNANALYZED-DERIVED for the touched items.
