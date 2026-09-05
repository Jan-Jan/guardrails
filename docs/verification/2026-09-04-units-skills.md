# Verification record — units-skills

branch: units-skills
reviewer: independent subagent (not the author; own task worktree units-skills-review off the change branch; inputs: the diff, the plan, D6/D9/D10/D12/D13, the units-architecture items, check-units.sh's header — no implementation narrative)
verdict: approve-with-findings — 1 IMPORTANT + 3 MINOR, all four fixed in the fix round and re-gated (dispositions below)
reproduced: no defect under repair — this change adds skill prose and its content lints; every new test was watched red before its prose existed (red -> green table below), and the reviewer independently sabotage-checked four pins, one of which (finding-1) failed to redden and became a finding.

## Scope

The four skill updates the units architecture left outside the
implementation change (docs/plans/2026-09-03-units-architecture.md, "Outside
this change"): `/ratchet` step 1b units interview writing the manifest and
per-unit configs (D9), `merge-change` "Multi-unit repositories" consuming
`check-units.sh --impact` mechanically (D6/D12), `grill-requirements`
"Declaring a dependency" (D10) + glossary escalation (D13),
`design-architecture` segregation/edge guidance (D5/D10). Contract: 14 named
test obligations in docs/plans/2026-09-04-units-skills.md, each pinned to one
`@test` in tests/skills.bats; the audit loop prints nothing at the final tip.

## Base

Merged from the LOCAL ref `main` at 0a35669 (both at plan time and re-checked
before the record: "Already up to date"). No fetch was possible from this
environment — the hardware key refuses non-interactive operations — so
"latest base" means latest in this clone; 0a35669 is the tip the user signed
earlier today, and `main` moves only by signed squashes.

## Test evidence

- baseline: 588 ok / 0 not ok at 0a35669 (fresh worktree, exit 0)
- after T1–T4: 602 ok / 0 not ok (gate log units-skills-gate.log; +14 tests)
- after rename (step 6): 602 ok / 0 not ok (units-skills-gate2.log)
- definitive, post-fix, final tip 05c437c: 602 ok / 0 not ok, exit 0
  (units-skills-gate3.log); obligation audit empty; `git status --porcelain`
  empty. Two tests were extended (not added) by the fix round.

## red -> green attestations (copied from the dispatch reports in the plan)

- T1: ratchet-asks-one-system-or-many; ratchet-units-interview-writes-facts-not-rules; ratchet-manifest-repo-has-no-root-config; ratchet-tooth-one-is-manifest-and-disclaimers; ratchet-per-unit-class-interview — each watched fail (pinned phrase absent) before the prose existed.
- T2: merge-consumes-impact-mechanically; merge-runs-impact-set-gates; merge-finalizes-touched-units-only; merge-record-names-units — same.
- T3: grill-dependency-assessment-interview; grill-gap-becomes-expectation; grill-glossary-escalates-interface-terms — same.
- T4: design-depends-on-is-a-decision; design-segregation-cites-a-control — same.
- fix round: finding-3's two new pins watched red before the grammar sentence; finding-1 and finding-4 validated by sabotage (prose deleted -> test red -> restored -> green).

## Findings

**finding-1**: the `merge-record-names-units` pin matched two sites in
merge-change, so deleting the step-6b rider — the instruction where the
record is written — left the suite green (demonstrated by the reviewer's
sabotage 4).
disposition: a second, rider-unique pin (`the record also names the units
touched`) added to the test; sabotage re-run reddens on rider deletion.

**finding-2**: grill-requirements said the provider's run "lists the open
expectations", overstating check-trace.sh, which prints a count
(`expectations against this unit: N open`).
disposition: reworded to "reports how many open expectations stand against
it" — the prose now states script behavior, not the decision's paraphrase.

**finding-3** (IMPORTANT): the `expects:` grammar omitted the `opened:
YYYY-MM-DD` annotation check-trace.sh requires; a user following the skill
verbatim wrote a shape the gate refuses (INCOMPLETE-EXPECTATION, exit 1).
disposition: red-first — pins `opened: YYYY-MM-DD` and
`INCOMPLETE-EXPECTATION` added to grill-gap-becomes-expectation, watched
red, then the grammar sentence added ("in the same item block, on its own
line", verified against gr_req_scan's column-one block attribution); green.

**finding-4**: the `ratchet-per-unit-class-interview` second pin (`that
unit's config`) was satisfied by the step-1b table row even with the step-4
sentence deleted.
disposition: pin replaced with `record each class in that unit's config`,
unique to step 4 after a whitespace reflow; targeted sabotage reddens.

## Known residuals

- The count-only provider advisory (finding-2's underlying script behavior)
  could list expectation IDs instead — a separate script change if wanted,
  not part of this change.
- check-review.sh cannot run on this repository (not self-hosted: no
  .guardrails/config.yaml and no manifest), so step 6c is satisfied by this
  record's existence and fields, checked by eye as before.

## Handoff

The monorepo track's skill updates are complete. Remaining in the track:
self-hosting (REQ/SDD/HAZ/RC minting per
docs/plans/2026-08-22-ratchet-gap-analysis.md) and the carried bash-3.2
inert-assertion problem report, both awaiting self-hosting.
