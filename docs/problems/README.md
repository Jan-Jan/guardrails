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
  opened: YYYY-MM-DD
  status: open|accepted|resolved
  <when resolved: one line — root cause + fix reference (reproducing test)>
  <when accepted: disposition: <the ruling and its date>>

- Record the problem BEFORE investigating (resolve-problem skill).
- EVERY item needs a `status:`, and every OPEN item an `opened:` date.
  `opened:` is a real calendar date in `YYYY-MM-DD`, and may
  be at most ONE day ahead of the machine running the check — that one day is
  there because "today" differs across timezones; anything further is a
  failure, because a date in the future ages backwards and would make a stale
  item look fresh. Both are read at COLUMN ONE, inside the item's block,
  and the FIRST occurrence of each is the one that counts. A keyword
  with nothing after it declares nothing and is reported as absent.
- A resolved item needs no `opened:`: it cannot age, and requiring the field
  on it would redden every ledger already written for no gain. Adopting this
  on an existing ledger is a backfill of the items still open, and
  check-trace.sh names each one.
- `status: accepted` is for a problem the project INVESTIGATED and ruled on:
  it will not be fixed, and that is a decision, not neglect. It needs BOTH an
  `opened:` and a `disposition:` — the ruling and the date it was made, read
  at column one inside the item's block like the other two:

      **PR-NNNNNN**: <observable symptom, one sentence>.
      affects: <REQ/RC/SDD/LLR IDs implicated>.
      opened: YYYY-MM-DD
      status: accepted
      disposition: ruled on YYYY-MM-DD — <why the software is not changing>

  `disposition:` is not optional and is what makes the status safe. An
  accepted item is exempt from `problem_age_days` and does not count toward
  `problem_open_max`; without a required ruling, `accepted` would be a
  one-word escape from both, reachable by anyone looking at a red
  `PROBLEM-BACKLOG`. `accepted` with no `disposition:` is reported
  INCOMPLETE-PROBLEM, and so is `accepted` with no `opened:`. That `opened:`
  is judged as a date exactly as an open item's is: a malformed or future one
  is MALFORMED-DATE, because the field records when the problem was RAISED and
  a date after today falsifies that on a ruled item as much as on an open one.
- An accepted item is NOT exempt from the roll-call: it is printed as an
  ACCEPTED-PR line at every merge, with its date and its ruling, and counted in
  the `problems:` summary as `accepted N`. A decision nobody is reminded of
  decays back into a thing nobody remembers deciding.
- A `disposition:` that belongs to no item block is reported
  ORPHAN-ANNOTATION, for the same reason an orphaned `opened:` is: it would
  otherwise be read, matched and dropped while the item above it reads as
  undisposed.
- There is no owner field: authorship is already answered by `git blame` on
  the ledger line, and problems are not personally owned — anyone may
  resolve them — so a name in the grammar only added a failure mode (a
  missing one) without adding triage value.
- An item with no readable `status:` is reported INCOMPLETE-PROBLEM. It is
  not merely unlabelled — before that check it read as RESOLVED and was
  absent from every merge's known-problem list.
- Open PRs are printed as UNRESOLVED-PR warnings at every merge, carrying
  their age so the list can be triaged. The warning itself never
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
