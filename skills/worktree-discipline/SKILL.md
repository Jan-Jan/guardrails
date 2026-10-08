---
name: worktree-discipline
description: Mandatory isolation for every change in a guardrails project - create a git worktree before touching docs or code, mint item IDs as you write them. Use at the start of ANY change, documentation or code alike.
---

# Worktree Discipline

**Announce at start:** "Using the worktree-discipline skill to isolate this change."

## Preconditions

- You are about to change something: documentation or code. Writing an SRS
  section is a change exactly like writing code, and **no change happens
  outside a worktree**.
- The base branch is the branch the primary, non-worktree checkout has checked
  out. It moves only by signed squash merges (`merge-change`).
- One change gets one **change worktree** on one **change branch** off the base
  branch. That is the only worktree `merge-change` sees.

## Steps

1. **Already isolated?** If `git rev-parse --git-dir` differs from
   `--git-common-dir` (and you are not in a submodule), you are in a worktree.
   Do not nest another, except as a task worktree under the carve-out below.

   **Carve-out — task worktrees.** A subagent dispatched from a change worktree
   works according to what it was dispatched to do:

   - **implementing a plan task** — it creates its own **task worktree** on a
     **task branch** off the **change branch** it was dispatched from, commits
     its work there, and stops. It does **not** merge. The dispatcher merges
     that task branch into the change branch, from the change worktree, once
     the task is green;
   - **reviewing the change** — its own task worktree on a task branch off the
     change branch, with nothing to merge back;
   - **running the verification gate** — **not** its own worktree. It runs in
     the **change worktree**, because `verify-before-merge`'s clean
     `git status` check reads that worktree's uncommitted state.

   The subagent cannot merge its own task branch: git rejects an update to a
   branch another worktree has checked out. Do not try `git merge`,
   `checkout`, `push .` or `fetch .` of the change branch
   (`references/rationale.md`). Commit, report, and stop.

   Fan out only across tasks whose **Files touched:** sets are disjoint
   (`plan-change`), so their task branches merge without conflict. Never share
   one worktree between parallel subagents.

   **Where the task worktree goes: `.worktrees/<change-branch>-t<N>`, nested
   inside the change worktree.** Use no other location, whatever the project
   or the harness uses for worktrees.
   Where a harness isolates a dispatched subagent, that harness
   pins that subagent to a subtree, and the only worktree inside that pin is
   one nested inside the change worktree it was dispatched from. A worktree
   beside the change worktree is outside that pin.

   `<N>` is the plan task number: task 3 gets `.worktrees/<change-branch>-t3`,
   on branch `<change-branch>-t3`. A dispatch with no task number takes a tag
   in place of `t<N>`, giving `.worktrees/<change-branch>-<tag>`: the
   independent review at `merge-change` step 6a goes to
   `.worktrees/<change-branch>-review`, and a fix dispatch takes the unique tag
   `merge-change`'s sequence header requires.

   The dispatcher names that path in the dispatch prompt. The subagent reports
   it back on the dispatch report's `worktree:` line (`develop-change`).

   **The `.worktrees/` ignore entry is the dispatcher's precondition.** An
   untracked directory inside the change worktree fails `verify-before-merge`'s
   clean `git status` check. Confirm the entry once, in the change worktree,
   before dispatching anyone; add and commit it if missing. A subagent does not
   make that commit: it would be on the change branch.

   The **change** worktree may be in the harness's own directory (e.g.
   `.claude/worktrees/`) or in `.worktrees/` in the primary checkout (step 3);
   `ratchet`'s setup gitignores both.

   ```sh
   # from the change worktree; creates .worktrees/<change-branch>-t<N>
   sh .guardrails/scripts/task-worktree.sh start t<N>
   ```

   **Then get inside it — harness tool first.** If your harness has a worktree
   tool (e.g. `EnterWorktree`, a `/worktree` command), pass it the path you
   just created. Otherwise remain where you are and drive the worktree by path,
   with `git -C .worktrees/<change-branch>-t<N> ...` and absolute paths for
   every edit. Either way, before you edit anything, confirm the worktree is
   usable with `git -C .worktrees/<change-branch>-t<N> status`; that spelling
   works on both routes. A worktree tool given a path outside the pin
   reports success and then rejects every shell call; re-enter the change
   worktree's own path with the same tool.

   Then edit, run the project's `verify_commands`, commit on the task branch
   (unsigned, `develop-change` step 6), report, and stop. The dispatcher merges.

   **A fresh task worktree contains only tracked files.** `start` copies the
   change worktree's ignored entries into it: a vendored test runner, installed
   dependencies, a build cache. If a `verify_commands` entry still reaches for a
   missing artifact, compare with `git status --ignored` in the change
   worktree. The copy leaves the tree clean, because anything missing for this
   reason is gitignored by definition and so cannot dirty `git status`.

   **The containment rule was measured once, on one harness.** Follow it
   wherever a harness isolates dispatched subagents. A harness that
   does not pin its subagents may put a task worktree anywhere; nest anyway.
   To tell whether yours pins, follow `references/harness-pin-test.md`.

2. **Check what is already open.** Before you create the change worktree, run
   the two checks in `references/before-opening.md`: (a) a status line per
   registered worktree, with its branch, commits ahead of the base branch,
   dirty-file count and last commit date; (b) for each item ID this change
   will resolve or amend, whether an unmerged local branch's diff against the
   base branch adds or removes a line containing the ID. A hit means another
   change claims the item: stop and ask the user.

   **Harness tool first.** If your harness has a worktree tool (e.g.
   `EnterWorktree`, a `/worktree` command), use it to create the change
   worktree.
3. **Fallback:**

   ```sh
   git worktree add .worktrees/<branch-name> -b <branch-name>
   cd .worktrees/<branch-name>
   ```

   Ensure `.worktrees/` is gitignored before creating it (add and commit if
   not). Branch names: short, kebab-case, describing the change
   (`add-dose-limits`, `rmf-overdose-hazards`).

   Steps 2 and 3 create the **change** worktree, from the primary checkout.
   Task worktrees follow step 1.
4. **Baseline:** run the project's `verify_commands`
   (`.guardrails/config.yaml`) immediately. If the baseline is red, report it
   and get an explicit decision before building on it.
5. **Mint the ID now.** A new requirement, risk, design or problem item gets
   its real ID the moment it is written:

   ```sh
   .guardrails/scripts/new-id.sh REQ        # -> REQ-a3k9z2
   .guardrails/scripts/new-id.sh HAZ 3      # three at once
   ```

   Never invent one by hand: `check-ids.sh` reports a hand-typed token as
   `MALFORMED-ID`. Reference the minted IDs freely in code, tests
   (`verifies:`) and the plan. They are final from the first keystroke; nothing
   rewrites them later.
6. **Draft doc files.** On ledger-layout projects (doc config keys point at
   directories), new items go into this change's own file:
   `docs/<area>/DRAFT-<branch>-<slug>.md`. `merge-change` renames it to
   `YYYY-MM-DD-<slug>.md`, dated when the draft name is retired. Edit an
   amendment to an existing item in the dated file that defines it; never move
   a definition between files.
7. **Commit early and often.** Worktree commits may be unsigned
   (`git -c commit.gpgsign=false commit`); they are squashed away, and only the
   merge commit on the base branch must be signed. Never check out or commit
   to the base branch from a worktree.
8. **The dispatcher removes every task worktree when its dispatch ends.** The
   task subagent commits on its task branch and leaves it there (step 1). Once
   the dispatch report is green, the dispatcher, in the change worktree,
   merges the task branch into the change branch, removes the worktree and
   deletes the task branch:

   ```sh
   # in the change worktree, once the dispatch report comes back green
   sh .guardrails/scripts/task-worktree.sh merge t<N>
   ```

   The path is the one the dispatcher named in the prompt,
   `.worktrees/<change-branch>-t<N>` (step 1), and `t<N>` is its tag; the
   report's `worktree:` line confirms the subagent went there.

   A review worktree has nothing to merge.
   `task-worktree.sh remove review` removes the worktree and its task branch,
   and rejects a branch with commits. Record each such commit as a finding,
   then run `task-worktree.sh discard review`, which removes the worktree and
   deletes the branch with them. Run `merge` only after a green task report;
   no remedy for a rejection names it. For the independent review the
   dispatcher is `merge-change`, and the removal is at
   the end of `merge-change` step 6a, where that dispatch ends.

   A verification dispatch has nothing to remove: it runs in the change
   worktree.
9. **The artifacts are the memory.** A conversation covers one change, start
   to finish. Write state to an artifact as you go, never only to the
   conversation:

   - **the plan** (`docs/plans/<date>-<slug>.md`) — the tasks, the files each
     touches, which are done, and, beside each completed task, the
     `red -> green:` attestations from its dispatch report, written down as
     the report arrives (`develop-change`), so `merge-change` step 6b copies
     them from a file;
   - **the ledger** — the requirement, risk, design and problem items, with
     their minted IDs and their `satisfies:` / `implements:` / `verifies:`
     references;
   - **the verification record** written by `merge-change` — what was run and
     what it reported.
10. **Leave the change worktree to `merge-change`.** It is removed after a
    verified signed squash merge, not before, and never with unmerged work in
    it without the user's explicit say-so. Task worktrees are removed by their
    dispatcher when the dispatch ends (step 8).

## Red flags

| Thought | Reality |
|---|---|
| "It's just a doc tweak, no worktree" | Docs are regulated artifacts. Worktree. |
| "I'll pick REQ-014, it's free" | Another worktree may have picked it too. Run `new-id.sh`. |
| "Quick fix directly on the base branch" | The base branch moves only by signed squash merge. |
| "I'll just have the subagents share this worktree" | They collide on `index.lock` and on each other's red→green evidence. One task worktree each, off the change branch. |
| "The subagent merges its own task branch back" | It can't. Git rejects an update to a branch another worktree has checked out, and `git merge` from the task worktree merges the wrong way and still exits 0. The dispatcher merges, in the change worktree. |
| "I'll remember what task 3 did" | You won't, and a subagent never could. It goes in the plan. |
| "I'll run the gate in a fresh worktree, it's cleaner" | It is clean because it is new. `verify-before-merge`'s `git status` check then proves nothing. The gate runs in the change worktree. |
| "The task worktree goes where this project keeps worktrees" | Nested inside the change worktree, at `.worktrees/<change-branch>-t<N>` — a dispatched subagent is pinned to that subtree. |
| "`git worktree add` succeeded, so the location is fine" | Creation succeeds in both locations. It proves nothing about whether you can then write, commit or test there. |
| "The file wrote, so I'm somewhere usable" | A plain shell redirect to a path outside the pin is not blocked even though the write tool is. Prove the location with `git -C <path> status`, not with a file appearing — that spelling works whether you entered the worktree or are driving it by path (step 1). |
| "The worktree tool reported that it entered, so I'm in" | Outside the pin it reports success and then rejects every shell call, `pwd` included. Re-enter the change worktree's own path with the same tool (step 1). |

## Done when

- The change is in a change worktree on its own change branch, and every
  dispatched task is in a task worktree at the path the dispatcher named,
  confirmed with `git -C <path> status`.
- The baseline was run, and a red baseline has an explicit decision.
- Every new item has an ID from `new-id.sh`, in this change's draft file on a
  ledger-layout project.
- Every task worktree is merged or discarded and removed, with its branch.
- The plan, the ledger and the verification record contain the change's state.

## References

- `references/rationale.md` — read when a rule here seems wrong for your case,
  or before proposing to change one.
- `references/before-opening.md` — read when you reach step 2, before you
  create a change worktree.
- `references/harness-pin-test.md` — read when you need to know whether your
  harness pins dispatched subagents to a subtree.
