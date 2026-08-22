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
- Never check out or commit to the base branch from here.

## Leaving

The worktree is removed by `merge-change` after a verified signed squash
merge — not before, and never with unmerged work in it without the user's
explicit say-so.

## Red flags

| Thought | Reality |
|---|---|
| "It's just a doc tweak, no worktree" | Docs are regulated artifacts. Worktree. |
| "I'll pick REQ-014, it's free" | Another worktree thinks so too. Run `new-id.sh`. |
| "Quick fix directly on the base branch" | The base branch moves only by signed squash merge. |
