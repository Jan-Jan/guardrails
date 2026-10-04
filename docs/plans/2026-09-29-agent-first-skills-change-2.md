# Agent-first skills, change 2: procedures become scripts

**Goal:** Script the three procedures D7 names, print a remedy line per rule
(D8), and bring `merge-change` under the D5 ceiling by pointing it at the
scripts instead of describing them.
**Implements:** D7 and D8 of `docs/plans/2026-09-28-agent-first-skills.md`
(D3 item 2), and D5 for `merge-change`. Resolves `PR-zmzav3` and `PR-sa5y4k`
(`docs/problems/2026-09-29-inherited-cleanup-claims.md`), and `PR-tz6gsp`
(`docs/problems/2026-10-04-base-branch-git-failure.md`), a defect inherited
from `main` that the git-call audit after review round 16 found and fixed;
round 17 found that no item had been opened for it. No REQ items exist in this repository.
**Safety class:** the toolkit is unclassified; the class B rules in `AGENTS.md`
apply. This change adds two scripts (`task-worktree.sh`, `merge-preflight.sh`)
and changes the output of three (`check-trace.sh`, `check-ids.sh`,
`finish-merge.sh`).
**Verification:** `sh tests/run-tests.sh` — every test passes. `check-ids.sh`
and `check-trace.sh` under `scratchpad/gate/gr-config.yaml` report nothing that
a clone of `main` does not also report.

Run single bats files with `tests/.bats-core/bin/bats <file>`, never with
`tests/run-tests.sh <file>`. A fresh task worktree lacks the gitignored
`tests/.bats-core`; copy it from the change worktree first.

**`tests/check-trace.bats` is edited as little as possible.** The open change
`assertion-gate` edits it. Behaviour tests for `check-trace.sh` and
`check-ids.sh` remedy lines go in the new `tests/remedies.bats`. As built, two
edits reached the file: one anchored count (T1) and the shared `setup()` fixture
moved to `write_traced_docs` in `tests/helpers.bash` (deslop, `b0bcddf`).
`git merge-tree` of `b0bcddf` with `assertion-gate` exits 0: no conflict.

Every script is POSIX `sh`, uses only git, grep, awk and sed, and follows the
header form of `scripts/finish-merge.sh`: usage line, what it does, exit codes
(0 pass, 1 a check failed, 2 usage or environment). Every new test body obeys
`tests/portability.bats` and the assertion rules of `70cd996`: no bare `!`
before a command mid-test, and no `[[ ]]` or `(( ))` — use `run` and
`[ "$status" -ne 0 ]`.

Every task that edits a script line greps
`docs/verification/*.mutations/` for each changed line first
(`develop-change` step 6), and re-cuts any anchor it breaks.

The remedy form of `check-trace.sh` and `check-ids.sh` (D8), which
`tests/remedies.bats` enforces:

```
fix <RULE>: <one imperative sentence, at most 200 characters>
```

`task-worktree.sh` and `merge-preflight.sh` use the same `fix <RULE>:` prefix,
but a remedy for a task or review worktree states several cases and is longer
than one sentence; review rounds 3 to 5 made it so. `finish-merge.sh` keeps
its own rejection messages and prints no `fix` line.

In `check-trace.sh` and `check-ids.sh`, one line per distinct rule that fired, after the violation lines and before
any `checked:`, `problems:` or `sources:` line, in the order the rules first
fired. Violation lines keep their documented form.

---

### T1 — remedy lines in check-trace.sh and check-ids.sh (D8)

**Status:** done, merged as `871daf3` (task commits `d69c7ef`, `cb676c8`).

red -> green:
- check-trace: one fix line per rule that fired, after the violations — watched fail (no fix line; violations went straight to `checked:`).
- check-trace: every report in the roster has a remedy — watched fail (all 25 roster tokens had no remedy entry).
- check-trace: a warning-only run prints its fix lines and exits 0 — watched fail (no `fix UNRESOLVED-PR` line).
- check-ids: one fix line per rule that fired — watched fail (violations printed, no fix line).
- check-ids: the remedy for a draft ID names new-id.sh — watched fail (no fix line).
- check-ids: --allow-draft-files prints no fix line for a draft file — watched fail (the no-flag half found no `fix DRAFT-FILE` line).
- check-trace: a clean run prints no fix line, and check-trace: violation lines are unchanged — green on arrival: regression guards, which cannot be red first.

Deviations: `check-ids.sh` had two stderr paragraphs, not three. Mutations M21,
M24 and M54 of `2026-08-22-id-tokens` quoted the removed stderr lines and were
re-cut; each applies and fails tests (M21 6, M24 2, M54 2). One line of
`tests/check-trace.bats` changed after all: "an overlapping doc_* reports an
orphan once, not twice" counted the token unanchored, so the `fix` line doubled
its count. The dispatcher anchored it (`cb676c8`). `assertion-gate` edits other
hunks of that file, so the two do not conflict.

**Files touched:** `scripts/check-trace.sh`, `scripts/check-ids.sh`,
`tests/remedies.bats`
**Parallel:** yes (with T3, T4, T5)

1. RED — create `tests/remedies.bats` (`load helpers`, fixtures in the shape
   `tests/check-trace.bats` and `tests/check-ids.bats` already build). Each
   test has `# verifies: D8 (docs/plans/2026-09-28-agent-first-skills.md)`.
   - `check-trace: one fix line per rule that fired, after the violations` —
     a fixture that fires `MISSING-TEST` twice and `DANGLING-REF` once prints
     exactly two `fix ` lines, `fix MISSING-TEST:` before `fix DANGLING-REF:`,
     both after the last violation line and before `checked:`.
   - `check-trace: a clean run prints no fix line`.
   - `check-trace: violation lines are unchanged` — in the same fixture's
     output, each of the three violation lines matches its documented text
     exactly. The test reads no git history.
   - `check-trace: every report in the roster has a remedy` — for every token
     in the `#   TOKEN` roster of the script header (default and scoped
     reports), the script contains exactly one remedy entry. The extraction is
     the one `tests/skills.bats` test "check-traceability: every report a
     single-unit check-trace.sh run prints has a catalogue row" already uses
     for the roster; it floors at 15 tokens so an empty extraction fails.
   - `check-trace: a warning-only run prints its fix lines and exits 0` —
     `UNRESOLVED-PR` alone.
   - `check-ids: one fix line per rule that fired` — `DUPLICATE-ID` and
     `MALFORMED-ID` in one fixture; one `fix` line each, after the violations.
   - `check-ids: the remedy for a draft ID names new-id.sh` — `DRAFT-ID`
     fixture; the `fix DRAFT-ID:` line contains `new-id.sh`.
   - `check-ids: --allow-draft-files prints no fix line for a draft file`.
   Run the file; every test but the clean-run ones fails for the right
   reason (no `fix` line exists).
2. GREEN — in each script, add one remedy table, keyed by report token, as a
   single `case` or awk map next to the roster, and one emitter that prints
   the `fix` lines for the tokens that fired. The remedy text is the "Fix"
   column of `skills/check-traceability/SKILL.md`, "Fixing each rule",
   condensed to one imperative sentence; where a row gives several cases,
   the line names the commonest and ends `— see the script header`.
   `check-ids.sh`'s three stderr paragraphs (after `DRAFT-ID`, `MALFORMED-ID`
   and the draft-file case) become its `fix` lines on stdout; delete the
   stderr text. Tests that pinned that stderr text are retargeted to the
   `fix` line (D4), keeping their `verifies:` lines.
3. Run `tests/remedies.bats`, `tests/check-trace.bats`, `tests/check-ids.bats`,
   `tests/check-units.bats`, `tests/units-chain.bats` and
   `tests/mutations.bats`. All pass.
4. Commit: `feat: check-trace and check-ids print one remedy line per rule`.

### T2 — the fix table becomes a pointer (D7 procedure 2)

**Status:** done, merged as `fa4867d` by `task-worktree.sh finish t2` (task
commit `7522636`). check-traceability was 2,473 words after T2, down from 4,894 (2,490 after the round 1 fix); it stays
exempt.

red -> green:
- check-traceability: the fix table is a pointer to the remedy lines — watched fail (the `## Fixing each rule` heading was present).
- Five retargeted tests in `tests/remedies.bats` (PR-6d2jvt, PR-9xxz3b, PR-4fwfjp twice, PR-n274s7, PR-58zsvf) — green on arrival, since T1 already prints the remedies; each was shown to fail by altering its remedy text or case, then reverted.

For T6, from T2's D6 sort — actions the removed table stated that neither the
remedy line nor the script header states. Place each in the
`scripts/check-trace.sh` header roster entry for its rule (`check-ids.sh` for
DUPLICATE-ID):

- MISSING-TEST: never annotate a test that does not verify the behaviour; an LLR test goes at the software item's own interface.
- UNANALYZED-DERIVED: several items may share one `assesses:` line.
- UNMITIGATED-HAZARD: the alternative is to record the acceptability rationale and control in the RMF.
- UNIMPLEMENTED-CONTROL: for a non-software control, note the external implementation in the RMF item; add an implementing REQ only if software is part of it.
- DANGLING-REF: deleting a defined item is a change that needs its own review.
- DANGLING-FILE: usual causes are a draft another change merged and renamed, or a draft in another unit; `finalize-docs.sh` does not rewrite a relative link, a name in emphasis or a name joined to a longer word; plans and verification records are not scanned; a reference to an existing draft passes; a bare name resolves against this unit's ledger directories only, so across units write the path.
- MISPLACED-ITEM: adding the stray file to `strict_paths` does not fix it; a `doc_*` directory resolves to its `*.md` files one level deep; a single-file `doc_*` resolves whatever its extension; indent an illustrative ID or keep it inline; never leave `**REQ-NNN**:` at the start of a line (MALFORMED-ID).
- ORPHAN-ANNOTATION: the three cases (before the first item; under a heading with no item since; inside a block whose prefix's gate does not read the keyword, usually the wrong item); move a separating heading before the item or drop it; an illustrative line needs indentation with no list marker, or inline backticks; which ledger each keyword is reported in; `mitigates:`, `implements:`, `verifies:` and `assesses:` cannot be orphaned.
- ACCEPTED-PR: never set `accepted` because PROBLEM-BACKLOG is failing; `resolve-problem` §4 has the form.
- INCOMPLETE-PROBLEM: a resolved item needs no `opened:`, so an existing ledger backfills only its open items.
- MALFORMED-DATE: the age is computed in local time from `date +%Y-%m-%d`; tomorrow counts as 0 days old.
- STALE-PROBLEM: `accepted` is the answer when the item is real but its fix is not this change's; `resolve-problem` requires the ruling first.
- PROBLEM-BACKLOG: the count includes open items with no usable `opened:` and excludes items whose status cannot be read.
- NON-RECIPROCAL-SUPERSESSION: each predecessor in a list is judged alone; if the two IDs are not a replacement pair, remove both halves and state the relationship in prose.
- MALFORMED-SUPERSESSION: prose or a parenthetical after the ID list ends it and is not reported.
- DUPLICATE-ID: a copy-pasted item is the usual cause.

Also for T6: the `scripts/check-trace.sh` comment near line 530 states that the
MISPLACED-ITEM exceptions are stated in `skills/check-traceability/SKILL.md`,
which no longer states them; correct it. The PR-58zsvf test
"merge-step-3-reports-rewrites" now greps `skills/merge-change/SKILL.md` for
`relative link`; keep that phrase in step 3.

**Files touched:** `skills/check-traceability/SKILL.md`, `tests/skills.bats`,
`tests/remedies.bats`
**Parallel:** no (serial, after T1)

1. RED — in `tests/skills.bats`, retarget "check-traceability: every report a
   single-unit check-trace.sh run prints has a catalogue row" (verifies
   `PR-6d2jvt`) under D4: move it to `tests/remedies.bats` as
   `check-trace: every report it prints has a remedy line`, keeping
   `# verifies: PR-6d2jvt` and adding D8. Its second half (every printed
   report is in the roster) is kept as it stands. Add to `tests/skills.bats`:
   `check-traceability: the fix table is a pointer to the remedy lines` —
   the skill has no `## Fixing each rule` heading and contains the string
   `fix <RULE>:`. Watch it fail.
2. GREEN — replace "Fixing each rule" and its table with a short section,
   `## Reading a finding`: every run prints one `fix <RULE>:` line per rule
   that fired; follow it; the script header documents each rule in full.
   Sort the table's "Meaning" text by D6: a sentence an agent needs to act on
   a finding and that the remedy line and the script header both lack goes
   into the script header's roster entry for that rule. The script is not in
   this task's file list, so list each such sentence in the task report under
   `surprises:`; T6 places it. Delete the rest.
3. Every other test in `tests/skills.bats` that pinned text of the removed
   table is retargeted under D4: to the remedy line in `tests/remedies.bats`
   where the text was a fix, with its `verifies:` line kept. List each
   retargeted test in the report.
4. Run `tests/skills.bats` and `tests/remedies.bats`. All pass.
5. Commit: `feat: check-traceability points at the remedy lines`.

### T3 — the task-worktree lifecycle script (D7 procedure 1)

**Status:** done, merged as `78f54f8` (task commit `4ad2f09`).

red -> green: all 20 tests in `tests/task-worktree.bats` — watched fail before
the script existed (exit 127, script not found), then pass.
"copies ignored entries, but not .worktrees/ or .claude/" failed a second time
against the first script version for a real defect (`tests/.bats-core` copied
into itself) and passed after the fix.

Open after T3: adding a script breaks three pinned counts outside T3's files —
`tests/check-ids.bats` "every gr_def_re call site is still a call site, and no
copy joins them" and "every script parses as POSIX sh", and `tests/lib.bats`
"every script stops outside a git repository, at gr_root". T4 adds a second
script, so they are fixed once, after T4 merges.

**Files touched:** `scripts/task-worktree.sh`, `tests/task-worktree.bats`
**Parallel:** yes (with T1, T4, T5)

Interface, run from the change worktree (the change branch is its current
branch; the script derives it):

```
task-worktree.sh start <tag>     # create .worktrees/<change-branch>-<tag>
task-worktree.sh merge <tag>     # merge it back, remove it, delete its branch
task-worktree.sh remove <tag>    # remove it without merging; rejects a branch with commits
task-worktree.sh discard <tag>   # list its commits, remove it, delete the branch with them
```

As written for T3 the merging command was `finish`. Review added
`finish --no-merge` (round 1 finding 1) and `discard` (round 3 finding 13);
after round 4 the maintainer's ruling renamed `finish` to `merge` and
`finish --no-merge` to `remove` (see "Decision after review round 4"). Every
command acts only on the nested task worktree. The tree and the script header
are authoritative; the specification below is updated to the names.

Every command first checks the change worktree for an operation in progress
(a merge, cherry-pick, revert or rebase, or unmerged entries) and rejects with
`fix CHANGE-BUSY:` (round 14 finding 69, round 15 finding 71). The remedy
concludes or aborts the operation, then returns to the dispatcher's step.
Under `start`, which a dispatched subagent runs, the remedy states that the
operation is the dispatcher's, that the subagent stops and reports the line,
and that the dispatcher concludes or aborts it (round 21 finding 92); for
the merge of the command's own task branch, concluding it is followed by
`remove`. Each remedy that concludes a merge names `git -c
commit.gpgsign=false commit --no-edit`, so it runs with no editor (round 20
finding 89), and the rebase remedy names `git -c commit.gpgsign=false -c
core.editor=true rebase --continue` (round 21 finding 90). Every git call names the task and change branches as
`refs/heads/<name>`, so a tag of the same name is not read in their place
(round 20 finding 87). `merge` prints the same CHANGE-BUSY remedy when its own merge stops
without a conflict and is not committed, for example when a `commit-msg` or
`pre-merge-commit` hook rejects the merge commit (round 18 finding 79). Every
command exits 2 when a git call fails where its result is read (round 15
finding 70, round 16 finding 73).

`start`:
- exits 2 when run from the primary checkout (`git rev-parse --git-dir`
  equals `--git-common-dir`), on a detached HEAD, or with a tag that is empty
  or contains `/` or whitespace, or that begins with `-` (round 6 finding 40),
  or that makes a task branch name `git check-ref-format` rejects (round 20
  finding 88; every command checks this),
  when the ignored-entry listing fails, and when another git call fails where
  its result is read;
- exits 1 with `fix WORKTREES-NOT-IGNORED: …` when `git check-ignore -q
  .worktrees/` exits 1 (any other non-zero status exits 2);
- exits 1 with `fix TASK-EXISTS: …` when the path or the branch already exists;
- runs `git worktree add .worktrees/<b>-<tag> -b <b>-<tag> <b>`;
- copies every ignored entry that
  `git ls-files --others --ignored --exclude-standard --directory` lists
  (nested ones included, such as `tests/.bats-core`; a target that already
  exists is skipped),
  except `.worktrees/` and `.claude/`, into the new worktree with `cp -R --`;
  as built, the list is read with `-z`, and a name containing a newline or a
  \001 byte is skipped with a message (round 6 finding 39);
- prints the absolute worktree path as its last line.

`merge`:
- exits 1 with a `fix` line, having changed nothing, when the task worktree
  has uncommitted or untracked files (`TASK-DIRTY`), or a worktree is
  registered inside it (`TASK-NESTED`);
- runs `git -c commit.gpgsign=false merge --no-ff --no-edit <b>-<tag>` in the
  change worktree; a conflict exits 1 with `fix TASK-CONFLICT: …` and leaves
  the merge for the dispatcher to resolve, removing nothing; a merge git stops
  without a conflict and does not commit exits 1 with `fix CHANGE-BUSY: …`,
  states that the merge was not committed, and removes nothing;
- then `git worktree remove` (no `--force`) and `git branch -d` (no `-D`);
  a rejection of either exits 1 naming what was and was not removed;
- `remove` merges nothing and rejects a branch with commits the change
  branch lacks; a review worktree is retired with `remove review`.

1. RED — `tests/task-worktree.bats`, each test
   `# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)`: one test per
   bullet above, normal and abnormal cases, including: `start` copies an
   ignored `tests/.bats-core`-shaped directory and does not copy
   `.worktrees/`; `merge` on a dirty task worktree leaves the path, the branch
   and the change branch's HEAD unchanged; `remove` on a review worktree with
   no commits removes both; a second `start` with the same tag after `merge`
   succeeds.
2. GREEN — write the script. Source `lib.sh` the way `finish-merge.sh` does.
3. Run `tests/task-worktree.bats` and `tests/portability.bats`. All pass.
4. Commit: `feat: task-worktree.sh creates and retires a nested task worktree`.

### T4 — the merge pre-flight (D7 procedure 3)

**Status:** done, merged as `13b46f1` (task commit `cb1975e`).

red -> green: tests 1 to 19 of `tests/merge-preflight.bats` — watched fail
before the script existed (exit 127), then pass. Six failed again after the
first draft on fixture gaps, fixed in the fixtures with the script unchanged.
"passes under an awk that rejects a newline in -v" was written after the script
and green on arrival; it was then shown to fail against a mutated impact-set
parse (`awk: newline in string`) once the script failed closed on an awk error.

Output as built: every check prints `ok`, or `skipped (<reason>)` where it does
not apply (UNITS in a single-unit repository; IDS and TRACE under UNITS; REVIEW
under `--before-review`). A passing check shows none of its tool's output, so
`UNRESOLVED-PR` and `ACCEPTED-PR` warnings are not shown; T7 fixes that.

**Files touched:** `scripts/merge-preflight.sh`, `tests/merge-preflight.bats`
**Parallel:** yes (with T1, T3, T5)

Interface, run from the change worktree:

```
merge-preflight.sh [--before-review] [--local-base] <change-branch>
```

Checks, in this order, stopping at the first failure. Each passing check
prints `preflight: <CHECK> ok`; the failing one prints the tool's own output,
then `fix <CHECK>: <remedy>`, and exits 1.

1. `CLEAN-TREE` — `git status --porcelain` is empty.
2. `BASE-MERGED` — the base branch (`gr_base_branch`) is an ancestor of
   `HEAD`, and so is `origin/<base>` where that ref exists. The script never
   fetches; the remedy names `merge-change` step 1.
3. `IDS` — `check-ids.sh` (no `--allow-draft-files`).
4. `TRACE` — `check-trace.sh`.
5. `UNITS` — only when `.guardrails/units.yaml` exists, and then in place of
   3 and 4: `check-units.sh` once, then `check-ids.sh` and `check-trace.sh`
   with `GR_CONFIG=<unit>/.guardrails/config.yaml` for every unit
   `check-units.sh --impact "refs/heads/<base>..HEAD"` prints
   (`skills/merge-change/references/multi-unit.md`).
6. `REVIEW` — `check-review.sh`. Skipped under `--before-review`.
7. `NESTED-WORKTREE` — `finish-merge.sh --check <change-branch>`. The verdict
   `no worktree is registered for` is a failure here, with the remedy "you
   named the wrong branch".

Exit 2 when run from the primary checkout, with a detached primary checkout,
on the base branch, or when the named branch is not the current branch. As built, also exit 2 on a detached
HEAD, on bad arguments, when a tool a check runs exits 2 (round 1 finding
4), and when a git call fails where its result is read, including BASE-MERGED's
read of `origin/<base>` and its `merge-base` (round 16 finding 73). BASE-MERGED
and the UNITS range name the base as `refs/heads/<base>` and
`refs/remotes/origin/<base>`, so a tag of the same name is not read in its
place (round 21 finding 91). `--local-base` checks BASE-MERGED against the local base only (round 2
finding 8). A check that does not apply prints `skipped (<reason>)`.

1. RED — `tests/merge-preflight.bats`, each test
   `# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)`: a fixture
   change worktree that passes all seven checks prints seven `ok` lines and
   exits 0; one test per check that makes exactly that check fail and asserts
   the earlier checks printed `ok`, the later ones printed nothing, and the
   `fix <CHECK>:` line is present; `--before-review` passes with no record;
   the wrong-branch verdict of check 7 fails; the three exit-2 cases. Reuse
   the fixture helpers in `tests/helpers.bash` and the record fixture
   `tests/check-review.bats` builds.
2. GREEN — write the script; call sibling scripts by `$gr_script_dir`.
3. Run `tests/merge-preflight.bats` and `tests/portability.bats`. All pass.
4. Commit: `feat: merge-preflight.sh runs merge-change's mechanical checks`.

### T5 — finish-merge.sh tells the truth about what it removed

**Status:** done, merged as `bfd3a70` (task commit `ffd6ef6`).

red -> green:
- finish-merge: a failed branch deletion with no worktree registered does not
  claim a removal — watched fail for the right reason (main's message "the
  worktree was removed but my-change could not be deleted" on the path that
  removed no worktree).
- finish-merge: a failed branch deletion after a removal reports the worktree
  removed — green on arrival, as planned: it pins the existing message on the
  path where it is true. Never red.

`PR-zmzav3` is a comment defect with no behaviour to test; no test verifies it,
and the record states the substitution. T6 must also correct
`skills/merge-change/SKILL.md` step 8, "nothing was removed", which is the
`PR-sa5y4k` claim in the skill.

**Files touched:** `scripts/finish-merge.sh`, `tests/finish-merge.bats`,
`skills/merge-change/references/cleanup-rejections.md`,
`docs/problems/2026-09-29-inherited-cleanup-claims.md`
**Parallel:** yes (with T1, T3, T4)

1. RED — in `tests/finish-merge.bats`:
   `finish-merge: a failed branch deletion after a removal reports the worktree removed`
   and
   `finish-merge: a failed branch deletion with no worktree registered does not claim a removal`
   (`# verifies: PR-sa5y4k`). Make `git branch -D` fail in the fixture (for
   example, check the branch out in a second worktree registered outside the
   change worktree). The second test fails on `main`'s message.
2. GREEN — give the no-worktree path its own message, which states that no
   worktree was removed and the branch could not be deleted.
3. Correct the key-touch sentence in the comment of
   "finish-merge: every nested worktree is named, not just the first" and in
   the script comment on reporting every nested worktree at once: a re-run
   verifies a signature and uses no private key (`PR-zmzav3`). Add
   `# verifies: PR-zmzav3` to that test only if it now asserts something about
   the cost; otherwise record in the report that `PR-zmzav3` is a comment
   defect with no behaviour to test, and T6's record states the substitution.
4. In `references/cleanup-rejections.md`, add the row for the `git branch -D`
   failure and correct the opening sentence: a non-zero exit removed nothing,
   except after a removal when only the branch deletion failed.
5. Set both items to `status: resolved`, with the commit that fixed each.
6. Run `tests/finish-merge.bats`, `tests/skills.bats`, `tests/mutations.bats`.
   All pass.
7. Commit: `fix: finish-merge.sh names what it removed when the branch deletion fails`.

### T6 — merge-change and the dispatch skills use the scripts (D5)

**Status:** done, merged as `f7aa545` by `task-worktree.sh finish t6` (task commits
`ad9628f`, `9360082`). `skills/merge-change/SKILL.md` was 1,984 words after T6 (1,996 after the round 1 and 2 fixes), down from
3,132, and `merge-change` is off the ceiling exemptions. Full suite in the task
worktree: 805 passed, 0 failed.

red -> green:
- merge-change: the mechanical checks are the pre-flight — watched fail ("step 4 does not run merge-preflight.sh --before-review").
- develop-change: the dispatch prompt names task-worktree.sh — watched fail ("the dispatch prompt does not name task-worktree.sh start").
- skill shape: every SKILL.md is at most 2,000 words — watched fail with "merge-change:3132" once the exemption was removed.

Six tests retargeted under D4, none deleted. The review worktree is retired with
`task-worktree.sh finish review`, preceded by a `git log` check for reviewer
commits, since `finish` merges them (review round 1 finding 1 replaces this
with `finish --no-merge`). Two leftovers, the hand-written remedy in
`references/cleanup-rejections.md` and step 6d named in `scripts/finish-merge.sh`,
were fixed by the deslop pass.

**Files touched:** `skills/merge-change/SKILL.md`,
`skills/merge-change/references/multi-unit.md`,
`skills/merge-change/references/rationale.md`,
`skills/develop-change/SKILL.md`, `skills/worktree-discipline/SKILL.md`,
`skills/verify-before-merge/SKILL.md`, `tests/skills.bats`, `README.md`,
`templates/AGENTS-block.md`
**Parallel:** no (serial, after T1 to T5 and T7)

The step numbering of `merge-change`, 1 to 8 with 6a to 6d, is unchanged,
because other skills, templates and `AGENTS.md` cite it.

1. RED — in `tests/skills.bats`, remove `merge-change` from
   `gr_ceiling_exempt_skills`. The ceiling test fails (`merge-change:3132`).
   Add `merge-change: the mechanical checks are the pre-flight` (step 4 and
   step 6c each name `merge-preflight.sh`) and
   `develop-change: the dispatch prompt names task-worktree.sh`. Watch all
   three fail.
2. GREEN — rewrite `skills/merge-change/SKILL.md` to at most 2,000 words:
   - Step 4 runs `merge-preflight.sh --before-review <branch>`; step 5 keeps
     only the rulings a script cannot make (a `DRAFT-FILE` or a rename this
     change did not create is another change's repair; never widen a pattern
     for `MALFORMED-ID`). Step 6c runs `merge-preflight.sh <branch>`; step 6d
     keeps only where to remove a worktree the pre-flight named.
   - Fix dispatches use `task-worktree.sh start` and `merge`, and the review
     worktree `start` and `remove` (named `finish` and `finish --no-merge`
     when T6 was run; renamed by the round 4 ruling); the hand-written
     remove-and-delete blocks go.
   - The documentation-review checklist of 6a moves to
     `references/review-checklist.md`, "read when the diff touches
     documentation, and hand it to the reviewer".
   - Red flags keep only rows no script enforces.
   - `references/multi-unit.md` states that the pre-flight runs the per-unit gates.
   `references/rationale.md` names no script (the change 1 test enforces it).
3. `develop-change` "Delegation" and the dispatch prompt, and
   `worktree-discipline` step 1, point at `task-worktree.sh` in place of the
   hand-written `git worktree add`, copy, merge, remove and delete. Add no
   other text to either skill; change 3 rewrites them.
4. `verify-before-merge`: no change unless a test shows it cites removed text.
5. Add `task-worktree.sh` and `merge-preflight.sh` rows to the script table
   in `README.md` and the script list in `templates/AGENTS-block.md`, in the
   form of the existing rows.
6. Retarget under D4 every test that pinned removed `merge-change` text, and
   T8 places the sentences T2 listed.
   Step 8's "nothing was removed" is corrected to match
   `references/cleanup-rejections.md` (`PR-sa5y4k`).
7. Run the full suite. All pass.
8. Commit: `feat: merge-change points at the scripts and meets the ceiling`.

### T7 — pinned script counts, and the pre-flight shows warnings

**Status:** done, merged as `fa39f0a` by `task-worktree.sh finish t7` (task commit
`7ecb422`).

red -> green:
- merge-preflight: a passing TRACE shows the warnings check-trace.sh printed — watched fail (exit 0, the seven pre-flight lines and no `UNRESOLVED-PR` line).
- The three pins were red after T3 and T4 merged ("unpinned script … merge-preflight.sh"; "expected 9 scripts, scanned 11"; "expected 8 scripts, got 10") and pass at 11, 11 and 10.

When T7 was merged, no test covered warnings under UNITS. Review round 8
(finding 50) added "merge-preflight: a passing UNITS shows a unit's
check-trace.sh warnings under that unit's header", which closes it.

**Files touched:** `tests/check-ids.bats`, `tests/lib.bats`,
`scripts/merge-preflight.sh`, `tests/merge-preflight.bats`
**Parallel:** yes (with T1 and T2)

1. `tests/check-ids.bats` "every gr_def_re call site is still a call site, and
   no copy joins them": add the `task_worktree` and `merge_preflight` entries
   (all counts 0 unless the script calls `gr_def_re`) and raise its seen count.
   "every script parses as POSIX sh" and `tests/lib.bats` "every script stops
   outside a git repository, at gr_root": raise the pinned counts to match the
   scripts now present. Each was red after T3 and T4 merged; record that.
2. RED — `tests/merge-preflight.bats`:
   `merge-preflight: a passing TRACE shows the warnings check-trace.sh printed`
   (`# verifies: D7 (docs/plans/2026-09-28-agent-first-skills.md)`) — a fixture
   with one open problem report prints its `UNRESOLVED-PR` line and exits 0.
3. GREEN — on a passing IDS, TRACE or UNITS run, print the tool's warning
   lines (the lines a warning-only run prints, and any `fix` line) before the
   `ok` line.
4. Run `tests/check-ids.bats`, `tests/lib.bats`, `tests/merge-preflight.bats`.
   All pass.
5. Commit: `fix: the script counts include the new scripts, and the pre-flight shows warnings`.

### T8 — the script headers state what the fix table stated (D6)

**Files touched:** `scripts/check-trace.sh`, `scripts/check-ids.sh`
**Parallel:** yes (with T6 and T7)

1. Place each sentence of T2's list above in the header roster entry of its
   rule, as a comment, in the header's existing style. Comments only: no
   executable line changes, and the remedy text is unchanged.
2. Correct the comment near line 530 of `scripts/check-trace.sh` that points
   to `skills/check-traceability/SKILL.md` for the MISPLACED-ITEM exceptions.
3. Grep `docs/verification/*.mutations/` for every changed line (none is
   expected, since mutations quote code). Run `tests/remedies.bats`,
   `tests/check-trace.bats`, `tests/check-ids.bats`, `tests/skills.bats` and
   `tests/mutations.bats`. All pass.
4. Commit: `docs: the check-trace and check-ids headers state each rule's cases`.

No red → green: comments only, no behaviour.

**Status:** done, merged by `task-worktree.sh finish t8` (task commit
`28643e8`). All 16 sentences placed, 15 in `check-trace.sh` and DUPLICATE-ID in
`check-ids.sh`; five roster first lines gained only a period, and the roster
extraction reads the same tokens.

Found by T8's run: `scripts/merge-preflight.sh` was committed as mode 100644,
and "every script is executable in the index" failed. Fixed by the dispatcher
in its own task worktree (`modefix`), watched pass after the fix.

---

## Decision after review round 4: fix lines never merge

Rounds 1 to 4 found one class of defect four times: a remedy or skill step
led to the merging `finish` command where a merge was unsafe, and each added
mode (`--no-merge`, `discard`, an after-squash remedy) gave the next round new
text to check. The maintainer decided on 2026-10-01: `task-worktree.sh` has
`start`, `merge`, `remove` and `discard`. `merge` is the dispatcher's
deliberate step after a green task report and is never printed as a remedy.
No remedy for a task or review worktree, in any script, skill or reference
file, names a merging command; `discard` is named only after each commit is
recorded as a finding. A remedy may name any command that merges nothing;
the test is that, not a list. Examples in the tree: `start`, a checkout of the
task branch, `git worktree remove`, `git worktree unlock`, `git worktree add`,
`git branch -d` or `-D` after the commits are recorded, `cp -R`, and deleting
a directory by hand after reading it;
keeping unreviewed work means returning to `develop-change` and rerunning
`merge-change` from step 1, or, after the squash, a new change. Remedies for
other rules are out of the ruling's scope: `check-trace.sh` and `check-ids.sh`
fix lines, BASE-MERGED ("merge the base branch"), TASK-CONFLICT, which
concludes a merge the dispatcher started, and CHANGE-BUSY, which concludes or
aborts an operation in progress in the change worktree, including a merge of
the task branch that `merge` started and git did not commit. Every command acts only on the nested
task worktree path.

## Decision after review round 20: the review ends at low severity

From round 16 on, each review round found one to four new findings, each
real and of low severity, most in a rare git state (a hook that rejects the
merge commit, a tag named like the task branch). The convergence rule, that the
review ends only on a round with no code or requirement finding, did not
converge. The maintainer decided on 2026-10-04: for this change, the review
ends on the first round whose code and requirement findings are all of low
severity. The reviewer tags each finding with a severity. That round's
low-severity findings are fixed without a further review round where the fix
is mechanical, and are otherwise recorded as open problem items. The gate is
run on the final tree either way.

The maintainer also decided that this rule is the default in the skills. That
is a change to `merge-change` step 6 and its review checklist, and it is out of
this change's scope, which is under review; it is for change 3.

## After T6

**The deslop pass** is done, committed on the change branch as `b0bcddf`:
- the nested-worktree scan moved to `gr_nested_worktrees` in `scripts/lib.sh`, and `finish-merge.sh` and `task-worktree.sh` both call it;
- `trace_remedy` was renamed `check_trace_remedy`;
- shared test helpers (`output_has`, `output_lacks`) and the traced fixture (`write_traced_docs`) moved to `tests/helpers.bash`;
- the two T6 leftovers were fixed;
- prose was rewrapped.

Every mutation applied the same before and after (173 apply, 11 fail identically).

Then `check-traceability`, `verify-before-merge` and `merge-change`, with the
verification record at `docs/verification/2026-09-30-agent-first-scripts.md`.
