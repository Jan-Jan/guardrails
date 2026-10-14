# Verification — derailment-conformance (2026-10-14)

branch: derailment-conformance
reviewer: one independent subagent, dispatched at `merge-change` step 6a with
the diff, the plan, PR-r6ypg9 and the review checklist, and no implementation
narrative; it worked in its own review worktree and ran the full suite itself.
verdict: approve. Its `requirement` and `code` findings were all low, so
round 1 was the last review round; each was fixed, its fix mechanical once D2
was stated.
reproduced: yes, by reading: `skills/develop-change/SKILL.md` at `main`
(`93ff657`) states "review returns findings on the same task twice" as a stop
with no exception for the conformance reviews, whose rerun loop meets it by
design; code-guidelines' CODE review had findings above low in rounds 1 and 2
(`docs/plans/2026-10-13-code-guidelines.md`). The new test fails on that text.

Change: `develop-change`'s derailment rule counts a conformance round only
through a finding above low that recurs, at the place it was cited, after its
fix was merged; no round count bounds the loop. Branched from `main` at
`93ff657`; base merged from local `main` at `93ff657`, per AGENTS.md
non-negotiable 4.
Plan: `docs/plans/2026-10-14-derailment-conformance.md`.

## The gate

Measured on: `6c4b5e2` — tree `b32dc134289da4eacc1fc07cf4360d82ad73296e`, on a clean worktree, after the
last-round fixes were merged and local `main` (`93ff657`, unmoved since the
branch was cut) was confirmed merged. `merge-change` step 3 renamed nothing:
the change adds no ledger file. The committed tree differs from it only by
this record.

| Gate | Result |
| --- | --- |
| `tests/run-tests.sh` | 1..1401, 1401 passed, 0 failed, exit 0 (2026-10-14) |
| `check-ids.sh` | identical output at the base and at the change, on scratch copies built from `templates/config.yaml` (this repository has no `.guardrails/config.yaml`) |
| `check-trace.sh` | exit 1 at the base and at the change alike, on the same scratch copies. The one difference: `PR-r6ypg9` leaves the roll-call as `UNRESOLVED-PR`. No verdict added |
| Coverage, against the class target | not configured |
| Working tree | clean |

## Red → green

This repository has no SRS, so the change implements no item and the table
has no rows. The one test the change adds carries
`verifies: D1, D2 (docs/plans/2026-10-14-derailment-conformance.md)`; its
`red -> green:` lines are copied here from the plan.

| Item | Test | Watched red |
| --- | --- | --- |

- red -> green: develop-change: a conformance finding that recurs after its fix stops the loop; a new one does not — watched fail for the right reason before the implementation existed (failing at the grep for the third derailment stop; section_of resolved and ran)
- red -> green: develop-change: a conformance finding that recurs after its fix stops the loop; a new one does not (no-round-count assertion) — the behavior already existed; watched fail at the new assertion with the sentence removed, pass with it restored
- red -> green: develop-change: a conformance finding that recurs after its fix stops the loop; a new one does not (D1, D2 assertions) — watched fail on the missing "A place is the file and lines" text before the skill edit

## What was wrong, and what was built

PR-r6ypg9: the derailment rule's stop "review returns findings on the same
task twice" had no exception for the conformance reviews, which rerun until a
round has nothing above low. Read literally, every change whose conformance
reviews need a second round went to the user.

The rule now has a third stop: a conformance review reports a finding again
after the fix dispatched for it was merged. A round with new findings is the
loop working. A finding recurs when the same guideline clause is reported at
the same place, the file and lines the earlier finding cited; only a finding
above low counts (D2), so a round with nothing above low ends the loop
whatever recurs in it. No round count bounds the loop. For a recurring
finding the user's choices include accepting it or ruling against the clause.
`references/rationale.md` gives the reasons. PR-r6ypg9 is resolved.

## Review

### Round 1

**finding-1**: requirement, low — "Same place" (skills/develop-change/SKILL.md:94-96; D1) does not say what a place is. code-guidelines' round-1 and round-2 Simplicity 4 findings on the duplicated `section_of` extractor (docs/plans/2026-10-13-code-guidelines.md:914, :948) could be read as one finding recurring, which would stop the loop D1 says must continue.
disposition: fixed — `skills/develop-change/SKILL.md` defines a place as the file and lines the earlier finding cited, and the same clause at another site as a new finding; asserted by "develop-change: a conformance finding that recurs after its fix stops the loop; a new one does not".

**finding-2**: requirement, low — the third derailment stop counts a finding of any severity, while the loop's end rule ignores lows; a low that recurs in a round with nothing above low falls under both, and neither says which wins.
disposition: fixed — D2 in `docs/plans/2026-10-14-derailment-conformance.md`: only a finding above low counts; stated in `skills/develop-change/SKILL.md`, its reason in `skills/develop-change/references/rationale.md`, asserted by "develop-change: a conformance finding that recurs after its fix stops the loop; a new one does not".

**finding-3**: code, low — the remedy "raise the effort level, or decompose the task differently" (SKILL.md:99-100) was written for a stuck task; for a recurring conformance finding the user's choices include accepting it or ruling against the clause.
disposition: fixed — the remedy in `skills/develop-change/SKILL.md` adds "accept the finding, or rule against the guideline clause"; asserted by "develop-change: a conformance finding that recurs after its fix stops the loop; a new one does not".

## Guideline reviews

### docs/CODE_GUIDELINES.md

Governs: docs/plans/2026-10-14-derailment-conformance.md docs/problems/2026-10-14-code-guidelines.md skills/develop-change/SKILL.md skills/develop-change/references/rationale.md tests/skills.bats

### Round 1

**finding-1**: guideline, low — Names 4, "A concept has one name in every file, test and task of the change, and where the codebase already names it, that name" — tests/skills.bats:1162
disposition: fixed — the variable `loop` renamed `section`, as the other tests extracting that section name it, in `tests/skills.bats`.

**finding-2**: guideline, low — Comments 3, "A change comments at about the rate of the file it edits" — tests/skills.bats:1156-1164
disposition: fixed — a why-comment added to the new test in `tests/skills.bats`.

Reviewer note, fixed: the edited paragraph of "The conformance reviews" in
`skills/develop-change/SKILL.md` was reflowed to the file's width, no word
changed.

### docs/TEST_GUIDELINES.md

Governs: docs/plans/2026-10-14-derailment-conformance.md docs/problems/2026-10-14-code-guidelines.md skills/develop-change/SKILL.md skills/develop-change/references/rationale.md tests/skills.bats

### Round 1

No findings. Floor note, fixed: the new test did not assert "No round count
bounds the loop"; it does now, in `tests/skills.bats`, watched fail with the
sentence removed. Seam note, no change: Seams 1 names no seam for a test that
reads skill prose, the gap code-guidelines' round-1 TEST review raised; it is
not this change's.

Both reviews had nothing above low, so round 1 was the last conformance round.

## Gaps

- D2 was taken by the dispatcher as the reading D1's purpose fixes, not ruled
  by the user; it is put to the user at the signing hand-over.
- The test checks the skill's text, not an agent's behavior: no test shows a
  dispatcher telling a recurring finding from a new one.
- `merge-preflight.sh` and `check-review.sh` were not run against this tree in
  place, because this repository has no `.guardrails/config.yaml`; `check-ids.sh`
  and `check-trace.sh` ran on scratch copies, and `check-review.sh` on a scratch
  clone.
