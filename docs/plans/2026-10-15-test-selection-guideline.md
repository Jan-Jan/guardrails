# Test Selection Guideline Implementation Plan

**Goal:** Development runs only the tests its work touches, and the whole
suite runs once, at the merge gate.
**Implements:** D1–D4 below; guardrails keeps no REQ ledger of its own. Each
test cites `verifies: D<n> (docs/plans/2026-10-15-test-selection-guideline.md)`.
**Resolves:** none.
**Safety class:** not configured in this repository; worked as class B (normal
and abnormal cases for each changed rule)
**Verification:** `tests/run-tests.sh`, every test passing.
**Base:** local `main` at `344faa3`, per AGENTS.md non-negotiable 4. Baseline:
`main`'s tree `49244466` is the `Gate-tree:` of 344faa3, so the baseline was
not run again.

This is the follow-up to `reviewer-scoped-suite`
(`docs/plans/2026-10-15-reviewer-scoped-suite.md` on its branch), which
scopes the reviewer's run. The user approved splitting it out on 2026-10-15:
"lets focus the existing D1-D3 and D4-5 as a follow-up". The two changes
touch disjoint files except `skills/ratchet/references/upgrade-notes.md`,
where each appends its own entry.

## Investigation

- `develop-tdd` step 4 reads "run the test; every other test still passes",
  and its Done when reads "The suite is green". Followed literally, each task
  runs the whole suite, which takes 15 to 75 minutes here. In practice task
  subagents mostly ran single files: over 2026-09-08..10-14 there were 6,575
  single-file runs and about 30 full runs by agents other than gates and
  reviewers. The skill text says one thing and agents do another.
- `develop-refactor` step 3 reads "Run the project's `verify_commands` after
  each fix". That is a whole-suite run per finding.
- The merge gate (`verify-before-merge`) runs the whole suite on the tree
  that is signed. It is the compliance evidence, so the whole-suite rule
  stays in the skills.
- ADR-me39p4: a rule a standard or a gate needs is floor and stays in the
  skills; everything else is a preference in `<KIND>_GUIDELINES.md`. Which
  tests to run during development is a preference, and the selection
  command is project-specific.
- Each subagent reads exactly one guidelines file. `develop-tdd` reads the
  TEST file. `develop-refactor` reads the CODE or ARCHITECTURE file, so it
  cannot read a TEST clause, and its rule goes in the skill.
- `templates/TEST_GUIDELINES.md` is at 1,894 words, under a 1,950 cap
  (`tests/test-guidelines.bats`, "the template is at most 1,950 words").
  The new section must fit in 56 words or cut an equal number elsewhere.
  Two tests pin the exact heading list: "the template has the seven
  headings, in order" and "this repository's file has the template's
  headings except UI".
- A guidelines file names no guardrails document or skill
  (`names_no_guardrails_document_or_skill` in `tests/helpers.bash`). The new
  clause says "the merge gate", never a skill name.

## Decisions

- **D1: a `## Test runs` section in both TEST guidelines files.** It goes
  before `## Existing suites`, with one clause: during development, run the
  tests that verify what the work touches and the tests it adds or edits,
  through the runner's file or name selection. The whole suite runs at the
  merge gate. The clause has a `Why:` and an `Example:`, like every clause.
  The template and this repository's `docs/TEST_GUIDELINES.md` both get it,
  and the two heading tests list `## Test runs`.
- **D2: `develop-tdd` runs the selection its guidelines file states.** Step
  4 and Done when stop implying a whole-suite run. Where the guidelines file
  has no `Test runs` section (a project tailored before this change), it
  runs the project's `verify_commands`, as today, and so it does where the
  runner cannot select (added by T2).
- **D3: `develop-refactor` runs the tests that cover the code it changed.**
  Step 3 says this in the skill itself, because a refactor dispatch reads no
  TEST guidelines file. Where the runner cannot select, it runs
  `verify_commands`. An upgrade-notes entry covers D1 to D3.
- **D4: no other development step runs the whole suite.** Added after the
  `merge-change` step 4 review (step 6a before `base-move-round` renumbered it) (finding-1 and finding-2, 2026-10-15). `worktree-discipline`
  step 1 tells a task subagent to "run the project's `verify_commands`"; it
  defers to `develop-tdd` step 4 instead. `develop-change` starts the
  conformance reviews "when the last task branch is merged and the suite is
  green" and lists "The suite is green" in Done when; both drop the
  whole-suite claim, since the merge gate runs it. `worktree-discipline`
  step 4's baseline stays: it is the one run before work starts, and finds
  a red base. Folded into D2 (finding-4): `develop-tdd` also falls back to
  `verify_commands` where the runner cannot select.

## Tasks

### T1 — The Test runs clause and the develop skills that follow it

**Files touched:** templates/TEST_GUIDELINES.md, docs/TEST_GUIDELINES.md,
skills/develop-tdd/SKILL.md, skills/develop-refactor/SKILL.md,
skills/ratchet/references/upgrade-notes.md, tests/test-guidelines.bats,
tests/develop-tdd.bats, tests/develop-refactor.bats
**Parallel:** no (the only task)

Load the skill at `skills/develop-tdd/SKILL.md` in the change worktree. This
repository has no `.guardrails/`; its scripts are under `scripts/`.

1. RED. In `tests/test-guidelines.bats`, add `## Test runs` before
   `## Existing suites` in the expected heading lists of "the template has
   the seven headings, in order" (rename it "the template has the eight
   headings, in order") and "this repository's file has the template's
   headings except UI". Then add:

   *(Code pruned at merge: 11 lines. Files touched: templates/TEST_GUIDELINES.md, docs/TEST_GUIDELINES.md, skills/develop-tdd/SKILL.md, skills/develop-refactor/SKILL.md, skills/ratchet/references/upgrade-notes.md, tests/test-guidelines.bats, tests/develop-tdd.bats, tests/develop-refactor.bats.)*

   In `tests/develop-tdd.bats`:

   *(Code pruned at merge: 15 lines. Files touched: templates/TEST_GUIDELINES.md, docs/TEST_GUIDELINES.md, skills/develop-tdd/SKILL.md, skills/develop-refactor/SKILL.md, skills/ratchet/references/upgrade-notes.md, tests/test-guidelines.bats, tests/develop-tdd.bats, tests/develop-refactor.bats.)*

   In `tests/develop-refactor.bats`:

   *(Code pruned at merge: 15 lines. Files touched: templates/TEST_GUIDELINES.md, docs/TEST_GUIDELINES.md, skills/develop-tdd/SKILL.md, skills/develop-refactor/SKILL.md, skills/ratchet/references/upgrade-notes.md, tests/test-guidelines.bats, tests/develop-tdd.bats, tests/develop-refactor.bats.)*

   Before relying on `section_of` and `step_of` in these files, check each
   file loads `tests/helpers.bash` and that `$template` and
   `$repo_guidelines` are set in `tests/test-guidelines.bats`'s `setup`.
   Run `sh tests/run-tests.sh tests/test-guidelines.bats
   tests/develop-tdd.bats tests/develop-refactor.bats`. Expected: the two
   heading tests and the three new tests fail, each with its `echo` message,
   and every other test passes.

2. GREEN, both TEST guidelines files: add before `## Existing suites`:

   > ## Test runs
   >
   > 1. **During development, run the tests the work touches**: those that
   >    verify what it changes, and those it adds or edits, through the
   >    runner's file or name selection. The whole suite runs at the merge
   >    gate. Why: a whole-suite run per step costs minutes and finds what
   >    the gate finds. Example: `<runner> tests/parser_test.ext`.

   Keep the template at or under 1,950 words; cut only restatements, and
   only text no `tests/test-guidelines.bats` assertion greps. This
   repository's file uses its own runner in the example:
   `sh tests/run-tests.sh tests/<file>.bats`.

3. GREEN, `skills/develop-tdd/SKILL.md`: step 4 becomes "run the test, then
   the selection the guidelines file's `Test runs` section states; the
   output is clean". Add once: "A guidelines file with no `Test runs`
   section means the project's `verify_commands`." Done when's "The suite
   is green and its output is clean" becomes "That selection is green and
   its output is clean."

4. GREEN, `skills/develop-refactor/SKILL.md` step 3: replace "Run the
   project's `verify_commands` after each fix" with "After each fix, run
   the tests that cover the code it changed, or `verify_commands` where the
   runner cannot select". Done when's "The suite is green" becomes "Those
   tests are green".

5. GREEN, `skills/ratchet/references/upgrade-notes.md`: add an entry at the
   top, in the shape of the entries there. It says the TEST guidelines
   template gained `## Test runs`, adopted clause by clause on upgrade, and
   that `develop-tdd` and `develop-refactor` now run a selection, with the
   whole suite left to the merge gate.

6. Run the three files from step 1 again, then `sh tests/run-tests.sh
   tests/skills.bats` (word caps and the skill shape). Expected: every test
   passes. Commit unsigned on the task branch.

### T2 — No other development step runs the whole suite

**Files touched:** skills/worktree-discipline/SKILL.md,
skills/develop-change/SKILL.md, skills/develop-tdd/SKILL.md,
skills/ratchet/references/upgrade-notes.md, tests/skills.bats,
tests/develop-tdd.bats
**Parallel:** no (serial, after T1)

Load the skill at `skills/develop-tdd/SKILL.md` in the change worktree.

1. RED, `tests/skills.bats`, after "develop-change: the conformance reviews
   run for ARCHITECTURE too": add "worktree-discipline: a task subagent runs
   develop-tdd's selection, not verify_commands" and "develop-change: the
   dispatcher claims no whole-suite run before the gate", each with
   `# verifies: D4 (docs/plans/2026-10-15-test-selection-guideline.md)`.
   The first reads `step_of "$skill" 1`, flattened, and fails if it contains
   "run the project's `verify_commands`", and passes only if it names
   `develop-tdd` step 4. The second fails if the flattened develop-change
   SKILL.md contains "and the suite is green" or its `## Done when` section
   contains "The suite is green". In `tests/develop-tdd.bats`, extend the D2
   test: step 4 also names "cannot select". Run
   `sh tests/run-tests.sh tests/skills.bats tests/develop-tdd.bats`;
   expected: these three fail with their `echo` messages, the rest pass.
2. GREEN, `skills/worktree-discipline/SKILL.md` step 1: "Then edit, run the
   project's `verify_commands`, commit on the task branch (unsigned,
   `develop-tdd` step 6)" becomes "Then edit, run the tests `develop-tdd`
   step 4 names, commit on the task branch (unsigned, step 6)", or wording
   no longer than the original. The file is at its 2,000-word cap: cut an
   equal number of words elsewhere only from restatements no test greps.
3. GREEN, `skills/develop-change/SKILL.md`: "When the last task branch is
   merged and the suite is green" becomes "When the last task branch is
   merged"; drop "- The suite is green." from Done when.
4. GREEN, `skills/develop-tdd/SKILL.md` step 4: the fallback reads "A
   guidelines file with no `Test runs` section, or a runner that cannot
   select, means the project's `verify_commands`."
5. GREEN, the last upgrade-notes entry gains one sentence: the task
   subagent's and the dispatcher's own steps no longer run the whole suite.
6. Run the files from step 1 again; every test passes. Commit unsigned.

## Done

### T1 — done (f8f032f)

```
red -> green: test guidelines: Test runs scopes development runs and leaves the whole suite to the merge gate — watched fail for the right reason ("templates/TEST_GUIDELINES.md has no Test runs section") before the implementation existed
red -> green: develop-tdd: GREEN runs the guidelines file's selection, not the whole suite — watched fail for the right reason ("develop-tdd does not name the Test runs section") before the implementation existed
red -> green: develop-refactor: a fix runs the tests that cover the changed code — watched fail for the right reason ("step 3 does not scope the run") before the implementation existed
red -> green: test guidelines: the template has the eight headings, in order (edited from "seven headings"; expected list gains ## Test runs) — watched fail on the missing heading before the implementation existed
red -> green: test guidelines: this repository's file has the template's headings except UI (expected list gains ## Test runs) — watched fail on the missing heading before the implementation existed
```

RED run of the three files: 38 passed, 5 failed (the five above). GREEN run
of those three files and `tests/skills.bats`: 192 passed, 0 failed.

Deviations: the upgrade-notes entry is appended at the end, not the top,
because that file is ordered oldest first. The template is now at exactly
1,950 words, its cap.

## Guideline reviews

### Round 1

CODE (docs/CODE_GUIDELINES.md):

1. medium, Names 1: `for f in "$template" "$repo_guidelines"` at
   tests/test-guidelines.bats:336 uses a single-character name. Open.
2. medium, Names 4: the same file names that loop variable `guidelines` at
   line 288. Open; the same fix as finding 1.
3. low, Names 4: develop-refactor step 3 says "the tests that cover the code
   it changed", against the TEST clause's "the tests the work touches".
   Open.

ARCHITECTURE (docs/ARCHITECTURE_GUIDELINES.md): no findings. Its note that
develop-refactor step 3 still says "the suite must stay green" and "keep the
suite green" is taken into the CODE fix with finding 3.

TEST (docs/TEST_GUIDELINES.md):

1. low, Seams 1: the two edited heading tests (tests/test-guidelines.bats:92
   and :239) now pin `## Test runs` but do not cite D1 in `verifies:`. Open.
2. low, floor: the D2 test (tests/develop-tdd.bats:112-116) greps the whole
   SKILL.md, so the fallback sentence alone satisfies it; scope it to step 4.
   Open.
3. low, floor: the D3 test (tests/develop-refactor.bats:74-87) does not check
   develop-refactor's Done when. Open.

Round 1 has two findings above low (CODE 1 and 2, one fix). The lows are
fixed in the same dispatches: CODE first (develop-refactor), then TEST
(develop-tdd), serially, as both touch the test files.

Fix dispatch code-r1 (develop-refactor; 49457bf, 32595a9), merged:

- CODE 1 and 2: fixed. The D1 loop variable is `guidelines`.
- CODE 3: fixed. develop-refactor step 3 reads "run the tests the fix
  touches: those that verify what it changes, and those it adds or edits",
  the TEST clause's wording, with `verify_commands` where the runner cannot
  select. Its "green" claims (step 3, red-flag row) now say "the tests you
  run". The D3 test is renamed "develop-refactor: a fix runs the tests that
  verify what it changes" and greps the new wording; it fails against the
  old text with "step 3 does not scope the run". The existing test "no
  behavior change, and no test loosened" pins the new phrases in place of
  the old ones. Result: 180 passed, 0 failed (test-guidelines, develop-refactor,
  skills).

Fix dispatch test-r1 (develop-tdd; 5ad83c0), merged:

- TEST 1: fixed. Both heading tests also cite D1 of this plan.
- TEST 2: fixed. The D2 test reads `step_of "$skill" 4` for the selection.
- TEST 3: fixed. The D3 test reads `## Done when`.

```
red -> green: develop-tdd: GREEN runs the guidelines file's selection, not the whole suite — strengthened step-4 check watched fail ("step 4 does not run the Test runs section's selection") with step 4 reverted to a whole-suite run and the fallback kept; green after restore
red -> green: develop-refactor: a fix runs the tests that verify what it changes — new Done when check watched fail ("Done when still implies the whole suite") with Done when reverted to "The suite is green."; green after restore
```

Result: 43 passed, 0 failed (test-guidelines, develop-tdd, develop-refactor).

### Round 2

CODE (docs/CODE_GUIDELINES.md), nothing above low:

1. low, Names 4: the upgrade note (skills/ratchet/references/upgrade-notes.md:709)
   still says "the tests that cover the code each fix changed", the wording
   code-r1 replaced in the skill, and leaves out "and those it adds or edits".
2. low, Names 4: tests/develop-tdd.bats:114 names the flattened skill file
   `body`, where the codebase calls it `flat`.

ARCHITECTURE (docs/ARCHITECTURE_GUIDELINES.md), nothing above low:

1. low, Domain 2: "the tests the work touches" (both TEST files) and "the
   tests the fix touches" (develop-refactor step 3) widen "touches", which
   elsewhere means the paths a change edits (`**Files touched:**`).

TEST (docs/TEST_GUIDELINES.md), nothing above low:

1. low, floor: the D1 test does not assert that development runs a
   selection, only `merge gate`, `Why:` and `Example:`.
2. low, floor: the D2 test does not assert the fallback names
   `verify_commands`, nor that Done when says "That selection is green".
3. low, floor: the D3 test does not assert step 3 names `verify_commands`.
4. low, Seams 1: "develop-refactor: no behavior change, and no test
   loosened" now pins this change's wording but cites only D1 of the
   2026-10-13 plan.

Round 2 is the last: no review has a finding above low.

Dispositions of the round 2 lows:

- CODE 1 (upgrade note wording): fixed by dispatch code-r2, because the note
  is what an adopting project reads and stated a narrower rule than the
  skill. code-r2 also rewords develop-refactor step 3's "commit it", which
  read as committing `verify_commands` (a CODE reviewer's note).
- CODE 2 (`body` for the flattened file in tests/develop-tdd.bats): accepted.
  A local name inside one test; the test reads correctly.
- ARCHITECTURE 1 ("touches" widened): accepted. Each use is followed at once
  by a colon that defines the selection, and the template is at its
  1,950-word cap.
- TEST 1 to 3 (assertions that a rewording could slip past): accepted. Each
  test pins today's correct text and was watched fail; tightening them
  further would open another review round for no change in the skills.
- TEST 4 (`verifies:` of the edited refactor test): accepted. The test's
  behavior is D1 of the 2026-10-13 plan; only the pinned phrases moved, and
  the D3 test verifies the new run scope.

Fix dispatch code-r2 (develop-refactor; 7add97b), merged: the upgrade note
uses step 3's wording, and step 3 reads "Where the runner cannot select, run
`verify_commands`. Commit each fix unsigned". Result: 158 passed, 0 failed
(develop-refactor, skills).

## Traceability

This repository has no `.guardrails/config.yaml`. `check-ids.sh` and
`check-trace.sh` ran on scratch copies of `main` (344faa3) and of the change
(43c239c), each with `templates/config.yaml` (strict path `scripts`) and a
one-heading stub SRS and SAD so the REQ and SDD gates can run. Each printed
the same output at both: `check-ids.sh` exit 1, `check-trace.sh` exit 1, on
the backlog this repository carries (`checked: REQ 11, HAZ 3, RC 3, SDD 3,
LLR 3, PR 101, ADR 13`; `problems: open 23`). The change adds no ID, item or
trace finding.

## Step 4 review, round 1 (reviewed e12cae0; gate 1453/1453 on tree bc03817)

Reviewer's own run: 1453 of 1453 passed. verdict: one medium requirement
finding, so not the last round.

1. requirement, medium: worktree-discipline step 1 still sends a task
   subagent to `verify_commands`. Fixed by T2 (D4).
2. requirement, low: develop-change claims a whole-suite run before the
   conformance reviews and in Done when. Fixed by T2 (D4).
3. code, low: the D1 test does not assert the selection half of the
   clause. Accepted, as round 2 TEST 1.
4. requirement, low: develop-tdd has no fallback where the section exists
   and the runner cannot select. Fixed by T2 (D2 step 4).
5. record: each "Code pruned at merge" pointer lists all of T1's files, not
   the file its block edited. Accepted: `prune-plans.sh` writes the task's
   Files touched list by design; the step's prose names each block's file.

### T2 — done (9c73792)

```
red -> green: worktree-discipline: a task subagent runs develop-tdd's selection, not verify_commands — watched fail for the right reason ("step 1 sends a task subagent to verify_commands") before the implementation existed
red -> green: develop-change: the dispatcher claims no whole-suite run before the gate — watched fail for the right reason ("the conformance reviews wait on a whole-suite run") before the implementation existed
red -> green: develop-tdd: GREEN runs the guidelines file's selection, not the whole suite — extended check watched fail for the right reason ("step 4 has no fallback for a runner that cannot select") before the implementation existed
```

RED run (skills, develop-tdd): 160 passed, 3 failed (the three above). GREEN
run (skills, develop-tdd, develop-refactor): 172 passed, 0 failed.

Deviations: step 1 keeps "(unsigned, `develop-tdd` step 6)", which an
existing develop-tdd test greps, and reads "run `develop-tdd` step 4's
tests"; "pass it the path you just created" became "pass it the new path"
to stay under the cap (1,999 words). The upgrade note gained two sentences.

## Guideline reviews, round 3 (after T2)

CODE (docs/CODE_GUIDELINES.md), nothing above low:

1. low, Names 4: worktree-discipline step 1 says "`develop-tdd` step 4's
   tests" where the change otherwise says "the selection". Its note: step 1
   governs a develop-refactor fix dispatch too, which step 3 of that skill
   scopes, not develop-tdd step 4.

ARCHITECTURE (docs/ARCHITECTURE_GUIDELINES.md): no findings. Notes taken
into the round 3 fix: the upgrade note's "no longer run the whole suite"
reads as absolute though the baseline stays, and its "`develop-tdd` does
too" is ambiguous.

TEST (docs/TEST_GUIDELINES.md), nothing above low:

1. low, floor: the D4 develop-change test makes only negative assertions on
   two literal strings. Accepted, as round 2 TEST 1 to 3.

Round 3 is the last: no review has a finding above low. Fix dispatch
wording-r3 takes CODE 1 and the notes on the same lines: worktree-discipline
step 1 names both skills' selections; the upgrade note keeps the baseline
out of its "no longer run the whole suite" sentence and names develop-tdd's
fallback plainly; develop-tdd's red-flag row "The suite is green" says
"That selection is green". D2's text now states the cannot-select fallback.

Fix dispatch wording-r3 (develop-refactor; 396aca5), merged: CODE 1 and the
notes fixed as listed. worktree-discipline step 1 reads "run the selection
`develop-tdd` step 4 or `develop-refactor` step 3 states"; six words cut
from step 8's restatement of the path keep it at 1,999.

```
red -> green: worktree-discipline: a task subagent runs develop-tdd's selection, not verify_commands — extended check watched fail ("step 1 does not name develop-refactor step 3") before the SKILL.md edit; green after
```

Result: 176 passed, 0 failed (skills, develop-tdd, tailor-guidelines).

## Step 4 review, round 2 (reviewed eaea763; gate 1455/1455 on tree 8602941)

Reviewer's own run: 1455 of 1455 passed. verdict: no `code` or
`requirement` finding above low, so the last review round.

1. code, low: no test pins worktree-discipline step 4's baseline, which D4
   keeps. Fixed by dispatch review-r2.
2. record: tests/develop-tdd.bats:120 cites D4 for the cannot-select
   fallback, which D2 states. Fixed by dispatch review-r2.
3. record: the header said "Implements: D1–D3". Now D1–D4.

Fix dispatch review-r2 (develop-tdd; c12a68e), merged: findings 1 and 2.

```
red -> green: worktree-discipline: a task subagent runs develop-tdd's selection, not verify_commands — baseline check watched fail ("step 4 lost the baseline run") with the phrase removed from step 4; green after restore
```

Result: skills 151 passed, develop-tdd 12 passed, 0 failed.

## Step 4 review, round 3 (after the base moved)

The base merged `ratchet-pinned-qualification`, which edited
upgrade-notes.md and tests/skills.bats; step 1 printed both as `shared:`.
The upgrade-notes conflict kept both appended entries, the base's first.
Reviewer's own run: 1485 of 1485 passed. No `code` or `requirement`
finding; two `record` findings (a stale line citation, the missing account
of this round), fixed in the record.

## Step 4 review, round 4 (after the base moved again)

The base merged `base-move-round`, which renumbered `merge-change` (the
independent review is now step 4, the record step 5, the gate 6a) and edited
develop-change, worktree-discipline, upgrade-notes.md and tests/skills.bats;
step 1 printed all four as `shared:`. The merge was clean. Reviewer's own
run: 1494 of 1494 passed. verdict: approve, the last review round.

1. record: this plan used the old step number for the review. Fixed here.
2. record: the record did not account for this base move or this round.
   Fixed in the record.
3. code, low: the upgrade note paraphrased D1 instead of quoting the
   clause. Fixed by dispatch note-r4.
