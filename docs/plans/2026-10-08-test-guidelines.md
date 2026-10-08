# Test guidelines: project preferences beside the compliance floor

**Goal:** Skills carry the compliance floor; each project tailors its
preferences in a guidelines file, starting with `TEST_GUIDELINES.md`, and a
narrow reviewer checks a change against each file.
**Implements:** none (this repository has no SRS); delivers D1 to D11 below.
**Resolves:** PR-ttg99p (T7).
**Opens:** PR-3kvpze.
**Records:** ADR-me39p4 (D2, D3, D6), which amends ADR-8ft3hb and ADR-4xh6cf
from floor to shipped default.
**Safety class:** not configured (this repository has no `.guardrails/config.yaml`).
**Verification:** `sh tests/run-tests.sh`

Context: change 2 of three on testing, after `test-seams`
(`docs/plans/2026-10-07-test-seams.md`), whose Gaps section records the
2026-10-08 ruling this change builds. The pattern is proved here on tests
first; `CODE_GUIDELINES.md` (with a `develop-tdd` / `develop-refactor` split)
and `ARCHITECTURE_GUIDELINES.md` (with per-unit constraints in `units.yaml`)
are later changes.

## Decisions

**D1 — Guideline reviews run in the develop phase.** After the refactor
(deslop) pass and before `merge-change`, one `review-guidelines` dispatch per
guidelines file reviews the change diff against that one file in a fresh
context. The dispatcher fixes the findings on the change branch, under 6a's
convergence rule: the first round with nothing above low is the last.
`merge-change` 6a remains the single compliance review and checks only that
each guidelines review ran and that its findings are fixed or dispositioned.
Why: a finding at 6a reruns the merge sequence from step 1, a full gate per
round per reviewer; in the develop phase a fix is a commit before the gate.
Cost: a guideline finding blocks a merge only through 6a's check that the
review ran and was dispositioned. Ruled 2026-10-08.

**D2 — The floor is what a standard or a gate needs; the rest is preference.**
Test-seams D1 to D10 move to `TEST_GUIDELINES.md` as defaults a project may
change, D4 (no mocks of owned code) included. The skills keep the floor:
`verifies:` annotations, red → green, the class B/C robustness rule, the
class C SDD-interface rule, and one rule stated here for the first time:
every test fails when the behavior it `verifies:` breaks, so an assertion
only that a double was called meets it only where the call is the
requirement. A guideline that contradicts the floor is a finding against the
guideline; the floor wins. Why: IEC 62304 asks for verification evidence, not
a kind of double; what harms it is a test that passes whatever the code does,
which the floor rule forbids under any guideline. Ruled 2026-10-08.

**D3 — One file applies to any code; a unit's file replaces the root's.**
The file is at the fixed path `docs/TEST_GUIDELINES.md`, as `docs/CONTEXT.md`
is; no config key names it. Where `.guardrails/units.yaml` exists, a unit may
have `<unit>/docs/TEST_GUIDELINES.md`, which replaces the root file entirely
for that unit's code: the two are never merged. A unit without its own file
uses the root file; with neither, the installed default applies. A change
spanning units hands each task its unit's file, and `review-guidelines` runs
once per applicable file over the part of the diff under that file's scope.
Why: one file per reader is read the same way by every agent; layered files
need override and removal rules that agents apply inconsistently. Cost: a
unit file repeats what it keeps from the root; `/ratchet` seeds it as a copy,
so a diff against the root shows what the unit changed. Ruled 2026-10-08.

**D4 — `review-guidelines` is its own skill, generic over guidelines files.**
`skills/review-guidelines/SKILL.md`. The dispatcher names one guidelines file
and the diff range; the reviewer, in a fresh context, loads only this skill
and receives the floor rules the file may not override (D2). It checks the
diff against each clause of the file, citing the clause; reports a clause
that contradicts the floor as a finding of its own; and reports nothing the
file does not state, except as a note. Each finding is
`**finding-N**: guideline, <low|medium|high> — <clause quoted> — <file:line>`,
and the report ends with a one-line verdict. A clause that seems wrong for
the case is a finding, never a silent waiver. Why: one job per agent; the
same skill serves `CODE_GUIDELINES.md` and `ARCHITECTURE_GUIDELINES.md`
later, unedited; `develop-change` (1998 of 2000 words) gains only a dispatch
section. Cost: one more skill for `/ratchet` to install. Ruled 2026-10-08.

**D5 — The guidelines file carries its rules whole; no reference files.**
`templates/TEST_GUIDELINES.md` holds numbered clauses under headings (Seams,
Doubles, Owned services, Property tests, Mutants, UI, Existing suites). Each clause states
the rule, where its boundary falls, a one- or two-sentence reason and
language-neutral examples. `skills/develop-change/references/test-seams.md`
and `references/ui-seams.md` are deleted and their content moved into the
template, so each rule has one home. The UI section is shipped web-specific
and included by `/ratchet` only for a project with a user interface; the
tailoring interview asks for examples in the project's own stack to replace
the generic ones. Why: much of the reference material is boundary-drawing
(the LLR criteria, fake versus fault injector, the faked-success condition),
which writer and reviewer both need; reasons let an agent decide an unstated
case and let a project see what a change to a rule gives up; the most useful
examples are stack-specific, and only the project can write them. Cost:
every TDD and review dispatch reads the whole file (about 1,200 to 1,500
words); a project that edits a clause owns its reason and examples, and a
reason that no longer fits its rule is a guideline finding (D4). Ruled
2026-10-08.

**D6 — A subagent reads exactly one guidelines file, and it stands alone.**
For each kind of guidelines file, a project's or unit's own file overrides
the shipped default entirely (D3), and a subagent is handed only that one
file; it reads the installed default only where the project has none. No
guidelines file refers to another: not a project file to the template, not
a unit file to the root, not the template to this repository's ADRs or
plans, which an adopter does not have. `/ratchet` seeds a project file as a
complete copy, and a reference from a guidelines file to another guidelines
file or to a guardrails-internal document is a guideline finding. This
applies to every guidelines file, not only `TEST_GUIDELINES.md`. Why: the
user ruled out project guidance that cross-references the default; a
reference the reader cannot open is a rule it cannot apply. Ruled
2026-10-08.

**D7 — `tailor-guidelines` is its own skill, generic over guidelines files.**
`skills/tailor-guidelines/SKILL.md` takes one guidelines file and, in a
repository with units, the unit it is for. It seeds a complete copy where the
project has none (D6); walks the clauses one question per message, keep,
change or drop, showing each clause's reason; asks for examples in the
project's own stack for the Seams and Doubles clauses; includes the UI
section only for a project with a user interface; checks that no changed
clause contradicts the floor (D2); and works in a worktree like any other
change. Its upgrade mode shows the diff between the old and new shipped
template, asks clause by clause which changes to adopt, and never
overwrites. `/ratchet` invokes it once per guidelines file at setup and its
upgrade mode on upgrade (on a retrofit, as a later tooth: the first tooth
only installs), in about 20 words found by tightening `ratchet`
(at 2000 of 2000). Why: one job per skill; a project re-tailors without a
full `/ratchet` run; the same skill serves the later guidelines files
unedited. Cost: a second new skill name. Ruled 2026-10-08.

**D8 — `scripts/guidelines-file.sh` picks the file.** `guidelines-file.sh
<kind> <path>...` takes a kind (`TEST`; later `CODE`, `ARCHITECTURE`) and the
paths a task touches, and prints one line per distinct governing file with the
paths it governs: the unit's `<unit>/docs/<KIND>_GUIDELINES.md` where it
exists (unit from `gr_unit_of_path`), else the root
`docs/<KIND>_GUIDELINES.md`, else the installed default
`<KIND>_GUIDELINES.md` in the `templates/` directory beside the script's own
directory (`.guardrails/templates/` in an adopter, `templates/` here). Exit 2
on an unknown kind or a missing installed default: the install is broken, and
the agent stops. POSIX sh, tested in `tests/guidelines-file.bats`. Its output
is what the dispatcher hands each task and what sets the `review-guidelines`
runs and their diff scopes (D3). Why: selection decided once, under test, the
same for every agent. Cost: one more script to install. Ruled 2026-10-08.

**D9 — 6a checks the floor; the record shows the guideline reviews.** The
review checklist's "## The test checklist" keeps only the floor (`verifies:`
annotations, each test fails when what it verifies breaks, the class B/C
robustness rule, the class C SDD-interface rule) and drops the seam and
double rules, which `review-guidelines` now checks. It gains one line: the
record lists a guidelines review for each file `guidelines-file.sh` prints
for the diff, and every finding has a disposition. `templates/verification.md`
gains a `## Guideline reviews` section: per review, the file, its diff scope,
the rounds, and each finding verbatim with its disposition, apart from
`## Review` so compliance and preference findings stay distinguishable. No
script enforces the section in this change; a `check-review.sh` gate for it
is a follow-up. Why: the 6a checklist holds the floor alone; one record shows
an auditor each preference review, against a file versioned in the same
tree. Cost: until the follow-up, a skipped guideline review is caught only by
the 6a reviewer reading the record. Ruled 2026-10-08.

**D10 — This repository gets its own `docs/TEST_GUIDELINES.md`, resolving
PR-ttg99p.** `develop-change` step 6 and `references/mutation-anchors.md`
are removed. This repository's `docs/TEST_GUIDELINES.md` is seeded as a
complete copy of the template (D6), gains a Mutants clause carrying the
anchor rule (grep the anchors for each changed script line, re-cut a hit,
prove it still applies and kills) with the content of `mutation-anchors.md`,
and replaces the generic examples with bats and POSIX sh ones
(`make_strict_awk` as a fake with a contract test; a `PATH` stub exiting 1 as
a fault injector). PR-ttg99p is resolved in this change. Why: mutation anchors
are this repository's preference, not floor; the file is the first real
project override. Cost: scope; past mutation evidence is untouched. Ruled
2026-10-08.

**D11 — An existing adopter's behavior does not change on upgrade.** A
project that upgrades without running `tailor-guidelines` has no
`docs/TEST_GUIDELINES.md` and falls back to the installed default, which
states the rules `develop-change` stated before this change. The `ratchet`
upgrade note says so and points to `tailor-guidelines`. Ruled 2026-10-08.

## Implementation

Every test this change writes carries
`# verifies: D<n> (docs/plans/2026-10-08-test-guidelines.md)`, naming the
decisions below it tests. Each new test is watched red before the text or
code it checks exists, and the red is stated in the task's Done note as a
`red -> green:` line. Text tests pin operative clauses only (test-seams D15):
the sentences listed in each task, matched with `grep -qF` or, for a line
that must survive whole, `grep -qxF`. Each task runs its own test file with
`sh tests/run-tests.sh tests/<file>.bats` and reports the counts; the full
suite is the merge gate, not a task step.

New tests go in one new file per artefact, so the tasks' file sets stay
disjoint: `tests/guidelines-file.bats` (T1), `tests/test-guidelines.bats`
(T2, T7), `tests/review-guidelines.bats` (T4),
`tests/tailor-guidelines.bats` (T5). Only T3, T6 and T7 edit
`tests/skills.bats`, serially.

Wave 1, in parallel: T1, T2, T3, T4, T5. Wave 2: T6 after T3. Wave 3: T7
after T2, T3 and T6.

### T1 — `guidelines-file.sh` picks the one file for each path

**Files touched:** `scripts/guidelines-file.sh`, `tests/guidelines-file.bats`
**Parallel:** yes
**Decisions:** D3, D8

Interface: `guidelines-file.sh KIND PATH...`, run from anywhere inside the
repository; it works from the repository root (`gr_root`). It sources
`lib.sh` from its own directory as the other scripts do, and it reads no
`config.yaml`.

- `KIND` is one of the kinds in a single list at the top of the script,
  `TEST` alone in this change. Any other value: exit 2,
  `guidelines-file: unknown kind: <KIND> (known: TEST)`.
- No `PATH` argument: exit 2 with the usage line.
- A `PATH` that is absolute, or that contains whitespace: exit 2, naming it.
  Paths are repository-relative, as `git diff --name-only` prints them.
- The installed default is `<KIND>_GUIDELINES.md` in the `templates`
  directory beside the script's own directory (`.guardrails/templates/` for
  `.guardrails/scripts/`, `templates/` for this repository's `scripts/`).
  Absent: exit 2, `guidelines-file: no installed default: <path> — reinstall
  guardrails`. It is checked on every run, before any path is resolved, so a
  broken install is caught even where a project file exists.
- For each path: where `gr_units_present`, take its unit from
  `gr_unit_of_path`; a `not_a_unit` answer or no answer means no unit. A unit
  whose `docs/` holds a file named exactly `<KIND>_GUIDELINES.md` governs the
  path with that file. Otherwise `docs/<KIND>_GUIDELINES.md` at the root, by
  the same exact-name test. Otherwise the installed default.
- The exact-name test lists the directory and matches the name whole
  (`ls DIR | grep -qxF NAME`), as `gr_units_present` does, so a
  `test_guidelines.md` on a case-insensitive filesystem is not taken for
  `TEST_GUIDELINES.md`.
- Output, exit 0: one line per distinct governing file, in the order each
  file is first needed, `<file>: <path> <path>...`, the file
  repository-relative, the paths in argument order.

Tests (`tests/guidelines-file.bats`, `load helpers`, `make_fixture_repo`, then
`mkdir -p .guardrails/templates` and a one-line
`.guardrails/templates/TEST_GUIDELINES.md` in the fixture):

1. No project file: `src/a.sh` prints
   `.guardrails/templates/TEST_GUIDELINES.md: src/a.sh`.
2. A root `docs/TEST_GUIDELINES.md`: prints `docs/TEST_GUIDELINES.md: src/a.sh`.
3. A units manifest with units `apps/pump` and `apps/ui`, and
   `apps/pump/docs/TEST_GUIDELINES.md` only, a root file present, and
   `vendor` under `not_a_unit`: paths `apps/pump/x.c apps/ui/y.ts
   apps/pump/z.c vendor/v.c` print exactly two lines,
   `apps/pump/docs/TEST_GUIDELINES.md: apps/pump/x.c apps/pump/z.c`, then
   `docs/TEST_GUIDELINES.md: apps/ui/y.ts vendor/v.c`.
   The manifest is written as `tests/check-units.bats` writes one.
4. The same manifest with no root file: `apps/ui/y.ts` falls to the
   installed default.
5. `docs/test_guidelines.md` (lower case) only: the installed default is
   printed, on any filesystem.
6. `CODE` as the kind: exit 2, output contains `unknown kind: CODE`.
7. No path: exit 2, output contains `usage`.
8. `/etc/passwd` and `'src/a b.sh'`: exit 2 each, the output naming the path.
9. The installed default removed, a root file present: exit 2, output
   contains `no installed default`.

`tests/portability.bats` runs every `scripts/*.sh` under the strict-awk and
`case`-pattern checks without edits; the new script passes them.

**Done** (eece93b, merged). Deviations: the missing-default message names the
absolute path; an empty `PATH` argument is also exit 2. The strict-awk stub
test runs a fixed list of scripts, so its extension to this script is a fix
dispatch (`awk-stub`, ef925d0, merged): a separate test in
`tests/portability.bats`, since the sweep's fixture has no installed default
or manifest.

```
red -> green: guidelines-file: with no project file the installed default governs — exit 127, script absent
red -> green: guidelines-file: a root docs/TEST_GUIDELINES.md governs over the default — exit 127, script absent
red -> green: guidelines-file: a unit's file replaces the root's for that unit's paths only — exit 127, script absent
red -> green: guidelines-file: a unit with no file and no root file falls to the installed default — exit 127, script absent
red -> green: guidelines-file: a lower-case test_guidelines.md is not the project file, on any filesystem — exit 127, script absent
red -> green: guidelines-file: an unknown kind is exit 2 — exit 127, script absent
red -> green: guidelines-file: no path is exit 2 with the usage line — exit 127, script absent
red -> green: guidelines-file: an absolute path or a path with whitespace is exit 2, naming it — exit 127, script absent
red -> green: guidelines-file: a missing installed default is exit 2 even where a project file exists — exit 127, script absent
red -> green: guidelines-file.sh resolves a unit's file under an awk that rejects a newline in -v — with a newline value passed to awk -v: `awk: newline in string`
```

### T2 — `templates/TEST_GUIDELINES.md` carries the rules whole

**Files touched:** `templates/TEST_GUIDELINES.md`, `tests/test-guidelines.bats`
**Parallel:** yes
**Decisions:** D2, D5, D6

The template is written from the text that exists now:
`skills/develop-change/SKILL.md` "### Where a test attaches",
`skills/develop-change/references/test-seams.md` and
`skills/develop-change/references/ui-seams.md`, read from the change branch.
Each clause moves **verbatim** where the source wording is a rule, so the
test-seams pins carry over unchanged; prose that pointed at another file is
rewritten to stand alone.

Shape:

- `# Test guidelines` then a preface of at most five lines: this file states
  the project's test preferences; an agent reads this file and no other
  guidelines file; the skills' compliance floor wins any conflict, and a
  clause that contradicts it is a finding against the clause; a project that
  changes a clause rewrites its reason and examples with it.
- `## Seams`, `## Doubles`, `## Owned services`, `## Property tests`,
  `## Mutants`, `## UI`, `## Existing suites`, in that order. Clauses are
  numbered from 1 within each heading, written `1. **<rule>.** <boundary,
  reason, examples>`; a reader cites a clause as `Doubles 2`.
- `## UI` opens with the line `Keep this section only where the project has
  a user interface.`, then carries `ui-seams.md`'s content as clauses.
- `## Mutants` carries the survivor rule (a missing test at the seam, or dead
  code; never a test below the seam unless an LLR criterion holds) and the
  sentence that whether a project runs mutation testing, with which command
  and to what score, is decided in this section.
- Reasons stand alone: no `ADR-`, no `docs/plans/`, no `references/`, no
  `SKILL.md`, no skill name. The reasons ADR-8ft3hb and ADR-4xh6cf give are
  stated in the clauses they back.

Tests (`tests/test-guidelines.bats`):

1. Pins for the template, carried over from the six test-seams seam tests in
   `tests/skills.bats` (lines 2217 to 2346 at `b4484b8`): every pin that
   reads `references/test-seams.md` or `references/ui-seams.md` is repointed
   to `templates/TEST_GUIDELINES.md`, with its clause-number prefix adjusted
   where the line now opens a numbered clause (the adjusted pin is listed in
   the Done note). Pins that read `SKILL.md` move to the template only where
   the sentence moved; T3 deletes the rest. Group them as the source tests
   are grouped, one `@test` per test-seams decision group (D1-3, D4/8/9/14,
   D5/6, D7, D10), each annotated with both plans:
   `# verifies: D5 (docs/plans/2026-10-08-test-guidelines.md); D1, D2, D3
   (docs/plans/2026-10-07-test-seams.md)`.
2. The seven headings exist, in order.
3. The preface states the one-file rule and the floor rule
   (`grep -qF 'and no other guidelines file'`,
   `grep -qF 'is a finding against the clause'`).
4. D6: `grep -c` of `ADR-`, `docs/plans/`, `references/`, `SKILL.md` and of
   each skill directory name under `skills/` is 0 in the template.
5. The UI section's opening line is pinned whole.
6. The template is at most 1,600 words (`wc -w`).

**Done** (c56fe3c, merged; 1,599 words). Five source tests, not six: the
sixth reads the review checklist and is T6's. Every pin repointed with an
adjusted indent or clause prefix is listed in the T2 dispatch report, carried
into the record. To fit the 1,600-word ceiling, which was the planner's
estimate, T2 dropped the rejected no-doubles rule, the owned-services cost,
the progressive web app sentence, and shortened the deep-IO paragraph; D5
needs those reasons and boundaries, so a fix dispatch (`t2-restore`) restores
them and raises the ceiling to 1,800 words.

```
red -> green: a test attaches only to an interface a REQ or LLR describes — template absent
red -> green: doubles fake only at the codebase boundary, each with a contract test — template absent
red -> green: property tests repeat and pin, and a survivor never goes below the seam — template absent
red -> green: a UI's interface is what the user perceives, and a markup snapshot verifies nothing — template absent
red -> green: the rules bind new and edited tests, not the existing suite — template absent
red -> green: the template has the seven headings, in order — template absent
red -> green: the preface states the one-file rule and the floor rule — template absent
red -> green: the template stands alone, naming no guardrails document or skill — template absent; then ADR-, develop-change and references/ appended one at a time, each named in the failure
red -> green: the UI section opens by saying when to keep it — template absent
red -> green: the template is at most 1,600 words — template absent, then 1,750 words
```

`t2-restore` (40b4887, merged; 1,745 words): the four passages restored, the
ceiling test renamed to 1,800.

```
red -> green: Doubles states why a rule of no doubles at all was rejected — the reason absent
red -> green: Owned services states their cost and leaves the provision to the project — the cost absent
red -> green: the real-browser clause names a progressive web app's error routes — the sentence absent
red -> green: deep IO and property invariants keep their full wording — Seams 3 shortened
```

### T3 — `develop-change` keeps the floor and reads one guidelines file

**Files touched:** `skills/develop-change/SKILL.md`,
`skills/develop-change/references/test-seams.md`,
`skills/develop-change/references/ui-seams.md`, `tests/skills.bats`
**Parallel:** yes
**Decisions:** D1, D2, D6, D8

In `SKILL.md`:

- Replace "### Where a test attaches" whole with "### Test guidelines":
  - the floor rule, bold, as its first sentence: **Every test fails when the
    behavior it `verifies:` breaks.** followed by: an assertion only that a
    double was called meets it only where the call is the requirement;
  - before RED, run `sh .guardrails/scripts/guidelines-file.sh TEST <the
    paths the task touches>` and follow, for each path, the one file it
    prints; read no other guidelines file;
  - a clause that contradicts this skill is a finding against the clause:
    this skill wins, and the dispatch report names the clause.
- Add to the delegation prompt template one line: the guidelines file
  `guidelines-file.sh TEST` printed for the task's **Files touched:**.
- Add "### The guideline reviews" after "### The deslop pass": after the
  deslop pass, run `guidelines-file.sh TEST` over
  `git diff --name-only <base>...<change-branch>`; dispatch one subagent per
  file it prints, under the `review-guidelines` skill, with that file, the
  paths it governs and the diff range; fix each finding on the change branch
  in a nested task worktree as any fix; stop at the first round with nothing
  above low; keep every finding and its disposition for the record's
  `## Guideline reviews`, which `merge-change` 6b fills in (T6 adds the
  section to the template). These reviews run before `merge-change`, not at
  its 6a.
- Red flags, one row: "The project file leaves this out; I'll read the
  default too" | "One file per path. A rule the project dropped is dropped."
- Done when, one line: each guidelines review ran, and its findings are fixed
  or dispositioned.
- References: remove the `test-seams.md` and `ui-seams.md` entries; delete
  both files (`git rm`). T2 has their content.
- Stay at or under 2,000 words (`tests/skills.bats` "skill shape").

In `tests/skills.bats`: delete the five `develop-change:` seam tests
(D1-D10 of test-seams, at lines 2217 to 2329 at `b4484b8`); T2 carries their
template pins. Add, annotated `# verifies: D<n>
(docs/plans/2026-10-08-test-guidelines.md)`:

1. D2: the floor sentence pinned whole, and the double-call sentence.
2. D8, D6: the `guidelines-file.sh TEST` line and
   `read no other guidelines file`.
3. D1: `### The guideline reviews` exists after `### The deslop pass` and
   before the next `###`; it names `review-guidelines`, `## Guideline
   reviews`, and `before \`merge-change\``.
4. D2: `is a finding against the clause` in `SKILL.md`.
5. The References section no longer names `test-seams.md` or
   `ui-seams.md`, and neither file exists (the skill-shape test already fails
   on a mismatch; this test pins the deletion).

**Done** (e1a4bf7, merged; `SKILL.md` 1909 words). Deviations: the Red
flags row that pointed to `references/test-seams.md` now points to the
guidelines file's `## Seams`; the review command reads `main...<change-branch>`
as the deslop prompt does.

```
red -> green: develop-change: every test fails when the behavior it verifies breaks — the floor line absent
red -> green: develop-change: before RED, guidelines-file.sh picks the one guidelines file — the guidelines-file.sh TEST line absent
red -> green: develop-change: the guideline reviews follow the deslop pass, before merge-change — the section absent
red -> green: develop-change: a clause that contradicts the skill is a finding against the clause — the sentence absent
red -> green: develop-change: the seam reference files are gone — References still named both files
```

### T4 — `review-guidelines` reviews a diff against one file

**Files touched:** `skills/review-guidelines/SKILL.md`,
`tests/review-guidelines.bats`
**Parallel:** yes
**Decisions:** D2, D4, D5, D6

Frontmatter `name: review-guidelines`; description states it reviews a change
diff against one project guidelines file, in a fresh context, dispatched by
`develop-change` after the deslop pass. Sections Preconditions, Steps, Red
flags, Done when; no References.

- Preconditions: you were dispatched with exactly one guidelines file, the
  paths it governs and a diff range; you have no implementation narrative.
  Read the guidelines file and the diff, nothing else of the project's
  guidance.
- Steps:
  1. Check every changed line under the governed paths against every clause.
  2. A finding is `**finding-N**: guideline, <low | medium | high> —
     <clause cited as Heading N, quoted> — <file:line>`; severity as
     `merge-change`'s review checklist defines it.
  3. Report a clause that contradicts the floor as a finding against the
     clause. The floor, listed here in full: every test carries `verifies:`;
     every new test was watched red; every test fails when the behavior it
     `verifies:` breaks; class B and C: abnormal-input tests for every REQ
     and LLR; class C: tests at every touched SDD item's interface.
  4. Report a clause whose reason no longer fits its rule, and a clause that
     refers to another guidelines file or to a document the project does not
     contain, each as a finding against the clause (D5, D6).
  5. What the file does not state is a `note:`, never a finding.
  6. End with `verdict: <one line>`.
- Red flags: "This is bad but the file doesn't say so" | "A note, not a
  finding."; "The clause seems wrong here, I'll let it go" | "A finding
  against the clause. Never a silent waiver."; "I'll read the shipped
  default for context" | "You read one file."
- Done when: every clause checked against the governed diff; every finding
  cites a clause; a verdict line.

Tests (`tests/review-guidelines.bats`): the finding shape line pinned whole;
the five floor items each pinned; the note rule; the three red-flag rows by
their first cell; the frontmatter name; the skill shape tests in
`tests/skills.bats` cover sections and word count with no edit.

**Done** (e7415fc, merged; 651 words). Deviations: two red-flag rows beyond
the plan's three ("The floor is someone else's review"; "This finding is
obvious, the clause need not be cited"); step 2 restates the severities so
the reviewer opens no other file.

```
red -> green: review-guidelines: the frontmatter names the skill — SKILL.md absent
red -> green: review-guidelines: a finding cites a clause, a severity and a location — SKILL.md absent
red -> green: review-guidelines: the floor is listed in full — SKILL.md absent
red -> green: review-guidelines: a clause that contradicts the floor is a finding against the clause — SKILL.md absent
red -> green: review-guidelines: a stale reason or a reference out of the file is a finding against the clause — SKILL.md absent
red -> green: review-guidelines: what the file does not state is a note, never a finding — SKILL.md absent
red -> green: review-guidelines: the report ends with a verdict line — SKILL.md absent
red -> green: review-guidelines: the three red flags are present — SKILL.md absent
```

### T5 — `tailor-guidelines`, and `ratchet` installs and invokes it

**Files touched:** `skills/tailor-guidelines/SKILL.md`,
`skills/ratchet/SKILL.md`, `skills/ratchet/references/upgrade-notes.md`,
`tests/tailor-guidelines.bats`
**Parallel:** yes
**Decisions:** D3, D6, D7, D11

`tailor-guidelines`, sections Preconditions, Steps, Red flags, Done when:

- Preconditions: a change worktree; a kind (`TEST`) and, where
  `.guardrails/units.yaml` exists, the unit or the root.
- Steps:
  1. The target is `docs/<KIND>_GUIDELINES.md`, or
     `<unit>/docs/<KIND>_GUIDELINES.md`. Absent: seed it as a complete copy,
     of the root file for a unit that has one, otherwise of the installed
     default `.guardrails/templates/<KIND>_GUIDELINES.md`. Never write a
     reference to the source in the copy.
  2. Walk the clauses one per message: show the clause and its reason; keep,
     change or drop; a change rewrites the reason and examples with it.
  3. For `## Seams` and `## Doubles`, ask for an example in the project's own
     stack for each clause, and replace the generic one.
  4. Drop `## UI` where the project has no user interface; ask.
  5. Reject a change that contradicts the floor (the five items, listed as in
     `review-guidelines`); say why.
  6. Commit in the worktree; `merge-change` integrates it.
- Upgrade mode: before the new template is copied over the installed
  default, diff the installed default (old) against the shipped template
  (new); walk each changed clause: adopt into the project file, adapt, or
  decline. Never overwrite the project file.
- Red flags: "I'll write 'see the default for the rest'" | "The file stands
  alone. Copy what is kept."; "The new default is better, I'll replace the
  file" | "Clause by clause. Never overwrite."

`ratchet/SKILL.md` (at 2,000 words; tighten existing sentences to fit, and
change no rule):

- Step 2.3 list gains `templates/TEST_GUIDELINES.md` →
  `.guardrails/templates/TEST_GUIDELINES.md`, and step 2 gains: run
  `tailor-guidelines` for `TEST` (once per unit that wants its own file).
- Upgrading, before step 2's copy: run `tailor-guidelines` in upgrade mode
  for each guidelines file; then re-copy the template with the scripts.

`upgrade-notes.md` gains `## Test guidelines are a project file`: an
upgraded project with no `docs/TEST_GUIDELINES.md` follows the installed
default, which states the rules `develop-change` stated before; run
`tailor-guidelines` to make the file the project's own; the default reaches
`.guardrails/templates/` with the scripts.

Tests (`tests/tailor-guidelines.bats`): the seed rule and its no-reference
sentence; the upgrade mode's "Never overwrite"; the floor rejection; the
`ratchet` copy line and the `tailor-guidelines` invocation in both scaffold
and upgrade; the upgrade-notes heading and its fallback sentence.

**Done** (f6ccc35, merged; `tailor-guidelines` 742 words, `ratchet` 1998).
Deviations: retrofit step 3.3 installs "config, scripts and templates", since
a retrofitted project otherwise has no installed default and
`guidelines-file.sh` exits 2; upgrade mode stops where the project has no
file of the kind (a first upgrade has no old default to diff); three red-flag
rows beyond the plan's two.

```
red -> green: tailor-guidelines: the skill is named, and seeds a complete copy that names no source — SKILL.md absent
red -> green: tailor-guidelines: a unit's file is its own, at the unit's path — SKILL.md absent
red -> green: tailor-guidelines: the interview walks one clause per message, with its reason — SKILL.md absent
red -> green: tailor-guidelines: a change that contradicts the floor is rejected, and the floor is listed — SKILL.md absent
red -> green: tailor-guidelines: upgrade mode walks the template diff and never overwrites — SKILL.md absent
red -> green: ratchet: the scaffold installs the test guidelines default and tailors it — copy line absent
red -> green: ratchet: an upgrade runs tailor-guidelines' upgrade mode before the template is re-copied — invocation absent
red -> green: upgrade notes: an upgraded project without its own file follows the installed default — section absent
```

### T6 — 6a checks the floor; the record has a guideline-reviews section

**Files touched:** `skills/merge-change/references/review-checklist.md`,
`templates/verification.md`, `tests/skills.bats`
**Parallel:** no (serial, after T3)
**Decisions:** D1, D2, D9

- `review-checklist.md` "## The test checklist": the opening sentence no
  longer cites "Where a test attaches"; the items become the floor: every new
  test carries `verifies:`; it fails when the behavior it verifies breaks,
  and an assertion only that a double was called meets this only where the
  call is the requirement; class B and C have abnormal-input tests; class C
  tests each touched SDD item at its interface; and the record's `##
  Guideline reviews` lists a review for each file `guidelines-file.sh TEST`
  prints for the diff, every finding with a disposition. The seam, double,
  owned-service and snapshot items are removed: `review-guidelines` checks
  them against the project's file.
- `templates/verification.md` gains `## Guideline reviews` between
  `## Review` and `## Gaps`: per review, a `### <guidelines file>` heading,
  the governed paths, `### Round <N>` blocks of `**finding-N**: guideline,
  <severity> — …` with `disposition:` lines, the same no-count rule as
  `## Review`; and the sentence that it is kept apart from `## Review` so
  compliance and preference findings stay distinguishable.
- `tests/skills.bats`: rewrite `merge-change: the review checklist asks where
  each new test attaches and which doubles it uses` as `merge-change: the
  review checklist's test section is the floor, and checks the guideline
  reviews ran` (D2, D9), pinning the new items and asserting that
  `three kinds` and `markup snapshot` no longer appear in the checklist; add
  `verification template: guideline reviews have their own section` (D9).
  Run the existing verification-template tests unchanged; they must stay
  green.

**Done** (1d62716, merged). Deviations: the template's example uses
`### Round <N>` and `**finding-<N>**:`, since the record-counts test needs
exactly one `Round 1` and one `finding-1` in the template; the field-grammar
comment adds `guideline` as a tag that takes a severity (`check-review.sh`
reads no tag, so it accepts one). T6 found that a bare `! grep` on a non-final
line asserts nothing under errexit; recorded as PR-3kvpze, not fixed here.

```
red -> green: merge-change: the review checklist's test section is the floor, and checks the guideline reviews ran — the checklist still cited "Where a test attaches" and had no floor items
red -> green: verification template: guideline reviews have their own section — the section absent
```

### T7 — this repository's `docs/TEST_GUIDELINES.md`; PR-ttg99p resolved

**Files touched:** `docs/TEST_GUIDELINES.md`,
`skills/develop-change/SKILL.md`,
`skills/develop-change/references/mutation-anchors.md`,
`docs/problems/2026-10-08-test-seams-gaps.md`, `tests/skills.bats`,
`tests/test-guidelines.bats`
**Parallel:** no (serial, after T2, T3 and T6)
**Decisions:** D6, D10

- `docs/TEST_GUIDELINES.md`: a complete copy of `templates/TEST_GUIDELINES.md`
  as T2 left it, then:
  - `## Mutants` gains a clause carrying the anchor rule from
    `develop-change` step 6 and the whole of `references/mutation-anchors.md`:
    grep `docs/verification/*.mutations/` for each changed script line; on a
    hit, keep the edit, re-cut the anchor and prove it applies and still
    kills tests.
  - The Seams and Doubles examples become this repository's: a bats test
    calling a script's command line as the seam; `make_strict_awk` and
    `make_bsd_date` as fakes with contract tests against the real tools in
    `tests/portability.bats`; a `PATH` stub that exits 1 with no output as a
    fault injector.
  - `## UI` is dropped: this repository has no user interface.
- `develop-change/SKILL.md`: remove step 6 and renumber step 7 to 6; remove
  the `mutation-anchors.md` References entry; `git rm` the file.
- `tests/skills.bats`: `develop-change: the loop greps the mutation anchors
  for a changed line` (PR-dr7k7k) is repointed to `docs/TEST_GUIDELINES.md`,
  same two greps, and gains `! grep -q 'mutations' skills/develop-change/SKILL.md`
  with the annotation `# verifies: PR-dr7k7k, PR-ttg99p`.
- `tests/test-guidelines.bats`: this repository's file has no `## UI`, holds
  the seven other headings, and passes the same D6 zero-count test as the
  template.
- `docs/problems/2026-10-08-test-seams-gaps.md`: PR-ttg99p
  `status: resolved`, and one line: the anchor rule moved from
  `develop-change` step 6 to this repository's `docs/TEST_GUIDELINES.md`
  (`develop-change: the loop greps the mutation anchors for a changed line`).

**Done** (737e204, merged; `docs/TEST_GUIDELINES.md` 1,889 words). The
repository's examples name its seam (a bats test running `sh scripts/<name>.sh`),
its boundary tools, `make_strict_awk` and `make_bsd_date` with their contract
tests, and the `parallel` stub without one (PR-dfndh4); `tests/lib.bats` is
spared under Existing suites. The negative assertion uses `if grep …; then
false; fi` (PR-3kvpze). Stale citations outside the task's files
(`develop-change/references/rationale.md` on step 6; `worktree-discipline`
naming develop-change's commit step as step 7) go to the deslop pass.

```
red -> green: develop-change: the mutation-anchor rule lives in this repository's TEST_GUIDELINES.md, not develop-change (named "the loop greps the mutation anchors for a changed line" until review round 1, finding-9) — docs/TEST_GUIDELINES.md absent
red -> green: test guidelines: this repository's file has the template's headings except UI — file absent
red -> green: test guidelines: this repository's file stands alone, naming no guardrails document or skill — file absent
```

### After the tasks

- Deslop pass (a375c4a): two stale citations of removed text, one wording of
  the floor across the skills, "installed default" and "guideline review"
  throughout.
- Guideline review against this repository's `docs/TEST_GUIDELINES.md`: one
  low finding (Seams 2 and 3 hung on an LLR this repository does not keep),
  fixed by `guideline-r1` (6a8a16f), which also defines the robustness rule
  in both files.

```
red -> green: here a plan decision or problem report states a deeper interface's contract, not an LLR — Seams 2 still hung on an LLR
red -> green: both files define the robustness rule where they first name it — the template did not define it
```

- Gate at 58075ce failed 4 of 1228: the repository's script inventories
  (`tests/check-ids.bats` twice, `tests/check-trace.bats`, `tests/lib.bats`)
  did not know `guidelines-file.sh`, which was mode 100644 and validated its
  arguments before `gr_root`. Fixed by `gate-inventory` (59e6f2c).

```
red -> green: every gr_def_re call site is still a call site, and no copy joins them — unpinned script: scripts/guidelines-file.sh
red -> green: every script parses as POSIX sh — expected 13 scripts, scanned 14
red -> green: every script is executable in the index, not just runnable via sh — guidelines-file.sh at 100644
red -> green: every script stops outside a git repository, at gr_root — usage error printed instead
```

- README names `guidelines-file.sh` and the two new skills.
- Review round 1 (63eb4a4), nine findings none above low, the last round:
  fixed by `r1-script` (97612e5; findings 1-3), `r1-skills` (2aeac30;
  findings 4, 5, 6, 9), `r1-docs` (8bb45f7; findings 7, 8) and the plan
  header (finding 7).

```
red -> green: files print in first-needed order and paths in argument order, unsorted — red under a `sort |` mutant
red -> green: an empty path is exit 2 with the usage line — red with the empty-path branch deleted
red -> green: an exported CDPATH does not change where it finds itself — `lib.sh: No such file or directory`
red -> green: develop-change: guideline review findings go into the plan as they arrive, and step 6b copies them — the plan-and-6b wording absent
red -> green: develop-change: a missing or broken guidelines-file.sh stops the task — the stop sentence absent
red -> green: develop-change: the dispatch prompt names the guidelines file for each of the task's paths — the per-path wording absent
red -> green: merge-change: the review checklist's test section is the floor, and checks the guideline reviews ran — the plan-lists pin absent
red -> green: ratchet: a retrofit tailors each guidelines file as a later tooth — absent from Later teeth
red -> green: ratchet: the T5 tightening kept the bats and multi-unit sentences — "Never add bats to the target project." absent
red -> green: each template clause that lacked a reason states one — "Seams 3 states no reason"
red -> green: this repository's file carries the template's added reasons — "Seams 3 states no reason"
red -> green: the seam and owned-service ADRs say ADR-me39p4 made them shipped defaults — no amendment note
```

## Follow-ups outside this change

- A `check-review.sh` gate that requires `## Guideline reviews` where
  `guidelines-file.sh` prints a file for the diff (D9).
- `CODE_GUIDELINES.md` with the `develop-tdd` / `develop-refactor` split, and
  `ARCHITECTURE_GUIDELINES.md` with per-unit constraints in `units.yaml`.
