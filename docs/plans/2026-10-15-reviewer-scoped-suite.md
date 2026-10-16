# Reviewer Scoped Suite Implementation Plan

**Goal:** A review round runs no full suite: the reviewer runs only the tests
it judges, and step 6a's gate is the one full run per round.
**Implements:** D1–D3 below; guardrails keeps no REQ ledger of its own. Each
test cites `verifies: D<n> (docs/plans/2026-10-15-reviewer-scoped-suite.md)`.
**Resolves:** none.
**Safety class:** not configured in this repository; worked as class B (normal
and abnormal cases for each changed rule)
**Verification:** `tests/run-tests.sh`, every test passing.
**Base:** local `main` at `344faa3`, per AGENTS.md non-negotiable 4. Baseline:
`main`'s tree `49244466` is the `Gate-tree:` of 344faa3, so the baseline was
not run again.
**Depends on:** change `base-move-round` (unmerged when this plan was
written). Its D4 moves the gate after the review and D5 renumbers the steps;
this plan cites its labels (review = step 4, gate = 6a). T1 starts only once
`base-move-round` is on `main` and step 1 of `merge-change` has merged it in. Satisfied: `base-move-round` (bb269de) and `test-selection-guideline`
(2bc3cca) were merged in on 2026-10-15; step 4, the rationale sections and
the phrase T1 replaces were re-read on the merged tree and match.

The user asked on 2026-10-14 why developing with guardrails takes so long.
They approved this change on 2026-10-15 after the measurements below.

## Investigation

Measured from this repository's session transcripts, 2026-09-08 to
2026-10-14: 43 sessions and 727 subagent transcripts, against about 44 merges
on `main`.

- About 350 full-suite runs: 164 started by gate subagents, 157 by
  reviewers and 30 by other agents. That is about 8 per change, at 15 to 75
  minutes each depending on machine load. Implementation tasks used a median
  of 6 active minutes each, and reviews and gates about 15 each.
- Most gate reruns re-measured a tree that already passed. Their
  descriptions number them by review round, for example "Gate on round 5
  tree", which reported 748 of 748 passing. The tree changed because a
  round's fix landed, not because a test broke.
- Recent changes took 7 to 8 rounds, driven by low and medium findings. In
  gate-proof-in-trailers, rounds 1 to 3 each had exactly one medium finding.
- `base-move-round`'s D4 already stops a round with findings before the
  gate: the sequence returns to step 1 from step 4, so the step 6a gate runs
  once, in the last round. The remaining per-round full run is the
  reviewer's (`merge-change` step 4: "The reviewer runs the suite itself").
- The reason given for it (`references/rationale.md`, "Step 4: the reviewer
  runs the suite") is independence of the evidence: "The reviewer reports
  the counts it saw, not the counts it was handed." After D4, the step 6a
  gate is a fresh subagent that did not write the code, running on the tree
  that is signed. Its counts are already independent of the author.
- `skills/merge-change/SKILL.md` is at the 2,000-word cap `tests/skills.bats`
  enforces. Each addition needs an equal cut.

## Decisions

- **D1: the reviewer runs only the tests it judges.** These are every test
  whose `verifies:` names an ID the change claims, and every test file the
  diff adds or edits. The reviewer selects them through the project's test
  runner (a file argument or a name filter) and reports the counts for that
  selection. Where the runner cannot select, it runs the whole suite. The
  reviewer still sees its own counts for every test whose meaning it judges.
- **D2: the step 6a gate is the only full run in a round, and stays its
  independent count.** A documentation-only diff's reviewer still runs no
  tests, and the record still says so.
- **D3: the cost is stated where the rule is defended.** The rationale
  section "Step 4: the reviewer runs the suite" becomes "Step 4: the reviewer
  runs the tests it judges". It says three things. Independence of the counts
  is kept by the 6a gate. A regression outside the selected tests now
  surfaces at 6a, after the review. Its fix then dispatches a reviewer under
  the existing rule ("A 6a gate failure's fix dispatches a reviewer unless it
  touches only the record or plan"). An upgrade-notes entry tells an adopting
  project that the reviewer's suite run is now scoped.

## Tasks

### T1 — Scope the reviewer's test run

**Files touched:** skills/merge-change/SKILL.md,
skills/merge-change/references/rationale.md,
skills/ratchet/references/upgrade-notes.md, tests/skills.bats
**Parallel:** no (the only task)

Load the skill at `skills/develop-tdd/SKILL.md` in the change worktree. This
repository has no `.guardrails/`; its scripts are under `scripts/`.

1. RED: add three tests to `tests/skills.bats`, after "merge-change: a round
   with no finding is the last":

   *(Code pruned at merge: 42 lines. Files touched: skills/merge-change/SKILL.md, skills/merge-change/references/rationale.md, skills/ratchet/references/upgrade-notes.md, tests/skills.bats.)*

   Run `sh tests/run-tests.sh tests/skills.bats`. Expected: the three new
   tests fail, each with its `echo` message, and every other test passes.

2. GREEN, `skills/merge-change/SKILL.md` step 4: replace the paragraph that
   opens **The reviewer runs the suite itself** with this text, or wording
   the D1 and D2 tests still match:

   > **The reviewer runs only the tests it judges**: each `verifies:` test
   > of a claimed ID and each test file the diff adds or edits, through the
   > runner's file or name selection, or the whole suite where it cannot
   > select. 6a's gate runs the whole suite. A documentation-only diff's
   > reviewer runs no tests; the record states it.

   Cut words elsewhere in the file to keep it at or under 2,000. Cut only
   restatements, and only where no `tests/skills.bats` assertion greps the
   text. Run `grep -n` for each phrase before cutting it.

3. GREEN, `skills/merge-change/references/rationale.md`: replace the section
   "## Step 4: the reviewer runs the suite" with "## Step 4: the reviewer
   runs the tests it judges". Its body states:
   - that independence of the counts is kept by the step 6a gate, a fresh
     subagent that did not write the code, running on the tree that is
     signed;
   - why the reviewer still runs the tests it judges: it sees a test it
     calls meaningful pass with its own eyes;
   - the cost: a regression outside the selection surfaces at 6a, after the
     review, and its fix dispatches a reviewer unless it touches only the
     record or the plan;
   - the measurement: about 350 full-suite runs over about 44 merges between
     2026-09-08 and 2026-10-14, and nearly half of them were reviewers';
   - that the user ruled this on 2026-10-15.

   In the section "Step 6a: the gate runs after the record", change "Before
   the review, the only suite run is the reviewer's own" to "Before the
   review, the only test run is the reviewer's selection".

4. GREEN, `skills/ratchet/references/upgrade-notes.md`: append an entry at the
   end (the file is oldest first), in the shape of the entries already
   there; `test-selection-guideline` appends there too, so expect a
   mechanical add/add conflict at the base merge. It states that
   `merge-change` step 4's reviewer now runs only the tests it judges, and
   that the step 6a gate is the one full run.

5. Run `sh tests/run-tests.sh tests/skills.bats`. Expected: every test
   passes, including the three new ones and the word-cap test. Commit
   unsigned on the task branch.

## Done

T1 done (merged from reviewer-scoped-suite-t1, a7c1b3c and c8c1344). Step 2
kept the plan text less its "through the runner's file or name selection", to fit the
word cap, and step 1 keeps "Run this step every round.". The test "merge-change: a late
gate's costs are stated: a reviewer for its fix, and no suite for a docs-only
review" now pins the new documentation-only sentence.

```
red -> green: merge-change: the reviewer runs only the tests it judges — watched fail for the right reason before the implementation existed ("step 4 does not scope the reviewer's run")
red -> green: merge-change: the step 6a gate is the round's only full run — watched fail for the right reason before the implementation existed ("step 4 does not name 6a's gate as the full run")
red -> green: merge-change: the rationale states what scoping the reviewer costs — watched fail for the right reason before the implementation existed ("no rationale section for the scoped run")
```

## Guideline reviews

`guidelines-file.sh` printed the same path list for all three files, every
path of the change diff.

### docs/TEST_GUIDELINES.md, round 1

**finding-1**: guideline, medium — floor, "every test fails when the behavior it `verifies:` breaks" — tests/skills.bats:2944-2956 — the D1 test's `` `verifies:` `` grep matches an older sentence of step 4, and nothing asserts "each test file the diff adds or edits"; either half of the selection can be deleted and the test passes.
disposition: the D1 test asserts "each `verifies:` test of a claimed ID" and "each test file the diff adds or edits" (tests/skills.bats).

```
red -> green: merge-change: the reviewer runs only the tests it judges — mutant m1 (deleted "each `verifies:` test of a claimed ID and " from step 4): new test not ok ("step 4 does not select each verifies: test of a claimed ID"); unmutated: ok
red -> green: merge-change: the reviewer runs only the tests it judges — mutant m2 (deleted " and each test file the diff adds or edits" from step 4): new test not ok ("step 4 does not select the test files the diff adds or edits"); unmutated: ok
```

**finding-2**: guideline, medium — the same floor clause — tests/skills.bats:2970-2985 — the D3 test greps the rationale for "6a" and "regression" only; the independence paragraph or the "its fix dispatches a reviewer" clause can be deleted and the test passes.
disposition: the D3 test asserts one phrase per statement: "The step 6a gate keeps that independence.", "a regression outside that selection surfaces at 6a", "its fix dispatches a reviewer unless it touches only the record or the plan" (tests/skills.bats).

```
red -> green: merge-change: the rationale states what scoping the reviewer costs — mutant m3 (deleted "The step 6a gate keeps that independence."): new test not ok ("the rationale does not state that the 6a gate keeps the counts independent"); unmutated: ok
red -> green: merge-change: the rationale states what scoping the reviewer costs — mutant m4 (deleted the "its fix dispatches a reviewer" clause): new test not ok ("the rationale does not state that the regression's fix dispatches a reviewer"); unmutated: ok
red -> green: merge-change: the rationale states what scoping the reviewer costs — mutant m5 (deleted "a regression outside that selection surfaces at 6a, after the review"): new test not ok ("the rationale does not state where a regression outside the selection surfaces"); unmutated: ok
```

### docs/CODE_GUIDELINES.md, round 1

**finding-1**: guideline, low — Names 3 and 4 — tests/skills.bats:2974 — `body` holds `section_of`'s output, which the file names `section` elsewhere; the plan's T1 block repeats it.
disposition: renamed `section` in the test and in the plan's T1 block (tests/skills.bats).

**finding-2**: guideline, low — Names 4 — tests/skills.bats:2947, 2962, 2965 — step 4's flattened text is `review` in one new test and unnamed, computed twice, in the next.
disposition: all three tests name it `step_4`, the file's existing name, and compute it once (tests/skills.bats); the plan's T1 block for the D2 test is left as written.

### docs/ARCHITECTURE_GUIDELINES.md, round 1

No findings; verdict "0 findings (0 high, 0 medium, 0 low); none above low".

### docs/TEST_GUIDELINES.md, round 2

**finding-1**: guideline, low — floor, "every test fails when the behavior it `verifies:` breaks" — tests/skills.bats:2954 — the D1 test's fallback check greps only "cannot select", so step 4 reversed to "and runs nothing where the runner cannot select" passes it.
disposition: the D1 test asserts "the whole suite where the runner cannot select" (tests/skills.bats).

```
red -> green: merge-change: the reviewer runs only the tests it judges — mutant (step 4's fallback changed to "and runs nothing where the runner cannot select"): new assertion not ok ("step 4 does not run the whole suite where the runner cannot select"); unmutated: ok
```

The CODE and ARCHITECTURE reviews had nothing above low in round 1, and TEST
nothing above low in round 2: each review's last round.
