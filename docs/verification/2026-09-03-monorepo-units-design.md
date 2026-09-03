# Verification — monorepo unit machinery architecture

branch: monorepo-units-design
reviewer: one independent subagent, dispatched fresh with the diff, the review questions, and repository access at the change HEAD — no implementation narrative, no chat history; docs-only diff, so it rests on the dispatched gate summary for code health and read every claimed file itself
verdict: approve-with-findings — D1–D14 covered faithfully with placements verified per decision; all eight inherited risk obligations mapped plausibly onto owning items; every claim the design makes about the existing code verified true against lib.sh, new-id.sh, check-ids.sh and templates/config.yaml with file:line evidence; one IMPORTANT and five MINOR findings, all dispositioned below
reproduced: not applicable in the defect sense — this change is a design, not a fix. The design's claims about the code it will change (the exact contents of GR_KNOWN_KEYS/GR_LIST_KEYS, every script's cd-to-toplevel, new-id.sh's gr_check_config call, DUPLICATE-ID's tree-wide scan, gr_limit's parse rules, the shipped problem limits) were each reproduced by the reviewer directly against the scripts at HEAD, which is the evidence this field exists to make visible.

**Change:** `monorepo-units-design` — the architecture for the monorepo unit
machinery decided in docs/plans/2026-08-26-monorepo-support.md (D1–D14) under
the controls of docs/risk/2026-09-01-monorepo-derived-items.md: unit scope
resolved by `lib.sh` so convictions land in the consumer's own run,
`check-units.sh` holding only what has no single-unit home (manifest,
UNCLAIMED-PATH, class floor, impact set, export surface), `new-id.sh` unit
inference from the caller's cwd. Produces
docs/plans/2026-09-03-units-architecture.md, resolution notes on the plan's
carried considerations 5 and 6, and a binding-site amendment to the dated
risk file. Three architecture decisions (scope home, impact-set home,
new-id unit selection) were put to the user 2026-09-03 and all resolved to
the recommended option before the document was written.
**Plan:** docs/plans/2026-08-26-monorepo-support.md is the requirements
input; the handoff that scoped this change is recorded in
docs/verification/2026-09-01-monorepo-derived-risks.md (the eight named test
obligations, inherited here as requirements).
**Base:** merged **from the local ref** `main` = `3fe5eb3` at step 1 and
again after the finding fixes (both "already up to date" — the branch was cut
from that commit and main did not move): the fetch cannot succeed in this
environment (hardware-key signing refused non-interactively). Named here per
the skill so the next reader knows what the tree was compared against.
`3fe5eb3` is the case-pattern squash the user signed and merged earlier
today.
**Class:** the toolkit is unclassified (Class A per
docs/adr/2026-08-22-safety-class.md); docs-only change, no code, no tests
added.

## Test evidence

Suite runs in the change worktree with the vendored bats copied in, raw logs
outside the tree, counts read from the logs:

- Step 2/6, after base merge and ledger finalization (at `cbd7be3`… suite
  ran at the finalized tree): **475/475, exit 0.**
- Rerun after the review-finding fixes (at `e6810e0`; only this record's
  own commit follows it, touching docs/verification/ alone):
  **475/475, exit 0.** The rerun performed no finalization — the design doc
  was already dated and every fix is an in-place amendment — so this single
  run stands as the rerun's step-2/step-6 evidence.
- Red → green attestations: not applicable — docs-only change, no
  `develop-change` dispatches, no `verifies:` tests added. The named test
  obligations this design defines bind on the *implementation* change
  (`plan-change` next), not on this document.

Check scripts (`check-ids.sh`, `check-trace.sh`, `check-review.sh`,
`finalize-docs.sh`) were not run against this repository: it is not yet
self-hosted (no `.guardrails/config.yaml` — the blocker is recorded in
docs/plans/2026-08-22-ratchet-gap-analysis.md), consistent with every prior
change. The draft ledger file was renamed to its merge-date name manually for
the same reason, with zero content change. Zero draft-named files and zero
`DRAFT-` tokens remain in the tree (verified by grep over docs/).

## Review findings and dispositions

**finding-1**: The engagement rule makes every config-reading script exit 2
in a manifest repository, but the design never said how `check-review.sh` or
`finalize-docs.sh` run in that world, nor which unit's `doc_verification`
holds D6's single per-change record — the one D6 obligation with no designed
home. (severity: IMPORTANT)
disposition: new item 9 (repository-level scripts): the record lives at the
repository root `docs/verification/` (the change, not a unit, is its
subject; the path is already the one `doc_*` location with a default);
`check-review.sh` validates the manifest in place of `gr_check_config` and
stays branch-keyed; `finalize-docs.sh` runs once per touched unit of the
impact set; `check-signing.sh` reads no config (verified) and is unchanged.
The engagement rule now names the unit-scoped scripts and points at item 9.
Obligations **review-record-is-repository-level** and
**finalize-runs-per-touched-unit** pin it (commit `e6810e0`).

**finding-2**: D8's "the export surface is then whatever `check-units.sh`
reports" had no owning mode — none of default/`--impact`/`--list` reports
exports. (severity: MINOR)
disposition: `--exports <unit>` added to item 6, required to be the same
computation as consumer-side resolution; obligation
**exports-mode-matches-resolution** (commit `e6810e0`).

**finding-3**: The risk file binds all eight obligations "on
`check-units.sh`" while the design relocates five conviction sites into the
scoped per-unit gates; the binding site went stale and the diff amended the
plan but not the risk file. (severity: MINOR)
disposition: binding-site amendment added to the dated risk file (edited in
place, per the amendments-in-the-defining-file rule): the obligations bind on
the unit machinery's bats suite wherever each conviction lands; no test
weakened or dropped (commit `e6810e0`).

**finding-4**: The unclaimed-path condition is exit 1 in default mode but
exit 2 in `--impact`, unexplained, and the findings table lists only the
exit-1 form — a reader of the table alone would implement it wrong.
(severity: MINOR)
disposition: rationale paragraph added under item 6's modes (a partial
impact set at exit 1 would read complete to `merge-change`; the exit 2
message names the default mode's finding as the remedy); obligation
**impact-unclaimed-path-is-exit-2** (commit `e6810e0`).

**finding-5**: Item 3 defined the conviction for a bad `exported:` but no
verdict for `expects:` on a non-REQ block or with a malformed value — half
the new annotation grammar had an unspecified failure mode. (severity: MINOR)
disposition: `INCOMPLETE-EXPECTATION` widened to one token for every
expectation the reader cannot read — non-REQ block, empty or non-path value,
and the existing `opened:` cases; obligation
**expects-grammar-errors-convict** (commit `e6810e0`).

**finding-6**: Item 5's scope narrowing leaves `not_a_unit:` paths checked by
no run at all — today's `MALFORMED-ID` and draft scans are tree-wide — the
same hazard shape as listed derived item 1, but absent from the derived
list. (severity: MINOR)
disposition: stated in item 5 as a deliberate rule with its residual named,
and added as derived item 3 to the needs-assessment list handed to
`analyze-risks` (commit `e6810e0`).

## Notes for the next reader

- The design carries **descriptive labels, not minted SDD/LLR tokens** —
  token minting follows self-hosting, the same convention as the plan's REQs
  and the risk file's HAZ/RCs.
- Handoff: **`analyze-risks`** owes an assessment of the three derived
  decisions in the design's derived list (disclaimed definitions convict
  DANGLING-REF with the wrong cause; check-units.sh exit 0 without a
  manifest; disclaimed paths scanned by no run). **`plan-change`** then owns
  the implementation, with the design's named test obligations (the eight
  inherited plus the new ones) as its binding test list.
