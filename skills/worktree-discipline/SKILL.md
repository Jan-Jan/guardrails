---
name: worktree-discipline
description: Mandatory isolation for every change in a guardrails project - create a git worktree before touching docs or code, mint draft IDs inside it. Use at the start of ANY change, documentation or code alike.
---

# Worktree Discipline

**Announce at start:** "Using the worktree-discipline skill to isolate this change."

In a guardrails project **no change happens outside a worktree** — writing an
SRS section is a change exactly like writing code. Main only ever moves by
signed squash merges (`merge-change`).

## Creating the worktree

1. **Already isolated?** If `git rev-parse --git-dir` differs from
   `--git-common-dir` (and you're not in a submodule), you're already in a
   worktree — don't nest another.
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

- **Draft IDs only.** New SRS/RMF/SAD items are minted as
  `<PREFIX>-DRAFT-<branch>-<n>` where `<branch>` is the branch name and `<n>`
  counts up from 1 within this change. Never hand-pick a final number —
  finals are assigned by `finalize-ids.sh` during `merge-change`, which makes
  parallel worktrees collision-free.
- Reference draft IDs freely in code, tests (`verifies:`), and the plan —
  finalization rewrites every occurrence.
- Commit early and often. Worktree commits may be unsigned
  (`git -c commit.gpgsign=false commit`) — they are squashed away; only the
  merge commit on main must be signed.
- Never `git checkout main` / commit to main from here.

## Leaving

The worktree is removed by `merge-change` after a verified signed squash
merge — not before, and never with unmerged work in it without the user's
explicit say-so.

## Red flags

| Thought | Reality |
|---|---|
| "It's just a doc tweak, no worktree" | Docs are regulated artifacts. Worktree. |
| "I'll pick REQ-014, it's free" | Another worktree thinks so too. Draft IDs only. |
| "Quick fix directly on main" | Main moves only by signed squash merge. |
