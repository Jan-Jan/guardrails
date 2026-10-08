# Agent-first skills, change 1: the shape and the merge-change pilot

**Goal:** Introduce the tested SKILL.md shape and apply it to `merge-change`,
moving its conditional material, reasons and rejection table to reference
files and dropping its incident history.
**Implements:** D4, D5, D6 and D9 of `docs/plans/2026-09-28-agent-first-skills.md`
(D3 item 1). No REQ items exist in this repository.
**Safety class:** the toolkit is unclassified. This change touches skill text,
tests, `AGENTS.md`, a comment in `scripts/finish-merge.sh`, the proposal, and two
problem ledger files;
no script behaviour changes.
**Verification:** `sh tests/run-tests.sh` — every test passes. `tests/skills.bats`
has 76 tests on `main` and 82 after the round 1 fix.

Every problem report a retargeted test verifies keeps that test and its
`verifies:` line (D4). The step numbering of `merge-change`, 1 to 8 with 6a to
6d, is unchanged, because other skills, templates and `AGENTS.md` cite it.

The files below were written and checked in a scratch clone of this branch:
the full `tests/skills.bats` and `tests/portability.bats` pass, and each of
the four breakages in T1 step 3 fails its test with the message shown there.

Run single bats files with `tests/.bats-core/bin/bats <file>`, never with
`tests/run-tests.sh <file>`. A fresh task worktree lacks the gitignored
`tests/.bats-core`; copy it from the change worktree first.

---

### T1 — the shape gates and the AGENTS.md rule

**Status:** done, merged as `1597191` (task commit `9bddace`).

red -> green:
- skill shape: every SKILL.md has the D9 sections in order — watched fail for the right reason (`merge-change:[Multi-unit repositories|The sequence|Red flags|]`); stays red until T2.
- skill shape: every shape exemption names a skill still out of order — watched fail with `nonexistent` added (`nonexistent:missing`), green once restored.
- skill shape: every SKILL.md is at most 2,000 words — watched fail with `ratchet` removed from the exemptions (`ratchet:7759`), green once restored.
- skill shape: every ceiling exemption names a skill still over it — watched fail with `plan-change` added (`plan-change:415`), green once restored.
- skill shape: the References section lists exactly the reference files — watched fail with a stray `skills/plan-change/references/stray.md`, green once removed.

**Files touched:** `tests/skills.bats`, `AGENTS.md`
**Parallel:** no (serial, before T2)

1. Append this block to the end of `tests/skills.bats`:

*(Code pruned at merge: 137 lines. Files touched: `tests/skills.bats`, `AGENTS.md`.)*

2. Run it and watch it fail for the right reason:

   *(Code pruned at merge: 1 line. Files touched: `tests/skills.bats`, `AGENTS.md`.)*

   Expected: `not ok 1 skill shape: every SKILL.md has the D9 sections in
   order`, reporting
   `merge-change:[Multi-unit repositories|The sequence|Red flags|]`. Tests 2 to
   5 print `ok`.

3. Watch each of the other four fail. Before the first breakage, copy
   `tests/skills.bats` outside the tree, and restore it from that copy after
   each one. `git checkout` would also discard the block appended in step 1:

   | Breakage | Expected failure |
   |---|---|
   | Add `plan-change` to `gr_ceiling_exempt_skills` | `not ok 4`, `remove from gr_ceiling_exempt_skills: plan-change:415` |
   | Remove `ratchet` from `gr_ceiling_exempt_skills` | `not ok 3`, `skills over 2,000 words: ratchet:7759` |
   | Add `nonexistent` to `gr_shape_exempt_skills` | `not ok 2`, `remove from gr_shape_exempt_skills: nonexistent:missing` |
   | `mkdir skills/plan-change/references && echo x > skills/plan-change/references/stray.md` (remove the directory after) | `not ok 5`, naming `plan-change` with `references/stray.md` present and nothing listed |

4. In `AGENTS.md`, under `## Rules`, replace the bullet that opens
   `- Skills live at` (three lines) with:

*(Code pruned at merge: 10 lines. Files touched: `tests/skills.bats`, `AGENTS.md`.)*

5. Run the whole file: `tests/.bats-core/bin/bats tests/skills.bats`.
   Expected: `1..81`, and only test 1 of the new block fails, as in step 2.
6. Commit unsigned:
   `git -c commit.gpgsign=false commit -am "test: the skill shape gates, D5 and D9"`.

---

### T2 — merge-change in the new shape

**Status:** done, merged (task commit `316722d`).

red -> green (red run: 1..81, these six the only failures):
- merge-change: a fix dispatch's tag is unique, and AGENTS.md defers on tags — failed while `references/rationale.md` did not exist.
- merge-change: step 8 maps guard 4's rejection to a remedy — failed while `references/cleanup-rejections.md` did not exist.
- merge-consumes-impact-mechanically, merge-runs-impact-set-gates, merge-finalizes-touched-units-only — each failed while `references/multi-unit.md` did not exist.
- skill shape: every SKILL.md has the D9 sections in order — failed on the old headings.

**Files touched:** `tests/skills.bats`, `skills/merge-change/SKILL.md`,
`skills/merge-change/references/multi-unit.md`,
`skills/merge-change/references/cleanup-rejections.md`,
`skills/merge-change/references/rationale.md`
**Parallel:** no (serial, after T1)

1. Retarget the tests first (D4). Save this script outside the tree, for
   example as `/tmp/t2-retarget.py`, and run it on `tests/skills.bats`. It
   exits non-zero and writes nothing if any replacement does not match exactly
   once:

*(Code pruned at merge: 69 lines. Files touched: `tests/skills.bats`, `skills/merge-change/SKILL.md`, `skills/merge-change/references/multi-unit.md`, `skills/merge-change/references/cleanup-rejections.md`, `skills/merge-change/references/rationale.md`.)*

   *(Code pruned at merge: 1 line. Files touched: `tests/skills.bats`, `skills/merge-change/SKILL.md`, `skills/merge-change/references/multi-unit.md`, `skills/merge-change/references/cleanup-rejections.md`, `skills/merge-change/references/rationale.md`.)*

2. Watch the retargeted tests fail against the old skill:

   *(Code pruned at merge: 1 line. Files touched: `tests/skills.bats`, `skills/merge-change/SKILL.md`, `skills/merge-change/references/multi-unit.md`, `skills/merge-change/references/cleanup-rejections.md`, `skills/merge-change/references/rationale.md`.)*

   Expected failures include the three multi-unit tests (the reference file
   does not exist), `a fix dispatch's tag is unique`, `step 8 maps guard 4's
   rejection to a remedy`, and `skill shape: every SKILL.md has the D9
   sections in order`.

3. Replace `skills/merge-change/SKILL.md` with:

*(Code pruned at merge: 390 lines. Files touched: `tests/skills.bats`, `skills/merge-change/SKILL.md`, `skills/merge-change/references/multi-unit.md`, `skills/merge-change/references/cleanup-rejections.md`, `skills/merge-change/references/rationale.md`.)*

4. Create `skills/merge-change/references/multi-unit.md`:

*(Code pruned at merge: 30 lines. Files touched: `tests/skills.bats`, `skills/merge-change/SKILL.md`, `skills/merge-change/references/multi-unit.md`, `skills/merge-change/references/cleanup-rejections.md`, `skills/merge-change/references/rationale.md`.)*

5. Create `skills/merge-change/references/cleanup-rejections.md`:

*(Code pruned at merge: 23 lines. Files touched: `tests/skills.bats`, `skills/merge-change/SKILL.md`, `skills/merge-change/references/multi-unit.md`, `skills/merge-change/references/cleanup-rejections.md`, `skills/merge-change/references/rationale.md`.)*

6. Create `skills/merge-change/references/rationale.md`:

*(Code pruned at merge: 122 lines. Files touched: `tests/skills.bats`, `skills/merge-change/SKILL.md`, `skills/merge-change/references/multi-unit.md`, `skills/merge-change/references/cleanup-rejections.md`, `skills/merge-change/references/rationale.md`.)*

7. Run both files the change can affect:

   *(Code pruned at merge: 2 lines. Files touched: `tests/skills.bats`, `skills/merge-change/SKILL.md`, `skills/merge-change/references/multi-unit.md`, `skills/merge-change/references/cleanup-rejections.md`, `skills/merge-change/references/rationale.md`.)*

8. Commit unsigned:
   `git -c commit.gpgsign=false add -A skills/merge-change tests/skills.bats && git -c commit.gpgsign=false commit -m "docs: merge-change in the agent-first shape"`.

---

## What was dropped, and where it already is

D6 removes incident history from the shipped skill. Each of these remains in
this repository's plans, records and git history:

- the review-round counts behind the convergence rule, and the three
  downstream changes' round totals;
- the commit that established the verification record is unverified;
- the five review rounds that failed to bound a `record` finding;
- the six half-applied sites on the first use of the supersession form;
- the merged change that existed only to correct a count.

## Self-review

1. D4, D5, D6 and D9 each have a test in T1 or a retargeted test in T2.
2. Every step contains the full text, command and expected output.
3. The helper names `gr_shape_exempt_skills`, `gr_ceiling_exempt_skills`,
   `gr_skill_headings`, `gr_skill_has_d9_order` and `gr_skill_words` are used
   consistently. The deslop pass renamed `gr_skill_shaped` to
   `gr_skill_has_d9_order`; see "After T2".
4. T1 and T2 share `tests/skills.bats`, so they run serially.

---

## After T2: the tree is authoritative

The file contents embedded in T1 and T2 are the text as the tasks wrote it.
These later commits changed that text, so from here the tree is
authoritative and the embedded blocks are history:

- `9991a60`, the deslop pass (`develop-change`). It rewrote prose under the
  writing rules, renamed `gr_skill_shaped` to `gr_skill_has_d9_order`, renamed
  the stale-exemption marker `:shaped` to `:in-order`, and rewrapped lines.
- `cf3f78c`, the round 1 fix below.
- `0dabaf3`, the round 2 fix below. It rewrote
  `skills/merge-change/references/rationale.md`.
- `00d9204`, `80f045e` and `86d4e14`, the round 3 fix below. It changed
  step 7 and step 6d of `skills/merge-change/SKILL.md`,
  `references/rationale.md` and the References test in `tests/skills.bats`.
- `47d0393` and `d3c6aba`, the round 4 fix below. It replaced the
  paragraphs of `references/rationale.md` that restated a script with
  pointers to the script's comments, and changed the References test and the
  "text the first rewrite lost is stated again" test in `tests/skills.bats`.
- `c4256df`, the round 5 fix below. It changed `references/rationale.md` and
  the "text the first rewrite lost is stated again" test in `tests/skills.bats`.
- `8199ae5` and `f4cc782`, the round 6 fix below, with the commit after them that
  edited this plan and `PR-2jr4pj`'s file. It removed every statement about a script from
  `references/rationale.md`, added "merge-change: the rationale file describes
  no script" to `tests/skills.bats`, and changed the References test and the
  "text the first rewrite lost is stated again" test.

## Round 1 fix (review round 1, findings 1 to 11)

**Status:** done, merged (task commit `cf3f78c`).

red -> green:
- merge-change: text the first rewrite lost is stated again — watched fail on the pre-fix skill (`The reviewer still reads the record and raises what is`), green after the edit script.
- merge-change: the tag does not shorten the sequence — each of its three assertions made live watched fail with its phrase appended to `references/rationale.md`, and pass once removed.

**Files touched:** `tests/skills.bats`, `skills/merge-change/SKILL.md`,
`skills/merge-change/references/rationale.md`,
`skills/merge-change/references/cleanup-rejections.md`,
`skills/merge-change/references/multi-unit.md`, `scripts/finish-merge.sh`,
`docs/plans/2026-09-28-agent-first-skills.md`
**Parallel:** no

Finding 7 rests on a measurement. In a scratch repository with `gpg.program`
set to a script that logs each call, `git commit -S` with nothing staged
printed `nothing to commit` and exited 1 without calling the signer. The
control, the same command with a file staged, called it (git 2.55.0). So
re-running the whole compound costs no key touch, and the header comment of
`scripts/finish-merge.sh` that states otherwise is corrected here. That is a
comment, not a behaviour change, and no mutation script quotes the line.

1. Append this test to `tests/skills.bats`, run it, and watch it fail on the
   current skill (`grep -q 'The reviewer still reads the record and raises
   what is'` fails first):

~~~~bash

@test "merge-change: text the first rewrite lost is stated again" {
    # verifies: D6 (docs/plans/2026-09-28-agent-first-skills.md)
    # Review round 1 of agent-first-skills found instructions from the old
    # skill that were neither kept nor listed as dropped history.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    rationale="$BATS_TEST_DIRNAME/../skills/merge-change/references/rationale.md"
    grep -q 'The reviewer still reads the record and raises what is' "$skill"
    grep -q 'name it so the user can run it' "$skill"
    grep -q 'consider two independent' "$skill"
    grep -q 'contains all four fields with values' "$skill"
    grep -q 'INCOMPLETE-RECORD' "$skill"
    grep -q 'With no worktree registered for the branch' "$skill"
    grep -q 'leave or remove it with the harness tool' "$skill"
    grep -q 'exempts nothing from' "$skill"
    grep -q 'not by its filename' "$skill"
    grep -q 'their shell has none of your variables' "$skill"
    grep -q 'Two open changes race on the base branch' "$rationale"
    grep -q 'cannot be re-identified one round' "$rationale"
    grep -q 'an unconditional commit exits 1 with nothing to' "$rationale"
    grep -q 'Nothing later repeats the `unrewritten` report' "$rationale"
    grep -q 'ORPHAN-ANNOTATION' "$rationale"
    run grep -q 'with two independent reviewers for critical' "$skill"
    [ "$status" -ne 0 ]
}
~~~~

2. Save this script outside the tree and run it from the worktree root. It
   exits non-zero, writing nothing, if any replacement does not match exactly
   once. It prints `round 1 fixes applied: 7 files`:

~~~~python
# Round 1 fixes for agent-first-skills (review round 1, findings 1-11).
# Run from the worktree root. Every replace must match exactly once, or the
# script exits non-zero before writing anything.
import sys
files = {}
def edit(path, old, new):
    text = files.get(path)
    if text is None:
        text = open(path).read()
    count = text.count(old)
    if count != 1:
        sys.exit("%s: expected one match, found %d:\n%s" % (path, count, old))
    files[path] = text.replace(old, new)

SK = "skills/merge-change/SKILL.md"
RA = "skills/merge-change/references/rationale.md"
CR = "skills/merge-change/references/cleanup-rejections.md"
MU = "skills/merge-change/references/multi-unit.md"
TB = "tests/skills.bats"

# finding-1: the three negated assertions become live
for phrase in ("'finding-free round'", "'runs only on the last round'",
               "'never reaches a later step\\.\\*\\* The paragraph below sends'"):
    edit(TB, "    ! grep -rq %s \"$(dirname \"$skill\")\"\n" % phrase,
         "    run grep -rq %s \"$(dirname \"$skill\")\"\n    [ \"$status\" -ne 0 ]\n" % phrase)

# finding-2: the reviewer still reads the record
edit(SK, "   as a gap, and rerun from step 1 — but no further reviewer is dispatched, and\n   the rerun ends at 6b.\n",
     "   as a gap, and rerun from step 1 — but no further reviewer is dispatched, and\n   the rerun ends at 6b. The reviewer still reads the record and raises what is\n   wrong with it. What changes is the price of a finding against it.\n")

# finding-3: name the compaction step
edit(SK, "   Recommend compacting the conversation before the next change; the plan, the\n   ledger and the record contain everything durable.\n",
     "   Recommend compacting the conversation before the next change; the plan, the\n   ledger and the record contain everything durable. If the harness offers a\n   compaction step, such as a `/compact` command, name it so the user can run it.\n")

# finding-4: two reviewers for class C stays advisory
edit(SK, "   reviewer, C a thorough review, with two independent reviewers for critical\n   items.\n",
     "   reviewer, C a thorough review. For class C, consider two independent\n   reviewers for critical items.\n")

# finding-5: step 6c states what the gate checks, and INCOMPLETE-RECORD
edit(SK, "   base branch it exits 2. Never answer a report by deleting a finding.\n\n   - `MISSING-RECORD` — step 6b did not happen for this branch.\n",
     "   base branch it exits 2. It checks that the record exists, declares this\n   branch, contains all four fields with values, and leaves no finding without\n   a disposition. Never answer a report by deleting a finding.\n\n   - `MISSING-RECORD` — step 6b did not happen for this branch.\n   - `INCOMPLETE-RECORD` — a required field is missing or has no value.\n")

# finding-6: the harness condition is a registered worktree
edit(SK, "   branch name; never pass it a path. If the harness tool already left or\n   removed the worktree, the script skips the removal and still deletes the\n   branch.\n",
     "   branch name; never pass it a path. If the harness created the worktree,\n   leave or remove it with the harness tool so its state stays consistent.\n   With no worktree registered for the branch, the script skips the removal\n   and still deletes the branch.\n")

# finding-7: the compound re-run costs no key touch; state why the script is re-run alone
edit(CR, "Re-running the whole compound does nothing: the squash is no longer staged,\nso `git commit` fails and `&&` stops before the script runs.\n",
     "Re-running the whole compound does nothing: the squash is no longer staged,\nso `git commit` fails and `&&` stops before the script runs. It also reads as\nthough the merge needs redoing. It does not: the merge is done, and only the\ncleanup is outstanding.\n")
edit("scripts/finish-merge.sh", "# `git commit` fails and `&&` short-circuits), but it wastes a key touch.\n",
     "# `git commit` fails and `&&` short-circuits). With nothing staged, git exits\n# before it invokes the signing program, so no key touch is spent either.\n")

# finding-8: dropped reasons and gate details, restored
edit(SK, "   - The test that verified the superseded item names both IDs:\n     `verifies: <old ID>, <new ID>`.\n",
     "   - The test that verified the superseded item names both IDs:\n     `verifies: <old ID>, <new ID>`. `superseded-by:` exempts nothing from\n     `MISSING-TEST`, so the dual annotation keeps it clean for both.\n")
edit(SK, "   - `branch:` — the change this record covers, matched whole.\n",
     "   - `branch:` — the change this record covers, matched whole. The gate finds\n     the record by this field, not by its filename.\n")
edit(SK, "   Hand the user exactly one command, with real paths and branch name\n   substituted, and **stop**:\n",
     "   Hand the user exactly one command, with real paths and branch name\n   substituted, because their shell has none of your variables, and **stop**:\n")
edit(RA, "## Step 1: the fetch, and putting the remote out of scope\n",
     "## Preconditions: one change at a time\n\n"
     "Two open changes race on the base branch, on the duplicate scan in step 4,\n"
     "and on the verification record. Each race surfaces here, at merge, rather\n"
     "than where it was created.\n\n"
     "## Step 1: the fetch, and putting the remote out of scope\n")
edit(RA, "## Step 3: the finalize date\n",
     "## Step 2: recording the tree\n\n"
     "A gate summary with no tree beside it cannot be re-identified one round\n"
     "later, and step 6 compares against this hash.\n\n"
     "## Step 3: the conditional commit and the unrewritten report\n\n"
     "On the second and later findings rounds the drafts are already dated, the\n"
     "script renames nothing, and an unconditional commit exits 1 with nothing to\n"
     "commit: a halt for no defect, in a sequence that stops at any failure.\n\n"
     "Nothing later repeats the `unrewritten` report. `DANGLING-FILE` at step 5\n"
     "reads the same scope the rewrite does, which is the gap this report closes.\n\n"
     "## Step 3: the finalize date\n")
edit(RA, "## Step 6a: the tag and the last review round\n",
     "## Step 6a: what the supersession gate reads\n\n"
     "`check-trace.sh` reads `supersedes:` and `superseded-by:` at column one\n"
     "inside an item's block, in every ledger. An orphaned half is\n"
     "`ORPHAN-ANNOTATION`. Both annotations are lists, so an item may replace\n"
     "several predecessors, and a second `supersedes:` line in a block adds to\n"
     "the first. A value with no readable ID is `MALFORMED-SUPERSESSION`, and so\n"
     "is one bad entry in a list of good ones: `supersedes: REQ-m7dq3v, REQ-nope`\n"
     "reports `REQ-nope` rather than recording half the list. Prose or a\n"
     "parenthetical after the list ends it and stays clean:\n"
     "`supersedes: REQ-m7dq3v (was REQ-001)`.\n\n"
     "## Step 6a: the tag and the last review round\n")

# finding-10: the multi-unit record sentence moves to its reference file
edit(SK, "   In a multi-unit repository,\n   the record also names the units touched, and the impact set.\n\n", "")
edit(MU, "The record at step 6b names the units touched and the impact set beside its\n`branch:` line.",
     "At step 6b, the record also names the units touched, and the impact set,\nbeside its `branch:` line.")
start = files.get(TB, open(TB).read()).index('@test "merge-record-names-units')
edit(TB, files[TB][start:].split("\n}\n")[0] + "\n}\n",
     files[TB][start:].split("\n}\n")[0].replace(
         'skills/merge-change/SKILL.md"', 'skills/merge-change/references/multi-unit.md"') + "\n}\n")

# finding-11: the proposal follows the replace list
PR = "docs/plans/2026-09-28-agent-first-skills.md"
edit(PR, "the tests that hold it,", "the tests that enforce it,")
edit(PR, "when change 1 lands are exempt", "when change 1 is merged are exempt")
edit(PR, "already hold them.", "already contain them.")
edit(PR, "do not intersect, holds for change 1 only.", "do not intersect, is true for change 1 only.")
edit(PR, "holds the interview rules.", "contains the interview rules.")

for path, text in files.items():
    open(path, "w").write(text)
print("round 1 fixes applied: %d files" % len(files))
~~~~

3. Prove finding 1's three assertions are live: append each phrase in turn to
   `skills/merge-change/references/rationale.md` and run
   `tests/.bats-core/bin/bats -f 'the tag does not shorten' tests/skills.bats`.
   Expected: `not ok` each time, and `ok` once the line is removed.
4. Run `tests/.bats-core/bin/bats` on `tests/skills.bats` (expected `1..82`,
   all ok), `tests/portability.bats` (all ok) and `tests/finish-merge.bats`
   (all ok).
5. Commit unsigned.


## Round 2 fix (review round 2, findings 12 to 14, and the gate's check 4)

**Status:** done, merged (task commit `0dabaf3`).

red -> green:
- merge-change: text the first rewrite lost is stated again, extended — watched fail on the pre-fix rationale file at its first new assertion, green once the reasons were added.

**Files touched:** `tests/skills.bats`, `skills/merge-change/references/rationale.md`,
`skills/merge-change/SKILL.md` (only if the sweep finds an instruction missing
from it), `docs/plans/2026-09-28-agent-first-skills-change-1.md`
**Parallel:** no

Finding 12 is the class finding 8 named, found again. So this fix sweeps the
class instead of the listed instances, and records the sweep.

1. **D4 has a verifying test (gate check 4).** In `tests/skills.bats`, add the
   line `    # verifies: D4 (docs/plans/2026-09-28-agent-first-skills.md)`
   directly below the existing `# verifies:` line of each test D4 changed that
   was watched failing because of the change. These are the tests named in the
   T2 and round 1 attestations above:
   - merge-change: a fix dispatch's tag is unique, and AGENTS.md defers on tags
   - merge-change: step 8 maps guard 4's rejection to a remedy
   - merge-consumes-impact-mechanically: the skill names the mode and forbids hand-picking
   - merge-runs-impact-set-gates: per-unit runs are spelled out
   - merge-finalizes-touched-units-only: the finalize loop is scoped
   - merge-change: the tag does not shorten the sequence

   Annotate no other test. A test never watched red under this change gets no
   D4 line.

2. **Sweep (finding 12's class).** Read `git show main:skills/merge-change/SKILL.md`
   paragraph by paragraph, including list items and red-flag rows. For each
   paragraph, find where each instruction, reason and statement of gate or script
   behaviour it contains now lives: `SKILL.md`, a file in `references/`, or the
   "What was dropped" list as incident history. Where one has no home:
   - an instruction goes into `SKILL.md` at its step, in one imperative line;
   - a reason or a gate or script detail goes into `references/rationale.md`,
     under a heading that names the step or rule it explains, in the order of
     the steps;
   - incident history goes into the "What was dropped" list above.

   The twelve items of finding 12 must each be covered. Write the result into
   this plan as a section `## Sweep of the old merge-change`, with one table
   row per paragraph of the old file: its line range in `main`, and where its
   content now is, or `dropped: history`. That table is the evidence the class
   was swept.

3. **Headings (finding 13).** Move the paragraph on draft files another change
   left behind out of "Step 3: the finalize date" into its own section,
   `## Steps 3 and 4: a draft another change left behind`, placed after the
   Step 3 sections. It covers the rename you do not recognise at step 3 and a
   `DRAFT-FILE` this change did not create at step 4. Keep the rationale file's
   headings accurate to what is under each.

4. **Tests.** Extend "merge-change: text the first rewrite lost is stated again"
   with one `grep -q` per item that step 2 adds, on a phrase from the added
   text, in the file it was added to. Watch the extended test fail before the
   text is added, and pass after it.

5. **Plan header (finding 14).** In this plan's header, the Verification line
   states that every test passes and that `tests/skills.bats` has 76 tests on
   `main` and 82 after the round 1 fix. The Safety class line states that the
   change touches skill text, tests, `AGENTS.md`, a comment in
   `scripts/finish-merge.sh`, and the proposal.

6. Run `tests/.bats-core/bin/bats` on `tests/skills.bats` (all ok) and
   `tests/portability.bats` (all ok). Run
   `wc -w skills/merge-change/SKILL.md` and report the count. Commit unsigned.

## Sweep of the old merge-change

**Superseded in part by the round 6 fix.** The table records where each paragraph's content was placed by the round 2 fix. The round 6 fix then removed every description of a script from `references/rationale.md`, deleted the headings that held only such descriptions, and removed the assertions on them. A row naming a rationale heading that no longer exists now maps to the script's own comments, and the closing claim below about one assertion per reason is no longer true. The tree is authoritative.

One row per paragraph, list item group or red-flag row of
`git show main:skills/merge-change/SKILL.md`. `SKILL` is
`skills/merge-change/SKILL.md`; `R:`, `MU` and `CR` are
`references/rationale.md` (by heading), `references/multi-unit.md` and
`references/cleanup-rejections.md`. A row that finding 12 named is marked
`(f12)`.

| main lines | where its content is now |
|---|---|
| 1-8 | SKILL front matter, title and announce line |
| 10-14 | SKILL Preconditions, items 2 and 3 |
| 16-18 | SKILL Preconditions, the `BASE=` block |
| 20-25 | SKILL Preconditions, "One change at a time"; R: Preconditions: one change at a time |
| 27-40 | SKILL Preconditions (pointer); MU, opening and first list |
| 42-48 | MU, second list |
| 50-52 | MU, last paragraph; R: Step 6b: the units in a multi-unit record |
| 56-63 | SKILL Steps, opening paragraph |
| 65-84 | SKILL Steps, second paragraph; R: Steps, opening paragraph: the fix dispatch tag is unique |
| 86-100 | SKILL step 1 and its block; R: Step 1 (the swallowed fetch) |
| 102-107 (f12) | SKILL step 1, first item; R: Step 1 (the local ref and its commit) |
| 109-115 | SKILL step 1, third item |
| 117-120 | SKILL step 1, fourth item, and step 4; R: Step 1 |
| 122-132 | SKILL step 1, second item; R: Step 1 (putting the remote out of scope) |
| 133-140 | SKILL step 2; MU (per unit) |
| 142-149 | SKILL step 2, the tree block; R: Step 2 |
| 150-162 | SKILL step 3, the block, the list and the paragraph after it |
| 164-174 | SKILL step 3, the `unrewritten` item; R: Step 3: the conditional commit and the unrewritten report |
| 176-182 | SKILL step 3, the last item; R: Steps 3 and 4: a draft another change left behind |
| 184-190 | SKILL step 3, the paragraph after the list; R: Step 3: the finalize date |
| 192-201 | SKILL step 3, the commit block; R: Step 3: the conditional commit and the unrewritten report |
| 203-206 (f12) | SKILL step 3, last paragraph; R: Step 3: there are no IDs to finalize |
| 207-210 | SKILL step 4; R: Step 1 (no base gate) |
| 212-215 (f12) | SKILL step 4, `MALFORMED-ID` item; R: Step 4: `MALFORMED-ID` |
| 217-224 | SKILL step 4, `DRAFT-FILE` item; R: Steps 3 and 4: a draft another change left behind |
| 225 | SKILL step 5 |
| 226-228 (f12) | SKILL step 6 head; R: Step 6: the tree hash decides re-verification (first paragraph) |
| 230-246 | SKILL step 6, block and paragraph; R: Step 6; R: Step 2 |
| 248-260 | SKILL step 6a, first paragraph and the reviewer's questions |
| 262-268 | SKILL step 6a, "The reviewer runs the suite itself"; R: Step 6a: the reviewer runs the suite |
| 270-277 (f12) | SKILL step 6a, second paragraph; R: Step 6a: the review worktree is nested; R: Step 6d: why the check comes before the squash |
| 279-296 | SKILL step 6a, the documentation checks |
| 298-305 | SKILL step 6a, last documentation check; R: Step 6a: what the supersession gate reads |
| 307-316 | R: Step 6a: what the supersession gate reads |
| 318-321, 324-325 | SKILL step 6a, last documentation check; R: Step 6a: what the supersession gate reads (`DANGLING-REF`) |
| 322-324 | dropped: history (the six half-applied sites) |
| 327-335 | SKILL step 6a, the finding shape and the verdict line |
| 337-348 | SKILL step 6a, the tag list; R: Step 6a: the tag and the last review round |
| 350-355, 358-360 | SKILL step 6a, "Every finding still sends the sequence back"; R: Step 6a: the tag and the last review round |
| 355-358 | dropped: history (the five review rounds) |
| 362-372 | SKILL step 6a, "A round raising no `code`"; R: Step 6a: the tag and the last review round |
| 372-377 | dropped: history (commit `328f0cfd`, the 27 rounds of three downstream changes) |
| 379-380 | SKILL step 6a, end of "A round raising no `code`" |
| 382-394 | SKILL step 6a, the removal block; R: Step 6a: where the review worktree is removed |
| 396-398 | SKILL step 6a, removal item 1 |
| 400-405 (f12) | SKILL step 6a, removal item 2; R: Step 6a: a round with no review worktree |
| 407-415 | SKILL step 6a, removal item 3; R: Step 6a: where the review worktree is removed |
| 417-423 | SKILL step 6a, removal item 4; R: Step 6a: a review worktree with scratch in it |
| 425-434 | SKILL step 6a, last paragraph |
| 436-444 | SKILL step 6b, first paragraph and list; R: Step 6b: the record is committed in the worktree |
| 446-453 | SKILL step 6b, the delta item; R: Step 6b: the delta, never the total |
| 454-455 | dropped: history (the change that existed only to correct a count) |
| 457-461 | R: Step 6b: the delta, never the total (no gate against count-shaped prose) |
| 463-472 | SKILL step 6b, the attestation item |
| 474-480 | R: Step 6b: the red → green attestations |
| 482-493 | SKILL step 6b, the four fields; R: Step 6b: the `reproduced:` field |
| 495 | MU, last paragraph |
| 497-502 | SKILL step 6b, the finding block |
| 504-507 | SKILL step 6c, first paragraph; R: Step 6c: what the record gate reports (exit 2) |
| 509-515 | SKILL step 6c, the verdict list; R: Step 6c: what the record gate reports (`STALE-RECORD`) |
| 517-526 | SKILL step 6d, head and block |
| 528-539 | SKILL step 6d, the exit list and the paragraph after it; R: Step 6d: what the check reads |
| 541-548 | SKILL step 6d, third exit item and the paragraph after the list; R: Step 6d: what the check reads |
| 550-555 | R: Step 6d: why the check comes before the squash |
| 557-564 | SKILL step 7, head and squash block |
| 566-572 | SKILL step 7, the message file; R: Step 7: the message file and the signing hand-over |
| 574-582 | SKILL step 7, the message block |
| 584-588 (f12) | SKILL step 7, the `Resolves:` paragraph; R: Step 7: `Resolves:` and `Opens:` |
| 590-595 | SKILL step 7, the hand-over and its block |
| 597-599 (f12) | SKILL step 7, "Never run `git commit -S` yourself"; R: Step 7: the message file and the signing hand-over |
| 601-612 | SKILL step 7, the four guards; R: Step 7: the message file and the signing hand-over |
| 614-619 | SKILL step 6d, last paragraph; R: Step 7: the message file and the signing hand-over |
| 621-622 | SKILL step 7, last paragraph |
| 624-629 (f12) | SKILL step 7, end of the guards paragraph; R: Step 7: the script is given the branch name |
| 630-636 | SKILL step 8, head and block |
| 638-644 (f12) | SKILL step 8, "Use `--strict`"; R: Step 8: `--strict` |
| 646-651 | SKILL step 8, the report paragraph |
| 653-656 | SKILL step 8, the cleanup paragraph; CR, opening |
| 658-664 (f12 for 660-662) | CR, the table; R: Step 8: the rejection table |
| 666-676 | SKILL step 8, last block; CR, last paragraph. The claim that the compound spends a key touch was false and was corrected in round 1 (finding 7) |
| 682-692 | SKILL Red flags, rows 1 to 11. Row 683's five review rounds: dropped: history. Row 686's reason: R: Step 7: the message file and the signing hand-over. Row 689's key touch: corrected in round 1 |
| 693 | SKILL Red flags, the `verdict:` row |
| 694 (f12) | SKILL Red flags, the deleted-finding row; R: Step 6c: what the record gate reports |
| 695-700 | SKILL Red flags, last six rows |

The sweep found no instruction missing from `SKILL.md`, so `SKILL.md` is
unchanged. It found no incident history beyond the list in "What was
dropped". Every reason and gate detail it found without a home is now under a
rationale heading, and "merge-change: text the first rewrite lost is stated
again" checks each one with a `grep -q`.

## Round 3 fix (review round 3, findings 16 to 18, 21 and 22; 19 and 20 booked)

**Status:** done, merged (task commits `00d9204`, `80f045e`, `86d4e14`).

red -> green:
- skill shape: the References section lists exactly the reference files, heading assertion — watched fail with an empty `## References` in a skill with no reference file.
- the same test, entry-form assertion — watched fail with an entry lacking `— read when`.

**Files touched:** `tests/skills.bats`, `skills/merge-change/SKILL.md`,
`skills/merge-change/references/rationale.md`,
`docs/plans/2026-09-28-agent-first-skills-change-1.md`, and a new problem
ledger draft `docs/problems/DRAFT-agent-first-skills-inherited-cleanup-claims.md`
**Parallel:** no

The maintainer decided the scope on 2026-09-29: fix the findings this change
introduced, and open problem reports for findings 19 and 20, which describe
defects already on `main`. Change 2 rewrites that procedure and is where they
are resolved. `docs/verification/` is the dispatcher's and is not touched here.

1. **Finding 17, test first.** In `tests/skills.bats`, extend
   "skill shape: the References section lists exactly the reference files" so
   that it also fails:
   - when a `## References` heading is present and the skill has no reference
     file, since D9 states the section is omitted then;
   - when a line in the `## References` section that opens with `- ` does not
     have the form ``- `references/<name>.md` — read when …``, since D9
     requires each entry to name the file and the condition for reading it.

   Watch each new failure in a scratch copy (an empty `## References` in a
   skill with no `references/` directory; an entry with no `— read when`),
   then confirm the tree passes. `merge-change`'s three entries already have
   that form. Every assertion you add must be able to fail.

2. **Finding 16.** In `skills/merge-change/SKILL.md` step 7, number the four
   things `finish-merge.sh` proves with the script's own guard numbers, in the
   order it proves them: guard 1 the signature, guard 2 the empty diff, guard 4
   no registered worktree inside, proved before guard 3, and guard 3 the
   removal without `--force`, which fails on a dirty worktree. In step 6d,
   state that the check answers guard 4 only: guards 1 and 2 read the squash
   commit, which does not exist yet, and guard 3 is the removal itself. Keep
   the phrase `proves four things` on one line; a test pins it.

3. **Finding 18.** In `references/rationale.md`, replace the sentence
   "Widening a pattern to accept the token keeps the item invisible and
   removes the report." with the true cost: `check-ids.sh` and `check-trace.sh`
   share one ID pattern (`gr_def_re` and `GR_ID_BODY` in `scripts/lib.sh`), so
   widening it makes the item visible to every gate and admits, everywhere, an
   ID that `new-id.sh` did not mint and whose form the pattern exists to reject.
   Then re-read every sentence the round 2 sweep added to that file against the
   script it describes, and correct any other false one. Report which you
   checked.

4. **Findings 19 and 20, booked.** Create
   `docs/problems/DRAFT-agent-first-skills-inherited-cleanup-claims.md` with
   this content. Do not name that file anywhere else; `finalize-docs.sh` renames
   it at merge:

   ~~~~markdown
   # Problem reports — cleanup claims inherited from the old merge-change

   Two items found by the independent review of `agent-first-skills`, round 3,
   in text that predates that change. `affects:` names files, because guardrails
   keeps no REQ/SDD/LLR ledger of its own. Both are for change 2 of
   `docs/plans/2026-09-28-agent-first-skills.md`, which scripts this procedure.

   **PR-zmzav3**: Two comments state that re-running `finish-merge.sh` costs a hardware key touch per run, but a re-run only verifies a signature, which uses no private key.
   affects: scripts/finish-merge.sh, the comment on reporting every nested worktree at once; tests/finish-merge.bats, the comment in "finish-merge: every nested worktree is named, not just the first".
   opened: 2026-09-29
   status: open
   Measured for the whole compound on 2026-09-28 with git 2.55.0: with nothing
   staged, `git commit -S` exits 1 without calling `gpg.program`. The script
   alone calls `check-signing.sh --strict`, which verifies and does not sign.
   The rule the comments support, to report every nested worktree in one run,
   is still right: it saves re-runs. Only the stated cost is wrong.

   **PR-sa5y4k**: `merge-change` states that a non-zero exit from `finish-merge.sh` removed nothing, but the script exits 1 after removing the worktree when `git branch -D` then fails.
   affects: skills/merge-change/SKILL.md step 8; skills/merge-change/references/cleanup-rejections.md, its opening sentence and its table, which has no row for this case; scripts/finish-merge.sh, the `git branch -D` failure path.
   opened: 2026-09-29
   status: open
   The old skill made the same claim. The message the script prints on this
   path, `the worktree was removed but <branch> could not be deleted`, is
   accurate; the skill text around it is not.
   ~~~~

5. **Finding 21.** In this plan's section "After T2: the tree is
   authoritative", replace "Two later commits changed that text" with a list
   that names every commit after T2 that changed embedded text: `9991a60`, the
   round 1 fix `cf3f78c`, the round 2 fix `0dabaf3`, and this round's fix.
   State no count.

6. Run `tests/.bats-core/bin/bats` on `tests/skills.bats` and
   `tests/portability.bats` (all ok), and
   `GR_CONFIG=/private/tmp/claude-501/-Users-jan-jan-Coding-guardrails/436bede3-b0ee-4508-977d-45cfac2ac37a/scratchpad/gate/gr-config.yaml sh scripts/check-trace.sh`
   and report the lines for PR-zmzav3 and PR-sa5y4k. Commit unsigned.

Finding 22 is the record's, and the dispatcher fixes it at step 6b.

## Round 4 fix (review round 4, findings 23 to 26 and 28; the rationale file points, not restates)

**Status:** done, merged (task commits `47d0393`, `d3c6aba`, `47cd0b3`).

red -> green:
- the References test, entry form — watched fail with the section as one prose line and with a `* ` bullet with no condition.
- the References test, heading — watched fail with `## References ` and a trailing space in a skill with no reference file.
- text the first rewrite lost, pointer assertions — watched fail against the pre-change rationale file, and on the script side with the cited phrase removed from `check-trace.sh`, `new-id.sh` and `finish-merge.sh`.

**Files touched:** `tests/skills.bats`, `skills/merge-change/references/rationale.md`,
`AGENTS.md`, `docs/problems/2026-09-29-inherited-cleanup-claims.md`,
`docs/plans/2026-09-28-agent-first-skills-change-1.md`, and
`skills/merge-change/SKILL.md` only if a pointer needs a matching edit there
**Parallel:** no

The maintainer decided the scope on 2026-09-29. Findings 18 and 23 are both
sentences in `references/rationale.md` that restate what a script does and
drifted from it. The fix removes the class: where a script's own comments
already state a behaviour, the rationale file points to them instead of
restating them. Findings 27 and 29 are the record's; the dispatcher fixes them.

1. **Finding 24, test first.** In "skill shape: the References section lists
   exactly the reference files", make the entry-form check read every
   non-blank line of the `## References` section after the heading, not only
   lines opening with `- `. Each such line must have the form
   ``- `references/<name>.md` — read when …``, or continue the previous entry
   as an indented line. Make the heading check match `## References` followed
   by optional trailing whitespace. Watch each fail in a scratch copy: a
   References section rewritten as one prose line naming the files, a `* `
   bullet with no condition, and `## References ` with a trailing space in a
   skill with no reference file. Then confirm the tree passes.

2. **Point, not restate.** Go through `references/rationale.md` section by
   section. Where a paragraph states how a script behaves, find the comment in
   that script that states it: usually the header, sometimes a comment at the
   function. If the script states it, replace the paragraph with one line
   naming the script and the comment, in the form
   `` `scripts/<name>.sh`, header: <what it explains>. `` or
   `` `scripts/<name>.sh`, the comment at `<function>`: <what it explains>. ``
   If the script does not state it, keep the sentence, verify it against the
   code, and correct it if false. Keep paragraphs that give the reason for an
   agent's process rule and describe no script, such as why the message file
   is outside the repository, why the agent never signs, one change at a
   time, and the convergence rule.
   - This covers finding 23: the ID paragraph points to the `scripts/new-id.sh`
     header, which states that collisions are detected, not prevented, and to
     the `scripts/check-ids.sh` header for the scan.
   - The "text the first rewrite lost is stated again" test greps phrases in
     the rationale file. For each phrase whose paragraph becomes a pointer,
     change the assertion to two: the rationale file contains the pointer, and
     the named script contains a phrase from the comment the pointer cites.
     Each assertion must be able to fail.

3. **Finding 25.** In `AGENTS.md`, the sentence on the exemptions names D5
   for the ceiling and D3 item 3 for the section order, not D9.

4. **Finding 26.** In `docs/problems/2026-09-29-inherited-cleanup-claims.md`,
   `PR-sa5y4k`'s body states that the message `the worktree was removed but
   <branch> could not be deleted` is accurate only on the path that removed a
   worktree. On the path where no worktree was registered, the script prints
   the same message and it is false. Add that path to `affects:`. Edit in
   place.

5. **Finding 28.** In this plan, remove
   `skills/merge-change/references/cleanup-rejections.md` from the round 3
   "Files touched" line. In "After T2: the tree is authoritative", give the
   round 3 bullet its SHAs, `00d9204`, `80f045e` and `86d4e14`, and add a
   bullet for this round's fix.

6. Run `tests/.bats-core/bin/bats` on `tests/skills.bats` and
   `tests/portability.bats` (all ok). Report `wc -w` for the four
   `skills/merge-change` files. Commit unsigned.

## Round 5 fix (review round 5, findings 30 and 32)

**Status:** done, merged (task commit `c4256df`).

red -> green:
- text the first rewrite lost, the two absence assertions — each watched fail with its removed pointer appended back to the rationale file, and pass once restored.

**Files touched:** `skills/merge-change/references/rationale.md`,
`tests/skills.bats`, and a new problem ledger draft
`docs/problems/DRAFT-agent-first-skills-id-allocation-claim.md`
**Parallel:** no

The claim finding 30 traces is in nine files across the toolkit and predates
this change, so by the maintainer's round 3 rule it is booked, as `PR-2jr4pj`,
not fixed here. This change's own text stops pointing into it: the step 1
pointer becomes a sentence verified against the code, and the two pointers that
duplicate the `scripts/new-id.sh` pointer beside them are removed. Findings 31
and 32 are the dispatcher's; the plan header was corrected with this section.

1. Save this script outside the tree and run it from the worktree root. It
   exits non-zero, writing nothing, if any replacement does not match exactly
   once, and prints `round 5 fixes applied: 3 files`. Do not name the draft
   ledger file anywhere else:

~~~~python
# Round 5 fix for agent-first-skills (findings 30 and 32). Run from the
# worktree root. Every replace must match exactly once, or nothing is written.
import sys
files = {}
def edit(path, old, new):
    text = files.get(path)
    if text is None:
        text = open(path).read()
    count = text.count(old)
    if count != 1:
        sys.exit("%s: expected one match, found %d:\n%s" % (path, count, old))
    files[path] = text.replace(old, new)

RA = "skills/merge-change/references/rationale.md"
TB = "tests/skills.bats"
PL = "docs/plans/2026-09-28-agent-first-skills-change-1.md"

# finding-30: no pointer leads into the check-ids.sh or finalize-docs.sh
# comments that state IDs are allocated against nothing (PR-2jr4pj)
edit(RA, "`scripts/check-ids.sh`, header: there is no gate against the base branch, and\n`DUPLICATE-ID` sees the base's IDs because step 1 merged the base first.\n",
     "`check-ids.sh` has no gate against the base branch. Its `DUPLICATE-ID` scan\nreads only the tree, and sees the base's IDs because step 1 merged the base\nfirst.\n")
edit(RA, "\n`scripts/check-ids.sh`, header: the case where random draws collide is caught\nby `DUPLICATE-ID` after the step 1 merge.\n", "")
edit(RA, "\n`scripts/finalize-docs.sh`, header: why nothing is assigned at merge.\n", "")
edit(TB, "    grep -qF '`scripts/check-ids.sh`, header: the case where random draws collide' \"$rationale\"\n    grep -qF 'the vanishing case where' \"$scripts/check-ids.sh\"\n",
     "    # Review round 5, finding 30: no pointer leads into a comment that states\n    # IDs are allocated against nothing (PR-2jr4pj).\n    run grep -qF '`scripts/check-ids.sh`, header' \"$rationale\"\n    [ \"$status\" -ne 0 ]\n    run grep -qF '`scripts/finalize-docs.sh`, header: why nothing is assigned' \"$rationale\"\n    [ \"$status\" -ne 0 ]\n")


LEDGER = "docs/problems/DRAFT-agent-first-skills-id-allocation-claim.md"
files[LEDGER] = """# Problem reports — the claim that IDs are allocated against nothing

One item found by the independent review of `agent-first-skills`, round 5, in
text that predates that change. `affects:` names files, because guardrails
keeps no REQ/SDD/LLR ledger of its own. Change 3 of
`docs/plans/2026-09-28-agent-first-skills.md` rewrites most of these files.

    **PR-2jr4pj**: Nine files state that an item ID is allocated against nothing, and three of them that two branches cannot mint the same ID by construction, but `new-id.sh` discards a candidate already in the tree and a collision with another branch is possible and is detected by `DUPLICATE-ID`.
affects: scripts/check-ids.sh, the header paragraph on the base-branch gate; scripts/finalize-docs.sh, the header paragraph on IDs; AGENTS.md, non-negotiable 5; skills/ratchet/SKILL.md, the upgrade note on random IDs; skills/worktree-discipline/SKILL.md, "Mint the ID now"; templates/AGENTS-block.md; templates/problems.md; templates/srs.md; docs/problems/README.md.
opened: 2026-09-29
status: open
The `scripts/new-id.sh` header states the behaviour exactly: collisions are
detected, not prevented, with a stated probability. The other texts overstate
it. `scripts/check-ids.sh` names the collision case in the same sentence as
"vanishing", so the gate is right and the prose around it is not. The
`merge-change` reference file for `agent-first-skills` points only to
`scripts/new-id.sh` for this reason.
"""

for path, text in files.items():
    open(path, "w").write(text)
print("round 5 fixes applied: %d files" % len(files))
~~~~

2. Watch the two new absence assertions in "text the first rewrite lost is
   stated again" fail: append each removed pointer back to the rationale file in
   turn and run the test, then restore the file.
3. Run `tests/.bats-core/bin/bats` on `tests/skills.bats` (`1..82`, all ok) and
   `tests/portability.bats` (all ok). Commit unsigned.

## Round 6 fix (review round 6, findings 33 to 36, and the gate's DUPLICATE-ID)

**Status:** done, merged (task commits `8199ae5`, `f4cc782`, `e266ba8`).

red -> green:
- merge-change: the rationale file describes no script — watched fail on the old file, listing each line naming a script; green once stripped.
- skill shape: the References section lists exactly the reference files — watched fail with a file named only on another entry's continuation line; the old test passed that copy.

**Files touched:** `skills/merge-change/references/rationale.md`,
`tests/skills.bats`, `docs/problems/2026-09-29-id-allocation-claim.md`,
`docs/plans/2026-09-28-agent-first-skills-change-1.md`
**Parallel:** no

The maintainer decided the scope on 2026-09-29. Rounds 3 to 6 found defects
in the rationale file's statements about scripts and in the comments its
pointers led to. The rationale file therefore stops describing scripts at all.
It keeps only the reasons behind the agent's process rules. An agent that
needs a script's behaviour reads the script, whose comments are the authority.

1. **Test first: the rationale file names no script.** Add a test to
   `tests/skills.bats`:
   `merge-change: the rationale file describes no script`, with
   `# verifies: D6 (docs/plans/2026-09-28-agent-first-skills.md)`. It fails
   when `skills/merge-change/references/rationale.md` contains `scripts/` or
   a word ending in `.sh`. Watch it fail on the current file.

2. **Strip the rationale file.** Remove every pointer to a script, and every
   sentence whose subject is what a script does, prints, reads or exits with.
   Keep each reason for a rule the agent follows: one change at a time, the
   fix dispatch tag, the fetch trade and the local-ref record, recording the
   tree, the conditional commit, the finalize date as a handle, a draft
   another change left behind, the tree hash deciding re-verification, the
   reviewer running the suite, the nested review worktree and where it is
   removed, the tag and the last review round, the delta and not the total,
   the red → green attestations, the message file outside the repository,
   the signing hand-over, never passing a path, `--strict`, and re-running the
   cleanup alone. Where such a reason needs a gate's name, name the report
   (`DUPLICATE-ID`, `DANGLING-FILE`), not the script. Keep each heading
   accurate to what is under it; delete a heading left empty. Keep the five
   phrases the fix-dispatch tag test pins, rewording "after a full
   `check-signing.sh --strict` run" so it names no script.

3. **Tests follow the file (D4).** In "merge-change: text the first rewrite
   lost is stated again", remove each assertion on a pointer or on a script
   file, and each on a phrase this step removed. Keep the assertions on
   reasons that remain. The two round 5 absence assertions are replaced by
   step 1's test.

4. **Finding 35.** In "skill shape: the References section lists exactly the
   reference files", collect the listed file names only from entry lines,
   the lines opening with ``- `references/``. A file named only on a
   continuation line or in prose then counts as unlisted. Watch it fail in a
   scratch copy with the rationale entry deleted and the file named on the
   cleanup-rejections entry's continuation line, then confirm the tree passes.

5. **Ledger.** In `docs/problems/2026-09-29-id-allocation-claim.md`, change
   the sentence on the `merge-change` reference file to state that it names
   no script. Edit in place.

6. **The gate's DUPLICATE-ID.** In this plan's round 5 section, the embedded
   script quotes `PR-2jr4pj`'s definition line at column one. Indent that one
   line by four spaces, so it defines nothing; the file the script created is
   the definition. Then run
   `GR_CONFIG=/private/tmp/claude-501/-Users-jan-jan-Coding-guardrails/436bede3-b0ee-4508-977d-45cfac2ac37a/scratchpad/gate/gr-config.yaml sh scripts/check-ids.sh`
   and confirm `DUPLICATE-ID PR-2jr4pj` is gone.

7. **Finding 36.** In "After T2: the tree is authoritative", add the round 5
   task commit `c4256df` and a bullet for this round's fix.

8. Run `tests/.bats-core/bin/bats` on `tests/skills.bats` and
   `tests/portability.bats` (all ok). Report `wc -w` for the rationale file.
   Commit unsigned.
