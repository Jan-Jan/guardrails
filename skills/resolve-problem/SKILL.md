---
name: resolve-problem
description: Problem-report workflow for guardrails projects - record every bug as a PR item, reproduce it as a failing annotated test, fix under TDD, resolve in the merging change. Use when any bug, anomaly, test failure, or unexpected behavior is found.
---

# Resolve Problem

**Announce at start:** "Using the resolve-problem skill."

## Preconditions

- A bug, anomaly, test failure or unexpected behavior was found.
- You are in a worktree (`worktree-discipline`). Record the problem before you
  investigate it or change any code.

## Steps

Steps 1 to 4 are cited as `resolve-problem` §1 to §4.

### 1. Record before you touch anything

Check first that the problem is not already recorded:
`.guardrails/scripts/find-items.sh list --kind PR --status open` lists the
open problem reports, and `find-items.sh show ID` prints one. If an open item
describes this problem, work under its ID and do not record a second one.

Otherwise, add the problem to this change's draft file in the problems ledger,
`docs/problems/DRAFT-<branch>-<slug>.md` (directory from `doc_problems` in
`.guardrails/config.yaml`).

Mint the ID first, with `.guardrails/scripts/new-id.sh PR`, and write the item
with the ID it printed:

```
  **PR-NNNNNN**: <observable symptom, one sentence>.
  affects: <REQ/RC/SDD/LLR IDs implicated — best current guess>.
  opened: <today, YYYY-MM-DD>
  status: open
```

The form above is indented and uses `NNNNNN` so that it defines no item. In the
ledger, write the item flush left, with the ID `new-id.sh` printed.

- `opened:` is required on an open item. It is read at column one, and the
  first occurrence is the one read.
- Its value is today's date: a real calendar date in `YYYY-MM-DD`, at most one
  day ahead of the machine that runs the check. Anything further ahead is
  `MALFORMED-DATE`.
- Do not add an owner field. Anyone may resolve a problem.
- `check-trace.sh` reports an item with no `opened:` or no `status:` as
  `INCOMPLETE-PROBLEM`.

An open item remains open until it is resolved or ruled on. `check-trace.sh`
prints `UNRESOLVED-PR` with the item's age at every run. Past the project's
`problem_age_days` or `problem_open_max` the warning becomes a failure: resolve
the item, rule on it (`status: accepted` with a `disposition:`, §4), or raise
the limit deliberately. Do not leave it open indefinitely.

### 2. Investigate systematically

Find the root cause before proposing a fix: read the error, reproduce it, form
a hypothesis, test the hypothesis. Do not write speculative fixes. Update the
PR item's `affects:` list as the real scope emerges.

Escalate when the investigation finds one of these:

- **The behavior violates no written requirement:** the requirement is
  missing. Run `grill-requirements` (possibly `satisfies: derived`).
- **The bug reveals a hazard the RMF missed, or defeats a risk control:** run
  `analyze-risks` before fixing. The fix may need to become an RC-backed
  requirement.
- **The spec itself is wrong:** that is a requirements change with its own
  review, not a silent reinterpretation.
- **The bug is a consequence of the design, not of this line:** a fix at the
  point of failure closes this occurrence and leaves every other one the
  design allows. Ask whether a structural change would prevent all of them,
  and if so run `design-architecture` before fixing. When the answer is
  unclear, put it to the user.

### 3. Fix under TDD

Reproduce the bug as a **failing test first**, annotated with the ID it
violates (`verifies: …`), per `develop-change`. Then write the minimal fix, go
green, and refactor. Keep the reproduction test: it is permanent regression
evidence.

### 4. Resolve in the same change that merges the fix

In the worktree that fixes it, update the PR item **in the dated ledger file
that defines it**: set `status: resolved`, and append a one-line resolution:
the root cause and the fix reference (the reproducing test name or file).
Never mark a problem resolved in a change that does not contain its fix. In
any document, name the IDs a change resolves or opens; never state the open
count, which the next merge makes false.

Then run the normal gate: `check-traceability`, `verify-before-merge`,
`merge-change`.

**When the ruling is "we are not fixing this".** A problem that was
investigated and deliberately not fixed goes to `status: accepted`, with a
`disposition:` line that states the ruling and the date it was made:

```
  **PR-NNNNNN**: <observable symptom, one sentence>.
  affects: <REQ/RC/SDD/LLR IDs implicated>.
  opened: <the date it was recorded, YYYY-MM-DD>
  status: accepted
  disposition: ruled on <YYYY-MM-DD> — <why the software is not changing>
```

The form is indented and uses `NNNNNN` for the same reason as the form in §1.

- An accepted item is exempt from `problem_age_days` and does not count toward
  `problem_open_max`. `check-trace.sh` still prints it as `ACCEPTED-PR` with
  the ruling at every run, and the `problems:` summary counts it as
  `accepted N`.
- `disposition:` is required. `check-trace.sh` reports
  `INCOMPLETE-PROBLEM … (accepted, no disposition:)`, and the same for an
  accepted item with no `opened:`.
- Do not set `accepted` to clear a red `PROBLEM-BACKLOG`. Set it only when you
  can state a ruling you can defend, with its date.
- `accepted` is not `resolved`. Use `resolved` only when the merging change
  contains a fix. Use `accepted` when there is no fix and there is a reason.
- If the ruling later changes, set the item back to `open` and resolve it
  under §3.

## Red flags

| Thought | Reality |
|---|---|
| "Tiny bug, skip the PR item" | Tiny bugs in regulated software are still records. 30 seconds. |
| "Fix now, log later" | A deferred record does not get written. Record first. |
| "Close the PR, fix ships next week" | Resolved means the merging change contains the fix. |
| "The test would just duplicate the fix" | The failing reproduction is the evidence the fix works. |
| "Mark it accepted, the backlog is red" | `accepted` needs a `disposition:` — a ruling you can defend, with a date. No ruling, no exemption. |
| "State the backlog size so the reader knows where we are" | The reader's own `check-trace.sh` run knows. A number in a document measures a tree that no longer exists. Name the IDs that moved. |

## Done when

- The PR item was recorded in the ledger before the investigation started,
  with `opened:` and `status:`.
- Where the bug is fixed, a failing test reproduced it, annotated with the ID
  it violates, and it passes after the fix.
- The item in its dated ledger file is `status: resolved` with a one-line
  resolution, in the change that contains the fix; or it is
  `status: accepted` with a dated `disposition:`.
- `check-traceability`, `verify-before-merge` and `merge-change` follow.

## References

- `references/rationale.md` — read when a rule here seems wrong for your case,
  or before proposing to change one.
