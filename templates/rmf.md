# Risk management ledger

This directory is a per-change ledger: each merged change contributes one
dated file, `YYYY-MM-DD-<slug>.md` (merge date, assigned by `merge-change`
from your worktree's `DRAFT-<branch>-<slug>.md`). **Edit existing items in
the file that defines them.** This README holds the project-wide
acceptability matrix; the dated files hold hazards, controls, derived
assessments, and residual-risk statements.

<!--
Item grammar (enforced by .guardrails/scripts/check-trace.sh):

  **HAZ-NNN**: <hazard — potential source of harm>, <hazardous situation>,
  <harm>. Severity: <S1..S3>. Probability: <P1..P3>.

  **RC-NNN**: <risk control measure>. mitigates: HAZ-NNN

- Every hazard must have at least one risk control that `mitigates:` it.
- Every risk control must be implemented by at least one requirement carrying
  `(implements: RC-NNN)` in the requirements ledger.
- Derived REQ/LLR assessments live here too: name the ID and its hazard
  impact ("no hazard impact because <reason>" is valid; silence fails
  check-trace as UNANALYZED-DERIVED).
- Mint new items as drafts in worktrees; record residual risk and its
  acceptability after controls are in place.
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
