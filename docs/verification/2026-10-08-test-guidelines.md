# Verification — test-guidelines (2026-10-08)

branch: test-guidelines
reviewer: independent Claude subagent with fresh context, given the diff, the plan, AGENTS.md, the review checklist and the items the change resolves, opens and records (merge-change step 6a), at `63eb4a4`; the guideline review of `develop-change`'s new step ran before it, in a fresh context of its own, against this repository's `docs/TEST_GUIDELINES.md`
verdict: converged at round 1 — every finding low or record; each was mechanical and is fixed, so no further reviewer was dispatched
reproduced: PR-ttg99p (develop-change step 6 obliged adopters to grep a directory only this repository has) was observed in the shipped text, `skills/develop-change/SKILL.md` step 6 at `b4484b8`; its test, `develop-change: the mutation-anchor rule lives in this repository's TEST_GUIDELINES.md, not develop-change`, was watched red with `docs/TEST_GUIDELINES.md` absent. Every other new test was watched red before its text or code existed (red → green below)

Change: skills keep the compliance floor, and each project's test preferences live in one standalone `TEST_GUIDELINES.md`, picked by `guidelines-file.sh`, tailored by `tailor-guidelines` and checked by `review-guidelines`. Branched from `main` at `b4484b8`; base merged from local `main` at `dd411a1`, per AGENTS.md non-negotiable 4.
Plan: `docs/plans/2026-10-08-test-guidelines.md`.

## The gate

Measured on: `34856f8` — `git rev-parse HEAD` — tree `edf5fa8acda93aeecdae190be23b95d5b09aa367`, clean worktree, `main` at `dd411a1`. Step 3's one rename (the draft problems file) was committed before the review; this tree contains it and every review fix, so it is the tree that merges, apart from this record.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` (parallel) | 1..1279, all ok, exit 0 (20:07–20:44, load 13 falling to 8) |
| `check-ids.sh --allow-draft-files` (scratch copies, base and change) | exit 1 on both, identical findings apart from line numbers in `tests/check-ids.bats`, shifted by the lines this change added there |
| `check-trace.sh` (scratch copies, base and change) | exit 1 on both; differing only by this change's items: PR-ttg99p leaves the open list, PR-3kvpze enters it, ADR-me39p4 is added |
| `check-review.sh --branch test-guidelines` (scratch copy) | exit 0 |
| Coverage | not configured |
| Working tree | clean |

The repository has no `.guardrails/config.yaml`, so `check-ids.sh` and `check-trace.sh` ran on scratch copies built from `main` and from the change with `templates/config.yaml` (its `strict_paths` entry set to `scripts`, and one-line placeholder `doc_srs`/`doc_sad` files so the trace gate runs), and `merge-preflight.sh` was not run, as in `docs/verification/2026-10-08-test-seams.md`. Item IDs were minted with `new-id.sh` under a scratch `GR_CONFIG` declaring `PR` and `ADR`; `finalize-docs.sh` ran under the same config.

Earlier full runs, not counted here: at `58075ce` the suite failed 4 of 1228 on the repository's script inventories, which did not yet know `guidelines-file.sh` (fixed by `gate-inventory`); at `3bf87d8` it passed 1268 of 1268, before step 3 and the review fixes changed the tree.

## Red → green

This repository has no SRS: the change implements decisions D1 to D11 of its plan, and each row names the tests whose `verifies:` cites them. The plan's `red -> green:` lines, one per test, are the full list.

| Item | Test | Watched red |
| --- | --- | --- |
| D1, D9 | `develop-change: the guideline reviews follow the deslop pass, before merge-change`; `develop-change: guideline review findings go into the plan as they arrive, and step 6b copies them`; `merge-change: the review checklist's test section is the floor, and checks the guideline reviews ran`; `verification template: guideline reviews have their own section` | each section or sentence absent before it was written |
| D2 | `develop-change: every test fails when the behavior it verifies breaks`; `develop-change: a clause that contradicts the skill is a finding against the clause`; `review-guidelines: the floor is listed in full`; `tailor-guidelines: a change that contradicts the floor is rejected, and the floor is listed` | the floor sentence absent; the skills absent |
| D3, D8 | the `guidelines-file:` tests in `tests/guidelines-file.bats`; `guidelines-file.sh resolves a unit's file under an awk that rejects a newline in -v`; `develop-change: before RED, guidelines-file.sh picks the one guidelines file`; `develop-change: the dispatch prompt names the guidelines file for each of the task's paths`; `develop-change: a missing or broken guidelines-file.sh stops the task` | exit 127 with the script absent; the order test under a `sort \|` mutant, the empty-path test with that branch deleted, the CDPATH test against the unfixed script (`lib.sh: No such file or directory`); the stub test with a newline passed to `awk -v`; the skill sentences absent |
| D4 | the `review-guidelines:` tests | `SKILL.md` absent |
| D5, D6 | the `tests/test-guidelines.bats` template tests (the five moved test-seams pin groups, headings, preface, stand-alone, UI opening, word ceiling, restored passages, robustness definition, clause reasons); `develop-change: the seam reference files are gone` | template absent; each restored passage and reason absent; the stand-alone test also with `ADR-`, `develop-change` and `references/` appended one at a time |
| D7, D11 | the `tailor-guidelines:`, `ratchet:` and `upgrade notes:` tests in `tests/tailor-guidelines.bats` | `SKILL.md` absent; each `ratchet` line and the upgrade-notes section absent |
| D10, PR-ttg99p | `develop-change: the mutation-anchor rule lives in this repository's TEST_GUIDELINES.md, not develop-change`; `test guidelines: this repository's file has the template's headings except UI`; `test guidelines: this repository's file stands alone, naming no guardrails document or skill`; `here a plan decision or problem report states a deeper interface's contract, not an LLR` | `docs/TEST_GUIDELINES.md` absent; Seams 2 still conditioned on an LLR |
| D2, D3 (ADR-me39p4) | `the seam and owned-service ADRs say ADR-me39p4 made them shipped defaults` | no amendment note in either ADR |
| D3, D8 (inventories) | `every gr_def_re call site is still a call site, and no copy joins them`; `every script parses as POSIX sh`; `every script is executable in the index, not just runnable via sh`; `every script stops outside a git repository, at gr_root` | the gate run at `58075ce` |

## What was wrong, and what was built

Skills mixed the compliance floor with preferences. After `test-seams`, `develop-change` stated where a test attaches and which doubles it may use as rules no project could change without editing a shipped skill, which an upgrade overwrites; its step 6 obliged every adopter to grep a mutation-evidence directory only this repository has (PR-ttg99p); and the merge review's test checklist restated those preferences as compliance checks.

Skills now state the floor only: `verifies:` annotations, red → green, every test fails when the behavior it verifies breaks, the class B/C robustness rule and the class C interface rule. Preferences live in `templates/TEST_GUIDELINES.md`, a standalone file of numbered clauses, each with its rule, boundary, reason and language-neutral examples, which a project copies to `docs/TEST_GUIDELINES.md` and a unit to `<unit>/docs/TEST_GUIDELINES.md`; a lower file replaces a higher one whole, and none refers to another (ADR-me39p4). `scripts/guidelines-file.sh` prints the one file that governs each path. `develop-change` reads it before RED and, after the deslop pass, dispatches `review-guidelines` once per file over the diff, writing its findings into the plan for step 6b to copy into the record's `## Guideline reviews`. `tailor-guidelines` seeds, interviews and upgrades a project's file clause by clause and never overwrites it; `ratchet` installs the default and invokes it. `develop-change`'s seam reference files are folded into the template and deleted. This repository's own `docs/TEST_GUIDELINES.md` carries the mutation-anchor rule and bats examples, which resolves PR-ttg99p. ADR-8ft3hb and ADR-4xh6cf note that they are now shipped defaults.

## Review

### Round 1

**finding-1**: code, low — `tests/guidelines-file.bats` does not test D8's output order ("in the order each file is first needed … the paths in argument order"): test 3's expected output is already in sorted order, and inserting `sort |` before the grouping awk in `scripts/guidelines-file.sh` line 115 (reordering both files and paths) left all 9 tests green. A fixture whose root-governed path comes first in the arguments (e.g. `apps/ui/y.ts apps/pump/x.c`) would kill this mutant.
disposition: fixed in 97612e5 (`r1-script`): `files print in first-needed order and paths in argument order, unsorted`, red under the `sort |` mutant.

**finding-2**: code, low — The empty-path rejection (`('') guidelines_die "empty path; $usage"`, `scripts/guidelines-file.sh` line 66) is behavior the T1 Done note lists as a deviation, but no test covers it: deleting the branch makes an empty argument resolve to the root file at exit 0, and no test fails. AGENTS.md requires a bats test for every behavior change to a script.
disposition: fixed in 97612e5: `an empty path is exit 2 with the usage line`, red with the empty-path branch deleted.

**finding-3**: code, low — `scripts/guidelines-file.sh` line 36 computes its directory with `$(cd "$(dirname "$0")" && pwd -P)` without clearing `CDPATH`, unlike `finish-merge.sh`, `merge-preflight.sh` and `task-worktree.sh`, which use `CDPATH= cd -- …` for this reason. With `CDPATH` exported the substitution also captures the echoed directory. Measured: `CDPATH=$PWD sh scripts/guidelines-file.sh TEST a` prints `lib.sh: No such file or directory` and exits 1, outside its documented 0/2. (`check-review.sh` exits 2 under the same `CDPATH`.)
disposition: fixed in 97612e5: every `cd` in the script runs as `CDPATH= cd --`; `an exported CDPATH does not change where it finds itself`, red against the unfixed script.

**finding-4**: requirement, low — `develop-change` "### The guideline reviews" says the record's `## Guideline reviews` is the one "which `merge-change` step 6b fills in", but `skills/merge-change/SKILL.md` 6b (not edited by this change) still enumerates only "the reviewer's verdict and every finding with its disposition" and never names guideline reviews. The new checklist item also asks the 6a reviewer to read that section of a record that 6b writes after 6a; this round I could check it only against the plan's narrative, because no record exists in this diff. The verification template does carry the section, so a 6b author copying it would see it, hence low.
disposition: fixed in 2aeac30 (`r1-skills`): `develop-change` writes each guideline review's findings into the plan as they arrive, step 6b names `## Guideline reviews` and copies them, and the checklist checks the plan (and the record where it exists); `develop-change: guideline review findings go into the plan as they arrive, and step 6b copies them`, red before the edit.

**finding-5**: requirement, low — D8 says that on exit 2 "the install is broken, and the agent stops", but `develop-change` "### Test guidelines" and "### The guideline reviews" never say what to do when `guidelines-file.sh` exits 2 or is absent, which is exactly the state of an adopter whose symlinked skills are newer than its `.guardrails/scripts/`. The script's own message ("no installed default … — reinstall guardrails") names the cause, hence low.
disposition: fixed in 2aeac30: `develop-change` stops when `guidelines-file.sh` exits 2 or is missing; `develop-change: a missing or broken guidelines-file.sh stops the task`, red before the edit.

**finding-6**: requirement, low — D7 says `/ratchet` invokes `tailor-guidelines` "once per guidelines file at setup", but only the greenfield scaffold (step 2.6) and upgrade (step 2) invoke it; the retrofit path (step 3) installs the templates but neither invokes `tailor-guidelines` nor lists it as a later tooth. Relatedly, T5 said to tighten `ratchet` changing no rule, but the tightening deleted "Never add bats to the target project." and retrofit step 3's "On a multi-unit repository, read `references/multi-unit.md` first." (each is still covered elsewhere — the bold "bats is never installed" and the References entry). And D3 says "A change spanning units hands each task its unit's file", but the delegation template has a single `<file>` slot, with no wording for a task whose Files touched span two units.
disposition: fixed in 2aeac30: the retrofit lists `tailor-guidelines` as a later tooth (the first tooth only installs; D7 updated to say so); both removed sentences restored verbatim; the dispatch prompt names the file for each of the task's paths. Tests `ratchet: a retrofit tailors each guidelines file as a later tooth`, `ratchet: the T5 tightening kept the bats and multi-unit sentences`, `develop-change: the dispatch prompt names the guidelines file for each of the task's paths`, each red before the edit.

**finding-7**: record — The plan's header (`**Opens:** PR-3kvpze`) and its tasks never mention the ADR this change adds, `ADR-me39p4`; and that ADR reframes `ADR-4xh6cf` and `ADR-8ft3hb` as shipped defaults rather than floor, while both still read as unconditional rules ("A test calls only an interface that a REQ or LLR describes") with no note pointing to ADR-me39p4. The documentation checklist's "an amendment edits the defining file in place".
disposition: the plan header names ADR-me39p4 and the two ADRs it amends; each of ADR-8ft3hb and ADR-4xh6cf ends with an amendment note (8bb45f7, `r1-docs`), pinned by `the seam and owned-service ADRs say ADR-me39p4 made them shipped defaults`, red before the edit.

**finding-8**: requirement, low — D5 requires each clause to state "a one- or two-sentence reason", but several template clauses state only the rule plus a boundary or example, with no reason: Doubles 2 (fakes at the codebase boundary only), Doubles 4, UI 3, UI 5 and UI 7. A project tailoring those clauses has no reason to weigh, which is what D5 says the reasons are for.
disposition: fixed in 8bb45f7: Doubles 2, Doubles 4, UI 3, UI 5 and UI 7, and on a full read Seams 3, UI 4 and Property tests 1, state a reason, mirrored into this repository's file where it keeps the clause; `each template clause that lacked a reason states one`, red before the edit; the template's word ceiling is raised to 1,950 instead of cutting content.

**finding-9**: code, low — `tests/skills.bats` keeps the name "develop-change: the loop greps the mutation anchors for a changed line", which now asserts the opposite (that `develop-change` no longer mentions mutations, and that `docs/TEST_GUIDELINES.md` states the rule). PR-ttg99p's resolution line cites the test by that misleading name.
disposition: fixed in 2aeac30: the test is renamed `develop-change: the mutation-anchor rule lives in this repository's TEST_GUIDELINES.md, not develop-change`, and PR-ttg99p's resolution and the plan cite the new name. A rename has no red.


## Guideline reviews

### `docs/TEST_GUIDELINES.md`

Governs: every path of `main...test-guidelines` at `a375c4a`; `guidelines-file.sh TEST` printed this one file for all of them.

### Round 1

**finding-1**: guideline, low — Seams 2, "A deeper interface gets a direct test only once it has an LLR" (and Seams 3, "the adapter becomes a software item with an LLR stating that contract") — docs/TEST_GUIDELINES.md:26 (and :48). The file is tailored to this repository, whose Seams 1 states it "keeps no REQ or LLR ledger of its own"; Seams 2 and 3 still condition their permission on an LLR, a document this project does not contain, so a reader cannot apply them as written. In practice Seams 2 always reads "never", consistent with Seams 1's no-sourcing-lib.sh rule, and nothing in the change is misled by it.
disposition: fixed in 6a8a16f (guideline-r1): Seams 2 and 3 of this repository's file name a plan decision or problem report in the LLR's role, and Seams 1 defers to Seams 2; pinned by `here a plan decision or problem report states a deeper interface's contract, not an LLR`, red before the edit.

notes (not findings): Doubles 5 names "the robustness rule" without defining it (folded into guideline-r1 for both files); the lower-case-name test can fail only on a case-insensitive filesystem (it is red on macOS without the exact-name check); `## Owned services` kept though the repository owns no service; "watched red" is the record's to show.

The guideline reviewer's verdict: one low finding, none above low.

## Gaps

- The guideline review ran once, before the independent review; the review fixes after it were not put through a second guideline review. The independent review read `docs/TEST_GUIDELINES.md` as part of the diff.
- `check-review.sh` does not require `## Guideline reviews`; a skipped guideline review is caught only by the 6a reviewer reading the plan and the record (D9's follow-up).
- The text tests pin the operative sentences the tasks listed; wording beyond them is the review's to judge, as in `test-seams`.
- `review-guidelines` and `tailor-guidelines` were exercised on this repository only: the first by the one guideline review above, the second not run at all. No adopter project has been tailored with it.
- `tests/guidelines-file.bats`'s lower-case-name test can fail only on a case-insensitive filesystem; on a case-sensitive host it passes even without the exact-name check.
- Open: PR-3kvpze (a bare `! cmd` on a non-final bats line asserts nothing; five existing assertions affected).
- Follow-ups not built: `CODE_GUIDELINES.md` with a `develop-tdd` / `develop-refactor` split; `ARCHITECTURE_GUIDELINES.md` with per-unit constraints in `units.yaml`; the `check-review.sh` gate for `## Guideline reviews`.
