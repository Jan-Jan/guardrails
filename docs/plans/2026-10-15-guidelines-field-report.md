# Guidelines Field Report Implementation Plan

**Goal:** No shipped guidelines clause contradicts the floor, and the
existing-code clauses say what edits a test or code.
**Implements:** D1–D3 below; guardrails keeps no REQ ledger of its own. Each
test cites `verifies: PR-<id>` and `D<n> (docs/plans/2026-10-15-guidelines-field-report.md)`.
**Resolves:** PR-kqesz5, PR-9n87ec.
**Safety class:** not configured in this repository; worked as class B (normal
and abnormal cases for each changed rule)
**Verification:** `tests/run-tests.sh`, every test passing.
**Base:** local `main` at `2bc3cca`, per AGENTS.md non-negotiable 4.

An adopter's field report (2026-10-14, upgrading `d015a48` to `344faa3`)
raised three points. The first two are recorded as PR-kqesz5 and PR-9n87ec in
`docs/problems/2026-10-15-guidelines-field-report.md`. The third is
PR-783b29, resolved by `52100a8` after the adopter's base; what it leaves is
the open PR-92mbhq and the drift PR-z6uaa8, neither in scope here (`ratchet`'s
SKILL.md is at 1,999 of its 2,000 words).

## Investigation

- `templates/TEST_GUIDELINES.md` UI 6 reads "A markup snapshot carries no
  `verifies:` annotation." The floor lists in `tailor-guidelines` step 5 and
  `review-conformance` step 3 both open with "every test carries
  `verifies:`". A test following UI 6 breaks the floor, and
  `review-conformance` step 3 must report the clause. Reproduced by reading:
  the two texts are on `main` at `2bc3cca`. The clause's own test,
  "test guidelines: a UI's interface is what the user perceives, and a markup
  snapshot verifies nothing" (`tests/test-guidelines.bats`), pins the
  contradicting sentence, so the suite has asserted the defect since
  test-seams.
- No test checks a guidelines file against the floor. The floor tests
  (`tests/tailor-guidelines.bats`, `tests/review-conformance.bats`) check only
  that each skill lists it.
- `Existing suites 1` (template and `docs/TEST_GUIDELINES.md`, identical
  text) binds "the tests a change writes or edits" and never says what edits
  a test. Its only remedy, "moves it to the seam instead of repairing it in
  place", fits a Seams breach; for a Doubles breach (a mock of owned code)
  the fix is to replace the mock, which is a repair in place. "They spare the
  existing suite" says nothing about the floor.
- `ARCHITECTURE` "Existing code" 1 (template and this repository's file)
  says "where a change edits it" with the same undefined edit.
  `templates/CODE_GUIDELINES.md` has no existing-code clause; the report's
  mention of it does not apply.
- Word caps: the TEST template is at 1,950 of 1,950
  (`tests/test-guidelines.bats`); the ARCHITECTURE template at 1,125 of
  1,300 and this repository's at 588 of 1,500; `docs/TEST_GUIDELINES.md` has
  no cap.

## Decisions

- **D1 (PR-kqesz5): UI 6 forbids the snapshot test instead of exempting it
  from `verifies:`.** The clause becomes: "**No markup snapshot test.** Every
  test carries `verifies:`, and a markup snapshot has no behavior to verify:
  it fails on a refactor that changes nothing a user sees, and passes a
  regression that the markup does not show." This is the adopter's wording,
  and it tightens the floor rather than loosening it. The alternative (a
  snapshot only inside a test whose other assertions carry its `verifies:`)
  keeps an assertion that fails on refactors, against UI 1; rejected.
  `docs/TEST_GUIDELINES.md` has no UI section and is unchanged by D1.
- **D2 (PR-kqesz5): a test scans every guidelines file for an exemption from
  a test floor item.** For each of `templates/*_GUIDELINES.md` and
  `docs/*_GUIDELINES.md`, the flattened text must not match
  `(no|without) (a |an |the |its )?\`verifies:\`` nor
  `without (being )?watched red`. Those are the two floor items a test
  clause could exempt a test from in so many words. Whether a clause
  contradicts the floor in general is a reader's judgement; the scan stops
  only this shape, and the record lists the gap.
- **D3 (PR-9n87ec): the existing-code clauses define an edit, and the TEST
  clause names a remedy per breach and keeps the floor.** Both TEST files'
  Existing suites 1 says: the rules bind the tests a change writes and those
  whose code it edits (setup, doubles, calls or assertions); correcting a
  comment or a citation alone does not edit a test; the rules spare the rest
  of the suite, but the floor binds every test; an edited test that breaks a
  rule is brought into line with it: one pinned below the seam moves to the
  seam, and a mock of owned code is replaced; an unedited test that breaks
  the rules is left alone; no change rewrites a suite wholesale. Both
  ARCHITECTURE files' Existing code 1 gains: "Correcting a comment or a
  citation alone does not edit code." An upgrade-notes entry covers D1 and
  D3. As shipped, after conformance round 3, the TEST clause says "Of the
  edited tests," for "brought into line", leaves "left alone" to "the rules
  spare the rest of the suite", and every clause D3 touches gives the edit
  definition a `Why:` and an `Example:`.

## Tasks

### T1 — UI 6 stops contradicting the floor, and a scan stops it recurring

**Files touched:** templates/TEST_GUIDELINES.md, tests/test-guidelines.bats,
skills/ratchet/references/upgrade-notes.md
**Parallel:** no (serial; T2 touches the same files)

Load the skill at `skills/develop-tdd/SKILL.md` in the change worktree. This
repository has no `.guardrails/`; its scripts are under `scripts/`. Read
`AGENTS.md` (the bats negation rule, the `case` pattern rule).

1. RED. In `tests/test-guidelines.bats`:
   - Change "test guidelines: a UI's interface is what the user perceives,
     and a markup snapshot verifies nothing" to pin the D1 sentences in
     place of the two `A markup snapshot carries no` greps: the bold
     `. **No markup snapshot test.**` and `a markup snapshot has no behavior
     to verify`. Add `PR-kqesz5` and `D1 (docs/plans/2026-10-15-guidelines-field-report.md)`
     to its `verifies:`.
   - Add "guidelines: no guidelines file exempts a test from a test floor
     item", `# verifies: PR-kqesz5; D2 (docs/plans/2026-10-15-guidelines-field-report.md)`.
     It loops over `templates/*_GUIDELINES.md` and `docs/*_GUIDELINES.md`
     (fail if either glob matches nothing), flattens each file's line breaks
     to spaces, and fails naming the file and the matched text where the D2
     patterns match (`grep -oE`, case-insensitive).
   Run `sh tests/run-tests.sh tests/test-guidelines.bats`. Expected: both
   tests fail, the new one naming `templates/TEST_GUIDELINES.md` and
   `no \`verifies:\``; every other test passes.
2. GREEN. Rewrite UI 6 of `templates/TEST_GUIDELINES.md` to D1's text,
   wrapped at the file's width. Keep the template at or under 1,950 words:
   cut only restatements, and only text no `tests/test-guidelines.bats`
   assertion greps; name each cut in the dispatch report.
3. GREEN. Append an entry to `skills/ratchet/references/upgrade-notes.md`
   (the file is oldest first), in the shape of the entries there: UI 6 of the
   TEST default now forbids a markup snapshot test rather than exempting it
   from `verifies:`, which the floor forbids; a project whose file keeps the
   old clause adopts the new one through `tailor-guidelines`; no gate changes.
4. Run `sh tests/run-tests.sh tests/test-guidelines.bats tests/skills.bats`.
   Expected: every test passes. Commit unsigned on the task branch.

### T2 — The existing-code clauses define an edit

**Files touched:** templates/TEST_GUIDELINES.md, docs/TEST_GUIDELINES.md,
templates/ARCHITECTURE_GUIDELINES.md, docs/ARCHITECTURE_GUIDELINES.md,
tests/test-guidelines.bats, tests/architecture-guidelines.bats,
skills/ratchet/references/upgrade-notes.md
**Parallel:** no (serial, after T1)

Load the skill at `skills/develop-tdd/SKILL.md` in the change worktree.

1. RED. In `tests/test-guidelines.bats`, rework "test guidelines: the rules
   bind new and edited tests, not the existing suite" to check, in both
   `$template` and `$repo_guidelines` (flattened Existing suites section):
   the clause names whose code a change edits; "Correcting a comment or a
   citation alone does not edit a test"; the floor binds every test; the
   Seams remedy (moves to the seam) and the Doubles remedy (a mock of owned
   code is replaced); "No change rewrites a suite wholesale". Drop the greps
   for "moves it to the seam instead of repairing it in place". Add
   `PR-9n87ec` and `D3 (docs/plans/2026-10-15-guidelines-field-report.md)`
   to its `verifies:`. In `tests/architecture-guidelines.bats`, add
   "architecture guidelines: correcting a comment or a citation does not
   edit code", same `verifies:`, requiring "Correcting a comment or a
   citation alone does not edit code." in the Existing code section of the
   template and of this repository's file. Run
   `sh tests/run-tests.sh tests/test-guidelines.bats tests/architecture-guidelines.bats`.
   Expected: the two tests fail with their `echo` messages, the rest pass.
2. GREEN. Rewrite Existing suites 1 in both TEST files to D3's content, in
   the file's clause shape (bold rule sentence, then the body). Keep the
   template at or under 1,950 words, cutting only restatements no test
   greps, and name each cut in the report. Add D3's sentence to Existing
   code 1 of both ARCHITECTURE files, after "only as far as that edit
   reaches;" clause's sentence; keep both under their caps.
3. GREEN. Extend T1's upgrade-notes entry: Existing suites 1 of the TEST
   default and Existing code 1 of the ARCHITECTURE default now say that
   correcting a comment or a citation alone edits no test or code; the TEST
   clause names the remedy for a Doubles breach and states that the floor
   binds every test; adopted through `tailor-guidelines`.
4. Run the two files from step 1, then `tests/skills.bats` and
   `tests/tailor-guidelines.bats`. Expected: every test passes. Commit
   unsigned on the task branch.

## Done

### T1 — done (7d3c961)

```
red -> green: test guidelines: a UI's interface is what the user perceives, and a markup snapshot verifies nothing — watched fail for the right reason ("UI 6 does not say a markup snapshot has no behavior to verify") before UI 6 was rewritten
red -> green: guidelines: no guidelines file exempts a test from verifies: or from being watched red (named "… from a test floor item" until fix code-r1) — watched fail for the right reason ("templates/TEST_GUIDELINES.md exempts a test from the floor: no `verifies:`") before UI 6 was rewritten
```

RED run (test-guidelines): 21 passed, 2 failed (the two above). GREEN run
(test-guidelines, skills): 193 passed, 0 failed.

Deviations: the template is at 1,948 words; one cut, Property tests 1's "It
is a preference, not a rule.", which restates "prefer a property test". The
scan also fails when fewer than two guidelines files are found.

### T2 — done (ea5c886)

```
red -> green: test guidelines: the rules bind new tests and tests whose code a change edits, and the floor binds every test (named "… not the existing suite" until fix code-r1) — watched fail for the right reason ("templates/TEST_GUIDELINES.md Existing suites 1 lacks: the tests a change writes, and those whose setup, doubles, calls or assertions it edits") before the clause was rewritten
red -> green: architecture guidelines: correcting a comment or a citation does not edit code — watched fail for the right reason ("templates/ARCHITECTURE_GUIDELINES.md Existing code 1 does not say a comment or citation fix edits no code") before the sentence was added
```

RED run (test-guidelines, architecture-guidelines): 34 passed, 2 failed (the
two above). GREEN run (test-guidelines, architecture-guidelines, skills,
tailor-guidelines): 219 passed, 0 failed.

Deviations: the template is at 1,949 words. To fit, Owned services 1's
sentence "A double that returns the service's own error, such as a conflict
response with its body, is this kind, not a fault injector." was cut from the
template (it restates Doubles 5's fake definition; this repository's file
keeps it), and the old clause's reason "such a test usually broke because a
refactor moved the internal it was pinned to" was dropped; the clause's
`Why:` is now the coverage-loss reason. The upgrade-notes entry is retitled
to cover both points.

## Guideline reviews

### Round 1

TEST (docs/TEST_GUIDELINES.md): no findings. Its notes that two test names
claimed more than they check were taken into fix code-r1.

CODE (docs/CODE_GUIDELINES.md):

1. medium, Simplicity 4: the Existing code and Existing suites tests each
   inlined a section-flattening awk pipeline that `section_of`
   (tests/helpers.bash) already does.
2. medium, Errors 2: the floor scan's `grep -oiE … || true` discarded grep's
   exit 2 with its exit 1, so a broken pattern passed the scan.
3. low, Names 3: `found` counted guidelines files.
4. low, Names 3: `matched` named a role.
5. low, Names 4: the awk flag `on`, where the codebase says `found` or
   `inside`.

ARCHITECTURE (docs/ARCHITECTURE_GUIDELINES.md):

1. low, preamble ("rewrites its reason and examples with it"): Existing
   code 1's new sentence had no reason or example, in this repository's file.
2. low, the same in the template.

Fix dispatch code-r1 (develop-refactor; 52491e7), merged: CODE 1 to 5 fixed;
the scan fails on a grep status above 1, watched pass on a broken pattern
under the old code and fail under the new. Both tests renamed, as above.
Result: 36 passed, 0 failed (test-guidelines, architecture-guidelines).

```
red -> green: guidelines: no guidelines file exempts a test from verifies: or from being watched red — grep-error path watched fail ("grep exited 2 scanning …") with an unbalanced pattern; the old `|| true` code passed it
```

Fix dispatch arch-r1 (develop-refactor; 84b0318), merged: ARCHITECTURE 1 and
2 fixed; each Existing code 1 `Why:` and `Example:` covers the comment or
citation case. Result: 13 passed, 0 failed (architecture-guidelines).

### Round 2

TEST (docs/TEST_GUIDELINES.md):

1. medium, Seams 1: the UI test still cited D7 of
   `docs/plans/2026-10-07-test-seams.md`, whose point 3 ("A markup snapshot
   test carries no `verifies:` annotation") the test now contradicts.
2. low, Seams 1: the Existing suites test cited D10 of the same plan, whose
   single remedy D3 partly supersedes.

CODE (docs/CODE_GUIDELINES.md):

1. low, Names 4: the two new loops named their variable `file`, where the
   file says `guidelines`.

ARCHITECTURE (docs/ARCHITECTURE_GUIDELINES.md): no findings. Its note that
the upgrade entry did not mention Existing code 1's new `Why:` and
`Example:` was taken into fix code-r2.

Fix dispatch test-r2 (develop-tdd; cf27045), merged: TEST 1 and 2 fixed; each
`verifies:` line keeps the old decision and names the part superseded by D1
or D3. No assertion changed. Result: 23 passed, 0 failed (test-guidelines).

Fix dispatch code-r2 (develop-refactor; 1f48f97), merged: CODE 1 fixed and
the upgrade entry extended. Result: 206 passed, 0 failed (test-guidelines,
architecture-guidelines, skills).

### Round 3

CODE (docs/CODE_GUIDELINES.md): no findings.

ARCHITECTURE (docs/ARCHITECTURE_GUIDELINES.md): no findings.

TEST (docs/TEST_GUIDELINES.md), nothing above low:

1. low, preamble ("rewrites its reason and examples with it"): Existing
   suites 1 in this repository's file gave no reason or example for
   "Correcting a comment or a citation alone does not edit a test."
2. low, the same in the template.

Round 3 is the last: no review has a finding above low. Both lows were fixed,
because the missing reason is the point the field report turned on.

Fix dispatch test-r3 (develop-tdd; e44939d), merged: each Existing suites 1
`Why:` gives the reason, worded as ARCHITECTURE Existing code 1's, with an
`Example:` (this repository's names a `PATH` stub in a `@test`). To hold the
template at 1,949 words, eight restatements were cut: Seams 2 ", even where a
deeper seam would be easier"; Doubles 4 ", so asserting it is a behavior
test, not a mock"; Owned services 1 "runs for real in a REQ-level test of the
normal case" to "is one", and its ", and a fake drifts from what it stands in
for"; Property tests 1 "an invariant that holds for all of them" to "the
invariant"; Mutants 1 "A survivor means one of:" to "For a survivor:";
Existing suites 1 "A test that breaks the rules and is not edited is left
alone." (restated by "The rules spare the rest of the suite") and "An edited
test that breaks a rule is brought into line with it:" to "Of the edited
tests,". The last two were made in both TEST files.

```
red -> green: test guidelines: the rules bind new tests and tests whose code a change edits, and the floor binds every test — new reason assertion watched fail ("templates/TEST_GUIDELINES.md Existing suites 1 lacks: and citations would be left wrong instead.") before the clause was edited
```

Result: 23 passed, 0 failed (test-guidelines).

## Step 4 review, round 1 (reviewed f8c6d71)

Reviewer's own run: 1496 of 1496 passed. verdict: pass, no `code` or
`requirement` finding above low, so the last review round.

1. requirement, low: Owned services 1's "there" lost its antecedent after a
   cut. Fixed by dispatch rev-r1.
2. requirement, low: repointing a test's `verifies:` counts as a citation
   fix, so an inherited test escapes the clauses. Recorded as PR-pk3xy5.
3. requirement, low: the upgrade entry omitted Existing suites 1's `Why:`
   and the template's other cuts. Fixed by dispatch rev-r1.
4. record: the PR-z6uaa8 mapping in the ledger preface. Fixed in the ledger.
5. record: D3 stated replaced wording. Fixed in D3.

Fix dispatch rev-r1 (develop-refactor; 10c0501), merged: the `Why:` reads
"faking it on the normal path verifies …" (template at 1,950 words, no cut);
the upgrade entry names both omissions and is rewrapped. Result: 193 passed,
0 failed (test-guidelines, skills).
