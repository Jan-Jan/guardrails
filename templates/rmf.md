# Risk Management File

<!--
Item grammar (enforced by .guardrails/scripts/check-trace.sh):

  **HAZ-NNN**: <hazard — potential source of harm>, <hazardous situation>,
  <harm>. Severity: <S1..S3>. Probability: <P1..P3>.

  **RC-NNN**: <risk control measure>. mitigates: HAZ-NNN

- Every hazard must have at least one risk control that `mitigates:` it.
- Every risk control must be implemented by at least one requirement carrying
  `(implements: RC-NNN)` in the SRS.
- Mint new items as drafts in worktrees (see SRS header).
- Record residual risk and its acceptability after controls are in place.
-->

## Risk acceptability matrix

Severity: S1 negligible · S2 non-serious injury · S3 serious injury or death
Probability: P1 improbable · P2 occasional · P3 frequent

| | P1 | P2 | P3 |
|---|---|---|---|
| **S3** | TBD | TBD | TBD |
| **S2** | TBD | TBD | TBD |
| **S1** | TBD | TBD | TBD |

<!-- Fill each cell with ACCEPTABLE or UNACCEPTABLE per your quality manual. -->

## Hazards

## Risk controls

## Derived requirements assessment

<!-- One line per derived REQ/LLR (satisfies: derived), naming the ID:
     does it introduce a hazard, affect a hazardous situation, or change a
     control's effectiveness? "No hazard impact because <reason>" is valid;
     silence fails check-trace (UNANALYZED-DERIVED). -->

## Residual risk evaluation
