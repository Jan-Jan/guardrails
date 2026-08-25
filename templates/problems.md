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
  owner: <who is answerable for it — free text>
  opened: YYYY-MM-DD
  status: open|resolved
  <when resolved: one line — root cause + fix reference (reproducing test)>

- Record the problem BEFORE investigating (resolve-problem skill).
- EVERY item needs a `status:`, and every OPEN item an `owner:` and an
  `opened:` date. `opened:` is a real calendar date in `YYYY-MM-DD`, and may
  be at most ONE day ahead of the machine running the check — that one day is
  there because "today" differs across timezones; anything further is a
  failure, because a date in the future ages backwards and would make a stale
  item look fresh. Each of the three is read at COLUMN ONE, inside the item's
  block, and the FIRST occurrence of each is the one that counts. A keyword
  with nothing after it declares nothing and is reported as absent.
- Resolved items need neither owner nor opened: they cannot age, and
  requiring the fields on them would redden every ledger already written for
  no gain. Adopting this on an existing ledger is a backfill of the items
  still open, and check-trace.sh names each one.
- An item with no readable `status:` is reported INCOMPLETE-PROBLEM. It is
  not merely unlabelled — before that check it read as RESOLVED and was
  absent from every merge's known-problem list.
- Open PRs are printed as UNRESOLVED-PR warnings at every merge, carrying
  their age and owner so the list can be triaged. The warning itself never
  blocks; what blocks is an item older than `problem_age_days`, a backlog
  larger than `problem_open_max`, or a missing field. Both limits are set in
  `.guardrails/config.yaml`, and both are printed on every run whether they
  are set or not.
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
