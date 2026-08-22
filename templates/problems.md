# Problem-report ledger

This directory is a per-change ledger: each merged change contributes one
dated file, `YYYY-MM-DD-<slug>.md` (merge date, assigned by `merge-change`
from your worktree's `DRAFT-<branch>-<slug>.md`). A problem's `status:` flip
to resolved happens **in the file that defines the PR** (the fix's change
edits it in place).

<!--
Item grammar (surfaced by .guardrails/scripts/check-trace.sh):

  **PR-NNNNNN**: <observable symptom, one sentence>.
  affects: <REQ/RC/SDD/LLR IDs implicated>.
  status: open|resolved
  <when resolved: one line — root cause + fix reference (reproducing test)>

- Record the problem BEFORE investigating (resolve-problem skill).
- Open PRs are printed as UNRESOLVED-PR warnings at every merge — they
  never block, but they are always seen.
- status: resolved only in the same change that merges the fix.
- Mint the ID when you write the item: run
  `.guardrails/scripts/new-id.sh <PREFIX>` and paste what it prints. The token
  is random and is allocated against nothing, so two worktrees and two GitHub
  PRs never contend for it. Never invent one by hand — the digit rule and the
  alphabet are what keep an ID from matching ordinary English.
- IDs in the examples above use `NNNNNN` as a placeholder, and the examples
  are indented. Both matter. A real ID here would be a reference to an item
  that does not exist, reported as `DANGLING-REF` on every run; and a
  definition form at COLUMN ONE is judged whatever its body, so an example
  written flush left is reported as `MALFORMED-ID` — inside a fenced code
  block too, because no gate in the toolkit parses fences. Indent illustrative
  forms, or keep them inline in backticks. A real ID is six characters of
  `23456789abcdefghjkmnpqrstuvwxyz` with at least one digit; `new-id.sh` draws
  it for you.
-->
