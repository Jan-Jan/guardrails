# Code guidelines: develop-change split into orchestrator, TDD and refactor

**Goal:** Code preferences live in one project file, `CODE_GUIDELINES.md`,
and each develop-phase subagent loads one skill and one guidelines file.
**Implements:** none (this repository has no SRS); delivers the decisions
below.
**Safety class:** not configured (this repository has no `.guardrails/config.yaml`).
**Verification:** `sh tests/run-tests.sh`

Context: change 3 in the series `test-guidelines` started
(`docs/plans/2026-10-08-test-guidelines.md`, "Follow-ups outside this
change"). That change proved the floor/preference split on tests (its D1 to
D11, ADR-me39p4); this one applies it to code.

## Decisions

**D1 — `develop-change` splits into three skills.** `develop-change` stays the
orchestrator: it dispatches plan tasks, merges task branches, runs the
conformance reviews and dispatches their fixes. `develop-tdd` is the only
skill a task subagent loads: the red → green loop, the floor rules, and the
test guidelines file `guidelines-file.sh TEST` names. `develop-refactor` is
the only skill a subagent loads to fix a `CODE` conformance finding: the
finding, the code guidelines file `guidelines-file.sh CODE` names, and no
behavior change. Why: each subagent loads one skill and one guidelines file
(test-guidelines D6), and never the orchestration text it does not use. The
name `develop-change` stays; only the citations of rules that move to
`develop-tdd` are repointed (`worktree-discipline`, `resolve-problem`,
`grill-requirements`, `verify-before-merge` check 6). Ruled 2026-10-13.

**D2 — The naming rules move into the code guidelines.** The `## Code: names`
section leaves the managed AGENTS.md block (`templates/AGENTS-block.md`) and
becomes the Names clauses of `templates/CODE_GUIDELINES.md`, with reasons and
examples; `ratchet`'s inventory note about a block with no `## Code: names`
section goes with it. This repository's own AGENTS.md section moves to
`docs/CODE_GUIDELINES.md`. Why: naming is a preference no standard or gate
needs (test-guidelines D2), and a rule with two homes drifts. Ruled
2026-10-13.

**D3 — The code guidelines ship four sections.** `templates/CODE_GUIDELINES.md`
holds numbered clauses, each with its rule, boundary, reason and
language-neutral examples, as `templates/TEST_GUIDELINES.md` does
(test-guidelines D5), under: Names (D2: no single-character names, no code
golf, concrete terms, one name per concept across the change); Simplicity
(the smallest code that passes, no speculative options or abstraction
without a second caller, dead and commented-out code deleted, no duplication
between tasks); Errors (fail loudly: no swallowed error, no silent fallback,
an edit or substitution that matches nothing is an error); Comments (why,
not what; no change narration; the surrounding code's comment density).
Each is a default a project keeps, changes or drops with `tailor-guidelines`.
Ruled 2026-10-13.

**D4 — The deslop pass is dropped; conformance reviews replace it.** When
every task branch is merged and the suite is green, `develop-change`
dispatches one `review-conformance` subagent per file that
`guidelines-file.sh TEST` and `guidelines-file.sh CODE` print, all at once:
each reads one file and changes nothing. Once every review has reported, the
findings are fixed in nested task worktrees, a `CODE` finding under
`develop-refactor` and a `TEST` finding under `develop-tdd`, and the reviews
run again; the first round with nothing above low is the last.
`guidelines-file.sh` learns the kind `CODE`. Why: the deslop pass predates
the guideline reviews, and its one unique job, duplication between tasks, is
a Simplicity clause a whole-diff review finds; the agent that fixes does not
review its own fix; a reviewer with one file misses less; IEC 62304 5.5.3
asks class C units to be checked against the coding standard. Cost: a
reviewer that only reports proposes fewer simplifications than an agent told
to improve the code; "this can be simpler" remains a Simplicity finding.
Ruled 2026-10-13.

**D5 — What carries over unchanged.** These follow from test-guidelines and
need no new ruling: a unit's `<unit>/docs/CODE_GUIDELINES.md` replaces the
root file whole (its D3); no guidelines file refers to another (its D6);
`tailor-guidelines` seeds and tailors the file, and `/ratchet` invokes it
for `CODE` as for `TEST` (its D7); the record's `## Guideline reviews` gains
the `CODE` entries (its D9). "Deslop pass" leaves every skill, template and
test; `verify-before-merge` check 8 asks instead that each conformance
review ran and its findings are fixed or dispositioned.

**D6 — `review-guidelines` is renamed `review-conformance`.** The skill
directory, its tests, and every skill, template, script remedy and README
line that names it change; the upgrade note tells an adopter to rerun
`install.sh`. Why: with several guidelines files, "review guidelines" reads
as reviewing the files themselves; the skill checks a diff's conformance to
one of them. Ruled 2026-10-13.

## Tasks

Every test this change writes or edits carries
`# verifies: D<n> (docs/plans/2026-10-13-code-guidelines.md)`, naming the
decisions above it tests; a test that already verified an earlier plan's
decision keeps that annotation beside the new one, as the test-guidelines
plan did. Each new test is watched red before the text or code it checks
exists, and the dispatcher writes the red into the task's Done note as a
`red -> green:` line. Text tests pin operative clauses only, matched with
`grep -qF`, or `grep -qxF` for a line that must survive whole; a sentence
that may wrap is matched on the section flattened with
`tr '\n' ' ' | tr -s ' '`. Each task runs its own test files with
`sh tests/run-tests.sh tests/<file>.bats` and reports the counts; the full
suite is the merge gate, not a task step.

A negative assertion is written `if grep …; then echo …; false; fi` or
`! grep … || { echo …; false; }` (AGENTS.md, Rules). A test that names an
old name (the dropped pass, `'des''lop'`; the renamed skill,
`'review-''guidelines'`) splits the literal, so the test file does not
contain the word T12's sweeps forbid.

### Inventory

What changes, by decision, found by `git grep` at `3694b1e`:

- D1, `skills/develop-change/SKILL.md` (1,865 words). To `develop-tdd`:
  the opening rule "No production code without a failing test first",
  "### The loop, one behavior at a time" (steps 1 to 6, numbering kept:
  `worktree-discipline` cites step 6 for the commit), "Class rules", "Bugs",
  "### Test guidelines" whole, and the dispatch report's shape fence.
  `develop-change` keeps Preconditions (rewritten), Delegation (the prompt
  names `develop-tdd`), the dispatch report's handling (the `worktree:`,
  `red -> green:` and plan bullets), Derailment and its References. "### The
  deslop pass" and "### The guideline reviews" become one "### The
  conformance reviews" (D4).
- D1, `skills/develop-change/references/rationale.md`: stays with
  `develop-change`. `## An inherited line is coverage, not evidence` moves
  into `develop-tdd`'s report section as two sentences, so `develop-tdd`
  needs no reference file. The three `## The deslop pass …` sections are
  replaced by three on the conformance reviews (D4).
- D1, the four citations it names: `skills/worktree-discipline/SKILL.md:93`
  ("`develop-change` step 6"), `skills/resolve-problem/SKILL.md:83` ("per
  `develop-change`"), `skills/grill-requirements/SKILL.md:109` ("written
  red-first (`develop-change`)"), `skills/verify-before-merge/SKILL.md:97`
  ("`develop-change`'s robustness rule"); and the comment at
  `tests/check-signing.bats:116`. Citations of the dispatcher stay:
  `worktree-discipline:65` and `:189`, `verify-before-merge:18`, `:59`,
  `:79`, `plan-change:80`, the `(develop-change)` remedies
  `scripts/task-worktree.sh` prints and `tests/task-worktree.bats` pins, and
  the workflow map row in `templates/AGENTS-block.md` (a subagent-only skill
  is not listed there, as `review-guidelines` and `tailor-guidelines` are
  not today).
- D2: `templates/AGENTS-block.md` `## Code: names`; `AGENTS.md`
  `## Code: names`; `skills/ratchet/SKILL.md:167-169` (inventory note);
  `tests/skills.bats` "clanker: the managed block names concrete naming
  rules", "clanker: this repository follows the same block", "clanker:
  ratchet reports a managed block with no code section".
- D3: `templates/CODE_GUIDELINES.md` (new); D2, D5: `docs/CODE_GUIDELINES.md`
  (new).
- D4: `scripts/guidelines-file.sh` `KNOWN_KINDS='TEST'` (line 34);
  `tests/guidelines-file.bats` "an unknown kind is exit 2" uses `CODE` as
  its unknown kind. Mutation anchors: `grep -rn 'KNOWN_KINDS\|guidelines-file'
  docs/verification/*.mutations/` prints nothing, so no anchor is re-cut.
  `develop-refactor` (new) fixes one `CODE` review's findings; `develop-tdd`
  fixes one `TEST` review's.
- D5, the record and the gate: `templates/verification.md:100-101` (names
  `guidelines-file.sh TEST` only, and the section "The guideline reviews");
  `skills/merge-change/references/review-checklist.md:73-76`;
  `skills/verify-before-merge/SKILL.md:100-103` (check 8) and
  `references/rationale.md:49`. The record's `## Guideline reviews` heading
  keeps its name (D5); `skills/merge-change/SKILL.md` (2,000 words) names
  only that heading, not the skill, so it needs no edit.
- D5, tailoring: `skills/tailor-guidelines/SKILL.md` (Preconditions name
  `TEST` only; step 3's examples are Seams and Doubles only),
  `skills/ratchet/SKILL.md:91` and `:128` (scaffold copy, `tailor-guidelines`
  for `TEST`; the upgrade and retrofit lines already say "each guidelines
  file"), `skills/ratchet/references/upgrade-notes.md` (a new section).
- D5, the dropped pass: `git grep -i deslop -- ':!docs/plans'
  ':!docs/verification'` hits `develop-change` (SKILL.md and rationale),
  `review-guidelines`, `verify-before-merge` (SKILL.md and rationale) and
  `tests/skills.bats` (1107-1200 and 2445-2451).
- D6, `git grep review-guidelines -- ':!docs/plans' ':!docs/verification'`:
  the skill directory, `tests/review-guidelines.bats`, `README.md:53`,
  `skills/develop-change/SKILL.md:227`,
  `skills/merge-change/references/review-checklist.md:60`,
  `templates/verification.md:156`, `tests/skills.bats:2453` and `:2517`. No
  script prints it, and `install.sh` globs `skills/*/`. `install.sh` links
  each skill directory by name, so an existing install gains the new
  skills, and loses the dangling old link, only when it is rerun and the
  link deleted (the upgrade note says so).
- Word budgets: `ratchet` 1,997 (T6 brings it to 1,999 with no cut; T9's
  removal of the inventory note brings it to 1,969); `worktree-discipline`
  1,996 (T11's edit is word for word); `merge-change` 2,000 (no edit);
  `develop-change` falls to about 1,350; `verify-before-merge` rises by 8 to
  about 1,374.
- Every skill directory name is a forbidden word in a guidelines file
  (`tests/test-guidelines.bats` and T2's test loop over `skills/*/`), so
  neither code guidelines file may contain `ratchet`, `merge-change` or any
  other skill name.

Wave 1, at most five at once: T1, T2, T3, T4, T5, then T6 and T7 as slots
free. Wave 2: T8 after T2; T11 after T3. Wave 3: T9 after T5, T6 and T8.
Wave 4: T10 after T9. Wave 5: T12 after all.

### T1 — `guidelines-file.sh` knows the kind `CODE`

**Files touched:** `scripts/guidelines-file.sh`, `tests/guidelines-file.bats`
**Parallel:** yes
**Decisions:** D4, D5

In `scripts/guidelines-file.sh`, line 34 becomes `KNOWN_KINDS='TEST CODE'`,
and the header comment's citation line becomes
`# (docs/plans/2026-10-08-test-guidelines.md D3, D8;
# docs/plans/2026-10-13-code-guidelines.md D4), one line per distinct`
rewrapped to fit. Nothing else in the script changes: every path rule is
already per kind (`${kind}_GUIDELINES.md`), so a unit's code file replaces
the root's whole (D5) with no new code.

In `tests/guidelines-file.bats`, rewrite the unknown-kind test and add three
after it:

```bash
# verifies: D8 (docs/plans/2026-10-08-test-guidelines.md); D4 (docs/plans/2026-10-13-code-guidelines.md)
@test "guidelines-file: an unknown kind is exit 2, naming the known kinds" {
    run sh .guardrails/scripts/guidelines-file.sh ARCHITECTURE src/a.sh
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"unknown kind: ARCHITECTURE (known: TEST CODE)"* ]] || { echo "$output"; false; }
}

# verifies: D4, D5 (docs/plans/2026-10-13-code-guidelines.md); D3, D8 (docs/plans/2026-10-08-test-guidelines.md)
@test "guidelines-file: CODE picks the unit's, the root's or the installed default file, as TEST does" {
    printf '# Code guidelines (installed default)\n' > .guardrails/templates/CODE_GUIDELINES.md
    run sh .guardrails/scripts/guidelines-file.sh CODE src/a.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$output" = ".guardrails/templates/CODE_GUIDELINES.md: src/a.sh" ] || { echo "$output"; false; }
    write_units_manifest
    printf '# Code guidelines (project)\n' > docs/CODE_GUIDELINES.md
    printf '# Code guidelines (pump)\n' > apps/pump/docs/CODE_GUIDELINES.md
    run sh .guardrails/scripts/guidelines-file.sh CODE apps/pump/x.c apps/ui/y.ts vendor/v.c
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    expected="apps/pump/docs/CODE_GUIDELINES.md: apps/pump/x.c
docs/CODE_GUIDELINES.md: apps/ui/y.ts vendor/v.c"
    [ "$output" = "$expected" ] || { echo "$output"; false; }
}

# verifies: D4 (docs/plans/2026-10-13-code-guidelines.md)
@test "guidelines-file: one kind's project file never governs another kind" {
    printf '# Code guidelines (installed default)\n' > .guardrails/templates/CODE_GUIDELINES.md
    write_root_guidelines
    run sh .guardrails/scripts/guidelines-file.sh CODE src/a.sh
    [ "$status" -eq 0 ] || { echo "$output"; false; }
    [ "$output" = ".guardrails/templates/CODE_GUIDELINES.md: src/a.sh" ] || { echo "$output"; false; }
}

# verifies: D4 (docs/plans/2026-10-13-code-guidelines.md)
@test "guidelines-file: a missing CODE default is exit 2 though the TEST default is installed" {
    run sh .guardrails/scripts/guidelines-file.sh CODE src/a.sh
    [ "$status" -eq 2 ] || { echo "$output"; false; }
    [[ "$output" == *"no installed default"* ]] || { echo "$output"; false; }
    [[ "$output" == *"CODE_GUIDELINES.md"* ]] || { echo "$output"; false; }
}
```

Red before the script edit: the three new tests and the rewritten one fail on
`unknown kind: CODE` or on `(known: TEST)`.

```sh
sh tests/run-tests.sh tests/guidelines-file.bats
sh tests/run-tests.sh tests/portability.bats
```

Expected: all pass, 15 tests in the first file; `portability.bats` passes
unchanged (POSIX sh, `case` patterns, the strict-awk run of this script).

**Done** (merged from `code-guidelines-t1`, 4dd07be).

red -> green: guidelines-file: an unknown kind is exit 2, naming the known kinds — watched fail on "(known: TEST)" before the script edit
red -> green: guidelines-file: CODE picks the unit's, the root's or the installed default file, as TEST does — watched fail on "unknown kind: CODE (known: TEST)" before the script edit
red -> green: guidelines-file: one kind's project file never governs another kind — watched fail on "unknown kind: CODE (known: TEST)" before the script edit
red -> green: guidelines-file: a missing CODE default is exit 2 though the TEST default is installed — watched fail on "unknown kind: CODE (known: TEST)" (status 2 matched, "no installed default" did not) before the script edit

### T2 — `templates/CODE_GUIDELINES.md` ships four sections

**Files touched:** `templates/CODE_GUIDELINES.md`, `tests/code-guidelines.bats`
**Parallel:** yes
**Decisions:** D2, D3, D5

Write `templates/CODE_GUIDELINES.md` with exactly this text. Its shape is
`templates/TEST_GUIDELINES.md`'s: a preface of four lines, then numbered
clauses written `N. **<rule>.** <boundary>. Why: <reason>. Example: <…>`. It
names no skill, ADR, plan or reference file (test-guidelines D6).

*(Code pruned at merge: 118 lines. Files touched: `templates/CODE_GUIDELINES.md`, `tests/code-guidelines.bats`.)*

New file `tests/code-guidelines.bats`:

*(Code pruned at merge: 105 lines. Files touched: `templates/CODE_GUIDELINES.md`, `tests/code-guidelines.bats`.)*

Red: every test fails with the template absent (the first on its `-f` check,
the others on `grep`, `awk` or `wc` reading a missing file).

*(Code pruned at merge: 2 lines. Files touched: `templates/CODE_GUIDELINES.md`, `tests/code-guidelines.bats`.)*

Expected: 7 of 7 pass; `test-guidelines.bats` passes unchanged. Report the
template's word count (about 1,050).


**Done** (merged from `code-guidelines-t2`, 45418c8).

red -> green: code guidelines: the template's clauses, by heading and number — watched fail (no templates/CODE_GUIDELINES.md) before the template existed
red -> green: code guidelines: the template has the four headings, in order — watched fail (grep non-zero on the missing template) before the template existed
red -> green: code guidelines: every clause states a reason and an example — watched fail (awk exit 2 on the missing template) before the template existed
red -> green: code guidelines: the boundaries D3 names are stated — watched fail ('without a second caller' not found) before the template existed
red -> green: code guidelines: the preface states the one-file rule and the floor rule — watched fail (awk exit 2 on the missing template) before the template existed
red -> green: code guidelines: the template stands alone, naming no guardrails document or skill — watched fail (grep could not read the missing template) before the template existed
red -> green: code guidelines: the template is at most 1,400 words — watched fail (wc could not read the missing template) before the template existed

### T3 — `develop-tdd` is the task subagent's one skill

**Files touched:** `skills/develop-tdd/SKILL.md`, `tests/develop-tdd.bats`
**Parallel:** yes
**Decisions:** D1, D4

`skills/develop-tdd/SKILL.md` is assembled from three parts, in order. The
moved text is copied byte for byte from `3694b1e`, so every pin T5 deletes
from `tests/skills.bats` has a twin here. It also serves a fix dispatch for
a `TEST` conformance review's findings (D4): the prompt names the findings,
each is fixed under the loop or reported not fixed, and the report gains a
`fixed:` line.

1. This head, then one blank line:

*(Code pruned at merge: 23 lines. Files touched: `skills/develop-tdd/SKILL.md`, `tests/develop-tdd.bats`.)*

2. Lines 20 to 83 of `develop-change`'s `SKILL.md` at `3694b1e`, unchanged:
   the opening rule, "### The loop, one behavior at a time" (steps 1 to 6),
   "Class rules", "Bugs" and "### Test guidelines", and the blank line 83:
   `git show 3694b1e:skills/develop-change/SKILL.md | sed -n 20,83p`.
3. This tail. Its shape fence is lines 136 to 146 of the same file with the
   `fixed:` line added before `surprises:`; its `inherited:` bullet carries
   the sentence `develop-change`'s rationale held ("It is coverage, not
   red-first evidence"), which T5 deletes there:

````markdown
### The dispatch report

Return this shape and nothing else: no diffs, no logs, no narrative.

```
task: <ID>
worktree: <path to the task worktree>
files touched: <paths>
tests added: <test name — verifies: <IDs>>   (one per line)
red -> green: <test name> — watched fail for the right reason before the
implementation existed   (one per line, one per test)
inherited: <test name> — from <old ID>
result: <N passed, N failed>
fixed: <finding-N — what changed, or "not fixed — <reason>">   (a fix
dispatch only, one per finding)
surprises: <anything unexpected, or "none">
```

- Write one `red -> green:` line per new test. It is the only record that
  the test failed before its implementation existed.
- An `inherited:` line names a pre-existing test of a superseded item that
  the task pointed at its successor. It is coverage, not red-first evidence:
  the successor still needs its own `red -> green:` test. Never re-annotate
  any other test that was green before the task.
- `worktree:` is the path the prompt stated. Work anywhere else is a task
  that did not work; say so under `surprises:`.

## Red flags

| Thought | Reality |
|---|---|
| "I'll keep the code I wrote as reference while I write the test" | Delete it and start from the test. |
| "The test passed on its first run, good" | It proves nothing. Find out why it did not fail. |
| "This helper is complex, I'll test it directly" | Do what the guidelines file's `## Seams` says. |
| "The project file leaves this out; I'll read the default too" | One file per path. A rule the project dropped is dropped. |
| "I'll merge my task branch when I am done" | Leave it on the task branch. The dispatcher runs `task-worktree.sh merge`. |
| "The suite is green, the red -> green lines can go" | Each new test needs its line; the gate reads them at check 4. |
| "This finding is wrong; I'll skip it quietly" | Report it as not fixed, with the reason. The dispatcher decides. |

## Done when

- Each behavior of the task has a test that was watched fail for the right
  reason, then pass; on a fix dispatch, each finding is fixed or reported
  not fixed with its reason.
- The suite is green and its output is clean.
- The work is committed on the task branch, which is not merged.
- The dispatch report is returned, with one `red -> green:` line per new
  test.
````

No `## References`: the skill has no reference file. About 1,050 words.

New file `tests/develop-tdd.bats` (T11 appends one test to it):

*(Code pruned at merge: 105 lines. Files touched: `skills/develop-tdd/SKILL.md`, `tests/develop-tdd.bats`.)*

Red: all ten fail with `SKILL.md` absent.

*(Code pruned at merge: 2 lines. Files touched: `skills/develop-tdd/SKILL.md`, `tests/develop-tdd.bats`.)*

Expected: 10 of 10; `test-guidelines.bats` unchanged and green (its
stands-alone loop now also checks that neither test guidelines file names
`develop-tdd`).

**Done** (merged from `code-guidelines-t3`, d39d234).

red -> green: develop-tdd: the skill is named, and only a dispatched task subagent loads it — watched fail ("no develop-tdd SKILL.md") before skills/develop-tdd/SKILL.md existed
red -> green: develop-tdd: a TEST conformance finding is fixed under the loop, or reported not fixed — watched fail ("no develop-tdd SKILL.md") before skills/develop-tdd/SKILL.md existed
red -> green: develop-tdd: no production code without a failing test first — watched fail ("no develop-tdd SKILL.md") before skills/develop-tdd/SKILL.md existed
red -> green: develop-tdd: the loop runs RED, then GREEN, and its sixth step commits — watched fail ("no develop-tdd SKILL.md") before skills/develop-tdd/SKILL.md existed
red -> green: develop-tdd: the class rules and the bug rule — watched fail ("no develop-tdd SKILL.md") before skills/develop-tdd/SKILL.md existed
red -> green: develop-tdd: every test fails when the behavior it verifies breaks — watched fail ("no develop-tdd SKILL.md") before skills/develop-tdd/SKILL.md existed
red -> green: develop-tdd: before RED, guidelines-file.sh picks the one test guidelines file — watched fail ("no develop-tdd SKILL.md") before skills/develop-tdd/SKILL.md existed
red -> green: develop-tdd: the dispatch report's shape, and an inherited test is coverage — watched fail ("no develop-tdd SKILL.md") before skills/develop-tdd/SKILL.md existed
red -> green: develop-tdd: carries no repository-only mutation-anchor rule — watched fail ("no develop-tdd SKILL.md") before skills/develop-tdd/SKILL.md existed
red -> green: develop-tdd: the subagent's red flags — watched fail ("no develop-tdd SKILL.md") before skills/develop-tdd/SKILL.md existed

### T4 — `develop-refactor` fixes one `CODE` review's findings

**Files touched:** `skills/develop-refactor/SKILL.md`,
`tests/develop-refactor.bats`
**Parallel:** yes
**Decisions:** D1, D4

Write `skills/develop-refactor/SKILL.md` with exactly this text. It is not a
whole-diff pass (D4): it fixes the findings it is handed, in its own nested
task worktree, and never reviews its own fix.

*(Code pruned at merge: 67 lines. Files touched: `skills/develop-refactor/SKILL.md`, `tests/develop-refactor.bats`.)*

New file `tests/develop-refactor.bats`:

*(Code pruned at merge: 66 lines. Files touched: `skills/develop-refactor/SKILL.md`, `tests/develop-refactor.bats`.)*

Red: all six fail with `SKILL.md` absent.

*(Code pruned at merge: 1 line. Files touched: `skills/develop-refactor/SKILL.md`, `tests/develop-refactor.bats`.)*

Expected: 6 of 6. About 550 words.

**Done** (merged from `code-guidelines-t4`, fa99353).

red -> green: develop-refactor: the skill is named, and fixes one CODE review's findings — watched fail (SKILL.md absent) before skills/develop-refactor/SKILL.md existed
red -> green: develop-refactor: it works in its nested task worktree and does not merge — watched fail (SKILL.md absent) before skills/develop-refactor/SKILL.md existed
red -> green: develop-refactor: it reads the one code guidelines file and fixes what the findings state — watched fail (SKILL.md absent) before skills/develop-refactor/SKILL.md existed
red -> green: develop-refactor: no behavior change, and no test loosened — watched fail (SKILL.md absent) before skills/develop-refactor/SKILL.md existed
red -> green: develop-refactor: a finding it cannot fix is reported, with the reason — watched fail (SKILL.md absent) before skills/develop-refactor/SKILL.md existed
red -> green: develop-refactor: the report's shape — watched fail (SKILL.md absent) before skills/develop-refactor/SKILL.md existed

### T5 — `develop-change` is the orchestrator, and runs the conformance reviews

**Files touched:** `skills/develop-change/SKILL.md`,
`skills/develop-change/references/rationale.md`, `tests/skills.bats`
**Parallel:** yes
**Decisions:** D1, D4, D5, D6

In `skills/develop-change/SKILL.md` (line numbers at `3694b1e`):

- Lines 1 to 16 (frontmatter to Preconditions) become:

*(Code pruned at merge: 16 lines. Files touched: `skills/develop-change/SKILL.md`, `skills/develop-change/references/rationale.md`, `tests/skills.bats`.)*

- Delete lines 20 to 83: the opening rule, the loop, Class rules, Bugs and
  "### Test guidelines" (T3 carries them).
- "### Delegation", first paragraph: "You orchestrate the loop: a subagent
  runs it for one plan task under\n`develop-tdd`, and you keep the plan, the
  trace and the decisions." In the prompt, line 99 ends `under the
  develop-tdd` in place of `under the develop-change`; nothing else in the
  prompt changes.
- "### The dispatch report": replace lines 133 to 146 (the opening sentence
  and the shape fence) with "The subagent returns the report shape
  `develop-tdd` states, and nothing\nelse: no diffs, no logs, no narrative."
  Keep the three bullets after it.
- Replace lines 184 to 235 ("### The deslop pass" and "### The guideline
  reviews", with the blank line after them) with this section. The reviews
  run all at once, outside the five-at-once cap, because each only reads
  (D4); the fixes are task dispatches like any other:

*(Code pruned at merge: 52 lines. Files touched: `skills/develop-change/SKILL.md`, `skills/develop-change/references/rationale.md`, `tests/skills.bats`.)*

- Replace "## Red flags" and "## Done when" with the following; the four
  rows about writing a test go to `develop-tdd` (T3):

*(Code pruned at merge: 21 lines. Files touched: `skills/develop-change/SKILL.md`, `skills/develop-change/references/rationale.md`, `tests/skills.bats`.)*

- Keep `## References` as it is. About 1,350 words.

In `skills/develop-change/references/rationale.md`: delete
`## An inherited line is coverage, not evidence` (its sentence is in
`develop-tdd` now), and replace the three `## The deslop pass …` sections,
from that heading to the end of the file, with:

*(Code pruned at merge: 23 lines. Files touched: `skills/develop-change/SKILL.md`, `skills/develop-change/references/rationale.md`, `tests/skills.bats`.)*

In `tests/skills.bats`:

- Replace `clanker: develop-change dispatches one deslop pass over the whole
  diff` with:

*(Code pruned at merge: 16 lines. Files touched: `skills/develop-change/SKILL.md`, `skills/develop-change/references/rationale.md`, `tests/skills.bats`.)*

- Rename `clanker: the deslop pass is not deferred to the merge review` to
  `clanker: the conformance reviews are not deferred to the merge review`,
  and add `; D4 (docs/plans/2026-10-13-code-guidelines.md)` to its
  `verifies:` line; its body is unchanged (`**reruns from step 1**` is kept
  in the new section).
- Replace `clanker: the deslop dispatch prohibits a task worktree` with:

*(Code pruned at merge: 9 lines. Files touched: `skills/develop-change/SKILL.md`, `skills/develop-change/references/rationale.md`, `tests/skills.bats`.)*

- Replace `clanker: the deslop pass reviews against the code rules` with:

*(Code pruned at merge: 14 lines. Files touched: `skills/develop-change/SKILL.md`, `skills/develop-change/references/rationale.md`, `tests/skills.bats`.)*

- In `skills: check 4 reads per ID and names an inherited test as coverage`,
  replace the `report=` assignment and the four assertions after it (the
  shape line, the plan line, the rationale comment and the coverage grep)
  with the comment and one assertion below; the rest of the test is
  unchanged:

*(Code pruned at merge: 4 lines. Files touched: `skills/develop-change/SKILL.md`, `skills/develop-change/references/rationale.md`, `tests/skills.bats`.)*

- Replace the block from the comment `# --- test guidelines
  (docs/plans/2026-10-08-test-guidelines.md) ---` through the end of
  `develop-change: before RED, guidelines-file.sh picks the one guidelines
  file` with:

*(Code pruned at merge: 33 lines. Files touched: `skills/develop-change/SKILL.md`, `skills/develop-change/references/rationale.md`, `tests/skills.bats`.)*

- Replace `develop-change: the guideline reviews follow the deslop pass,
  before merge-change` with:

*(Code pruned at merge: 12 lines. Files touched: `skills/develop-change/SKILL.md`, `skills/develop-change/references/rationale.md`, `tests/skills.bats`.)*

- In `develop-change: guideline review findings go into the plan as they
  arrive, and step 6b copies them`, the `awk` that cuts the section reads
  `/^### The conformance reviews$/` in place of `/^### The guideline
  reviews$/`; nothing else changes.
- Delete `develop-change: a missing or broken guidelines-file.sh stops the
  task` and `develop-change: a clause that contradicts the skill is a finding
  against the clause`: both pin text that moved, and `tests/develop-tdd.bats`
  pins it there.

Red, watched before the skill edit: the four replaced tests, the two new
ones in the split block (`it is the dispatcher`, `task subagents load
develop-tdd`), and the edited `guideline review findings go into the plan`
fail; every other test in the file passes.

*(Code pruned at merge: 1 line. Files touched: `skills/develop-change/SKILL.md`, `skills/develop-change/references/rationale.md`, `tests/skills.bats`.)*

Expected: all pass, 127 tests. `clanker: the gate checks that the deslop
pass was run` still names the old pass; T10 replaces it.

**Done** (merged from `code-guidelines-t5`, 3b7f7a7).

red -> green: develop-change: one conformance review per guidelines file replaces the old whole-diff pass — watched fail ("no conformance reviews section") before the skill edit
red -> green: develop-change: a conformance reviewer changes nothing and gets no task worktree — watched fail on the missing "Read the change worktree at <path>; do not create a task worktree, edit, or commit." before the skill edit
red -> green: develop-change: a CODE finding is fixed under develop-refactor, a TEST finding under develop-tdd — watched fail on the missing "Once every review has reported, dispatch the fixes" before the skill edit
red -> green: develop-change: it is the dispatcher, which no subagent loads — watched fail ("the description does not name develop-tdd") before the skill edit
red -> green: develop-change: task subagents load develop-tdd, and the loop is stated there, not here — watched fail ("the prompt does not name develop-tdd") before the skill edit
red -> green: develop-change: the conformance reviews follow derailment, before merge-change — watched fail on the last-### heading check before the skill edit
red -> green: develop-change: guideline review findings go into the plan as they arrive, and step 6b copies them — watched fail on the missing "Write each finding…" line before the skill edit
renamed: develop-change: the task prompt names the guidelines file guidelines-file.sh TEST printed — its one assertion carried from "before RED, guidelines-file.sh picks the one guidelines file"
renamed: clanker: the conformance reviews are not deferred to the merge review — renamed from the deslop-pass test; the floor-note fix later gave it a second assertion, with its own red -> green line

### T6 — tailoring knows `CODE`; `ratchet` installs and tailors it

**Files touched:** `skills/tailor-guidelines/SKILL.md`,
`skills/ratchet/SKILL.md`, `skills/ratchet/references/upgrade-notes.md`,
`tests/tailor-guidelines.bats`
**Parallel:** yes
**Decisions:** D2, D4, D5, D6

- `tailor-guidelines`:
  - description: "(such as docs/TEST_GUIDELINES.md or
    docs/CODE_GUIDELINES.md)", and "its test or code guidelines";
  - Preconditions: "You know the kind: `TEST` (`docs/TEST_GUIDELINES.md`) or
    `CODE`\n  (`docs/CODE_GUIDELINES.md`). Where" (the rest of the bullet
    unchanged);
  - steps 3 and 4 become, wrapped so that `ask for an example in the
    project's own stack` stays on one line for the existing pin:

*(Code pruned at merge: 6 lines. Files touched: `skills/tailor-guidelines/SKILL.md`, `skills/ratchet/SKILL.md`, `skills/ratchet/references/upgrade-notes.md`, `tests/tailor-guidelines.bats`.)*

  - the red-flag row "The generic examples will do" answers "Ask for the
    project's own: Seams and Doubles for `TEST`, every clause for `CODE`."
  - `CODE` gets every clause because D3's examples are language-neutral and
    each is better in the project's language; `TEST`'s other sections keep
    their generic examples, as test-guidelines D7 ruled.
- `ratchet/SKILL.md` (1,997 words; this task adds 2, to 1,999, and T9's
  removal pays them back):
  - step 2.3, `- \`templates/TEST_GUIDELINES.md\` →
    \`.guardrails/templates/TEST_GUIDELINES.md\`` becomes
    `- \`templates/*_GUIDELINES.md\` → \`.guardrails/templates/\``, as the
    upgrade step already says;
  - step 2.6: "Run `tailor-guidelines` for `TEST` and `CODE` (once more per
    unit that\n   wants its own file)."
- `upgrade-notes.md` gains, at its end:

*(Code pruned at merge: 21 lines. Files touched: `skills/tailor-guidelines/SKILL.md`, `skills/ratchet/SKILL.md`, `skills/ratchet/references/upgrade-notes.md`, `tests/tailor-guidelines.bats`.)*

In `tests/tailor-guidelines.bats`, replace `ratchet: the scaffold installs
the test guidelines default and tailors it` with the first block below, and
append the other two:

*(Code pruned at merge: 28 lines. Files touched: `skills/tailor-guidelines/SKILL.md`, `skills/ratchet/SKILL.md`, `skills/ratchet/references/upgrade-notes.md`, `tests/tailor-guidelines.bats`.)*

Red before the skill edits: the three new or rewritten tests fail; the rest
pass.

*(Code pruned at merge: 2 lines. Files touched: `skills/tailor-guidelines/SKILL.md`, `skills/ratchet/SKILL.md`, `skills/ratchet/references/upgrade-notes.md`, `tests/tailor-guidelines.bats`.)*

Expected: 12 of 12; `1999 skills/ratchet/SKILL.md`. If the count is above
2,000, cut words from the two edited lines only; change no rule.

**Done** (merged from `code-guidelines-t6`, 04ac939).

red -> green: ratchet: the scaffold installs every guidelines default and tailors TEST and CODE — watched fail before the edit (the `templates/*_GUIDELINES.md` → `.guardrails/templates/` line was absent)
red -> green: tailor-guidelines: the kinds are TEST and CODE, and CODE's examples are the project's — watched fail before the edit (Preconditions named only `TEST`)
red -> green: upgrade notes: code guidelines, the dropped pass and the renamed reviewer — watched fail before the edit ("no Code guidelines section")
renamed: ratchet: the scaffold installs every guidelines default and tailors TEST and CODE — from "ratchet: the scaffold installs the test guidelines default and tailors it"

### T7 — `review-guidelines` is renamed `review-conformance`

**Files touched:** `skills/review-guidelines/SKILL.md`,
`skills/review-conformance/SKILL.md`, `tests/review-guidelines.bats`,
`tests/review-conformance.bats`
**Parallel:** yes
**Decisions:** D4, D6

The other files that name the skill are renamed by the task that already
edits them: `develop-change` (T5), `README.md` (T11), the review checklist
and the record template (T10), `tests/skills.bats` (T5, T10).

1. `git mv tests/review-guidelines.bats tests/review-conformance.bats`;
   in it, replace every `review-guidelines` with `review-conformance` (the
   header comment, the `setup` path, every test name), add
   `; D6 (docs/plans/2026-10-13-code-guidelines.md)` to the frontmatter
   test's `verifies:` line, and append the two tests below. Run it: all ten
   fail, since `skills/review-conformance/SKILL.md` does not exist.
2. `git mv skills/review-guidelines skills/review-conformance`, then in
   `SKILL.md`:
   - `name: review-conformance`;
   - description: "Review a change diff for conformance to one project
     guidelines file (such as docs/TEST_GUIDELINES.md or
     docs/CODE_GUIDELINES.md) in a fresh context, read-only, citing a clause
     for every finding. Dispatched by develop-change once per guidelines
     file that governs the diff, all at once, after every task branch is
     merged." (one line);
   - the title `# Review Conformance`, and the announce line "Using the
     review-conformance skill against <file>.";
   - a fourth Preconditions bullet: "Change nothing: no edit, no commit, no
     task worktree. Another agent fixes\n  your findings, and the next round
     reviews the fix.";
   - a sixth Red flags row: `| "The fix is one line; I'll make it" | You
     change nothing. Report it; a fixer makes it. |`.

*(Code pruned at merge: 15 lines. Files touched: `skills/review-guidelines/SKILL.md`, `skills/review-conformance/SKILL.md`, `tests/review-guidelines.bats`, `tests/review-conformance.bats`.)*

*(Code pruned at merge: 1 line. Files touched: `skills/review-guidelines/SKILL.md`, `skills/review-conformance/SKILL.md`, `tests/review-guidelines.bats`, `tests/review-conformance.bats`.)*

Expected: 10 of 10. About 700 words.

**Done** (merged from `code-guidelines-t7`, fe41277).

red -> green: review-conformance: the frontmatter names the skill — watched fail (still red after the git mv; green once `name: review-conformance` was written)
red -> green: review-conformance: a finding cites a clause, a severity and a location — watched fail (skills/review-conformance/SKILL.md missing) before the rename
red -> green: review-conformance: the floor is listed in full — watched fail (skills/review-conformance/SKILL.md missing) before the rename
red -> green: review-conformance: a clause that contradicts the floor is a finding against the clause — watched fail (skills/review-conformance/SKILL.md missing) before the rename
red -> green: review-conformance: a stale reason or a reference out of the file is a finding against the clause — watched fail (skills/review-conformance/SKILL.md missing) before the rename
red -> green: review-conformance: what the file does not state is a note, never a finding — watched fail (skills/review-conformance/SKILL.md missing) before the rename
red -> green: review-conformance: the report ends with a verdict line — watched fail (skills/review-conformance/SKILL.md missing) before the rename
red -> green: review-conformance: the three red flags are present — watched fail (skills/review-conformance/SKILL.md missing) before the rename
red -> green: review-conformance: the old name is gone, and the description names both kinds — watched fail (old skill dir present; after the git mv, red on the description text)
red -> green: review-conformance: the reviewer changes nothing — watched fail (after the git mv, red on the missing "Change nothing" precondition)
renamed: the eight renamed review-conformance tests — from the same names in tests/review-guidelines.bats

### T8 — this repository's `docs/CODE_GUIDELINES.md`

**Files touched:** `docs/CODE_GUIDELINES.md`, `tests/code-guidelines.bats`
**Parallel:** no (serial, after T2)
**Decisions:** D2, D5

`docs/CODE_GUIDELINES.md` is a complete copy of `templates/CODE_GUIDELINES.md`
as T2 left it (test-guidelines D6: no reference to the template), keeping
every clause, with its examples replaced by this repository's: POSIX sh and
awk from `scripts/`. Names 1 and 2 carry AGENTS.md's `## Code: names` rules
("No single-character names. No code golf." and "Name in concrete terms."),
which T9 then removes from AGENTS.md. Each example names code that exists:
`index_number` (`scripts/guidelines-file.sh`, `scripts/prune-plans.sh`),
`governing_file`, `guidelines_name` and `has_exact_file`
(`scripts/guidelines-file.sh`), `repo_root` (the scripts), `gr_die`
(`scripts/lib.sh`, which prints `guardrails: <message>` and exits 2),
`grep -c … || true` (`scripts/check-review.sh`), `prune_plans`'s stated
default (`scripts/prune-plans.sh`), the `# NOT cd "$(gr_root)" …` comment
(`scripts/guidelines-file.sh`). The file names no skill, not even in an
example, since every skill directory name is a forbidden word in it.

*(Code pruned at merge: 122 lines. Files touched: `docs/CODE_GUIDELINES.md`, `tests/code-guidelines.bats`.)*

Append to `tests/code-guidelines.bats`:

*(Code pruned at merge: 51 lines. Files touched: `docs/CODE_GUIDELINES.md`, `tests/code-guidelines.bats`.)*

Red: the four fail with the file absent.

*(Code pruned at merge: 1 line. Files touched: `docs/CODE_GUIDELINES.md`, `tests/code-guidelines.bats`.)*

Expected: 11 of 11. About 1,130 words.

**Done** (merged from `code-guidelines-t8`, b702c54). Deviation: Comments 1's example quotes `scripts/guidelines-file.sh:47` exactly, inner backticks included.

red -> green: code guidelines: this repository's file keeps every clause of the template — watched fail ("no docs/CODE_GUIDELINES.md") before the file existed
red -> green: code guidelines: this repository's file stands alone, naming no guardrails document or skill — watched fail ("no docs/CODE_GUIDELINES.md") before the file existed
red -> green: code guidelines: this repository's examples are its own POSIX sh — watched fail ("no docs/CODE_GUIDELINES.md") before the file existed
red -> green: code guidelines: this repository's file is at most 1,600 words — watched fail ("integer expression expected") before the file existed

### T9 — the naming rules leave the managed block and AGENTS.md

**Files touched:** `templates/AGENTS-block.md`, `AGENTS.md`,
`skills/ratchet/SKILL.md`, `tests/skills.bats`
**Parallel:** no (serial, after T5, T6 and T8)
**Decisions:** D2

- `templates/AGENTS-block.md`: delete the `## Code: names` heading, its two
  bullets and the blank line after them. The workflow map is unchanged.
- `AGENTS.md`: delete the same four lines. `docs/CODE_GUIDELINES.md` (T8)
  carries them, and the conformance review reads it through
  `guidelines-file.sh CODE`.
- `skills/ratchet/SKILL.md`, retrofit step 3.1: delete the bullet "A managed
  block with no `## Code: names` section is a gap that no check reports.
  Record it in the gap analysis; the first tooth's block merge replaces it."
  The count falls from 1,999 to 1,969.

In `tests/skills.bats`, replace `clanker: the managed block names concrete
naming rules`, `clanker: this repository follows the same block` and
`clanker: ratchet reports a managed block with no code section`, in that
order, with these three:

*(Code pruned at merge: 44 lines. Files touched: `templates/AGENTS-block.md`, `AGENTS.md`, `skills/ratchet/SKILL.md`, `tests/skills.bats`.)*

Red before the three file edits: all three fail; every other test passes.

*(Code pruned at merge: 2 lines. Files touched: `templates/AGENTS-block.md`, `AGENTS.md`, `skills/ratchet/SKILL.md`, `tests/skills.bats`.)*

Expected: all pass, 127 tests; `1969 skills/ratchet/SKILL.md`.

**Done** (merged from `code-guidelines-t9`, acc824f). Red run: 124 ok, 3 not ok of 127, exactly the three below.

red -> green: code guidelines: the naming rules left the managed block for the code guidelines template — watched fail before the block edit
red -> green: code guidelines: this repository's naming rules live in its own code guidelines file — watched fail before the AGENTS.md edit (that body was later cut by the round-3 CODE fix, 0064b11, and restored with positive assertions in the last-round fix below)
red -> green: ratchet: the retrofit inventory no longer looks for a ## Code: names section — watched fail before the ratchet edit

### T10 — the gate and the record name the conformance reviews

**Files touched:** `skills/verify-before-merge/SKILL.md`,
`skills/verify-before-merge/references/rationale.md`,
`skills/merge-change/references/review-checklist.md`,
`templates/verification.md`, `tests/skills.bats`
**Parallel:** no (serial, after T9)
**Decisions:** D1, D4, D5, D6

- `verify-before-merge/SKILL.md`: check 8 becomes the following (8 words
  more, to about 1,374); check 6 reads "per `develop-tdd`'s robustness" in
  place of "per `develop-change`'s robustness" (D1).

*(Code pruned at merge: 5 lines. Files touched: `skills/verify-before-merge/SKILL.md`, `skills/verify-before-merge/references/rationale.md`, `skills/merge-change/references/review-checklist.md`, `templates/verification.md`, `tests/skills.bats`.)*

- `verify-before-merge/references/rationale.md`, `## Check 8 is the
  dispatcher's`, its paragraph becomes: "The tree records no difference
  between a diff a conformance review checked\nand a diff nobody reviewed,
  so the gate subagent cannot answer the check.\nThe dispatcher answers it
  from the plan, where each finding and its\ndisposition are written."
- `merge-change/references/review-checklist.md`: line 60 names
  `review-conformance`; the last item of `## The test checklist` becomes the
  block below. `merge-change/SKILL.md` (2,000 words) is not edited.

*(Code pruned at merge: 5 lines. Files touched: `skills/verify-before-merge/SKILL.md`, `skills/verify-before-merge/references/rationale.md`, `skills/merge-change/references/review-checklist.md`, `templates/verification.md`, `tests/skills.bats`.)*

- `templates/verification.md`: the `## Guideline reviews` section keeps its
  heading (D5); its first sentence opens as below, the rest unchanged; and
  the field-grammar comment's `(\`review-guidelines\`)` reads
  `(\`review-conformance\`)`.

*(Code pruned at merge: 2 lines. Files touched: `skills/verify-before-merge/SKILL.md`, `skills/verify-before-merge/references/rationale.md`, `skills/merge-change/references/review-checklist.md`, `templates/verification.md`, `tests/skills.bats`.)*

In `tests/skills.bats`:

- Replace `clanker: the gate checks that the deslop pass was run` with the
  two tests below.
- In `merge-change: the review checklist's test section is the floor, and
  checks the guideline reviews ran`: the comment's `review-guidelines`
  reads `review-conformance`; the pin `the plan lists a guideline review for
  each file` reads `the plan lists a conformance review for each file`; and
  after it add
  `printf '%s\n' "$section" | grep -qF 'and for each file `guidelines-file.sh CODE` prints for it'`.
- In `verification template: guideline reviews have their own section`,
  after the line that greps `guidelines-file.sh TEST`, add:

*(Code pruned at merge: 3 lines. Files touched: `skills/verify-before-merge/SKILL.md`, `skills/verify-before-merge/references/rationale.md`, `skills/merge-change/references/review-checklist.md`, `templates/verification.md`, `tests/skills.bats`.)*

*(Code pruned at merge: 20 lines. Files touched: `skills/verify-before-merge/SKILL.md`, `skills/verify-before-merge/references/rationale.md`, `skills/merge-change/references/review-checklist.md`, `templates/verification.md`, `tests/skills.bats`.)*

Red before the four file edits: the two new tests and the two extended ones
fail.

*(Code pruned at merge: 2 lines. Files touched: `skills/verify-before-merge/SKILL.md`, `skills/verify-before-merge/references/rationale.md`, `skills/merge-change/references/review-checklist.md`, `templates/verification.md`, `tests/skills.bats`.)*

Expected: all pass, 128 tests in `skills.bats`; `check-review.bats`, which
reads the record template, unchanged and green.

**Done** (merged from `code-guidelines-t10`, 1d68ff1).

red -> green: verify-before-merge: check 8 asks that each conformance review ran and was dispositioned — watched fail on the "8. **Each conformance review ran** ..." grep before the SKILL.md edit
red -> green: verify-before-merge: check 6 cites the robustness rule where develop-tdd states it — watched fail on "per `develop-tdd`'s robustness rule" before the SKILL.md edit
red -> green: merge-change: the review checklist's test section is the floor, and checks the guideline reviews ran — watched fail on "the plan lists a conformance review for each file ..." before the checklist edit
red -> green: verification template: guideline reviews have their own section — watched fail on "guidelines-file.sh CODE" before the template edit
renamed: verify-before-merge: check 8 asks that each conformance review ran and was dispositioned — from "clanker: the gate checks that the deslop pass was run"

### T11 — citations of the moved rules name `develop-tdd`; README

**Files touched:** `skills/worktree-discipline/SKILL.md`,
`skills/resolve-problem/SKILL.md`, `skills/grill-requirements/SKILL.md`,
`README.md`, `tests/check-signing.bats`, `tests/develop-tdd.bats`
**Parallel:** no (serial, after T3)
**Decisions:** D1, D4, D6

Each skill edit swaps one name for another, so no word count changes
(`worktree-discipline` stays at 1,996):

- `worktree-discipline/SKILL.md` step 1: "(unsigned, `develop-tdd` step 6)"
  in place of "(unsigned, `develop-change` step 6)". Its other two
  citations of `develop-change` (the `worktree:` line the dispatcher checks,
  the `red -> green:` lines the dispatcher writes into the plan) stay.
- `resolve-problem/SKILL.md` "### 3. Fix under TDD": "per `develop-tdd`".
- `grill-requirements/SKILL.md`: "written red-first (`develop-tdd`)".
- `tests/check-signing.bats`, the comment at line 116: "the one thing
  `develop-tdd` forbids in the rule that opens its Steps section".
- `README.md`, the workflow diagram: the `TG` node reads
  `tailor-guidelines<br/>the project's TEST_GUIDELINES.md<br/>and CODE_GUIDELINES.md`,
  and the four lines from `W --> DEV` through `RG --> CT` become:

*(Code pruned at merge: 7 lines. Files touched: `skills/worktree-discipline/SKILL.md`, `skills/resolve-problem/SKILL.md`, `skills/grill-requirements/SKILL.md`, `README.md`, `tests/check-signing.bats`, `tests/develop-tdd.bats`.)*

Append to `tests/develop-tdd.bats`:

*(Code pruned at merge: 13 lines. Files touched: `skills/worktree-discipline/SKILL.md`, `skills/resolve-problem/SKILL.md`, `skills/grill-requirements/SKILL.md`, `README.md`, `tests/check-signing.bats`, `tests/develop-tdd.bats`.)*

Red: the test fails on its first grep before the edits.

*(Code pruned at merge: 2 lines. Files touched: `skills/worktree-discipline/SKILL.md`, `skills/resolve-problem/SKILL.md`, `skills/grill-requirements/SKILL.md`, `README.md`, `tests/check-signing.bats`, `tests/develop-tdd.bats`.)*

Expected: all pass (11 in `develop-tdd.bats`); `1996`.

**Done** (merged from `code-guidelines-t11`, f12aa15).

red -> green: develop-tdd: the skills that cite the TDD rules cite develop-tdd, and the README shows the split — watched fail at its first grep ("(unsigned, `develop-tdd` step 6)" absent from worktree-discipline) before the edits

### T12 — sweeps, word counts and section shape across every skill

**Files touched:** `tests/code-guidelines.bats`
**Parallel:** no (serial, after T1 to T11)
**Decisions:** D2, D4, D5, D6

Append to `tests/code-guidelines.bats`:

*(Code pruned at merge: 42 lines. Files touched: `tests/code-guidelines.bats`.)*

These guard what T1 to T11 already did, so each is watched red against a
temporary breakage, then restored with `git checkout -- <file>`: set
`KNOWN_KINDS='TEST CODE ARCHITECTURE'` in `scripts/guidelines-file.sh` (the
first fails: no template for ARCHITECTURE); append a line holding both old
names to `README.md` (the second and fourth fail, naming the line); append
`## Code: names` to `templates/AGENTS-block.md` (the third fails).

Then run the shape checks over every skill and the whole of each new and
edited test file:

*(Code pruned at merge: 7 lines. Files touched: `tests/code-guidelines.bats`.)*

Expected: every test passes (15 in `code-guidelines.bats`; the three
`skill shape:` tests in `skills.bats` cover the D9 section order, the 2,000
word ceiling and the References listing for all fifteen skills), and the
counts are at most 2,000: `develop-change` about 1,350, `develop-refactor`
about 550, `develop-tdd` about 1,050, `merge-change` 2,000, `ratchet` 1,969,
`review-conformance` about 700, `tailor-guidelines` about 780,
`verify-before-merge` about 1,374, `worktree-discipline` 1,996, the rest as
at `3694b1e`. Report each count in the dispatch report's `surprises:` line
where it differs from these by more than 50 words.

**Done** (merged from `code-guidelines-t12`, 6d78fe9). Each sweep was watched red against a temporary breakage, then restored.

red -> green: code guidelines: every kind guidelines-file.sh knows has a shipped template — watched fail ("no template for ARCHITECTURE") with a third kind added to KNOWN_KINDS
red -> green: code guidelines: the old whole-diff pass is gone from the skills, templates and tests — watched fail (named README.md:137) with the old name appended to README.md
red -> green: code guidelines: no skill, template or AGENTS.md keeps a ## Code: names section — watched fail (named templates/AGENTS-block.md:113) with the heading appended
red -> green: code guidelines: the old name of review-conformance is gone outside the upgrade notes — watched fail (named README.md:137) with the old name appended to README.md

### Fix errors3 — Errors 3 no longer asks that a named default be reported

Found by the T8 subagent: the clause's second half ("a fallback a requirement
names is reported where it is taken") contradicted this repository's own
example, `prune_plans` falling back to `on` silently, and asked for noise the
clause does not intend. Dropped from both files (merged from
`code-guidelines-errors3`, 17772f8).

red -> green: code guidelines: no silent fallback does not require reporting a named default — watched fail ("templates/CODE_GUIDELINES.md requires a named default to be reported") before the edit

### Conformance reviews

#### Round 1 — `docs/TEST_GUIDELINES.md`

reviewer: one `review-conformance` subagent, read-only, range `main...code-guidelines`
verdict: 1 finding (0 high, 1 medium, 0 low); 1 is above low.

**finding-1**: guideline, medium — Seams 1, "A test calls only an interface that a REQ or LLR describes ... In this repository the interface is a script's command line. A bats test runs `sh scripts/<name>.sh` with arguments in a temporary repository and asserts on its output, its exit status and the files it leaves." — tests/code-guidelines.bats:171
The test "code guidelines: every kind guidelines-file.sh knows has a shipped template" gets the script's kinds by running `sed` over the source of `scripts/guidelines-file.sh` and matching the `KNOWN_KINDS='...'` assignment. It never runs the script. That ties the test to an internal variable's name and quoting. A refactor that renames or restructures the variable, with every behavior kept, breaks the test. That is exactly the failure the clause's "Why" names. The behavior is visible at the command line: an unknown kind exits 2 with `unknown kind: <kind> (known: TEST CODE)` (scripts/guidelines-file.sh:62), and tests/guidelines-file.bats already asserts that message. The kinds can be read from that output.
disposition: fixed in `3f103f6` (merged from `code-guidelines-cr1-test`); the rewritten test was watched fail with a third kind in KNOWN_KINDS

note (reviewer): most new tests check shipped skill or template text by grep or awk; Seams 1 names only the script command line as this repository's interface, so the file has a gap for tests of shipped documents (not a finding).

#### Round 1 — `docs/CODE_GUIDELINES.md`

reviewer: one `review-conformance` subagent, read-only, range `main...code-guidelines`, run in parallel with the TEST review
verdict: 5 findings — 0 high, 4 medium, 1 low; four are above low.

**finding-1**: guideline, medium — Simplicity 4, "No duplication between tasks." — "Where two parts of one change add the same helper, constant or check, one copy stays, where both can reach it" — tests/code-guidelines.bats:111, tests/develop-refactor.bats:12, tests/develop-tdd.bats:13
The change adds three byte-identical copies of the `section_of` awk helper. A fourth copy was already at tests/tailor-guidelines.bats:14 on main. `tests/helpers.bash` is reachable from every file through `load helpers`, and code-guidelines.bats already loads it. One copy belongs there.
disposition: fixed in `e04669c` (merged from `code-guidelines-cr1-code`)

**finding-2**: guideline, medium — Errors 2, "No swallowed error." — "Where an error is expected and handled, the handling says why that is safe" / "`|| true` after `grep -c` ... is handled on purpose and its comment says so" — tests/code-guidelines.bats:91, 96, 133, 138 (`count=$(grep -cF ... || true)`) and 189, 198, 207 (`hits=$(... | grep -v ... || true)`)
None of these seven `|| true` carries a comment saying why discarding the exit status is safe. The comments above 189–207 explain the upgrade-notes filter, not the `|| true`. At 91–138, `|| true` also discards grep's exit 2 for an unreadable file. The test still fails then, but only because `[ "" -eq 0 ]` errors, which the code does not state.
disposition: fixed in `e04669c` (merged from `code-guidelines-cr1-code`)

**finding-3**: guideline, medium — Comments 2, "No change narration." — "A comment describes the code as it is, never the change that wrote it: no "added", "now uses", "previously", "fixed" or ticket history" — tests/skills.bats:1084, 1101–1102, 1201, 2278–2279, 2437–2439
These added comments narrate the change rather than state why the test holds: 1084 "The past-participle rule dropped with the prose rules stays dropped."; 1101–1102 "the rules it ships moved to the code guidelines ... The prose section stays removed"; 1201 "The section left the managed block, so a block without it is no gap."; 2278–2279 "The report form and the coverage sentence moved to develop-tdd with the loop"; 2437–2439 "The floor and the one-file rule moved on with the TDD loop to develop-tdd".
disposition: fixed in `e04669c` (merged from `code-guidelines-cr1-code`)

**finding-4**: guideline, medium — Comments 2, "No change narration." — same clause and words — tests/develop-tdd.bats:109
"The loop, the annotation rule and the red-first rule moved to develop-tdd, so a citation of them names it".
disposition: fixed in `e04669c` (merged from `code-guidelines-cr1-code`)

**finding-5**: guideline, low — Names 4, "One name per concept across the change." — "A concept has one name in every file, test and task of the change" — skills/develop-change/SKILL.md:156, templates/verification.md:98
The change renames the concept "conformance reviews" (develop-change's "### The conformance reviews", verification.md:101 "The conformance reviews"). The record section that holds those reviews keeps the old name `## Guideline reviews`, so one concept has two names across the change. The heading may be one a script parses, which would make keeping it right; if so, the code is right and this is a gap only.
disposition: not fixed — D5 keeps the record heading `## Guideline reviews` by name, so records written before and after this change share one section; no script parses it today (`grep -rn 'Guideline reviews' scripts/` is empty), and the queued D9 gate will read that one name.

Reviewer notes checked: the claim that Comments 1's example misquotes its source is wrong (`scripts/guidelines-file.sh:47` reads ``# NOT `cd "$(gr_root)" || exit 2` alone: ...``); the note that `|| true` after `grep -c` in `scripts/check-review.sh:153` carries no comment is right but outside this diff.

#### Round 2 — `docs/TEST_GUIDELINES.md`

reviewer: one `review-conformance` subagent, read-only, range `main...code-guidelines`, run in parallel with the CODE review
verdict: 0 findings (0 high, 0 medium, 0 low); none above low.

note (reviewer): Seams 1 still names no seam for a content lint over a SKILL.md or template; most of this change's tests are that kind (a gap in the file, raised in round 1 too).

#### Round 2 — `docs/CODE_GUIDELINES.md`

reviewer: one `review-conformance` subagent, read-only, range `main...code-guidelines`, run in parallel with the TEST review
verdict: 6 findings (high 0, medium 3, low 3); findings above low: yes (finding-1, finding-2, finding-4).

**finding-1**: guideline, medium — Simplicity 4, "Where two parts of one change add the same helper, constant or check, one copy stays, where both can reach it" — tests/skills.bats:1126, 1213, 2451, 2479, 2491; tests/review-conformance.bats:69
This change adds `section_of` to tests/helpers.bash (commit 51f5397, "one section_of ... for the four files that used a copy"). skills.bats already loads helpers. Even so, task T5 (3b7f7a7) adds five new inline `awk '/^### The conformance reviews$/ { inside = 1; next } /^##/ { inside = 0 } inside'` / `/^## Preconditions/` section extractors to skills.bats. review-conformance.bats:69 adds another one and does not `load helpers`. Each one is the same check as `section_of`, and both files can reach `section_of`.
disposition: fixed in `379aa2f` (merged from `code-guidelines-cr2-code`), every instance in the range swept, not only the cited lines

**finding-2**: guideline, medium — Simplicity 4, "one copy stays" — tests/code-guidelines.bats:88-105 and 125-143
Two tests repeat the same check line for line, comment block included. One is "the template stands alone" (T2) and the other is "this repository's file stands alone" (T8). Each loops over the forbidden tokens and every skill name, then runs `grep -c ... || true` against one file. Only the file differs. The test at lines 161-168 shows the one-copy form the file already uses: a loop over `"$template" "$repo_guidelines"`.
disposition: fixed in `379aa2f` (merged from `code-guidelines-cr2-code`), every instance in the range swept, not only the cited lines

**finding-3**: guideline, low — Simplicity 4, "one copy stays" — tests/code-guidelines.bats:187-199, 201-211, 213-223
Three sweep tests each add the same check: `run grep -r...`, then filter out `skills/ratchet/references/upgrade-notes.md` with `grep -v ... || true`, then assert the result is empty. They also repeat the same three-line comment. Only the token and the directories differ. The code is correct, so this is low.
disposition: fixed in `379aa2f` (merged from `code-guidelines-cr2-code`), every instance in the range swept, not only the cited lines

**finding-4**: guideline, medium — Names 4, "where the codebase already names it, that name"; Example: "the checkout's top directory is `repo_root` in every script, not `root_dir` in one of them" — docs/CODE_GUIDELINES.md:36-38
The example is false for this project, so the clause does not stand as written. The scripts name the checkout's top directory `gr_repo_root` in 12 places, for example scripts/check-ids.sh:61, scripts/check-signing.sh:52 and scripts/check-review.sh:72. Only scripts/guidelines-file.sh:49-51 uses `repo_root`. A reader who follows the example would rename against the clause's own rule to use the codebase's existing name.
disposition: fixed in `379aa2f` (merged from `code-guidelines-cr2-code`), every instance in the range swept, not only the cited lines

**finding-5**: guideline, low — Names 3, "A name says what the thing is in the project's domain, not its type or a role in general"; Names 4, "One name per concept across the change" — tests/skills.bats:1175
`check=$(tr '\n' ' ' < "$skill" | tr -s ' ')` holds the flattened text of verify-before-merge's SKILL.md, not a check. Elsewhere in the change the same concept is `flat` (tests/develop-refactor.bats, tests/develop-tdd.bats, tests/code-guidelines.bats:71). Also, skills.bats:2270 already uses `check` for a different value, a path.
disposition: fixed in `379aa2f` (merged from `code-guidelines-cr2-code`), every instance in the range swept, not only the cited lines

**finding-6**: guideline, low — Comments 2, "A comment describes the code as it is, never the change that wrote it: no ... ticket history" — tests/develop-refactor.bats:2-3; tests/develop-tdd.bats:2-3; tests/code-guidelines.bats:3
These file headers name the plan tasks that wrote the files: "T4", "T3 and T10", and "T2, T8 and T12". The citation of the decision (`docs/plans/2026-10-13-code-guidelines.md`) is a design reference. The task numbers only record which change wrote the file. An existing file follows the same convention (tests/tailor-guidelines.bats:2, "T5"), so this is low.
disposition: fixed in `379aa2f` (merged from `code-guidelines-cr2-code`), every instance in the range swept, not only the cited lines

Checked: `grep -lw gr_repo_root scripts/*.sh` lists 12 scripts and `grep -lw repo_root` one, so finding-4 holds; the T8 report's "repo_root in ten scripts" matched the longer name.

#### Round 3 — `docs/TEST_GUIDELINES.md`

reviewer: one `review-conformance` subagent, read-only, range `main...code-guidelines`, run in parallel with the CODE review
verdict: 0 findings (0 high, 0 medium, 0 low); none above low.

note (reviewer, floor): `tests/skills.bats` "clanker: the conformance reviews are not deferred to the merge review" gained `verifies: … D4` with no red -> green line, and its one assertion (`**reruns from step 1**`) would still pass if the reviews moved to 6a.
note (reviewer, floor): two absence-only tests pass vacuously if the file they read is missing ("ratchet: the retrofit inventory no longer looks for a ## Code: names section"; "code guidelines: no silent fallback does not require reporting a named default").

#### Round 3 — `docs/CODE_GUIDELINES.md`

reviewer: one `review-conformance` subagent, read-only, range `main...code-guidelines`, run in parallel with the TEST review
verdict: 3 findings (0 high, 0 medium, 3 low); none above low.

Both reviews have nothing above low, so round 3 is the last: the low findings are fixed where the fix is mechanical, and no further review is dispatched.

**finding-1**: guideline, low — Simplicity 4, "No duplication between tasks." — "Where two parts of one change add the same helper, constant or check, one copy stays" — tests/skills.bats:1088, 1090-1092, 1108-1111, 1131, 1179; tests/review-conformance.bats:66; tests/develop-tdd.bats:110; tests/code-guidelines.bats:176-180
The change adds sweeps in tests/code-guidelines.bats. Several per-file checks it adds elsewhere repeat what those sweeps already check:
- The `des''lop` sweep (code-guidelines.bats:189) greps `skills/` case-insensitively. That already covers skills.bats:1131 (develop-change), skills.bats:1179 (verify-before-merge SKILL.md and references/rationale.md) and review-conformance.bats:66 (the description).
- The `## Code: names` sweep (code-guidelines.bats:198) covers `templates/AGENTS-block.md` and `AGENTS.md`. That repeats skills.bats:1088 and 1108.
- The `review-''guidelines` sweep (code-guidelines.bats:206) covers `README.md`. That repeats develop-tdd.bats:110.
- skills.bats:1090-1092 and 1109-1111 grep the Names clauses 1-3 in the template and in the repository file. The clause-list tests at code-guidelines.bats:49-51 and the "keeps every clause of the template" test already pin those clauses exactly.
- code-guidelines.bats:176-180 asserts that CODE is in the known-kinds list. guidelines-file.bats:75 already pins `(known: TEST CODE)`.

The code is correct, so this is low. It is still two copies of each check, which the clause says will drift.
disposition: fixed in `0064b11` (merged from `code-guidelines-cr3-code`)

**finding-2**: guideline, low — Names 4, "One name per concept across the change." — "A concept has one name in every file, test and task of the change, and where the codebase already names it, that name" — skills/develop-refactor/SKILL.md:46-48 (pinned at tests/develop-refactor.bats:345-347)
The two dispatch reports this change adds name the same fields differently:
- develop-refactor's report says `files changed: <paths>`. develop-tdd's says `files touched: <paths>` (skills/develop-tdd/SKILL.md:96). The codebase already uses "touched": plans carry `**Files touched:**` (templates/config.yaml:114).
- develop-refactor reports an unfixed finding on its own `not fixed:` line. develop-tdd folds it into `fixed: <finding-N — what changed, or "not fixed — <reason>">`.

In both cases two shapes read as two concepts to the dispatcher that collects both reports.
disposition: fixed in `0064b11` (merged from `code-guidelines-cr3-code`)

**finding-3**: guideline, low — Errors 2, "No swallowed error." — "no discarded return code or error value" — tests/code-guidelines.bats:147
`if cmp -s "$template" "$repo_guidelines"; then ...` treats cmp's exit 2 the same as "the files differ". That happens when `$template` is missing or unreadable. This test checks `$repo_guidelines` exists but not `$template`, so it would pass that check silently. Only a missing template reaches this, and other tests would fail first, so the state is contrived.
disposition: fixed in `0064b11` (merged from `code-guidelines-cr3-code`)

Also fixed in the last round, from the round-3 TEST reviewer's floor notes: the renamed "clanker: the conformance reviews are not deferred to the merge review" test asserts what its D4 annotation claims, and the two absence-only tests fail when the file they read is missing.

Floor notes fixed in `f66972f` (merged from `code-guidelines-floor`):

red -> green: clanker: the conformance reviews are not deferred to the merge review — with "These reviews run here, before" removed from develop-change, the new assertion failed while the old one still passed
red -> green: ratchet: the retrofit inventory no longer looks for a ## Code: names section — pointed at a missing file, failed at the new existence assertion
red -> green: code guidelines: no silent fallback does not require reporting a named default — pointed at a missing file, failed at the new existence assertion

### After the tasks

The change's own conformance reviews run under `develop-change` as T5 leaves
it: one `review-conformance` dispatch for `docs/TEST_GUIDELINES.md` and one
for `docs/CODE_GUIDELINES.md` (T8), at once, then their fixes.
