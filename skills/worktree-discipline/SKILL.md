---
name: worktree-discipline
description: Mandatory isolation for every change in a guardrails project - create a git worktree before touching docs or code, mint item IDs as you write them. Use at the start of ANY change, documentation or code alike.
---

# Worktree Discipline

**Announce at start:** "Using the worktree-discipline skill to isolate this change."

In a guardrails project **no change happens outside a worktree** — writing an
SRS section is a change exactly like writing code. The base branch (whatever
branch the primary, non-worktree checkout has checked out) only ever moves by
signed squash merges (`merge-change`).

## Creating the worktree

1. **Already isolated?** If `git rev-parse --git-dir` differs from
   `--git-common-dir` (and you're not in a submodule), you're already in a
   worktree — don't nest another.

   **Carve-out — task worktrees.** One change gets one **change worktree** on
   one **change branch** off the base branch, and that is the only worktree
   `merge-change` ever sees. A subagent dispatched to work on that change is
   the exception, and which exception depends on what it was dispatched to do:

   - **implementing a plan task** — it creates its own **task worktree** on a
     **task branch** off the **change branch** it was dispatched from, commits
     its work there, and stops. It does **not** merge. Whoever dispatched it
     merges that task branch into the change branch, from the change worktree,
     once the task is green;
   - **reviewing the change** — its own task worktree on a task branch off the
     change branch, same as above, with nothing to merge back;
   - **running the verification gate** — **not** its own worktree. It runs in
     the **change worktree** itself, because `verify-before-merge`'s clean
     `git status` check reads *that* worktree's uncommitted state, and a task
     worktree branched fresh off the change branch is clean by construction —
     the check would pass having proved nothing.

   **Why the dispatcher merges and not the subagent.** "The subagent finishes
   its own work" is the intuitive answer and it is the wrong one: git will not
   update a branch that another worktree has checked out, and the change branch
   is checked out in the change worktree. From a task worktree every route is
   closed — `git merge <change-branch>` merges the wrong direction, into the
   task branch, leaving the change branch exactly where it was and exiting 0 as
   if it had worked; `git checkout <change-branch>` fails with `is already used
   by worktree`; `git push .` and `git fetch .` into it are refused with
   `refusing to update checked out branch` and `refusing to fetch into branch
   ... checked out at`. The one place the merge is possible is the change
   worktree, and a task subagent must not work there — that is the collision
   the red flags below forbid. So the subagent commits and reports; the
   dispatcher merges.

   Fan-out is what makes that safe: tasks dispatched in parallel touch disjoint
   **Files touched:** sets (`plan-change`), so their task branches merge into
   the change branch without conflicting with each other.

   Never share one worktree between parallel subagents — they collide on files
   and on `index.lock`, and they destroy the evidence TDD runs on: watching a
   test fail for the right reason means nothing if another agent is committing
   underneath you.

   Create a task worktree the way steps 2 and 3 describe — harness tool
   first — naming the change branch as the start point, and put it in
   whichever directory this project already uses for worktrees. The two
   usual locations resolve differently, and only one of them needs an ignore
   entry:

   - **inside the change worktree** — step 3's `.worktrees/`, a path relative
     to the change worktree's own root. It must be gitignored: an untracked
     directory inside the change worktree fails `verify-before-merge`'s clean
     `git status` check. **That entry is the dispatcher's precondition, not
     the subagent's.** Confirm it once, in the change worktree, before
     dispatching anyone (add + commit if missing). A subagent cannot do it —
     the commit would land on the change branch from the change worktree,
     where no task subagent may work, and five of them fanned out would race
     the same commit.
   - **outside it** — the harness's own location (e.g. `.claude/worktrees/`),
     which usually sits beside the change worktree rather than within it.
     Nothing there is inside the change worktree, so its `git status` never
     sees it and no ignore entry is needed.

   Either way, note where the worktree actually landed: the subagent reports
   that path back on the dispatch report's `worktree:` line
   (`develop-change`), and the dispatcher needs it to remove the worktree
   afterwards.

   ```sh
   # <worktrees-dir> inside the change worktree (.worktrees/) must be gitignored;
   # a harness location outside it (.claude/worktrees/) needs no ignore entry
   git worktree add <worktrees-dir>/<change-branch>-t<N> -b <change-branch>-t<N> <change-branch>
   ```

2. **Native tool first.** If your harness has a worktree tool (e.g.
   `EnterWorktree`, a `/worktree` command), use it.
3. **Fallback:**

   ```sh
   git worktree add .worktrees/<branch-name> -b <branch-name>
   cd .worktrees/<branch-name>
   ```

   Ensure `.worktrees/` is gitignored before creating it (add + commit if
   not). Branch names: short, kebab-case, describing the change
   (`add-dose-limits`, `rmf-overdose-hazards`).
4. **Baseline:** run the project's `verify_commands`
   (`.guardrails/config.yaml`) immediately. If the baseline is red, report it
   and get an explicit decision before building on it.

## Inside the worktree

- **Mint the ID now.** A new requirement/risk/design/problem item gets its
  real ID the moment it is written:

  ```sh
  .guardrails/scripts/new-id.sh REQ        # -> REQ-a3k9z2
  .guardrails/scripts/new-id.sh HAZ 3      # three at once
  ```

  The token is random, minted once, and allocated against nothing, so two
  worktrees — or two GitHub PRs — never contend for it and nothing is
  renumbered at merge. Never invent one by hand: the alphabet drops the
  characters that are read wrong (`0`/`o`, `1`/`l`/`i`) and every token
  carries a digit, which is what stops `REQ-argued` in prose from reading as
  an ID. `check-ids.sh` reports a hand-typed one as `MALFORMED-ID`.
- **Draft doc files.** On ledger-layout projects (doc config keys point at
  directories), new items go into this change's own file:
  `docs/<area>/DRAFT-<branch>-<slug>.md`. merge-change renames it to
  `YYYY-MM-DD-<slug>.md` (merge date), so parallel worktrees never touch the
  same file and the ledger reads chronologically. Amendments to existing
  items are edited in the dated file that defines them; never move a
  definition between files.
- Reference the minted IDs freely in code, tests (`verifies:`), and the plan.
  They are final from the first keystroke; nothing rewrites them later.
- Commit early and often. Worktree commits may be unsigned
  (`git -c commit.gpgsign=false commit`) — they are squashed away; only the
  merge commit on the base branch must be signed.
- **Every task worktree dies with its dispatch, at the dispatcher's hand.** The
  task subagent commits on its task branch and leaves it there; it cannot merge
  (step 1). The dispatcher — the agent in the change worktree — merges that task
  branch into the change branch once the task's tests are green, then removes
  the worktree and deletes the task branch:

  ```sh
  # in the change worktree, once the dispatch report comes back green
  git -c commit.gpgsign=false merge --no-ff <change-branch>-t<N>
  git worktree remove <task-worktree-path>   # the report's worktree: line, or
                                             # `git worktree list` to find it
  git branch -d <change-branch>-t<N>
  ```

  **That merge is unsigned for the same reason the commits are** — it is
  squashed away too, and `--no-ff` writes a commit object every time, up to
  five of them per fan-out. `git merge` honors `commit.gpgsign` exactly as
  `git commit` does, and a guardrails project sets it (`ratchet`'s setup
  checklist), so without the flag each task merge asks for a hardware-key
  touch or fails with `error: gpg failed to sign the data` /
  `fatal: failed to write commit object` — which leaves `MERGE_HEAD` and a
  staged, half-merged change worktree behind, and `verify-before-merge`'s
  clean `git status` check then fails on the mess.

  Take the worktree's path from the dispatch report rather than rebuilding it:
  `.worktrees/` is relative to the change worktree while a harness location is
  not (step 1). `git worktree list` gives it back if the report is out of
  reach.

  A task worktree dispatched only to review the change has nothing to merge —
  the dispatcher removes the worktree and its task branch as they are. Either
  way the branch goes too, so nothing survives to `merge-change`. A verification
  dispatch has nothing to remove at all: it runs the gate in the change
  worktree, never in one of its own (see the carve-out in step 1). Task work
  never reaches the base branch on its own; it gets there only inside this
  change's signed squash. The base branch still sees exactly one squash per
  change, and `merge-change` still sees exactly one worktree — the change
  worktree.
- Never check out or commit to the base branch from here.

## Leaving

This is about the **change worktree**. It is removed by `merge-change` after a
verified signed squash merge — not before, and never with unmerged work in it
without the user's explicit say-so. Task worktrees are on their own clock:
whoever dispatched one removes it, with its task branch, when that dispatch
ends (see "Inside the worktree").

## The artifacts are the memory

A conversation carries one change, start to finish. Everything that has to
survive it lives in an artifact, never in scrollback:

- **the plan** (`docs/plans/<date>-<slug>.md`) — the tasks, the files each
  touches, which are done, and, beside each completed task, the
  `red -> green:` attestations from its dispatch report, written down as the
  report lands (`develop-change`) so `merge-change` step 6b copies them from
  an artifact and not from scrollback;
- **the ledger** — the requirement, risk, design and problem items, with their
  minted IDs and their `satisfies:` / `implements:` / `verifies:` references;
- **the verification record** written by `merge-change` — what was run and what
  it reported.

Write state down as you go, not at the end. Scrollback is not durable: it is
summarized away, it is dropped, and a subagent never had it in the first place.
If the only place a decision exists is the transcript, it is already lost.

That is also what makes it safe to compact between changes. Once a change is
merged, clearing or condensing the conversation (e.g. a `/compact` command, or
simply a fresh session) before the next change costs nothing — the artifacts
carry it.

## Red flags

| Thought | Reality |
|---|---|
| "It's just a doc tweak, no worktree" | Docs are regulated artifacts. Worktree. |
| "I'll pick REQ-014, it's free" | Another worktree thinks so too. Run `new-id.sh`. |
| "Quick fix directly on the base branch" | The base branch moves only by signed squash merge. |
| "I'll just have the subagents share this worktree" | They collide on `index.lock` and on each other's red→green evidence. One task worktree each, off the change branch. |
| "The subagent merges its own task branch back" | It can't. Git refuses to update a branch another worktree has checked out, and `git merge` from the task worktree merges the wrong way and still exits 0. The dispatcher merges, in the change worktree. |
| "I'll remember what task 3 did" | You won't, and a subagent never could. It goes in the plan. |
| "I'll run the gate in a fresh worktree, it's cleaner" | It is clean because it is new. `verify-before-merge`'s `git status` check then proves nothing. The gate runs in the change worktree. |
