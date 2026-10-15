# Verification — base-move-round (2026-10-15)

branch: base-move-round
reviewer: independent subagents with fresh context, one per round, dispatched
at `merge-change` step 6a (the step order in force on `main`) with the diff,
the plan and the review checklist, and no implementation narrative; each
worked in its own review worktree and ran the full suite itself. Round 2's
first dispatch was cut off by an authentication error before it reported; it
was re-dispatched on the same reviewed commit.
verdict: approve. Round 1 raised one `requirement` finding at medium; round 2
found the change satisfies D1–D5, every round-1 disposition holding, with
every finding low or `record`. The base then moved, and the files both sides
edit sent the whole change to round 3, which found D1–D5 satisfied and the
shared files merged intact, with `record` findings only, so round 3 was the
last review round. Each finding was fixed.
reproduced: yes, by reading and by test. At `main` (`344faa3`),
`skills/merge-change/SKILL.md` gates at step 2 before the review and writes
the record at 6b after it, so step 7's tree comparison fails on every merge
until a second gate runs; step 1 gates without looking for a squash staged in
the primary checkout; and the last-round rule names only a round whose
findings "are all `low`". The D1 test fails against `main`'s step 1 fence
(it merged with the primary index staged), and the D4 and D5 tests fail
against `main`'s skill.

Change: `merge-change` runs the gate after the review and the record, so one
gate per round measures the tree that is signed; step 1 stops while the
primary checkout's index is not empty; a round that dispatches no reviewer
skips the pre-flight before the review; a round with no finding is the last;
and the steps are renumbered 1, 2, 3, 4, 5, 6a, 6b, 6c, 6d, 7, 8.
Plan: `docs/plans/2026-10-14-base-move-round.md`.

## The gate

The gate's figures are not in this record: the squash commit carries them as
its `Gate-tree:`, `Gate:` and `Base:` trailers. This repository has no
`.guardrails/config.yaml`, so `merge-preflight.sh` stops at its config read;
`check-ids.sh` and `check-trace.sh` ran instead on scratch copies of `main`
and of the change, each built from `templates/config.yaml` with `scripts` as
its strict path, and printed identical output at both. The comparison was
repeated after the base moved, against `main` at its new commit, with the
same result. The change adds no ID,
item or trace finding. Coverage is not configured.

## Red → green

This repository has no SRS, so the change implements no item and the table
has no rows. Its tests carry `verifies: D<n>
(docs/plans/2026-10-14-base-move-round.md)` for D1–D5; their `red -> green:`
lines are copied here from the plan, under each test's current name.

| Item | Test | Watched red |
| --- | --- | --- |

- red -> green: merge-change: the base merge stops while a squash is staged in the primary checkout — red: status 0, the fence merged the moved base with the primary index staged
- red -> green: merge-change: the base merge stops while a squash is staged in the primary checkout (the no-primary-checkout case) — red: status 0, "Merge made by the 'ort' strategy" with `git worktree list` failing
- red -> green: merge-change: the base merge stops while a squash is staged in the primary checkout (the index message) — red: "not the index message: a squash is staged in …"
- red -> green: merge-change: the base merge stops while a squash is staged in the primary checkout (unreadable-index case) — red: "the index of …/repo is not empty" in place of the cannot-read message
- red -> green: ratchet: the upgrade notes say the base merge stops on a staged squash — red: "the renumbering entry does not announce step 1's new stop"
- red -> green: merge-change: a round that dispatches no reviewer skips the pre-flight before the review — red: "step 4 does not say when it is skipped"; then, for the base-move list, red on a mutated skill ("then 6b to 7."), and red on the uncorrected list ("step 7 does not list the base-move round's steps")
- red -> green: merge-change: a round with no finding is the last — red: "the last-round sentence does not cover a round with no finding"
- red -> green: merge-change: the review checklist's last round covers a round with no finding — red: "the checklist's last-round sentence does not cover a round with no finding"
- red -> green: merge-change: the gate runs after the record, on the tree that is signed — red: "step labels: 1 2 3 4 5 6 6a 6b 6c 6d 7 8"
- red -> green: merge-change: it starts after develop-change, since the gate runs inside it — red: "still requires verify-before-merge first"
- red -> green: merge-change: the review checklist asks for the record only where it exists — red: "the checklist asks every reviewer for inherited: lines in the record"
- red -> green: merge-change: no step renames a ledger file, and the tree check confirms the tree the gate summary describes — red observed after the implementation, against the base: run on 2026-10-15 on a scratch copy of the change with `main`'s skill in place, it failed because 6b is the record there
- red -> green: merge-change: the record is written before the gate and holds no gate figure — red observed after the implementation, against the base, the same way: "the skill still orders the record before the last rerun"
- red -> green: merge-change: a late gate's costs are stated: a reviewer for its fix, and no suite for a docs-only review — red with either sentence removed from a working copy of the skill: "step 4 does not say a gate failure's fix dispatches a reviewer", "... reviewer skips the suite"
- red -> green: ratchet: the upgrade notes say the base merge stops on a staged squash (the missing-primary stop) — red: "the renumbering entry does not announce the missing-primary stop"

## What was wrong, and what was built

At `main`, `merge-change` gated at step 2, before the review, and wrote the
record at 6b, after it. The record is part of the tree, so the tree the gate
measured was never the tree signed: step 7's comparison of the staged tree
with the gated tree failed on every merge, and the sequence reran from step 1
for a second gate. The review's own suite run measured the same tree as the
early gate. A moved base, found at step 7, reran everything from step 1, and
step 1 would start a gate while another change's squash was staged in the
primary checkout, a base that was about to move.

The gate now runs at 6a, after the review (4) and the record (5), and 6b
confirms the tree it measured, so one gate per round measures the tree that
is signed. Step 1 stops while the primary checkout's index is not empty, and
also when the primary checkout cannot be found or its index cannot be read.
A round that dispatches no reviewer skips the pre-flight before the review,
since 6c runs every check it does; a base-move round runs steps 2 to 4 only on
a `shared:` line, and any round in which step 4 ran reaches step 5 before the
gate. A round whose findings, if any, are all low is the last review round. A
gate failure after a review dispatches a reviewer unless its fix touches only
the record or the plan; a documentation-only diff's reviewer skips the suite.

The labels were renumbered so the order reads in sequence; 1, 6c, 6d, 7 and 8
keep their numbers. Every live file follows the new labels: the skills, their
references, the scripts' comments and messages, the templates, the README,
AGENTS.md, the ADRs (each with an amendment note) and every upgrade-notes
entry, under a new entry with the mapping. Dated plans, records and problem
items keep the numbers they were written with. Test names state a step's role,
not its number.

## Review

### Round 1

**finding-1**: requirement, medium — The base-move round runs step 5 "only for a new `left whole` plan", even when a `shared:` line sent the change to a fresh review at step 4; a shared:-triggered review that finds nothing leaves no trace in the record, against the template's rule that the record names the shared files and that review round.
disposition: fixed — a round whose step 4 ran reaches step 5 before the gate, in `skills/merge-change/SKILL.md` and `skills/merge-change/references/rationale.md`; pinned by "merge-change: a round that dispatches no reviewer skips the pre-flight before the review".

**finding-2**: code, low — `scripts/check-ids.sh` said the pre-flight is step 4; it is step 2.
disposition: fixed — `scripts/check-ids.sh`; no mutation quotes the comment.

**finding-3**: requirement, low — The skill and the rationale disagreed on what a round with no finding does next.
disposition: fixed — `skills/merge-change/references/rationale.md` states the skill's path: the last review round reruns from step 1 with steps 2 to 4 skipped.

**finding-4**: requirement, low — The review checklist asked every reviewer to check the record, which a first-round reviewer cannot see under the new order.
disposition: fixed — `skills/merge-change/references/review-checklist.md` asks for it "where the record exists"; pinned by "merge-change: the review checklist asks for the record only where it exists".

**finding-5**: requirement, low — The D1 test named a step number, against the plan's rule that a test name states a step's role.
disposition: fixed — renamed "merge-change: the base merge stops while a squash is staged in the primary checkout" in `tests/skills.bats`.

**finding-6**: record — The upgrade note did not announce step 1's new stop.
disposition: fixed — `skills/ratchet/references/upgrade-notes.md`; pinned by "ratchet: the upgrade notes say the base merge stops on a staged squash". This record states the stop under What was built, `docs/verification/2026-10-15-base-move-round.md`.

### Round 2

**finding-1**: code, low — Two rules of the new order had no test: a 6a gate failure's fix dispatches a reviewer unless it touches only the record or plan, and a documentation-only diff's reviewer skips the suite.
disposition: fixed — pinned by "merge-change: a late gate's costs are stated: a reviewer for its fix, and no suite for a docs-only review" in `tests/skills.bats`.

**finding-2**: requirement, low — ADR-f6ytg7 still stated the consequence the new order removed: a record written after the last gate costs one more gate run.
disposition: fixed — `docs/adr/ADR-f6ytg7-squash-commit-certifies-the-gate.md`, with its amendment note.

**finding-3**: requirement, low — ADR-cy7ahd described the order it decided as if nothing had moved since.
disposition: fixed — `docs/adr/ADR-cy7ahd-ledger-files-named-at-creation.md`'s amendment note says the later order changed those sentences.

**finding-4**: requirement, low — `skills/check-traceability/SKILL.md` named "the `verify-before-merge` gate at its step 6a", which reads as verify-before-merge's own step.
disposition: fixed — `skills/check-traceability/SKILL.md` names merge-change's step.

**finding-5**: record — The plan's lists of word cuts left out five cuts in the diff of the skill.
disposition: fixed — the plan lists them, `docs/plans/2026-10-14-base-move-round.md`; the reviewer found that none changes a rule.

**finding-6**: record — D1 stated one stop where the tree has three, and the upgrade note omitted the missing-primary stop.
disposition: fixed — D1 states all three in `docs/plans/2026-10-14-base-move-round.md`, and `skills/ratchet/references/upgrade-notes.md` names the missing primary checkout.

### Round 3

Step 1 printed `shared:` for `skills/ratchet/references/upgrade-notes.md` and
`tests/skills.bats`: the base edited both after round 2's reviewed commit, so
round 3 reviewed the whole change again.

**finding-1**: record — The record called round 2 the last review round, had no block for the round the shared files sent the change to, and did not say whether the trace and ID comparison was repeated against the moved base.
disposition: fixed — `verdict:`, "The gate" and this round's block in `docs/verification/2026-10-15-base-move-round.md`.

**finding-2**: record — Plan D2 still listed the base-move round as before review round 1 corrected it.
disposition: fixed — D2 in `docs/plans/2026-10-14-base-move-round.md` states the corrected list.

## Guideline reviews

The findings and dispositions of every round are in the plan,
`docs/plans/2026-10-14-base-move-round.md`, under "Conformance reviews"; they
are copied here as dispositioned.

### docs/ARCHITECTURE_GUIDELINES.md

Governs: every path of the diff

### Round 1

**finding-1**: guideline, medium — Domain 2, "A term means one thing in every script, skill and template" — skills/merge-change/SKILL.md, skills/ratchet/references/upgrade-notes.md
disposition: fixed — the renumbering stands, and every live file uses the new labels: the ADRs, for example `docs/adr/ADR-y8jmes-local-main-is-the-base.md`, and the older entries of `skills/ratchet/references/upgrade-notes.md`.

**finding-2**: guideline, low — Boundaries 1, "A script and a skill each have one job, stated in one sentence without "and"" — skills/verify-before-merge/SKILL.md:3
disposition: fixed — `skills/verify-before-merge/SKILL.md` states one job.

### Round 2

**finding-1**: guideline, low — Boundaries 1 — skills/merge-change/SKILL.md:3
disposition: fixed — `skills/merge-change/SKILL.md`'s description states one job.

**finding-2**: guideline, low — Boundaries 1 — skills/verify-before-merge/SKILL.md:3
disposition: no change — its job sentence has no "and"; the "and" is in the "Use before …" trigger sentence, which the clause does not govern.

Round 2 had nothing above low, so it was the last round.

### docs/TEST_GUIDELINES.md

Governs: every path of the diff

### Round 1

**finding-1**: guideline, medium — Seams 1, "a test verifies the problem report or the plan decision that states the behavior" — tests/skills.bats
disposition: fixed — "merge-change: the record is written before the gate and holds no gate figure" verifies D4 of `docs/plans/2026-10-14-base-move-round.md`.

**finding-2**: guideline, medium — Seams 1 — tests/skills.bats
disposition: fixed — "merge-change: no step renames a ledger file, and the tree check confirms the tree the gate summary describes" verifies D5 of `docs/plans/2026-10-14-base-move-round.md`.

**finding-3**: guideline, low — Seams 1 — tests/check-review.bats
disposition: fixed — "check-review: the record need not be committed" verifies D9 of `docs/plans/2026-08-23-review-artefact.md`.

### Round 2

**finding-1**: guideline, low — Mutants 1, "A surviving mutant means a missing test at the seam" — tests/skills.bats
disposition: fixed — "merge-change: a round that dispatches no reviewer skips the pre-flight before the review" asserts the base-move round's step list.

Round 2 had nothing above low, so it was the last round.

### docs/CODE_GUIDELINES.md

Governs: every path of the diff

### Round 1

**finding-1**: guideline, medium — Comments 2, "No change narration" — tests/skills.bats
disposition: fixed — the "Re-aimed" comments in `tests/skills.bats` state what each test checks.

**finding-2**: guideline, medium — Comments 2 — tests/skills.bats
disposition: fixed — as finding-1, in `tests/skills.bats`.

**finding-3**: guideline, medium — Comments 2 — tests/skills.bats
disposition: fixed — as finding-1, in `tests/skills.bats`.

**finding-4**: guideline, medium — Comments 2 — tests/skills.bats
disposition: fixed — as finding-1, in `tests/skills.bats`.

**finding-5**: guideline, medium — Names 4, "One name per concept across the change" — tests/skills.bats
disposition: fixed — renamed "merge-change: a round that dispatches no reviewer skips the pre-flight before the review".

**finding-6**: guideline, low — Errors 2/3, "No swallowed error", "No silent fallback" — skills/merge-change/SKILL.md
disposition: fixed — step 1 stops on an empty primary path, in `skills/merge-change/SKILL.md`; pinned by "merge-change: the base merge stops while a squash is staged in the primary checkout".

**finding-7**: guideline, low — Names 2, "no chained conditional expression standing in for an `if`" — tests/skills.bats
disposition: fixed — an `if` in `tests/skills.bats`.

### Round 2

**finding-1**: guideline, medium — Names 4 — skills/develop-change/SKILL.md:81-82
disposition: fixed — `skills/develop-change/SKILL.md` names step 5.

**finding-2**: guideline, medium — Names 4 — tests/skills.bats
disposition: fixed — test names state a step's role, not its number; no script, mutation or helper reads a test name, in `tests/skills.bats`.

**finding-3**: guideline, low — Simplicity 4, "Where two parts of one change add the same helper … one copy stays" — tests/skills.bats
disposition: fixed — `step_of` in `tests/helpers.bash` takes lettered labels.

**finding-4**: guideline, low — Names 2 — tests/skills.bats
disposition: fixed — an `if` in `tests/skills.bats`.

**finding-5**: guideline, low — Comments 1, "A comment says why, not what" — tests/skills.bats
disposition: fixed — the comments removed from `tests/skills.bats`.

**finding-6**: guideline, low — Errors 1, "An error is reported where it is detected" — skills/merge-change/SKILL.md
disposition: fixed — step 1's message says the index is not empty, in `skills/merge-change/SKILL.md`.

### Round 3

**finding-1**: guideline, medium — Names 3, "A name says what the thing is in the project's domain" — tests/skills.bats
disposition: fixed — `review_at`, `record_at` and `gate_at` in `tests/skills.bats`.

**finding-2**: guideline, medium — Comments 2 — tests/skills.bats
disposition: fixed — the history comments in `tests/skills.bats` state the current rule.

**finding-3**: guideline, low — Simplicity 4 — tests/skills.bats
disposition: fixed — `step_of` and `sh_fence` reused in `tests/skills.bats`.

**finding-4**: guideline, low — Names 3 — tests/skills.bats
disposition: fixed — `checklist_text` and `preconditions` in `tests/skills.bats`.

### Round 4

**finding-1**: guideline, low — Errors 1/2 — skills/merge-change/SKILL.md
disposition: fixed — step 1 tells a non-empty index from an unreadable one, in `skills/merge-change/SKILL.md`; pinned by "merge-change: the base merge stops while a squash is staged in the primary checkout".

**finding-2**: guideline, low — Simplicity 2, "a helper one script calls stays in that script" — tests/helpers.bash
disposition: fixed — `sh_fence` lives in `tests/skills.bats`.

**finding-3**: guideline, low — Simplicity 4 — tests/skills.bats
disposition: fixed — the label checks kept in "merge-change: the gate runs after the record, on the tree that is signed" only.

**finding-4**: guideline, low — Names 3 — tests/skills.bats
disposition: fixed — `preflight_at` and `ruling_at` in `tests/skills.bats`.

**finding-5**: guideline, low — Comments 2 — tests/skills.bats, tests/prune-plans.bats
disposition: fixed — the provenance tags dropped from `tests/prune-plans.bats` and `tests/skills.bats`.

Round 4 had nothing above low, so it was the last round.

## Gaps

- Two tests have red observed after the implementation, against the base
  (`main`'s skill in a scratch copy), not watched before the implementation
  existed: the D5 tree-check test and the D4 record-before-gate test.
- D2 to D5 are rules written in skill text. Their tests pin the text and the
  step order; no test shows an agent following the order, and D2 and D3 have
  no abnormal-input case beyond the text pins.
- This change was itself merged under the step order on `main`, the one it
  replaces: the gate before the review, then a second gate after the record.
  The new order has not yet run a merge.
- `merge-preflight.sh` was not run against this tree in place, because this
  repository has no `.guardrails/config.yaml`; `check-ids.sh` and
  `check-trace.sh` ran on scratch copies.
- `skills/merge-change/SKILL.md` is at its 2,000-word cap; the next change to
  it must cut what it adds.
