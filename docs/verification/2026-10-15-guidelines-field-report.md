# Verification — guidelines-field-report (2026-10-15)

branch: guidelines-field-report
reviewer: one independent subagent, dispatched at `merge-change` step 4 with the diff, the plan, the claimed items and the review checklist, and no implementation narrative; it worked in its own review worktree and ran the full suite itself.
verdict: pass. The review raised no `code` or `requirement` finding above low, so its round was the last; its lows were fixed or recorded as PR-pk3xy5, and its record findings were fixed.
reproduced: yes, by reading and by test. UI 6 and Existing suites 1 were read on `main` at `2bc3cca` as the field report quotes them, and each new or reworked test was watched fail on that text before the fix; the floor scan reported "templates/TEST_GUIDELINES.md exempts a test from the floor: no `verifies:`".

Change: no shipped guidelines clause exempts a test from the floor, and the existing-code clauses say what edits a test or code.
Plan: `docs/plans/2026-10-15-guidelines-field-report.md`.

Resolves PR-kqesz5 and PR-9n87ec. Opens PR-pk3xy5.

## The gate

The figures are in the squash commit's trailers (`Gate-tree:`, `Gate:`,
`Base:`). This repository has no `.guardrails/config.yaml`, so
`merge-preflight.sh` stops at its config read; `check-ids.sh` and
`check-trace.sh` were run instead on scratch copies of `main` and of the
change, each built from `templates/config.yaml` with `scripts` as its strict
path and stub SRS, SAD and SOUP files. `check-ids.sh` printed the same output
at both. `check-trace.sh` differed only by this change's own items, then
open (`UNRESOLVED-PR PR-kqesz5`, `UNRESOLVED-PR PR-9n87ec`); both exit 1 at
both on the backlog this repository carries. Coverage is not configured.

## Red → green

This repository has no SRS, so the change implements no item and the table
has no rows. Each test the change adds or edits carries `verifies:` with
its problem item and plan decision; its `red -> green:` lines are copied
here from the plan.

| Item | Test | Watched red |
| --- | --- | --- |

- red -> green: test guidelines: a UI's interface is what the user perceives, and a markup snapshot verifies nothing — watched fail ("UI 6 does not say a markup snapshot has no behavior to verify") before UI 6 was rewritten
- red -> green: guidelines: no guidelines file exempts a test from verifies: or from being watched red — watched fail ("templates/TEST_GUIDELINES.md exempts a test from the floor: no `verifies:`") before UI 6 was rewritten; its grep-error path watched fail ("grep exited 2 scanning …") with an unbalanced pattern, which the earlier `|| true` code passed
- red -> green: test guidelines: the rules bind new tests and tests whose code a change edits, and the floor binds every test — watched fail ("Existing suites 1 lacks: the tests a change writes, and those whose setup, doubles, calls or assertions it edits") before the clause was rewritten; its reason assertion watched fail ("Existing suites 1 lacks: and citations would be left wrong instead.") before the `Why:` was added
- red -> green: architecture guidelines: correcting a comment or a citation does not edit code — watched fail ("templates/ARCHITECTURE_GUIDELINES.md Existing code 1 does not say a comment or citation fix edits no code") before the sentence was added

## What was wrong, and what was built

An adopter tailoring the three guidelines files at `344faa3` found two
defects in the shipped defaults, both present since the test-seams change.
`templates/TEST_GUIDELINES.md` UI 6 read "A markup snapshot carries no
`verifies:` annotation", the one test shape the floor ("every test carries
`verifies:`") forbids, so `review-conformance` had to report the default
against itself; `tests/test-guidelines.bats` pinned that sentence. Existing
suites 1 bound "the tests a change writes or edits" without saying what edits
a test, so the adopter's reviewer treated a repointed citation in a comment as
an edit and demanded the test's mocks replaced; its one remedy, "moves it to
the seam", fitted no Doubles breach. ARCHITECTURE Existing code 1 had the same
undefined edit.

Built:

- UI 6 forbids a markup snapshot test: every test carries `verifies:`, and a
  snapshot has no behavior to verify (D1).
- A bats test scans every `templates/*_GUIDELINES.md` and
  `docs/*_GUIDELINES.md` for a phrase exempting a test from `verifies:` or
  from being watched red, and fails on a grep error (D2).
- Existing suites 1, in both TEST files, binds the tests a change writes and
  those whose setup, doubles, calls or assertions it edits; says correcting a
  comment or a citation alone edits none; keeps the floor on every test; names
  a remedy per breach; and gives the edit definition a `Why:` and an
  `Example:`. Existing code 1, in both ARCHITECTURE files, says the same of
  code, with its own `Why:` and `Example:` (D3).
- The TEST template stays within its 1,950-word cap by cutting restatements
  from Seams 2, Doubles 4, Owned services 1, Property tests 1 and Mutants 1,
  none of which changes a rule; the plan lists each cut.
- An upgrade-notes entry tells an adopting project all of this.

`merge-change` step 1 pruned no plan; no plan was left whole.

## Review

### Round 1

**finding-1**: requirement, low — templates/TEST_GUIDELINES.md:100-102, Owned services 1: after a word-cap cut, "Why: a fake of it there" lost what "there" pointed to.
disposition: the `Why:` reads "faking it on the normal path verifies the main behavior against something the project never ships" (templates/TEST_GUIDELINES.md).

**finding-2**: requirement, low — templates/TEST_GUIDELINES.md:220, docs/TEST_GUIDELINES.md:234: "Correcting a comment or a citation alone does not edit a test" also covers repointing a test's `# verifies:` to a successor ID, so an inherited test escapes the Seams and Doubles clauses.
disposition: recorded as PR-pk3xy5; its fix is a new rule that needs words the template's cap does not leave, and its own review.

**finding-3**: requirement, low — skills/ratchet/references/upgrade-notes.md:775-797: the entry omitted Existing suites 1's new `Why:` and `Example:` and the template's other cuts, and one line was 95 characters.
disposition: the entry names both, says the shortened clauses keep their rules and may be declined, and is rewrapped (skills/ratchet/references/upgrade-notes.md).

**finding-4**: record — docs/problems/2026-10-15-guidelines-field-report.md:11-14: mapping the report's missing-skills note to PR-z6uaa8 stretched that item's drift.
disposition: the preface says the note is read as PR-z6uaa8's drift taken to cover which skills are installed (docs/problems/2026-10-15-guidelines-field-report.md).

**finding-5**: record — docs/plans/2026-10-15-guidelines-field-report.md, D3 stated wording conformance round 3 replaced.
disposition: D3 notes the shipped wording (docs/plans/2026-10-15-guidelines-field-report.md).

## Guideline reviews

`guidelines-file.sh` printed the same path list for all three files, every
path of the change diff.

### docs/TEST_GUIDELINES.md

Governs: every path of the change diff.

### Round 1

No findings; verdict "0 findings (0 high, 0 medium, 0 low); none above low".

### Round 2

**finding-1**: guideline, medium — Seams 1, "a test verifies the problem report or the plan decision that states the behavior, at the same seam" — tests/test-guidelines.bats:64
disposition: the `verifies:` line names D7 point 3's snapshot sentence as superseded by D1 (tests/test-guidelines.bats).

**finding-2**: guideline, low — Seams 1 — tests/test-guidelines.bats:87, the D10 citation whose single remedy D3 partly supersedes.
disposition: the `verifies:` line names D10's one remedy as superseded by D3 (tests/test-guidelines.bats).

### Round 3

**finding-1**: guideline, low — preamble, "A project that changes a clause rewrites its reason and examples with it." — docs/TEST_GUIDELINES.md:232-239
disposition: Existing suites 1's `Why:` gives the comment-or-citation reason, with an `Example:` (docs/TEST_GUIDELINES.md); `test guidelines: the rules bind new tests and tests whose code a change edits, and the floor binds every test` reddens without it.

**finding-2**: guideline, low — preamble — templates/TEST_GUIDELINES.md:221-229, the same gap in the template.
disposition: as finding-1 (templates/TEST_GUIDELINES.md).

### docs/CODE_GUIDELINES.md

Governs: every path of the change diff.

### Round 1

**finding-1**: guideline, medium — Simplicity 4, "Where two parts of one change add the same helper, constant or check, one copy stays, where both can reach it." — tests/architecture-guidelines.bats:142, tests/test-guidelines.bats:90
disposition: both tests call `section_of` (tests/helpers.bash).

**finding-2**: guideline, medium — Errors 2, "no discarded return code" — tests/test-guidelines.bats:367
disposition: the scan fails on a grep status above 1, with a comment on why exit 1 passes; `guidelines: no guidelines file exempts a test from verifies: or from being watched red` was watched fail on a broken pattern (tests/test-guidelines.bats).

**finding-3**: guideline, low — Names 3 — tests/test-guidelines.bats:361, `found` counting files.
disposition: renamed `guidelines_count` (tests/test-guidelines.bats).

**finding-4**: guideline, low — Names 3 — tests/test-guidelines.bats:366, `matched`.
disposition: renamed `exempting_phrase` (tests/test-guidelines.bats).

**finding-5**: guideline, low — Names 4 — the awk flag `on`.
disposition: removed with finding-1 (tests/test-guidelines.bats).

### Round 2

**finding-1**: guideline, low — Names 4 — tests/test-guidelines.bats:88, tests/architecture-guidelines.bats:140, the loop variable `file`.
disposition: renamed `guidelines` (tests/test-guidelines.bats, tests/architecture-guidelines.bats).

### Round 3

No findings; verdict "0 findings (0 high, 0 medium, 0 low); none above low".

### docs/ARCHITECTURE_GUIDELINES.md

Governs: every path of the change diff.

### Round 1

**finding-1**: guideline, low — preamble, "A project that changes a clause rewrites its reason and examples with it." — docs/ARCHITECTURE_GUIDELINES.md:57
disposition: Existing code 1's `Why:` and `Example:` cover the comment-or-citation case (docs/ARCHITECTURE_GUIDELINES.md).

**finding-2**: guideline, low — preamble — templates/ARCHITECTURE_GUIDELINES.md:118
disposition: as finding-1 (templates/ARCHITECTURE_GUIDELINES.md).

### Round 2

No findings; verdict "0 findings (0 high, 0 medium, 0 low); none above low".

### Round 3

No findings; verdict "0 findings (0 high, 0 medium, 0 low); none above low".

## Gaps

- The floor scan stops only the wording "no/without `verifies:`" and
  "without being watched red"; a clause that contradicts the floor in other
  words passes it. Whether a clause contradicts the floor stays a reader's
  judgement, at `tailor-guidelines` and `review-conformance`.
- Repointing a test's `verifies:` is not yet an edit (PR-pk3xy5).
- The TEST template is at its 1,950-word cap; the next clause must cut words.
- The report's third point is not fixed here: PR-92mbhq and PR-z6uaa8 stay
  open, and nothing checks that a skill a skill names is installed.
