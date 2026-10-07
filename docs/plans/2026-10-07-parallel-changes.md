# Phase 2: changes may run in parallel

**Roadmap:** `docs/plans/2026-10-06-salvage-churn-and-parallel.md`, phase 2
(D1, D2, D4, D5).
**Resolves, opens:** no problem items. The decisions are the roadmap's; each
test cites the decision it verifies,
`verifies: D<N> (docs/plans/2026-10-06-salvage-churn-and-parallel.md)`.
**Base:** `main` at `2d0bbba`. Baseline: phase 1's gate, 1101 of 1101 on
`4fa522d`; `main` differs from that tree only by
`docs/verification/2026-10-07-test-runner.md`.

## Tasks

| Task | Files touched | Depends on |
|---|---|---|
| T1 — AGENTS.md drops non-negotiable 4 | `AGENTS.md`, `docs/adr/ADR-y8jmes-local-main-is-the-base.md`, `README.md`, `tests/skills.bats` | — |
| T2 — `merge-change` drops the precondition; step 7 checks the lock | `skills/merge-change/SKILL.md`, `skills/merge-change/references/rationale.md`, `tests/skills.bats` | T1 |
| T3 — `worktree-discipline` checks before a change opens | `skills/worktree-discipline/SKILL.md`, `skills/worktree-discipline/references/` (new file), `tests/skills.bats` | T2 |

All three touch `tests/skills.bats`, so they run in sequence.

### T1 — AGENTS.md drops non-negotiable 4 (D1)

1. Delete non-negotiable 4 ("Open one change at a time") whole, including its
   sentence on running tasks in parallel only inside a change: task fan-out
   inside a change is `worktree-discipline` step 1's, which keeps it.
2. Renumber non-negotiable 5 to 4, and every citation of it outside dated
   history: the record phrase in AGENTS.md itself ("per AGENTS.md
   non-negotiable 4"), and both mentions in
   `docs/adr/ADR-y8jmes-local-main-is-the-base.md`. The ADR's line on where the
   argument used to live names the rule by its subject, not its number, so it
   stays true across a renumbering. Past verification records, plans and
   problem items keep "5": they describe the tree they were written against.
3. `README.md` says "Changes are sequential; parallel work happens only inside
   a change." Replace it with what holds now: changes may run in parallel,
   each in its own change worktree, and `merge-change` step 1 merges the latest
   base into each every round.
4. `tests/skills.bats`: rename the test "AGENTS.md: non-negotiable 5 states the
   rule and points to its ADR" to "non-negotiable 4", with its body unchanged.
   Add a test, `verifies: D1`, that fails on the current tree: AGENTS.md
   contains no "Open one change at a time" and no "never across changes"; its
   numbered non-negotiables run 1 to 4 and no further; no file in `AGENTS.md`,
   `README.md`, `docs/adr/`, `skills/` or `templates/` contains "non-negotiable
   5"; README.md does not contain "Changes are sequential". Watch it fail
   before the edit.

### T2 — `merge-change` drops the precondition; step 7 checks the lock (D2, D5)

1. Delete the precondition bullet "**One change at a time.** …" from
   `skills/merge-change/SKILL.md`.
2. In `references/rationale.md`, replace "## Preconditions: one change at a
   time" with a section, under a heading naming no step, that states why
   parallel changes are safe: step 1 merges the latest base every round, so a
   change merged meanwhile reaches every other change before its gate;
   `new-id.sh` mints random tokens, so two worktrees do not contend for an ID,
   and `DUPLICATE-ID` catches the improbable collision after the base merge;
   each change writes its own verification record, found by its `branch:`
   field.
3. Step 7 gains the lock check (D5). Measured on 2026-10-07 in a scratch
   repository: with one squash already staged in the primary index, a second
   `git merge --squash` exits 0 and stacks its files onto the first when the
   two touch different files and the squash fast-forwards; on a shared file,
   or on any non-fast-forward, it fails naming the staged files (corrected
   after review round 4, finding-20: the first measurement had disjoint files
   only). So the staged squash is a lock only if the agent checks
   for it. Before `git merge --squash`, the agent runs
   `git diff --cached --quiet` in the primary checkout; a non-empty index
   means another change holds step 7. It stops, tells the user, and once the
   user has signed that squash, reruns from step 1, which merges the new base
   in. Keep the SKILL.md wording short: the file is at 2,000 words, and the
   deleted bullet frees about 15. Move reasons, not instructions, to the
   rationale if more room is needed.
4. The rationale gains "## Step 7: the agent stages the squash" (or extends
   the existing step 7 section): the staged squash is first come, first
   served; a session that finds it waits, and merges local main in after the
   user signs. Staging the squash inside the handed-over command instead (P1
   of the parallel-session proposals) would leave the index empty until the
   key touch, so no other session could see that a squash was pending.
5. `tests/skills.bats`: the test "merge-change: text the first rewrite lost is
   stated again" asserts 'Two open changes race on the base branch'. Remove
   that assertion. Add a test, `verifies: D2`, that SKILL.md no longer
   contains "One change at a time" and the rationale states why parallel
   changes are safe; and a test, `verifies: D5`, that step 7 contains the
   `git diff --cached --quiet` check and the rationale states why the agent,
   not the command handed over, stages the squash. Watch both fail first.

### T3 — `worktree-discipline` checks before a change opens (D4)

1. Add the check where a change worktree is created, without renumbering any
   step: steps 1 to 10 are cited by number across the skills. Steps 2 and 3
   create the change worktree, so the check goes before step 2's instruction
   or in Preconditions, whichever reads as an instruction to act.
2. The check has two parts:
   - **(a) a status line per registered worktree**: branch, commits ahead of
     the base branch, dirty-file count, date of the last commit. POSIX sh
     over `git worktree list --porcelain`.
   - **(b) the claim check**: for each item ID the new change will resolve
     or amend, and for each unmerged local branch, does the branch's diff
     against the base branch add or remove a line containing the ID
     (`git diff "$BASE...$branch" | grep -e "^[-+].*$ID"`, or an
     equivalent)? A plain `git grep` of the branch is not enough: the ID is
     defined on the base branch, so every branch contains it. A hit means
     another change claims the item: stop and ask the user. Evidence: on
     2026-10-06 two sessions resolved PR-s8dcmp, and one change was
     discarded.
3. The snippets go in a new `references/` file named in `## References` with
   the condition for reading it; SKILL.md (1,997 words) states the check in a
   few sentences and moves other text to references if it needs room.
4. Run both snippets in a scratch repository with two worktrees, one of them
   claiming an ID, and report what they printed in the dispatch report.
5. `tests/skills.bats`: a test, `verifies: D4`, that the skill states both
   parts and names the reference file, and that the reference file contains
   `git worktree list --porcelain` and a diff against the base branch. Watch it
   fail first.

## Done

- **T1** (b4035c8, merged 3aab325). red -> green: "AGENTS.md: changes may run
  in parallel; the non-negotiables run 1 to 4" failed on the unedited tree at
  its first status check, grep finding "Open one change at a time" in
  AGENTS.md; it passed after the edits. `tests/skills.bats` 103 of 103.
- **T2** (7cfea7e). red -> green: "merge-change: changes may run in parallel,
  and the rationale says why" failed on the unedited skill when grep found
  "one change at a time"; "merge-change: step 7 checks for a staged squash
  before staging its own" failed because step 7 had no
  `git diff --cached --quiet`. Both passed after the edit. SKILL.md stays at
  2,000 words: the reason sentence on repeated tags left the Steps opening
  paragraph, and the rationale already states it. `tests/skills.bats` 105 of
  105.
- **T3** (67437e7). red -> green: "worktree-discipline: a change opens after
  checking the worktrees and the claimed items" failed on the unedited tree at
  its first grep, the phrase "a status line per registered worktree" being
  absent; it passed after the edit (and a fix to the test's own joining of
  wrapped lines). Both snippets ran in a scratch repository under `/bin/sh`
  and `dash`: (a) listed a dirty, a detached, a prunable and an ahead
  worktree; (b) reported `CLAIMED PR-abc123 by fix-parser` where a plain
  `git grep` found the ID on all four branches. Step 2 gains the check; the
  git refusal messages of step 1 and the compaction paragraph of step 9 moved
  to `references/rationale.md`. SKILL.md 1,995 words. `tests/skills.bats` 106
  of 106. Known limit, stated in `references/before-opening.md`: a branch
  whose only edit is an item's `status:` line adds no line containing the ID.

## Review rounds

Findings and dispositions are in the verification record. What the rounds
added beyond the tasks above, so the plan describes the tree:

- **Step 7 compares the staged tree with the branch after every squash**
  (round 3, finding-11), with `git reset --merge` and a rerun from step 1
  when the base moved after step 1. This goes beyond D5: with parallel
  changes, a base that moves between step 1 and step 7 would otherwise be
  signed unverified.
- **A base merge after a review round that shares a file with the change
  reruns the whole process, review included** (round 4, finding-16; ruled by
  the maintainer 2026-10-07: the test is file overlap, not git conflicts —
  two changes editing the same test file can break each other with no
  conflict). A base merge on disjoint files reruns the gate only.
- **The before-opening snippets run under `sh` whatever the caller's shell**
  (round 4, finding-15), and the tests execute both the snippets and step 7's
  lines against scratch repositories.
- **A reviewer dispatch is marked in the branch's history** (round 5,
  finding-21): 6a makes an empty `review dispatched` commit before it
  dispatches a reviewer, and step 1 lists shared files against the base's
  edits since that commit's merge-base. A rerun after a failed gate lists
  them again until the next reviewer is marked. `templates/verification.md`
  asks the record to name the shared files and the re-review round.
- **A `CLAIMED` line is a sign, not a verdict, and the before-opening
  snippets stop on an empty BASE** (round 6, finding-25 and finding-26).
  `references/before-opening.md` says a `CLAIMED` line means the branch's
  diff adds or removes a line naming the ID, which a branch that only cites
  the ID also does; the agent reads those lines and asks the user before it
  opens a second change. Each snippet's first line exits with
  `BASE is empty: detect the base branch first` when base detection set
  nothing, where (a) printed `ahead 0` for every worktree and (b) printed no
  `CLAIMED` line; the D4 run test runs both snippets with BASE empty.
