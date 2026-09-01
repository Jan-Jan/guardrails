# Verification — monorepo support requirements

branch: monorepo-requirements
reviewer: one independent subagent, dispatched fresh with the diff, the four questions, and repository access at merged HEAD as ground truth — no implementation narrative, no chat history
verdict: accept-with-findings — every load-bearing factual claim in the document verified against the scripts at HEAD (including against base commits b7fbd7f and 860dce4 that landed mid-change); no contradictions among D1–D14; eight findings (two IMPORTANT, six MINOR), all dispositioned below
reproduced: not applicable in the defect sense — this change is a requirements document, not a fix. The claims it makes about script behavior were reproduced by the reviewer directly against the scripts (file:line evidence for each row of the facts table), which is the record of evidence this field exists to make visible.

**Change:** `monorepo-requirements` — requirements (D1–D14), best practices,
and three ADRs for multi-unit repositories under guardrails.
**Plan:** the change IS the requirements document,
`docs/plans/2026-08-26-monorepo-support.md`; it was produced by the
grill-requirements interview, decision by decision, with the user.
**Base:** merged in twice as `main` advanced. `860dce4` at step 1 (merge
commit `76eca69`; fetch performed by the user — hardware key), then `bb7eee5`
(merge commit `de8ad82`) **from the local ref**: the fetch cannot succeed in
this environment (hardware-key signing refused non-interactively), and
`bb7eee5` was the user's own freshly pulled main. Named here per the skill so
the next reader knows what the tree was compared against.
**Class:** the toolkit is unclassified; docs-only change, no code, no tests
added.

## Test evidence

- Baseline before work built on it (at `e6e8acc`): 380/380 pass, exit 0.
- Step 2, after base merge (at `4d6d738`): **435 tests, 0 failures, exit 0** —
  including `problem grammar prose: no shipped file still carries owner:`
  from base commit `860dce4`, which this change's doc satisfies after its
  owner-reference fix.
- Step 6 re-run at final HEAD (after the finding dispositions and the
  `bb7eee5` base merge): dispatched to a fresh subagent per
  `verify-before-merge`, raw log kept outside the tree; gate summary:
  **435 tests, 0 failures, exit 0** — the merge command was not handed over
  before this summary arrived.
- Red → green attestations: not applicable — docs-only change, no
  `develop-change` dispatches, no `verifies:` tests added.

Check scripts (`check-ids.sh`, `check-trace.sh`, `check-review.sh`) were not
run against this repository: it is not yet self-hosted (no
`.guardrails/config.yaml` — the blocker is recorded in
`docs/plans/2026-08-22-ratchet-gap-analysis.md`), consistent with every prior
verification record here. The bats suite is the qualification evidence.

## Findings and dispositions

**finding-1**: (MINOR) "Schema notes (guardrails 0.5.0)" was a stale version
label — base commit `31e2303` bumped the template to 0.5.1 mid-change; the
reviewer re-verified both underlying facts at 0.5.1 and they hold.
disposition: label corrected to 0.5.1 in `d247034`; content unchanged.

**finding-2**: (MINOR) The "Considerations carried, not yet decided" list and
the header status were stale within the document — items 1–3 were resolved by
D12/D13/D14 while the list still presented them as open.
disposition: header now reads "interview complete; D1–D14 decided"; each
resolved item carries a **Resolved by Dnn** marker (`d247034`).

**finding-3**: (IMPORTANT) D13's root-vs-unit glossary conflict rule was the
one gate-shaped sentence with no finding token and no mechanical definition of
"different meanings" — underivable as a test.
disposition: explicitly demoted to a skill rule for the interviews, not a
check, with the same rationale D13 already used to reject the exported-term
gate (`d247034`).

**finding-4**: (MINOR) D5's `segregated_from:` entry invented an inline
`(RC-…)` grammar without requiring the cited control to exist — a dangling RC
in config would be the classic false-green shape.
disposition: the manifest validator must verify the entry names a declared
dependency and that the cited RC/ADR resolves; an entry with neither is
INCOMPLETE-SEGREGATION, exit 1 (`d247034`).

**finding-5**: (MINOR) D11's "exit 1 on the consumer's merges" was ambiguous
between merge-time-only and every run.
disposition: pinned to every run of the consumer's checks, matching the
problem limits it is modeled on (`d247034`).

**finding-6**: (MINOR) Line 12 overclaimed that decisions are "written in
shall form"; D7 left path-matching semantics and root-level files undefined.
disposition: line 12 now states REQ minting will be a deliberate rewrite;
D7 defines whole-leading-path-component matching and implicitly disclaims
tracked files directly at the repository root (`d247034`).

**finding-7**: (IMPORTANT) D10's MISSING-TEST exemption for unmet expectation
REQs is a derived, gate-weakening decision that lacked the "derived, needs
assessment" tag its two peers carry — it creates the one class of REQ that can
sit in an SRS with neither a test nor a conviction.
disposition: tagged derived, needs assessment, naming `analyze-risks` and
stating the weakening explicitly (`d247034`); it joins the derived-items list
for the risk-analysis handoff.

**finding-8**: (MINOR) The dependency-cycle-is-exit-2 rule was decided inside
D12's implementation note — a requirement hiding where REQ minting would lose
it.
disposition: promoted into D2, where the manifest is defined, with a
back-reference to D12's motivation (`d247034`).

A ninth defect was introduced and removed during disposition: the chained edit
for finding-7 garbled one sentence ("the exemption is exempt"); repaired in
the follow-up commit before this record was written.

## Reviewer's negative findings, recorded

Explicitly clean: no stale `owner:` references after `4d6d738` (checked
against `860dce4`); no claim invalidated by the new one-command merge
(`b7fbd7f`); no contradiction in the D4/D10 reverse-visibility crack (bounded
and self-declared); D9's no-knobs rule not violated by D11's limits (budgets
in the existing problem-limit mold, not rule switches); all three ADRs match
the plan, meet the three-part bar, and follow the local date-slug convention.

## Open items handed forward

- Derived, for `analyze-risks`: D4's reverse-visibility exception; D8's
  export-removal scenario ("believed covered; not verified"); D10's
  MISSING-TEST exemption (finding-7).
- For `design-architecture`: `check-units.sh`, foreign definitions, manifest
  validation (including INCOMPLETE-SEGREGATION and the cycle check),
  `new-id.sh` unit inference.
- D7's open sub-question (disclaim-entry justifications) deliberately left as
  a rejected-for-now alternative.
