# Verification — code-guidelines (2026-10-14)

branch: code-guidelines
reviewer: one independent subagent, dispatched at `merge-change` step 6a with
the diff, the plan and the review checklist, and no implementation narrative;
it worked in its own review worktree and ran the full suite itself, twice
(see the Gaps).
verdict: approve. Its `code` findings were all low and it raised no
`requirement` finding, so round 1 was the last review round; the low findings
were fixed where the fix was mechanical, and the two that need a rule were
recorded as open problem items.
reproduced: not applicable as a defect reproduction: the change delivers the
plan's decisions D1 to D6 and fixes no recorded defect. Each test it adds or
rewrites was watched failing before its edit; the lines are below.

Change: `develop-change` splits into an orchestrator, `develop-tdd` and
`develop-refactor`; code preferences move into `CODE_GUIDELINES.md`; the
deslop pass is replaced by parallel conformance reviews, one per guidelines
file; `review-guidelines` is renamed `review-conformance`. Branched from
`main` at `baa983f`; base merged from local `main` at `25e723f`, per AGENTS.md
non-negotiable 4.
Plan: `docs/plans/2026-10-13-code-guidelines.md`.

## The gate

Measured on: `5deae5a` — tree `088ef49f1c2940f1018cb5837f467bf1612692e0`, on a clean worktree, after the
last-round fixes were merged and local `main` (`25e723f`, unmoved since the
step 1 merge) was confirmed merged. `merge-change` step 3 renamed nothing: the
change adds no draft ledger file. The committed tree differs from it only by
this record.

| Gate | Result |
| --- | --- |
| `tests/run-tests.sh` | 1..1432, 1432 passed, 0 failed, exit 0 (2026-10-14 02:08–02:37) |
| `check-ids.sh` | identical output at the base and at the change, on scratch copies built from `templates/config.yaml` (this repository has no `.guardrails/config.yaml`) |
| `check-trace.sh` | exit 1 at the base and at the change alike, on the same scratch copies. The differences: this change's own items `PR-tqwky6`, `PR-75pdcu` and `PR-r6ypg9` enter the roll-call as `UNRESOLVED-PR`, and the MISSING-TEST remedy names `develop-tdd`. No verdict added |
| Coverage, against the class target | not configured |
| Working tree | clean |

## Red → green

This repository has no SRS, so the change implements no item and the table
has no rows. Every test the change adds or rewrites carries
`verifies: D<n> (docs/plans/2026-10-13-code-guidelines.md)`, and its
`red -> green:` line is copied here from the plan. A `renamed:` line is a test
renamed for the new skill or kind, kept as coverage, not watched red anew.

| Item | Test | Watched red |
| --- | --- | --- |

- red -> green: guidelines-file: an unknown kind is exit 2, naming the known kinds — watched fail on "(known: TEST)" before the script edit
- red -> green: guidelines-file: CODE picks the unit's, the root's or the installed default file, as TEST does — watched fail on "unknown kind: CODE (known: TEST)" before the script edit
- red -> green: guidelines-file: one kind's project file never governs another kind — watched fail on "unknown kind: CODE (known: TEST)" before the script edit
- red -> green: guidelines-file: a missing CODE default is exit 2 though the TEST default is installed — watched fail on "unknown kind: CODE (known: TEST)" (status 2 matched, "no installed default" did not) before the script edit
- red -> green: code guidelines: the template's clauses, by heading and number — watched fail (no templates/CODE_GUIDELINES.md) before the template existed
- red -> green: code guidelines: the template has the four headings, in order — watched fail (grep non-zero on the missing template) before the template existed
- red -> green: code guidelines: every clause states a reason and an example — watched fail (awk exit 2 on the missing template) before the template existed
- red -> green: code guidelines: the boundaries D3 names are stated — watched fail ('without a second caller' not found) before the template existed
- red -> green: code guidelines: the preface states the one-file rule and the floor rule — watched fail (awk exit 2 on the missing template) before the template existed
- red -> green: code guidelines: the template stands alone, naming no guardrails document or skill — watched fail (grep could not read the missing template) before the template existed
- red -> green: code guidelines: the template is at most 1,400 words — watched fail (wc could not read the missing template) before the template existed
- red -> green: <test name> — watched fail for the right reason before the
- red -> green: develop-tdd: the skill is named, and only a dispatched task subagent loads it — watched fail ("no develop-tdd SKILL.md") before skills/develop-tdd/SKILL.md existed
- red -> green: develop-tdd: a TEST conformance finding is fixed under the loop, or reported not fixed — watched fail ("no develop-tdd SKILL.md") before skills/develop-tdd/SKILL.md existed
- red -> green: develop-tdd: no production code without a failing test first — watched fail ("no develop-tdd SKILL.md") before skills/develop-tdd/SKILL.md existed
- red -> green: develop-tdd: the loop runs RED, then GREEN, and its sixth step commits — watched fail ("no develop-tdd SKILL.md") before skills/develop-tdd/SKILL.md existed
- red -> green: develop-tdd: the class rules and the bug rule — watched fail ("no develop-tdd SKILL.md") before skills/develop-tdd/SKILL.md existed
- red -> green: develop-tdd: every test fails when the behavior it verifies breaks — watched fail ("no develop-tdd SKILL.md") before skills/develop-tdd/SKILL.md existed
- red -> green: develop-tdd: before RED, guidelines-file.sh picks the one test guidelines file — watched fail ("no develop-tdd SKILL.md") before skills/develop-tdd/SKILL.md existed
- red -> green: develop-tdd: the dispatch report's shape, and an inherited test is coverage — watched fail ("no develop-tdd SKILL.md") before skills/develop-tdd/SKILL.md existed
- red -> green: develop-tdd: carries no repository-only mutation-anchor rule — watched fail ("no develop-tdd SKILL.md") before skills/develop-tdd/SKILL.md existed
- red -> green: develop-tdd: the subagent's red flags — watched fail ("no develop-tdd SKILL.md") before skills/develop-tdd/SKILL.md existed
- red -> green: develop-refactor: the skill is named, and fixes one CODE review's findings — watched fail (SKILL.md absent) before skills/develop-refactor/SKILL.md existed
- red -> green: develop-refactor: it works in its nested task worktree and does not merge — watched fail (SKILL.md absent) before skills/develop-refactor/SKILL.md existed
- red -> green: develop-refactor: it reads the one code guidelines file and fixes what the findings state — watched fail (SKILL.md absent) before skills/develop-refactor/SKILL.md existed
- red -> green: develop-refactor: no behavior change, and no test loosened — watched fail (SKILL.md absent) before skills/develop-refactor/SKILL.md existed
- red -> green: develop-refactor: a finding it cannot fix is reported, with the reason — watched fail (SKILL.md absent) before skills/develop-refactor/SKILL.md existed
- red -> green: develop-refactor: the report's shape — watched fail (SKILL.md absent) before skills/develop-refactor/SKILL.md existed
- red -> green: develop-change: one conformance review per guidelines file replaces the old whole-diff pass — watched fail ("no conformance reviews section") before the skill edit
- red -> green: develop-change: a conformance reviewer changes nothing and gets no task worktree — watched fail on the missing "Read the change worktree at <path>; do not create a task worktree, edit, or commit." before the skill edit
- red -> green: develop-change: a CODE finding is fixed under develop-refactor, a TEST finding under develop-tdd — watched fail on the missing "Once every review has reported, dispatch the fixes" before the skill edit
- red -> green: develop-change: it is the dispatcher, which no subagent loads — watched fail ("the description does not name develop-tdd") before the skill edit
- red -> green: develop-change: task subagents load develop-tdd, and the loop is stated there, not here — watched fail ("the prompt does not name develop-tdd") before the skill edit
- red -> green: develop-change: the conformance reviews follow derailment, before merge-change — watched fail on the last-### heading check before the skill edit
- red -> green: develop-change: guideline review findings go into the plan as they arrive, and step 6b copies them — watched fail on the missing "Write each finding…" line before the skill edit
- renamed: develop-change: the task prompt names the guidelines file guidelines-file.sh TEST printed — its one assertion carried from "before RED, guidelines-file.sh picks the one guidelines file"
- renamed: clanker: the conformance reviews are not deferred to the merge review — renamed from the deslop-pass test; the floor-note fix later gave it a second assertion, with its own red -> green line
- red -> green: ratchet: the scaffold installs every guidelines default and tailors TEST and CODE — watched fail before the edit (the `templates/*_GUIDELINES.md` → `.guardrails/templates/` line was absent)
- red -> green: tailor-guidelines: the kinds are TEST and CODE, and CODE's examples are the project's — watched fail before the edit (Preconditions named only `TEST`)
- red -> green: upgrade notes: code guidelines, the dropped pass and the renamed reviewer — watched fail before the edit ("no Code guidelines section")
- renamed: ratchet: the scaffold installs every guidelines default and tailors TEST and CODE — from "ratchet: the scaffold installs the test guidelines default and tailors it"
- red -> green: review-conformance: the frontmatter names the skill — watched fail (still red after the git mv; green once `name: review-conformance` was written)
- red -> green: review-conformance: a finding cites a clause, a severity and a location — watched fail (skills/review-conformance/SKILL.md missing) before the rename
- red -> green: review-conformance: the floor is listed in full — watched fail (skills/review-conformance/SKILL.md missing) before the rename
- red -> green: review-conformance: a clause that contradicts the floor is a finding against the clause — watched fail (skills/review-conformance/SKILL.md missing) before the rename
- red -> green: review-conformance: a stale reason or a reference out of the file is a finding against the clause — watched fail (skills/review-conformance/SKILL.md missing) before the rename
- red -> green: review-conformance: what the file does not state is a note, never a finding — watched fail (skills/review-conformance/SKILL.md missing) before the rename
- red -> green: review-conformance: the report ends with a verdict line — watched fail (skills/review-conformance/SKILL.md missing) before the rename
- red -> green: review-conformance: the three red flags are present — watched fail (skills/review-conformance/SKILL.md missing) before the rename
- red -> green: review-conformance: the old name is gone, and the description names both kinds — watched fail (old skill dir present; after the git mv, red on the description text)
- red -> green: review-conformance: the reviewer changes nothing — watched fail (after the git mv, red on the missing "Change nothing" precondition)
- renamed: the eight renamed review-conformance tests — from the same names in tests/review-guidelines.bats
- red -> green: code guidelines: this repository's file keeps every clause of the template — watched fail ("no docs/CODE_GUIDELINES.md") before the file existed
- red -> green: code guidelines: this repository's file stands alone, naming no guardrails document or skill — watched fail ("no docs/CODE_GUIDELINES.md") before the file existed
- red -> green: code guidelines: this repository's examples are its own POSIX sh — watched fail ("no docs/CODE_GUIDELINES.md") before the file existed
- red -> green: code guidelines: this repository's file is at most 1,600 words — watched fail ("integer expression expected") before the file existed
- red -> green: code guidelines: the naming rules left the managed block for the code guidelines template — watched fail before the block edit
- red -> green: code guidelines: this repository's naming rules live in its own code guidelines file — watched fail before the AGENTS.md edit (that body was later cut by the round-3 CODE fix, 0064b11, and restored with positive assertions in the last-round fix below)
- red -> green: ratchet: the retrofit inventory no longer looks for a ## Code: names section — watched fail before the ratchet edit
- red -> green: verify-before-merge: check 8 asks that each conformance review ran and was dispositioned — watched fail on the "8. **Each conformance review ran** ..." grep before the SKILL.md edit
- red -> green: verify-before-merge: check 6 cites the robustness rule where develop-tdd states it — watched fail on "per `develop-tdd`'s robustness rule" before the SKILL.md edit
- red -> green: merge-change: the review checklist's test section is the floor, and checks the guideline reviews ran — watched fail on "the plan lists a conformance review for each file ..." before the checklist edit
- red -> green: verification template: guideline reviews have their own section — watched fail on "guidelines-file.sh CODE" before the template edit
- renamed: verify-before-merge: check 8 asks that each conformance review ran and was dispositioned — from "clanker: the gate checks that the deslop pass was run"
- red -> green: develop-tdd: the skills that cite the TDD rules cite develop-tdd, and the README shows the split — watched fail at its first grep ("(unsigned, `develop-tdd` step 6)" absent from worktree-discipline) before the edits
- red -> green: code guidelines: every kind guidelines-file.sh knows has a shipped template — watched fail ("no template for ARCHITECTURE") with a third kind added to KNOWN_KINDS
- red -> green: code guidelines: the old whole-diff pass is gone from the skills, templates and tests — watched fail (named README.md:137) with the old name appended to README.md
- red -> green: code guidelines: no skill, template or AGENTS.md keeps a ## Code: names section — watched fail (named templates/AGENTS-block.md:113) with the heading appended
- red -> green: code guidelines: the old name of review-conformance is gone outside the upgrade notes — watched fail (named README.md:137) with the old name appended to README.md
- red -> green: code guidelines: no silent fallback does not require reporting a named default — watched fail ("templates/CODE_GUIDELINES.md requires a named default to be reported") before the edit
- red -> green: clanker: the conformance reviews are not deferred to the merge review — with "These reviews run here, before" removed from develop-change, the new assertion failed while the old one still passed
- red -> green: ratchet: the retrofit inventory no longer looks for a ## Code: names section — pointed at a missing file, failed at the new existence assertion
- red -> green: code guidelines: no silent fallback does not require reporting a named default — pointed at a missing file, failed at the new existence assertion

## What was wrong, and what was built

`develop-change` was one skill that both orchestrated a change and held the
red → green loop a task subagent runs, so every task subagent loaded the
orchestration text it never used. Code preferences lived in two lines of the
managed AGENTS.md block, with no reasons or examples and nothing that checked
a change against them except the deslop pass, which predated the guideline
reviews and duplicated their one unique job.

The change, as it stands at merge:

- `skills/develop-change/SKILL.md` is the orchestrator. `skills/develop-tdd/SKILL.md`
  holds the loop, the class rules and the dispatch report a task subagent
  loads; `skills/develop-refactor/SKILL.md` fixes one `CODE` review's
  findings in a nested task worktree, without changing behavior (D1).
- `templates/CODE_GUIDELINES.md` ships Names, Simplicity, Errors and Comments
  as numbered clauses with reasons and examples; this repository's
  `docs/CODE_GUIDELINES.md` carries them with its own POSIX sh examples, and
  `## Code: names` is gone from `templates/AGENTS-block.md`, `AGENTS.md` and
  `ratchet`'s inventory (D2, D3).
- The deslop pass is gone. After every task branch is merged, one read-only
  `review-conformance` subagent runs per file `scripts/guidelines-file.sh`
  prints for `TEST` and `CODE`, all at once; findings go to `develop-refactor`
  (`CODE`) or `develop-tdd` (`TEST`), and the reviews repeat until a round has
  nothing above low. `guidelines-file.sh` knows the kind `CODE` (D4).
- `tailor-guidelines` and `ratchet` install and tailor the `CODE` file;
  `verify-before-merge` check 8 asks that each conformance review ran and was
  dispositioned; the review checklist and `templates/verification.md` name the
  `CODE` reviews; the upgrade notes cover symlink and copy installs (D5).
- `review-guidelines` is `review-conformance` (D6).
- Citations of rules that now live in `develop-tdd` name it, the
  MISSING-TEST remedy of `scripts/check-trace.sh` included.

The change also corrected its own template: Errors 3 no longer asks for a
documented default to be reported where it is taken, which this repository's
own `prune_plans` example contradicted.

## Review

### Round 1

**finding-1**: code, low — D1 says "the citations of rules that move to `develop-tdd` are repointed". The plan's inventory missed two of them, and both still name `develop-change`: `scripts/check-trace.sh:255`, the MISSING-TEST remedy that adopters see: "Write a test annotated verifies: <ID> at the lowest level that exists, LLR before REQ (develop-change)". The annotation rule now lives only in `develop-tdd` (`skills/develop-tdd/SKILL.md:38`). `scripts/prune-plans.sh:228`, a comment: "(the develop-change dispatch report opens with `task:`)". The report shape now lives in `develop-tdd`. The remedy still leads somewhere useful, because `develop-change`'s description names `develop-tdd`. Editing line 255 may touch a mutation anchor, so grep the `docs/verification/*.mutations/` dirs first.
disposition: fixed in `5deae5a`: the remedy in `scripts/check-trace.sh` names `develop-tdd`, and the new test "check-trace: the MISSING-TEST remedy names develop-tdd, where the annotation rule lives" in `tests/remedies.bats` fails on the old text; the comment in `scripts/prune-plans.sh` names `develop-tdd`. No mutation anchor quotes either line. Every other `develop-change` citation in `scripts/` and `templates/` names dispatcher work and stays.

**finding-2**: code, low — The test at `tests/skills.bats:1095`, "code guidelines: this repository's naming rules live in its own code guidelines file", carries `verifies: D2 (docs/plans/2026-10-13-code-guidelines.md)`. It no longer checks anything about the naming rules. The round-3 fix (0064b11) deleted its `## Code: names` check on AGENTS.md and its Names 1-3 greps on `docs/CODE_GUIDELINES.md`. What is left only checks that `## Writing: prose, names and messages` is absent, which was already true on main. It would pass with `## Code: names` back in AGENTS.md and with `docs/CODE_GUIDELINES.md` deleted. D2 is still covered by other tests (`tests/code-guidelines.bats:128` and `:193`), so no behavior is left untested. But this test's name and annotation are false. The sibling test at `tests/skills.bats:1079` also lost its template asserts. It now passes without failing if `templates/AGENTS-block.md` is missing, because a `grep` that exits 2 inside `if` reads as "not found". The round-3 fix took assertions out of tests as a duplication fix. `skills/develop-refactor/SKILL.md:30-31` says "Never delete, skip or loosen a test to keep the suite green". No skill says what a fixer does when a Simplicity 4 finding lands on test assertions. Fix: give the test back one positive assertion, or rename it and drop the D2 annotation.
disposition: fixed in `5deae5a`: "code guidelines: this repository's naming rules live in its own code guidelines file" in `tests/skills.bats` asserts `docs/CODE_GUIDELINES.md` exists with `## Names` and `AGENTS.md` has no `## Code: names`, each watched failing; its sibling asserts both template files exist. The missing rule for a fixer is recorded as PR-75pdcu.

**finding-3**: code, low — The upgrade note leaves out copy-mode installs. `skills/ratchet/references/upgrade-notes.md:620-623` says "rerun `install.sh`, and delete the dangling `review-guidelines` link it leaves". That only fits the symlink install. With `install.sh --copy`, a rerun prints `SKIP  <name> (exists and is not a symlink — remove it manually to replace)` (`install.sh:25`) for every existing skill. So `develop-change`, `verify-before-merge` and the others stay at the old version, and a full `review-guidelines` directory that still describes the dropped pass stays installed. The same note is also missing one step. The older note (`:507-509`) told projects to keep removed rules outside the managed markers. This one never says that a project which did that for naming rules should move them into `docs/CODE_GUIDELINES.md`. Otherwise those rules have the two homes D2 rules out.
disposition: fixed in `5deae5a`: `skills/ratchet/references/upgrade-notes.md` gives the copy-install path (delete each copied guardrails skill directory, `review-guidelines` included, then rerun `install.sh --copy`) and tells a project that kept naming rules outside the markers to move them into `docs/CODE_GUIDELINES.md`; "upgrade notes: code guidelines, the dropped pass and the renamed reviewer" in `tests/tailor-guidelines.bats` pins both and was watched failing.

**finding-4**: code, low — The derailment rule now trips on the normal review loop. `skills/develop-change/SKILL.md:90` still stops the change when "review returns findings on the same task twice". The new section (`:153`) runs the conformance reviews again until a round has nothing above low, so findings in round 1 and round 2 are an expected outcome. This change's own CODE review had findings above low in rounds 1 and 2. Read literally, line 90 calls that a derailment and hands it to the user. The rule should say whether conformance rounds count.
disposition: recorded as PR-r6ypg9: whether conformance rounds count, and what bounds a conformance loop that does not converge, is a rule to decide, not a mechanical fix.

**finding-5**: record — The plan's record of the tests does not match the final tree: `docs/plans/2026-10-13-code-guidelines.md:739` says the test from finding-2 was "watched fail before the AGENTS.md edit". The body that exists now could not have failed then; the red -> green line describes a body that 0064b11 removed. `:552` records "clanker: the conformance reviews are not deferred to the merge review" as `inherited:` with "body unchanged". f66972f later added an assertion to it, and the plan lists a red -> green line for it as well. `inherited:` is used throughout for renamed tests. `skills/develop-tdd/SKILL.md:109-110` defines it as "a pre-existing test of a superseded item", so these lines will be misleading when 6b copies them into the record.
disposition: fixed in `aaa3da8`: in `docs/plans/2026-10-13-code-guidelines.md` the line for finding-2's test says its body was cut by `0064b11` and restored, the clanker test's line says it gained an assertion, and every renamed test is listed as `renamed:`, not `inherited:`; this record, `docs/verification/2026-10-14-code-guidelines.md`, copies them as such.

## Guideline reviews

### docs/TEST_GUIDELINES.md

Governs: every path of the diff (`guidelines-file.sh TEST` printed the one file for all of them).

### Round 1


Reviewer — one `review-conformance` subagent, read-only, range `main...code-guidelines`
Round verdict — 1 finding (0 high, 1 medium, 0 low); 1 is above low.

**finding-1**: guideline, medium — Seams 1, "A test calls only an interface that a REQ or LLR describes ... In this repository the interface is a script's command line. A bats test runs `sh scripts/<name>.sh` with arguments in a temporary repository and asserts on its output, its exit status and the files it leaves." — tests/code-guidelines.bats:171
The test "code guidelines: every kind guidelines-file.sh knows has a shipped template" gets the script's kinds by running `sed` over the source of `scripts/guidelines-file.sh` and matching the `KNOWN_KINDS='...'` assignment. It never runs the script. That ties the test to an internal variable's name and quoting. A refactor that renames or restructures the variable, with every behavior kept, breaks the test. That is exactly the failure the clause's "Why" names. The behavior is visible at the command line: an unknown kind exits 2 with `unknown kind: <kind> (known: TEST CODE)` (scripts/guidelines-file.sh:62), and tests/guidelines-file.bats already asserts that message. The kinds can be read from that output.
disposition: fixed in `3f103f6` (merged from `code-guidelines-cr1-test`); the rewritten test was watched fail with a third kind in KNOWN_KINDS; in `tests/code-guidelines.bats`

note (reviewer): most new tests check shipped skill or template text by grep or awk; Seams 1 names only the script command line as this repository's interface, so the file has a gap for tests of shipped documents (not a finding).

### Round 2


Reviewer — one `review-conformance` subagent, read-only, range `main...code-guidelines`, run in parallel with the CODE review
Round verdict — 0 findings (0 high, 0 medium, 0 low); none above low.

note (reviewer): Seams 1 still names no seam for a content lint over a SKILL.md or template; most of this change's tests are that kind (a gap in the file, raised in round 1 too).

### Round 3


Reviewer — one `review-conformance` subagent, read-only, range `main...code-guidelines`, run in parallel with the CODE review
Round verdict — 0 findings (0 high, 0 medium, 0 low); none above low.

note (reviewer, floor): `tests/skills.bats` "clanker: the conformance reviews are not deferred to the merge review" gained `verifies: … D4` with no red -> green line, and its one assertion (`**reruns from step 1**`) would still pass if the reviews moved to 6a.
note (reviewer, floor): two absence-only tests pass vacuously if the file they read is missing ("ratchet: the retrofit inventory no longer looks for a ## Code: names section"; "code guidelines: no silent fallback does not require reporting a named default").

### docs/CODE_GUIDELINES.md

Governs: every path of the diff (`guidelines-file.sh CODE` printed the one file for all of them).

### Round 1


Reviewer — one `review-conformance` subagent, read-only, range `main...code-guidelines`, run in parallel with the TEST review
Round verdict — 5 findings — 0 high, 4 medium, 1 low; four are above low.

**finding-1**: guideline, medium — Simplicity 4, "No duplication between tasks." — "Where two parts of one change add the same helper, constant or check, one copy stays, where both can reach it" — tests/code-guidelines.bats:111, tests/develop-refactor.bats:12, tests/develop-tdd.bats:13
The change adds three byte-identical copies of the `section_of` awk helper. A fourth copy was already at tests/tailor-guidelines.bats:14 on main. `tests/helpers.bash` is reachable from every file through `load helpers`, and code-guidelines.bats already loads it. One copy belongs there.
disposition: fixed in `e04669c` (merged from `code-guidelines-cr1-code`); in `tests/helpers.bash`

**finding-2**: guideline, medium — Errors 2, "No swallowed error." — "Where an error is expected and handled, the handling says why that is safe" / "`|| true` after `grep -c` ... is handled on purpose and its comment says so" — tests/code-guidelines.bats:91, 96, 133, 138 (`count=$(grep -cF ... || true)`) and 189, 198, 207 (`hits=$(... | grep -v ... || true)`)
None of these seven `|| true` carries a comment saying why discarding the exit status is safe. The comments above 189–207 explain the upgrade-notes filter, not the `|| true`. At 91–138, `|| true` also discards grep's exit 2 for an unreadable file. The test still fails then, but only because `[ "" -eq 0 ]` errors, which the code does not state.
disposition: fixed in `e04669c` (merged from `code-guidelines-cr1-code`); in `tests/code-guidelines.bats`

**finding-3**: guideline, medium — Comments 2, "No change narration." — "A comment describes the code as it is, never the change that wrote it: no "added", "now uses", "previously", "fixed" or ticket history" — tests/skills.bats:1084, 1101–1102, 1201, 2278–2279, 2437–2439
These added comments narrate the change rather than state why the test holds: 1084 "The past-participle rule dropped with the prose rules stays dropped."; 1101–1102 "the rules it ships moved to the code guidelines ... The prose section stays removed"; 1201 "The section left the managed block, so a block without it is no gap."; 2278–2279 "The report form and the coverage sentence moved to develop-tdd with the loop"; 2437–2439 "The floor and the one-file rule moved on with the TDD loop to develop-tdd".
disposition: fixed in `e04669c` (merged from `code-guidelines-cr1-code`); in `tests/skills.bats`

**finding-4**: guideline, medium — Comments 2, "No change narration." — same clause and words — tests/develop-tdd.bats:109
"The loop, the annotation rule and the red-first rule moved to develop-tdd, so a citation of them names it".
disposition: fixed in `e04669c` (merged from `code-guidelines-cr1-code`); in `tests/develop-tdd.bats`

**finding-5**: guideline, low — Names 4, "One name per concept across the change." — "A concept has one name in every file, test and task of the change" — skills/develop-change/SKILL.md:156, templates/verification.md:98
The change renames the concept "conformance reviews" (develop-change's "### The conformance reviews", verification.md:101 "The conformance reviews"). The record section that holds those reviews keeps the old name `## Guideline reviews`, so one concept has two names across the change. The heading may be one a script parses, which would make keeping it right; if so, the code is right and this is a gap only.
disposition: no change — D5 keeps the record heading `## Guideline reviews` by name, so records written before and after this change share one section; no script parses it today (`grep -rn 'Guideline reviews' scripts/` is empty), and the queued D9 gate will read that one name.

Reviewer notes checked: the claim that Comments 1's example misquotes its source is wrong (`scripts/guidelines-file.sh:47` reads ``# NOT `cd "$(gr_root)" || exit 2` alone: ...``); the note that `|| true` after `grep -c` in `scripts/check-review.sh:153` carries no comment is right but outside this diff.

### Round 2


Reviewer — one `review-conformance` subagent, read-only, range `main...code-guidelines`, run in parallel with the TEST review
Round verdict — 6 findings (high 0, medium 3, low 3); findings above low: yes (finding-1, finding-2, finding-4).

**finding-1**: guideline, medium — Simplicity 4, "Where two parts of one change add the same helper, constant or check, one copy stays, where both can reach it" — tests/skills.bats:1126, 1213, 2451, 2479, 2491; tests/review-conformance.bats:69
This change adds `section_of` to tests/helpers.bash (commit 51f5397, "one section_of ... for the four files that used a copy"). skills.bats already loads helpers. Even so, task T5 (3b7f7a7) adds five new inline `awk '/^### The conformance reviews$/ { inside = 1; next } /^##/ { inside = 0 } inside'` / `/^## Preconditions/` section extractors to skills.bats. review-conformance.bats:69 adds another one and does not `load helpers`. Each one is the same check as `section_of`, and both files can reach `section_of`.
disposition: fixed in `379aa2f` (merged from `code-guidelines-cr2-code`), every instance in the range swept, not only the cited lines; in `tests/skills.bats`, `tests/review-conformance.bats`

**finding-2**: guideline, medium — Simplicity 4, "one copy stays" — tests/code-guidelines.bats:88-105 and 125-143
Two tests repeat the same check line for line, comment block included. One is "the template stands alone" (T2) and the other is "this repository's file stands alone" (T8). Each loops over the forbidden tokens and every skill name, then runs `grep -c ... || true` against one file. Only the file differs. The test at lines 161-168 shows the one-copy form the file already uses: a loop over `"$template" "$repo_guidelines"`.
disposition: fixed in `379aa2f` (merged from `code-guidelines-cr2-code`), every instance in the range swept, not only the cited lines; in `tests/code-guidelines.bats`

**finding-3**: guideline, low — Simplicity 4, "one copy stays" — tests/code-guidelines.bats:187-199, 201-211, 213-223
Three sweep tests each add the same check: `run grep -r...`, then filter out `skills/ratchet/references/upgrade-notes.md` with `grep -v ... || true`, then assert the result is empty. They also repeat the same three-line comment. Only the token and the directories differ. The code is correct, so this is low.
disposition: fixed in `379aa2f` (merged from `code-guidelines-cr2-code`), every instance in the range swept, not only the cited lines; in `tests/code-guidelines.bats`

**finding-4**: guideline, medium — Names 4, "where the codebase already names it, that name"; Example: "the checkout's top directory is `repo_root` in every script, not `root_dir` in one of them" — docs/CODE_GUIDELINES.md:36-38
The example is false for this project, so the clause does not stand as written. The scripts name the checkout's top directory `gr_repo_root` in 12 places, for example scripts/check-ids.sh:61, scripts/check-signing.sh:52 and scripts/check-review.sh:72. Only scripts/guidelines-file.sh:49-51 uses `repo_root`. A reader who follows the example would rename against the clause's own rule to use the codebase's existing name.
disposition: fixed in `379aa2f` (merged from `code-guidelines-cr2-code`), every instance in the range swept, not only the cited lines; in `docs/CODE_GUIDELINES.md`

**finding-5**: guideline, low — Names 3, "A name says what the thing is in the project's domain, not its type or a role in general"; Names 4, "One name per concept across the change" — tests/skills.bats:1175
`check=$(tr '\n' ' ' < "$skill" | tr -s ' ')` holds the flattened text of verify-before-merge's SKILL.md, not a check. Elsewhere in the change the same concept is `flat` (tests/develop-refactor.bats, tests/develop-tdd.bats, tests/code-guidelines.bats:71). Also, skills.bats:2270 already uses `check` for a different value, a path.
disposition: fixed in `379aa2f` (merged from `code-guidelines-cr2-code`), every instance in the range swept, not only the cited lines; in `tests/skills.bats`

**finding-6**: guideline, low — Comments 2, "A comment describes the code as it is, never the change that wrote it: no ... ticket history" — tests/develop-refactor.bats:2-3; tests/develop-tdd.bats:2-3; tests/code-guidelines.bats:3
These file headers name the plan tasks that wrote the files: "T4", "T3 and T10", and "T2, T8 and T12". The citation of the decision (`docs/plans/2026-10-13-code-guidelines.md`) is a design reference. The task numbers only record which change wrote the file. An existing file follows the same convention (tests/tailor-guidelines.bats:2, "T5"), so this is low.
disposition: fixed in `379aa2f` (merged from `code-guidelines-cr2-code`), every instance in the range swept, not only the cited lines; in `tests/develop-tdd.bats`, `tests/develop-refactor.bats`, `tests/code-guidelines.bats`

Checked: `grep -lw gr_repo_root scripts/*.sh` lists 12 scripts and `grep -lw repo_root` one, so finding-4 holds; the T8 report's "repo_root in ten scripts" matched the longer name.

### Round 3


Reviewer — one `review-conformance` subagent, read-only, range `main...code-guidelines`, run in parallel with the TEST review
Round verdict — 3 findings (0 high, 0 medium, 3 low); none above low.

Both reviews have nothing above low, so round 3 is the last: the low findings are fixed where the fix is mechanical, and no further review is dispatched.

**finding-1**: guideline, low — Simplicity 4, "No duplication between tasks." — "Where two parts of one change add the same helper, constant or check, one copy stays" — tests/skills.bats:1088, 1090-1092, 1108-1111, 1131, 1179; tests/review-conformance.bats:66; tests/develop-tdd.bats:110; tests/code-guidelines.bats:176-180
The change adds sweeps in tests/code-guidelines.bats. Several per-file checks it adds elsewhere repeat what those sweeps already check:
- The `des''lop` sweep (code-guidelines.bats:189) greps `skills/` case-insensitively. That already covers skills.bats:1131 (develop-change), skills.bats:1179 (verify-before-merge SKILL.md and references/rationale.md) and review-conformance.bats:66 (the description).
- The `## Code: names` sweep (code-guidelines.bats:198) covers `templates/AGENTS-block.md` and `AGENTS.md`. That repeats skills.bats:1088 and 1108.
- The `review-''guidelines` sweep (code-guidelines.bats:206) covers `README.md`. That repeats develop-tdd.bats:110.
- skills.bats:1090-1092 and 1109-1111 grep the Names clauses 1-3 in the template and in the repository file. The clause-list tests at code-guidelines.bats:49-51 and the "keeps every clause of the template" test already pin those clauses exactly.
- code-guidelines.bats:176-180 asserts that CODE is in the known-kinds list. guidelines-file.bats:75 already pins `(known: TEST CODE)`.

The code is correct, so this is low. It is still two copies of each check, which the clause says will drift.
disposition: fixed in `0064b11` (merged from `code-guidelines-cr3-code`); in `tests/skills.bats`, `tests/code-guidelines.bats`

**finding-2**: guideline, low — Names 4, "One name per concept across the change." — "A concept has one name in every file, test and task of the change, and where the codebase already names it, that name" — skills/develop-refactor/SKILL.md:46-48 (pinned at tests/develop-refactor.bats:345-347)
The two dispatch reports this change adds name the same fields differently:
- develop-refactor's report says `files changed: <paths>`. develop-tdd's says `files touched: <paths>` (skills/develop-tdd/SKILL.md:96). The codebase already uses "touched": plans carry `**Files touched:**` (templates/config.yaml:114).
- develop-refactor reports an unfixed finding on its own `not fixed:` line. develop-tdd folds it into `fixed: <finding-N — what changed, or "not fixed — <reason>">`.

In both cases two shapes read as two concepts to the dispatcher that collects both reports.
disposition: fixed in `0064b11` (merged from `code-guidelines-cr3-code`); in `skills/develop-refactor/SKILL.md`, `tests/develop-refactor.bats`

**finding-3**: guideline, low — Errors 2, "No swallowed error." — "no discarded return code or error value" — tests/code-guidelines.bats:147
`if cmp -s "$template" "$repo_guidelines"; then ...` treats cmp's exit 2 the same as "the files differ". That happens when `$template` is missing or unreadable. This test checks `$repo_guidelines` exists but not `$template`, so it would pass that check silently. Only a missing template reaches this, and other tests would fail first, so the state is contrived.
disposition: fixed in `0064b11` (merged from `code-guidelines-cr3-code`); in `tests/code-guidelines.bats`

Also fixed in the last round, from the round-3 TEST reviewer's floor notes: the renamed "clanker: the conformance reviews are not deferred to the merge review" test asserts what its D4 annotation claims, and the two absence-only tests fail when the file they read is missing.

Floor notes fixed in `f66972f` (merged from `code-guidelines-floor`):

red -> green: clanker: the conformance reviews are not deferred to the merge review — with "These reviews run here, before" removed from develop-change, the new assertion failed while the old one still passed
red -> green: ratchet: the retrofit inventory no longer looks for a ## Code: names section — pointed at a missing file, failed at the new existence assertion
red -> green: code guidelines: no silent fallback does not require reporting a named default — pointed at a missing file, failed at the new existence assertion


## Gaps

- The reviewer's own suite runs were not clean, and neither is the reason
  this record's gate figure stands: run 1 (1..1431) had 1429 passed and 2
  failed, both `check-trace` age tests, in a run that crossed midnight
  (recorded as PR-tqwky6); run 2 had 1430 passed and 1 failed,
  `new-id: a FIFO is rejected rather than read` timing out under load
  (PR-qf5tkd, already open). Each failing test passed in the other run, and
  the diff touches none of their files. The gate above is the author's run on
  the final tree.
- `docs/TEST_GUIDELINES.md` names no seam for a test of a shipped skill or
  template's text, which is most of this change's tests; both TEST reviewers
  noted it and no clause was added.
- `## Guideline reviews` keeps its name while the skills call them
  conformance reviews (D5); the `check-review.sh` gate for that section, a
  follow-up of the test-guidelines change, is still unbuilt.
- The rule for test assertions under a duplication finding (PR-75pdcu) and
  the derailment rule's reach (PR-r6ypg9) are open.
