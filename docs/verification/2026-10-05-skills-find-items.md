# Verification — skills-find-items (2026-10-05)

branch: skills-find-items
reviewer: round 1, a fresh subagent with the diff, the plan, AGENTS.md and the review checklist, and no implementation narrative
verdict: round 1 ACCEPT on three low requirement findings and one record finding, all fixed; under the low-severity convergence rule (ruled by the user 2026-10-04) it is the last review round
reproduced: no defect is repaired; three skills read ledger items with `find-items.sh` instead of reading ledger files whole, at the user's request of 2026-10-05.

Change: `plan-change` checks that each claimed REQ exists with `find-items.sh show ID` and reads each cited item with it; `analyze-risks` finds hazards and controls with `list --kind HAZ --kind RC`, `show` and `refs`, and reads a derived item with `show`; `merge-change` step 6a hands the reviewer `find-items.sh show` of each ID the change claims or amends instead of SRS/RMF/SAD excerpts. Documentation only. Branched from `main` at `407ffe7` while `ratchet-self-host` was open, by the user's decision of 2026-10-05 overriding AGENTS.md non-negotiable 4; the two changes share no file. Base merged from local `main` at `407ffe7` before the first two gates (`Already up to date`), and at `2e07045` (`ratchet-self-host`, four documentation files, no conflict) before the third, per AGENTS.md non-negotiable 5.
Plan: `docs/plans/2026-10-05-skills-find-items.md`.

## The gate

Guardrails has no `.guardrails/config.yaml`. `check-ids.sh` and
`check-trace.sh` were run against scratch copies of `main` at `407ffe7` and
of the change, built by the recipe in
`docs/verification/2026-10-03-accept-2scmvn.md`. Both are red on `main`
already, so the criterion is no finding on the change that `main` lacks.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh`, round 3 | `1..1055`: 1055 ok, 0 not ok, 0 skipped, no `bats warning:` line, on `7449aff`, tree `607b644dd89fc2adba75f19fecca8398b4ccbf28`, 20:08:08 to 20:37:19 CEST, clean before and after |
| `sh tests/run-tests.sh`, round 2 | `1..1055`: 1055 ok, 0 not ok, 0 skipped, no `bats warning:` line, on `1fec9b5`, tree `93fbecfce57e080a116a3c3ea23607b01257df19`, 19:13:57 to 19:53:03 CEST, clean before and after |
| `check-ids.sh` | exit 1 on `main` and on the change, 79 lines each, no difference; at `407ffe7` against `1fec9b5`, and at `2e07045` against `7449aff` |
| `check-trace.sh` | exit 1 on `main` and on the change, no difference: 147 lines each at `407ffe7` against `1fec9b5`, 148 each at `2e07045` against `7449aff` |
| `tests/skills.bats`, reviewer's run on `5d8c505` | `1..93`: 93 ok, 0 not ok |
| `check-review.sh` | run on the commit that adds this record (merge-change step 6c); its result is reported with the hand-over |
| Coverage | not configured; the toolkit is unclassified |
| Working tree | clean before and after every run |

The diff is documentation only, so the reviewer did not run the suite; the
gate above is substituted for it. A first gate dispatched on `5d8c505` was
stopped before it reported, because the review fixes changed the tree; its
figures are not used. This record is committed after the gate and changes no
file the suite reads.

`tests/evidence.sh` is not run: the change adds no test and touches no
script, so it has no new test to measure.

## Red → green

Not applicable: documentation only, no `verifies:` test. `skills.bats` (93 of
93) enforces section order and the 2,000-word limit; `merge-change` is at
2,000 words.

## Deslop

The pass was run at `d46ab53` and committed `1689b5a`: `merge-change` step 6a
spells the script as `.guardrails/scripts/find-items.sh` on its first
mention. Considered and kept: the absolute "not by reading the ledger files
whole" in `plan-change`, as in `grill-requirements`.

## Findings

**finding-1**: requirement, low — `merge-change` step 6a hands the reviewer "`find-items.sh show` of each claimed ID" where it used to hand "the SRS/RMF/SAD excerpts". Items the change amends or supersedes without claiming them, which the documentation checklist's supersession sweep needs, are no longer handed over; the reviewer can still run `show` and `refs` in its worktree.
disposition: fixed in `3a4c15e`: step 6a hands over `find-items.sh show` of each ID the change claims or amends.

**finding-2**: requirement, low — "(or a human reviewer, by team policy)" can be read as an optional substitute, where the old "where team policy requires one" made the human reviewer mandatory under that policy.
disposition: fixed in `3a4c15e`: "(or a human reviewer where team policy requires one)" is restored. Six words inside 6a were cut to stay at 2,000: "also", "with it", "own" twice, "onto" once; none removes a rule, command or reference, and `skills.bats` 93 of 93 ok.

**finding-3**: requirement, low — `plan-change` names "REQ, RC and SDD items the plan cites", and a plan also cites LLR IDs.
disposition: fixed in `3a4c15e`: "Read each item the plan cites with `find-items.sh show ID`".

**finding-4**: record — the plan's T1 step 4 states the edit "adds three words and removes two"; the net change is one word, and the literal claim is wrong.
disposition: fixed in `c8732c1`: the plan states a net one-word change, to 2,000.

## Gaps

- No reviewer read the round 1 fixes, including the six word cuts; under the low-severity rule there is no round 2.
- `merge-change/SKILL.md` is at the 2,000-word limit; the next addition to it needs an equal cut or a move to `references/`.
