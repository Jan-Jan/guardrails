# Verification — reviewer-scoped-suite (2026-10-15)

branch: reviewer-scoped-suite
reviewer: one independent subagent per round, dispatched at `merge-change`
step 4 with the diff, the plan and the review checklist, and no
implementation narrative; each worked in its own review worktree and, under
the rule this change adds, ran only `tests/skills.bats`, which holds every
test the diff adds or edits (173 passed, 0 failed, in each round).
verdict: approve. Round 1 raised no `code` or `requirement` finding above
low; its low findings were fixed and its record finding corrected. Local
`main` then advanced, and its merge touched `skills/ratchet/references/upgrade-notes.md`,
a file this change edits (a `shared:` line), so round 2 reviewed the whole
change again. It found both upgrade-notes entries whole and in order, and
raised no finding above low.
reproduced: not applicable — the change edits skill and reference text, not a
defect. The whole-suite wording it replaces was measured on `main`
(`2bc3cca`): step 4 read "**The reviewer runs the suite itself** in its
worktree and reports the counts". Each new test was watched fail on that
text.

Change: a review round runs no full suite; the reviewer runs only the tests it
judges, and step 6a's gate is the one full run.
Plan: `docs/plans/2026-10-15-reviewer-scoped-suite.md`.

## The gate

The figures are in the squash commit's trailers (`Gate-tree:`, `Gate:`,
`Base:`). This repository has no `.guardrails/config.yaml`, so
`merge-preflight.sh` stops at its config read; `check-ids.sh` and
`check-trace.sh` were run instead on scratch copies of `main` and of the
change, each built from `templates/config.yaml` with `scripts` as its strict
path and a one-heading stub SRS and SAD. Each printed the same output at
both, and exited 1 at both on the problem backlog this repository carries.
The comparison was run again after each base merge, against `main` as the
`Base:` trailer names it. The change adds no ID, item or trace finding. Coverage is not configured.

## Red → green

This repository has no SRS, so the change implements no item and the table
has no rows. Each test the change adds or edits carries
`verifies: D<n> (docs/plans/2026-10-15-reviewer-scoped-suite.md)`, except the
edited base-move-round test, which keeps its own; the `red -> green:` lines
are copied here from the plan and the fix reports.

| Item | Test | Watched red |
| --- | --- | --- |

- red -> green: merge-change: the reviewer runs only the tests it judges — watched fail ("step 4 does not scope the reviewer's run"); its selection checks watched fail with either half of the selection deleted ("step 4 does not select each verifies: test of a claimed ID", "step 4 does not select the test files the diff adds or edits"); its fallback check watched fail with the fallback reversed ("step 4 does not run the whole suite where the runner cannot select")
- red -> green: merge-change: the step 6a gate is the round's only full run — watched fail ("step 4 does not name 6a's gate as the full run"); its count check watched fail with a third whole-suite run added to step 4 ("step 4 names 3 whole-suite runs, not the fallback and 6a's gate")
- red -> green: merge-change: the rationale states what scoping the reviewer costs — watched fail ("no rationale section for the scoped run"); its per-statement checks watched fail with each statement deleted ("the rationale does not state that the 6a gate keeps the counts independent", "the rationale does not state where a regression outside the selection surfaces", "the rationale does not state that the regression's fix dispatches a reviewer", "the rationale does not settle a skill-text diff that claims tested IDs", "the rationale does not define a documentation-only diff by its selection", "step 6a's rationale does not give the selection as the reason"); with the old reason restored ("step 6a's rationale still gives the old reason"); and with the upgrade note's heading or gate sentence changed ("no upgrade note for the scoped run", "the upgrade note does not say the step 6a gate is the one full run")

## What was wrong, and what was built

Over 2026-09-08 to 2026-10-14 this repository ran about 350 full suites
across about 44 merges; 157 of them were started by reviewers. After
`base-move-round`, the step 6a gate runs once, in the last round, and the
remaining per-round full run was the reviewer's.

Built, by the plan's decisions:

- D1: `merge-change` step 4's reviewer runs each `verifies:` test of a claimed
  ID and each test file the diff adds or edits, or the whole suite where the
  runner cannot select.
- D2: 6a's gate runs the whole suite; a documentation-only diff's reviewer
  runs no tests, and the record states it.
- D3: the rationale section "Step 4: the reviewer runs the tests it judges"
  states that 6a keeps the counts independent, that a regression outside the
  selection surfaces at 6a and its fix dispatches a reviewer, and that a diff
  whose claimed IDs have `verifies:` tests is not documentation-only. An
  upgrade-notes entry tells an adopting project.
- To stay within the 2,000-word cap, `merge-change/SKILL.md` lost five
  restatements; step 1 keeps "Run this step every round.".

`merge-change` step 1 pruned the plan's code blocks; no plan was left whole.

## Review

### Round 1

**finding-1**: requirement, low — skills/merge-change/SKILL.md:113-117 — step 4's "each `verifies:` test of a claimed ID" and "A documentation-only diff's reviewer runs no tests" conflict for a skill-text diff that claims tested IDs.
disposition: the rationale states that such a diff is not documentation-only and its reviewer runs them, and that a documentation-only diff is one whose selection is empty (skills/merge-change/references/rationale.md); `merge-change: the rationale states what scoping the reviewer costs` reddens without either sentence.

**finding-2**: requirement, low — skills/merge-change/references/rationale.md:333-336 — the Step 6a section kept the old reason, "no gate summary to hand its reviewer".
disposition: it says the reviewer runs no tests because its selection is empty (skills/merge-change/references/rationale.md); the D3 test rejects the old reason.

**finding-3**: code, low — tests/skills.bats:2986 — the D3 test's upgrade-note check did not anchor on the entry's heading or check the gate statement.
disposition: it anchors on `## The reviewer runs only the tests it judges` and asserts the entry names the step 6a gate as the one full run (tests/skills.bats).

**finding-4**: code, low — tests/skills.bats:2961-2969 — the D2 test did not check "only".
disposition: it asserts step 4 names exactly two whole-suite runs, the fallback and 6a's gate (tests/skills.bats).

**finding-5**: record — docs/plans/2026-10-15-reviewer-scoped-suite.md:139 — the Done note misquoted the phrase step 2 cut.
disposition: it quotes "through the runner's file or name selection" (docs/plans/2026-10-15-reviewer-scoped-suite.md).

### Round 2

**finding-1**: record — docs/verification/2026-10-15-reviewer-scoped-suite.md:4-10 — the `reviewer:` and `verdict:` fields named one review round, though the base merge sent the change back to step 4.
disposition: both fields name round 2, what it ran and its verdict (docs/verification/2026-10-15-reviewer-scoped-suite.md).

**finding-2**: record — docs/verification/2026-10-15-reviewer-scoped-suite.md:22-30 — the gate section did not say which `main` the ID and trace comparison used, after `main` moved.
disposition: the comparison was rerun on the merged tree, and the section says it ran after each base merge against the `main` the `Base:` trailer names (docs/verification/2026-10-15-reviewer-scoped-suite.md).

**finding-3**: requirement, low — skills/merge-change/references/rationale.md:336-339 — the documentation-only sentence no longer reads as a cost of gating after the record.
disposition: no change — with the gate after the review, a documentation-only diff's tree gets no test run before 6a, which is the cost the sentence states (skills/merge-change/references/rationale.md); the selection rule says why the reviewer runs nothing.

## Guideline reviews

`guidelines-file.sh` printed the same path list for all three files, every
path of the change diff.

### docs/TEST_GUIDELINES.md

Governs: every path of the change diff.

### Round 1

**finding-1**: guideline, medium — floor, "every test fails when the behavior it `verifies:` breaks" — tests/skills.bats:2944-2956 — the D1 test's `` `verifies:` `` grep matched an older sentence of step 4, and nothing asserted "each test file the diff adds or edits".
disposition: the D1 test asserts "each `verifies:` test of a claimed ID" and "each test file the diff adds or edits" (tests/skills.bats).

**finding-2**: guideline, medium — the same floor clause — tests/skills.bats:2970-2985 — the D3 test grepped the rationale for "6a" and "regression" only.
disposition: the D3 test asserts one phrase per statement (tests/skills.bats).

### Round 2

**finding-1**: guideline, low — floor — tests/skills.bats:2954 — the fallback check grepped only "cannot select", so a reversed fallback passed.
disposition: the D1 test asserts "the whole suite where the runner cannot select" (tests/skills.bats).

### docs/CODE_GUIDELINES.md

Governs: every path of the change diff.

### Round 1

**finding-1**: guideline, low — Names 3 and 4 — tests/skills.bats:2974 — `body` held `section_of`'s output, which the file names `section`.
disposition: renamed `section` in the test and the plan (tests/skills.bats).

**finding-2**: guideline, low — Names 4 — tests/skills.bats:2947 — step 4's flattened text had three treatments across the tests.
disposition: all three tests name it `step_4` and compute it once (tests/skills.bats).

### docs/ARCHITECTURE_GUIDELINES.md

Governs: every path of the change diff.

### Round 1

No findings; verdict "0 findings (0 high, 0 medium, 0 low); none above low".

## Gaps

- The D1, D2 and D3 tests pin today's wording; a rewording that restored a
  whole-suite reviewer run in other words could pass them.
- A regression outside the reviewer's selection now surfaces at 6a, after the
  review; its fix dispatches a reviewer (the rationale's stated cost).
- Step 6a no longer repeats "Do not run it in your own context."; the rule is
  in `verify-before-merge` and AGENTS.md non-negotiable 3.
- Round 1 was dispatched without the `review dispatched` marker commit step 4
  states; round 2 has it (`f35a4a9` on the branch). Step 1 found the shared
  file by comparing with the last reviewed state by hand.
