# Verification — risk assessment of the monorepo derived items

branch: monorepo-derived-risks
reviewer: one independent subagent, dispatched fresh with the diff, the review questions, and repository access at the change HEAD — no implementation narrative, no chat history
verdict: accept-with-findings — all load-bearing claims verified against the plan, template, and handoff at HEAD with file:line evidence; all three derived items dispositioned with hazard, controls, and residual risk; two MINOR form findings, both dispositioned below
reproduced: not applicable in the defect sense — this change is a risk assessment, not a fix. The claims it assesses (the D6+D12 impact-set chain, D10's met-condition, the optionality of the problem limits) were reproduced by the reviewer directly against the plan and templates/config.yaml at HEAD, which is the evidence this field exists to make visible.

**Change:** `monorepo-derived-risks` — ISO 14971 assessment of the three items
docs/plans/2026-08-26-monorepo-support.md marked "derived, needs assessment"
(D10's MISSING-TEST exemption, D8's export-removal scenario, D4's
reverse-visibility exception), producing
docs/risk/2026-09-01-monorepo-derived-items.md plus in-place plan amendments.
**Plan:** the assessed decisions live in
docs/plans/2026-08-26-monorepo-support.md; the handoff that scoped this change
is recorded in docs/verification/2026-09-01-monorepo-requirements.md.
**Base:** merged **from the local ref** `main` = `f64be47` at step 1 and again
after the finding fixes: the fetch cannot succeed in this environment
(hardware-key signing refused non-interactively). Named here per the skill so
the next reader knows what the tree was compared against. `f64be47` is the
squash the user merged and verified hours before this change opened.
**Class:** the toolkit is unclassified; docs-only change, no code, no tests
added.

## Test evidence

All suite runs dispatched to fresh subagents per `verify-before-merge`, raw
logs kept outside the tree, counts read from the logs:

- Baseline before work built on it (at `f64be47`): 435/435 pass, exit 0.
- Step 2, after base merge (at `fa5e1ee`): **435 tests, 0 failures, exit 0.**
- Step 6, after ledger finalization (at `6a4f22b`): **435/435, exit 0.**
- Final run after the review-finding fixes (at `2659024`, the squashed HEAD):
  **435/435, exit 0.** The rerun performed no finalization — the ledger file
  was already dated and both fixes are in-place amendments — so this single
  gate run stands as the rerun's step-2/step-6 evidence.
- Red → green attestations: not applicable — docs-only change, no
  `develop-change` dispatches, no `verifies:` tests added.

Check scripts (`check-ids.sh`, `check-trace.sh`, `check-review.sh`,
`finalize-docs.sh`) were not run against this repository: it is not yet
self-hosted (no `.guardrails/config.yaml` — the blocker is recorded in
docs/plans/2026-08-22-ratchet-gap-analysis.md), consistent with every prior
change. The draft ledger file was renamed to its merge-date name manually for
the same reason, with zero content change (commit `6a4f22b`). No draft-named
files and no "needs assessment" tags remain in the tree.

## Review findings and dispositions

**finding-1**: The "expects: naming a non-declared dependency is a conviction"
control was a gate rule on `check-units.sh` that named no finding token —
every other conviction in the plan carries one — and, unlike assessments 2
and 3, was pinned by no named test obligation; the disposition paragraph then
misclassified it as "template policy". (severity: MINOR)
disposition: the conviction is pinned to `UNDECLARED-DEPENDENCY` (a stray
`expects:` is exactly a reference across an undeclared edge), the named test
obligation **expects-undeclared-unit-convicts** is added to the risk file, the
D10 plan amendment names the token, and the disposition paragraph now
separates template policy from gate rules (commit `2659024`).

**finding-2**: The tag-flip convention was applied inconsistently — the D6
transitivity item still read "**Derived, needs assessment:**" after this
change appended "**Resolved by D12**: transitive.", so a mechanical scan for
open tags still hit a dispositioned item. (severity: MINOR)
disposition: the tag is flipped in place to "**Derived, resolved by D12:**",
original statement preserved; a tree-wide grep for "needs assessment" now
returns zero (commit `2659024`).

## Reviewer's negative findings, recorded

Explicitly clean, with file:line evidence in the review: the shipped-set
rationale for the expectation limits matches templates/config.yaml's own
stated rationale for the problem limits; D10's met-condition (exported REQ
carrying `satisfies:`) is quoted correctly; the D6+D12 impact-set chain holds
as claimed; D2's cycle detection concerns `depends_on:` edges only, so the
reverse edge cannot affect it; no D9 conflict (the limits are budgets in the
problem-limit mold); all three derived items dispositioned, none dropped, each
with hazard, controls, and residual risk; ledger and amendment form correct
(new items in this change's file, amendments in place, nothing restated);
descriptive-label justification stated and consistent with precedent.

## Open items handed forward

- For `design-architecture`: `check-units.sh` inherits eight named test
  obligations from docs/risk/2026-09-01-monorepo-derived-items.md
  (expects-undeclared-unit-convicts; export-removal-convicts;
  export-removal-reopens-expectation; item-deletion-degrades-to-dangling;
  transitive-dependent-unaffected; reverse-edge-is-exactly-expects;
  satisfies-across-wrong-edge-convicts; reverse-edge-discharges-nothing) —
  requirements, not suggestions.
- For `ratchet` / templates: `expectation_age_days` and `expectation_open_max`
  ship **set** in the per-unit config template (assessment 1).
- HAZ/RC token minting for these assessments awaits self-hosting, as it does
  for the plan's requirements.
