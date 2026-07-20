# Problem-report ledger

This directory is a per-change ledger: each merged change contributes one
dated file, `YYYY-MM-DD-<slug>.md` (merge date, assigned by `merge-change`
from your worktree's `DRAFT-<branch>-<slug>.md`). A problem's `status:` flip
to resolved happens **in the file that defines the PR** (the fix's change
edits it in place).

<!--
Item grammar (surfaced by .guardrails/scripts/check-trace.sh):

  **PR-NNN**: <observable symptom, one sentence>.
  affects: <REQ/RC/SDD/LLR IDs implicated>.
  status: open|resolved
  <when resolved: one line — root cause + fix reference (reproducing test)>

- Record the problem BEFORE investigating (resolve-problem skill).
- Open PRs are printed as UNRESOLVED-PR warnings at every merge — they
  never block, but they are always seen.
- status: resolved only in the same change that merges the fix.
- Mint new items as **<PREFIX>-DRAFT-<branch>-<n>** in worktrees.
-->
