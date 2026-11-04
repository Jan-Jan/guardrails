# Problem-report ledger

This directory is a per-change ledger: each change contributes one dated
file, `YYYY-MM-DD-<slug>.md`, dated the day the change creates it and never
renamed. The change that fixes a problem **deletes its item** from the file
that defines it, names it in the squash message's `Resolves:`, and gives
cause and fix under `Problems:`. Its regression test verifies the lowest-level
item the defect broke: the LLR where one exists, else the REQ (or the RC's
implementing REQ), never the PR.

<!--
Item grammar (surfaced by .guardrails/scripts/check-trace.sh):

  **PR-NNNNNN**: <observable symptom, one sentence>.
  affects: <REQ/RC/SDD/LLR IDs implicated>.
  opened: YYYY-MM-DD
  status: open|accepted
  <when accepted: disposition: <the ruling and its date>>

- Record the problem BEFORE investigating (resolve-problem skill).
- An item is terse: no rationale, history or implementation detail.
- EVERY item needs a `status:`, and every OPEN item an `opened:` date.
  `opened:` is a real calendar date in `YYYY-MM-DD`, and may
  be at most ONE day ahead of the machine running the check — that one day is
  there because "today" differs across timezones; anything further is a
  failure, because a date in the future ages backwards and would make a stale
  item look fresh. Both are read at COLUMN ONE, inside the item's block,
  and the FIRST occurrence of each is the one that counts. COLUMN ONE means
  column one: a leading list marker is NOT stepped over, so `- status: open`
  declares no status and the item is reported `INCOMPLETE-PROBLEM`. That is
  deliberate. Because the first occurrence wins, a reader that accepted the
  bullet form would let a quoted `- status: accepted` somewhere in an item's
  prose outrank the item's own `status: open`, and the open item would stop
  aging. A missing field named out loud is
  recoverable; a wrong status nobody is told about is not. The orphan
  backstop, which reports rather than reads, DOES step over list markers —
  bullets (`-`, `*`, `+`) and ordered markers (`1.`, `1)`) alike, one or more
  of them — so a list-item annotation belonging to no item at all is reported
  `ORPHAN-ANNOTATION` — which is why the illustrative forms below use no
  list marker. Bare indentation is not a marker and neither is a bare number;
  only the marker is stepped over. A keyword with nothing after it declares
  nothing and is reported as absent.
- `status: resolved` is RESOLVED-PROBLEM: a fixed problem's item is deleted,
  not kept. Adopting `opened:` on an existing ledger is a backfill of the
  items still open, and check-trace.sh names each one.
- `status: accepted` is for a problem the project INVESTIGATED and ruled on:
  it will not be fixed, and that is a decision, not neglect. It needs BOTH an
  `opened:` and a `disposition:` — the ruling and the date it was made, read
  at column one inside the item's block, like the other two:

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
  INCOMPLETE-PROBLEM, and so is `accepted` with no `opened:`. That `opened:` is
  judged as a date exactly as an open item's is: a malformed or future one is
  MALFORMED-DATE, because the field records when the problem was RAISED and a
  date after today falsifies that on a ruled item as much as on an open one.
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
  not merely unlabelled — it would otherwise be absent from every merge's
  known-problem list.
- Open PRs are printed as UNRESOLVED-PR warnings at every merge, containing
  their age so the list can be triaged. The warning itself never
  blocks; what blocks is an item older than `problem_age_days`, a backlog
  larger than `problem_open_max`, or a missing field. Both limits are set in
  `.guardrails/config.yaml`, and both are printed on every run whether they
  are set or not.
- Delete a problem's item only in the same change that merges the fix.
- Mint the ID when you write the item: run
  `.guardrails/scripts/new-id.sh <PREFIX>` and paste what it prints. The token
  is random and is not allocated against a base branch, so two worktrees or
  two GitHub PRs can mint the same one. That collision is improbable, and
  `DUPLICATE-ID` detects it at merge rather than preventing it. Never invent
  one by hand — the digit rule and the
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
