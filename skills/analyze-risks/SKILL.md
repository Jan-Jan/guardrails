---
name: analyze-risks
description: ISO 14971 risk analysis interview - identify hazards, hazardous situations, and harms; evaluate against the acceptability matrix; mint risk controls that become requirements. Use when adding/changing functionality that could affect safety, or when the risk management file is incomplete.
---

# Analyze Risks

**Announce at start:** "Using the analyze-risks skill for ISO 14971 risk analysis."

Work happens **in a worktree** (`worktree-discipline`); the risk management
file (`docs/risk/rmf.md`, path from `.guardrails/config.yaml`) is updated
inline as the analysis proceeds; integrate via `merge-change`.

## The interview

One question at a time, recommended answer with each. For the capability
under analysis, walk the ISO 14971 chain explicitly:

1. **Hazard** — what source of harm could this create or fail to prevent?
   Probe systematically: wrong output/dose, missing alarm, stale data, race
   on shared state, power loss mid-operation, foreseeable misuse, degraded
   SOUP behavior.
2. **Hazardous situation** — the circumstances that expose people to the
   hazard. Invent concrete scenarios; force precision about boundaries.
3. **Harm** — worst credible harm, its **severity** (S1 negligible / S2
   non-serious injury / S3 serious injury or death) and **probability**
   (P1 improbable / P2 occasional / P3 frequent).
4. **Evaluate** against the acceptability matrix in the RMF. Unacceptable →
   controls are mandatory, in ISO 14971 priority order: inherent safety by
   design first, then protective measures (alarms, interlocks), then
   information for safety (labeling) last.
5. **Risk controls** — mint RC items. Each control can introduce new hazards:
   ask "what does this control break?" before moving on.
6. **Residual risk** — after controls, re-estimate and record whether the
   residual risk is acceptable.

## Item grammar (checked by `check-trace.sh`)

- `**HAZ-…**: <hazard>, <hazardous situation>, <harm>. Severity: S_. Probability: P_.`
- `**RC-…**: <control measure>. mitigates: HAZ-…`
- New items use **draft IDs** (`HAZ-DRAFT-<branch>-<n>`); finals are minted at
  merge time.
- Every HAZ needs ≥1 RC mitigating it. Every RC needs ≥1 requirement
  `(implements: RC-…)` in the SRS — hand each software control to
  `grill-requirements` to become a testable requirement. Controls outside
  software (hardware interlocks, labeling) are recorded in the RMF with a
  note that implementation lies outside this codebase.

## Class awareness

The severity answers here justify the project's IEC 62304 class
(`safety_class` in config). If analysis reveals harm potential above what the
current class assumes (e.g. S3 in a Class B project), stop and flag it: the
classification, not just the RMF, must change (rerun the `ratchet`
safety-class interview and record an ADR).

## Done when

- Every analyzed hazard has controls and a residual-risk statement, or a
  recorded acceptability rationale.
- All software RCs have been grilled into REQ items.
- `check-trace.sh` reports no UNMITIGATED-HAZARD / UNIMPLEMENTED-CONTROL for
  the touched items.
