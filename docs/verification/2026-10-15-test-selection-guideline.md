# Verification — test-selection-guideline (2026-10-15)

branch: test-selection-guideline
reviewer: one independent subagent per round, dispatched at `merge-change`
step 4 (step 6a before `base-move-round` renumbered the sequence) with the diff, the plan and the review checklist, and no
implementation narrative; each worked in its own review worktree and ran the
full suite itself.
verdict: approve. The base moved twice after the first review rounds; the last review round, after the second move, raised no `code` or `requirement` finding above low and found both merges consistent with this change; the medium requirement finding of the first round was fixed by T2 (D4).
reproduced: not applicable — the change edits skill and guideline text, not a
defect. The whole-suite wording it replaces was measured on `main`
(`344faa3`): develop-tdd step 4 read "every other test still passes",
develop-refactor step 3 read "Run the project's `verify_commands` after each
fix", and worktree-discipline step 1 sent a task subagent to
`verify_commands`. Each new test was watched fail on that text.

Change: development runs the tests its work touches, and the whole suite runs
once, at the merge gate.
Plan: `docs/plans/2026-10-15-test-selection-guideline.md`.

## The gate

The figures are in the squash commit's trailers (`Gate-tree:`, `Gate:`,
`Base:`). This repository has no `.guardrails/config.yaml`, so
`merge-preflight.sh` stops at its config read; `check-ids.sh` and
`check-trace.sh` were run instead on scratch copies of `main` and of the
change, each built from `templates/config.yaml` with `scripts` as its strict
path and a one-heading stub SRS and SAD. Each printed the same output at
both, and exited 1 at both on the problem backlog this repository carries.
The change adds no ID, item or trace finding. Coverage is not configured.

## Red → green

This repository has no SRS, so the change implements no item and the table
has no rows. Each test the change adds or edits carries
`verifies: D<n> (docs/plans/2026-10-15-test-selection-guideline.md)`; its
`red -> green:` lines are copied here from the plan.

| Item | Test | Watched red |
| --- | --- | --- |

- red -> green: test guidelines: Test runs scopes development runs and leaves the whole suite to the merge gate — watched fail ("templates/TEST_GUIDELINES.md has no Test runs section")
- red -> green: develop-tdd: GREEN runs the guidelines file's selection, not the whole suite — watched fail ("develop-tdd does not name the Test runs section"); its strengthened step-4 check watched fail ("step 4 does not run the Test runs section's selection") with step 4 reverted; its cannot-select check watched fail ("step 4 has no fallback for a runner that cannot select")
- red -> green: develop-refactor: a fix runs the tests that verify what it changes — watched fail ("step 3 does not scope the run"); its Done when check watched fail ("Done when still implies the whole suite") with Done when reverted
- red -> green: test guidelines: the template has the eight headings, in order — watched fail on the missing `## Test runs`
- red -> green: test guidelines: this repository's file has the template's headings except UI — watched fail on the missing `## Test runs`
- red -> green: worktree-discipline: a task subagent runs develop-tdd's selection, not verify_commands — watched fail ("step 1 sends a task subagent to verify_commands"); its extended check watched fail ("step 1 does not name develop-refactor step 3"); its baseline check watched fail ("step 4 lost the baseline run")
- red -> green: develop-change: the dispatcher claims no whole-suite run before the gate — watched fail ("the conformance reviews wait on a whole-suite run")

## What was wrong, and what was built

Over 2026-09-08 to 2026-10-14 this repository ran about 350 full suites
across about 44 merges, at 15 to 75 minutes each. The skills told every
development step to run the whole suite: develop-tdd's GREEN step and Done
when, develop-refactor after each fix, worktree-discipline step 1 for every
task subagent, and develop-change before the conformance reviews. Task
subagents mostly ran single files anyway, against the text.

Built, by the plan's decisions:

- D1: both TEST guidelines files have a `## Test runs` clause: during
  development, run the tests the work touches, through the runner's file or
  name selection; the whole suite runs at the merge gate. The template is at
  its 1,950-word cap.
- D2: develop-tdd step 4 runs that selection, and `verify_commands` where the
  file has no `Test runs` section or the runner cannot select.
- D3: develop-refactor step 3 runs the tests the fix touches, or
  `verify_commands` where the runner cannot select, stated in the skill
  because a refactor dispatch reads no TEST guidelines file.
- D4: worktree-discipline step 1 sends a task subagent to the selection
  develop-tdd step 4 or develop-refactor step 3 states, and develop-change no
  longer waits on a whole-suite run. worktree-discipline step 4's baseline
  still runs the whole suite once, when a change worktree opens.
- An upgrade-notes entry tells an adopting project all of this.

`merge-change` step 1 pruned the plan's code blocks; no plan was left whole.

## Review

### Round 1

**finding-1**: requirement, medium — skills/worktree-discipline/SKILL.md:92 still told a task subagent to run the project's `verify_commands`, contradicting D2 and the plan's Goal.
disposition: step 1 sends it to the selection develop-tdd step 4 or develop-refactor step 3 states (skills/worktree-discipline/SKILL.md); `worktree-discipline: a task subagent runs develop-tdd's selection, not verify_commands` reddens without it. Plan decision D4, task T2.

**finding-2**: requirement, low — skills/develop-change/SKILL.md:127 and :197 required a whole-suite run before the conformance reviews and in Done when.
disposition: both claims dropped (skills/develop-change/SKILL.md); `develop-change: the dispatcher claims no whole-suite run before the gate` reddens without it.

**finding-3**: code, low — tests/test-guidelines.bats:334-344, the D1 test, does not assert that development runs a selection.
disposition: no change — the test pins today's correct clause and was watched fail on its absence; the same gap was accepted at TEST conformance round 2, and tightening it would open another round for no change in the skills. Listed under Gaps.

**finding-4**: requirement, low — develop-tdd had no fallback where the `Test runs` section exists and the runner cannot select.
disposition: step 4's fallback covers a runner that cannot select (skills/develop-tdd/SKILL.md); the cannot-select check in `develop-tdd: GREEN runs the guidelines file's selection, not the whole suite` reddens without it.

**finding-5**: record — each "Code pruned at merge" pointer in the plan lists all of T1's files, not the file its block edited.
disposition: no change — `prune-plans.sh` writes the task's Files touched list by design, and the step's prose names each block's file (docs/plans/2026-10-15-test-selection-guideline.md).

### Round 2

**finding-1**: code, low — no test pinned worktree-discipline step 4's baseline, which D4 keeps; removing its `verify_commands` run would pass the suite (skills/worktree-discipline/SKILL.md:132).
disposition: the test `worktree-discipline: a task subagent runs develop-tdd's selection, not verify_commands` also requires step 4's "run the project's `verify_commands`", and was watched fail with it removed (tests/skills.bats).

**finding-2**: record — tests/develop-tdd.bats:120 cited D4 for the cannot-select fallback, which the plan states in D2.
disposition: the separate D4 comment is removed; the test's own D2 citation covers the check (tests/develop-tdd.bats). Recorded in docs/verification/2026-10-15-test-selection-guideline.md.

**finding-3**: record — the plan header read "Implements: D1–D3" though the plan defines and implements D4.
disposition: the header reads D1–D4 (docs/plans/2026-10-15-test-selection-guideline.md). Recorded in docs/verification/2026-10-15-test-selection-guideline.md.

### Round 3

After round 2 the base merged the change `ratchet-pinned-qualification`,
which edited two files this change also edits:
`skills/ratchet/references/upgrade-notes.md` and `tests/skills.bats`.
`merge-change` step 1 printed both as `shared:`, so this round reviewed the
whole change again. The merge conflicted only at the end of the upgrade
notes, where each change appended an entry; both entries are kept, the
base's first, in the file's oldest-first order. The reviewer found the
resolution correct and ran the full suite on the merged change.

**finding-1**: record — the TEST conformance round 3 finding cited the D4 develop-change test by a line range that the base merge moved, and that was wrong before it.
disposition: it cites the test by name, `develop-change: the dispatcher claims no whole-suite run before the gate` (docs/verification/2026-10-15-test-selection-guideline.md).

**finding-2**: record — the record did not state the base move, the merge and its conflict resolution, or this round, and its verdict was written against round 2.
disposition: this round's account above, and the verdict line covers it (docs/verification/2026-10-15-test-selection-guideline.md).

### Round 4

After round 3 the base merged the change `base-move-round`, which
renumbered `merge-change` and edited four files this change also edits:
`skills/develop-change/SKILL.md`, `skills/worktree-discipline/SKILL.md`,
`skills/ratchet/references/upgrade-notes.md` and `tests/skills.bats`.
`merge-change` step 1 printed all four as `shared:`, so this round reviewed
the whole change again. The merge was clean; the reviewer found both
changes' edits present and in agreement, the word caps held, and every step
number this change cites still right. It ran the full suite on the merged
change.

**finding-1**: record — the plan used the old step number, 6a, for the independent review, which is now step 4.
disposition: the plan names it step 4, noting the old number once (docs/plans/2026-10-15-test-selection-guideline.md).

**finding-2**: record — the record did not account for the second base move, its shared files, or this round, and its verdict described only the first move.
disposition: this round's account above, and the verdict line covers both moves (docs/verification/2026-10-15-test-selection-guideline.md).

**finding-3**: code, low — the upgrade note paraphrased D1 ("the tests that verify what the work touches") instead of the clause's wording ("the tests the work touches: those that verify what it changes").
disposition: the note quotes the clause (skills/ratchet/references/upgrade-notes.md).

## Guideline reviews

`guidelines-file.sh` printed the same path list for all three files, every
path of the change diff.

### docs/TEST_GUIDELINES.md

Governs: every path of the change diff.

### Round 1

**finding-1**: guideline, low — Seams 1, "a test verifies the problem report or the plan decision that states the behavior, at the same seam" — tests/test-guidelines.bats:92, :239
disposition: both heading tests also cite D1 of this plan (tests/test-guidelines.bats).

**finding-2**: guideline, low — floor, "every test fails when the behavior it `verifies:` breaks" — tests/develop-tdd.bats:112-116
disposition: the D2 test reads step 4 with `step_of` (tests/develop-tdd.bats); watched fail with step 4 reverted.

**finding-3**: guideline, low — floor, "every test fails when the behavior it `verifies:` breaks" — tests/develop-refactor.bats:74-87
disposition: the D3 test reads `## Done when` (tests/develop-refactor.bats); watched fail with Done when reverted.

### Round 2

**finding-1**: guideline, low — floor — tests/test-guidelines.bats:334-343 — the D1 test does not assert the selection half of the clause.
disposition: no change — the test pins today's correct text and was watched fail; listed under Gaps.

**finding-2**: guideline, low — floor — tests/develop-tdd.bats:118-119 — the fallback check does not assert `verify_commands`, nor Done when's "That selection is green".
disposition: no change — as finding-1 of this round.

**finding-3**: guideline, low — floor — tests/develop-refactor.bats:79-80 — the fallback check does not assert `verify_commands`.
disposition: no change — as finding-1 of this round.

**finding-4**: guideline, low — Seams 1 — tests/develop-refactor.bats:38-41 — "no behavior change, and no test loosened" pins this change's wording but cites only D1 of the 2026-10-13 plan.
disposition: no change — its behavior is that plan's D1; only the pinned phrases moved, and `develop-refactor: a fix runs the tests that verify what it changes` verifies the new run scope.

### Round 3

**finding-1**: guideline, low — floor — tests/skills.bats, `develop-change: the dispatcher claims no whole-suite run before the gate` — makes only negative assertions on two literal strings.
disposition: no change — as round 2 finding-1; listed under Gaps.

### docs/CODE_GUIDELINES.md

Governs: every path of the change diff.

### Round 1

**finding-1**: guideline, medium — Names 1, "No single-character names." — tests/test-guidelines.bats:336
disposition: the loop variable is `guidelines` (tests/test-guidelines.bats).

**finding-2**: guideline, medium — Names 4, "where the codebase already names it, that name" — tests/test-guidelines.bats:336
disposition: as finding-1; the file's other loop over the same files already used `guidelines` (tests/test-guidelines.bats).

**finding-3**: guideline, low — Names 4, "A concept has one name in every file, test and task of the change" — skills/develop-refactor/SKILL.md:29
disposition: step 3 uses the TEST clause's wording, "the tests the fix touches: those that verify what it changes, and those it adds or edits", and its green claims say "the tests you run" (skills/develop-refactor/SKILL.md).

### Round 2

**finding-1**: guideline, low — Names 4 — skills/ratchet/references/upgrade-notes.md:709 — the note kept the old "cover" wording.
disposition: the note uses step 3's wording (skills/ratchet/references/upgrade-notes.md).

**finding-2**: guideline, low — Names 4 — tests/develop-tdd.bats:114 — the flattened file is `body` where the codebase says `flat`.
disposition: no change — a local name inside one test, which reads correctly.

### Round 3

**finding-1**: guideline, low — Names 4 — skills/worktree-discipline/SKILL.md:92 — "`develop-tdd` step 4's tests" where the change says "the selection", and step 1 governs a develop-refactor fix dispatch too.
disposition: step 1 reads "run the selection `develop-tdd` step 4 or `develop-refactor` step 3 states" (skills/worktree-discipline/SKILL.md).

### docs/ARCHITECTURE_GUIDELINES.md

Governs: every path of the change diff.

### Round 1

No findings; verdict "0 findings ... none above low".

### Round 2

**finding-1**: guideline, low — Domain 2, "One term, one meaning, across the repository" — templates/TEST_GUIDELINES.md:216, docs/TEST_GUIDELINES.md:224, skills/develop-refactor/SKILL.md:29 — "the tests the work touches" widens "touches" beyond the paths a change edits.
disposition: no change — each use is followed at once by a colon that defines the selection, and the template is at its word cap. Listed under Gaps.

### Round 3

No findings; verdict "0 findings (0 high, 0 medium, 0 low); nothing above low".

## Gaps

- The D1, D2, D3 and D4 tests pin today's wording; a rewording that restored
  a whole-suite run in other words could pass them (step 4 round 1
  finding-3; TEST conformance round 2 and round 3).
- "touches" in the `Test runs` clause has a wider meaning than in
  `**Files touched:**` (ARCHITECTURE round 2).
- `merge-change` step 4's reviewer still runs the whole suite; scoping it is
  the separate change `reviewer-scoped-suite`.
- The `templates/TEST_GUIDELINES.md` template is at its 1,950-word cap; the
  next clause must cut words.
