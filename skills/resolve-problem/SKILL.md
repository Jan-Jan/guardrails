---
name: resolve-problem
description: Problem-report workflow for guardrails projects - record every bug as a PR item, reproduce it as a failing annotated test, fix under TDD, resolve in the merging change. Use when any bug, anomaly, test failure, or unexpected behavior is found.
---

# Resolve Problem

**Announce at start:** "Using the resolve-problem skill."

Every bug is a change-control event, not a quick fix. In a regulated project
the record of *what went wrong and what was done about it* matters as much
as the fix (IEC 62304 problem resolution; DO-178C §7.2.8 problem reports).

## 1. Record before you touch anything

In a worktree (`worktree-discipline`), add the problem to this change's
draft file in the problems ledger, `docs/problems/DRAFT-<branch>-<slug>.md`
(directory from `doc_problems` in `.guardrails/config.yaml`):

Mint the ID first — `.guardrails/scripts/new-id.sh PR` — and write the item
with the ID it printed:

```
  **PR-NNNNNN**: <observable symptom, one sentence>.
  affects: <REQ/RC/SDD/LLR IDs implicated — best current guess>.
  opened: <today, YYYY-MM-DD>
  status: open
```

(Indented, and `NNNNNN` rather than a real token, for the same two reasons the
ledger READMEs give: a real ID here is a reference to an item that does not
exist, and a definition form at column one is judged wherever it appears —
in a fenced block too. Write the item flush left in the ledger, with the ID
`new-id.sh` printed.)

`opened:` is required on an open item and is read at column
one; the first occurrence is the one read. It is today's date — a real
calendar date in `YYYY-MM-DD`, and no more than one day ahead of the machine
that runs the check (that one day of tolerance exists so a timezone difference
does not fail a correct item; anything further is `MALFORMED-DATE`). It exists
so the open list can be triaged rather than scrolled past: without an age
nothing can go stale. There is no owner field — authorship is already answered
by `git blame` on the ledger line, and problems are not personally owned:
anyone may resolve them.
`check-trace.sh` reports a missing `opened:` as
`INCOMPLETE-PROBLEM`, and an item with no `status:` at all the same way —
before that check such an item read as *resolved*.

Recording first is the discipline: if investigation dead-ends, the open PR
remains and appears at every merge (`check-trace.sh` prints
`UNRESOLVED-PR` warnings until it's resolved, with the item's age
on the line). Past the project's `problem_age_days` or `problem_open_max`
the warning becomes a failure — resolve it, rule on it (`status: accepted`
with a `disposition:`, §4), or raise the limit deliberately, but do not leave
it open indefinitely.

## 2. Investigate systematically

Find the root cause before proposing a fix — read the error, reproduce it,
form a hypothesis, test the hypothesis. No speculative "fixes". Update the
PR item's `affects:` list as the real scope emerges.

Escalations discovered during investigation:

- **The behavior violates no written requirement** → the requirement is
  missing; run `grill-requirements` (possibly `satisfies: derived`).
- **The bug reveals a hazard the RMF missed, or defeats a risk control** →
  run `analyze-risks` before fixing; the fix may need to become an RC-backed
  requirement.
- **The spec itself is wrong** → that's a requirements change with its own
  review, not a silent reinterpretation.
- **The bug is a consequence of the design, not of this line** → a fix at the
  point of failure closes this occurrence and leaves every other one the
  design allows. Ask whether a structural change would prevent all of them,
  and if so run `design-architecture` before fixing. When the answer is
  unclear, put it to the user.

## 3. Fix under TDD

Reproduce the bug as a **failing test first**, annotated with the ID it
violates (`verifies: …`), per `develop-change`. Then the minimal fix, green,
refactor. The reproduction test is permanent regression evidence.

## 4. Resolve in the same change that merges the fix

In the worktree that fixes it, update the PR item **in the dated ledger
file that defines it**: `status: resolved`, and
append a one-line resolution: root cause + fix reference (the reproducing
test name or file). The PR item and the fix merge together — never mark a
problem resolved in a change that doesn't contain its fix.

Then the normal gate: `check-traceability`, `verify-before-merge`,
`merge-change`.

### When the ruling is "we are not fixing this"

A problem that was investigated and deliberately not fixed is **not** the same
as a problem nobody has got to. It goes to `status: accepted`, with a
`disposition:` line containing the ruling and the date it was made:

```
  **PR-NNNNNN**: <observable symptom, one sentence>.
  affects: <REQ/RC/SDD/LLR IDs implicated>.
  opened: <the date it was recorded, YYYY-MM-DD>
  status: accepted
  disposition: ruled on <YYYY-MM-DD> — <why the software is not changing>
```

(Indented and `NNNNNN`, for the same two reasons as the item form above.)

That is the *decided* / *forgotten* distinction, and it is the whole point of
the status. An accepted item stops aging — it is exempt from
`problem_age_days` and does not count toward `problem_open_max`, because
neither limit measures anything about a decision, and a project that triages
honestly should not hit the ceiling faster than one that quietly drops things.
It stays in the roll-call: `check-trace.sh` prints `ACCEPTED-PR` with the
ruling at every merge, and the `problems:` summary counts it as `accepted N`.
A decision nobody is reminded of decays back into a thing nobody remembers
deciding.

**`disposition:` is required, and rejecting `accepted` without one is what
makes the status safe.** Without it, `accepted` is a one-word escape from both
limits — reachable by an author staring at a red `PROBLEM-BACKLOG` — and the
gate would ship its own bypass. `check-trace.sh` reports
`INCOMPLETE-PROBLEM … (accepted, no disposition:)`, and the same for an
accepted item with no `opened:`. So this is not a way out of a backlog: it is
a way to record a ruling you can defend, and the ruling is the price.

`accepted` is not `resolved`. Use `resolved` only when the merging change
contains a fix; use `accepted` when there is no fix and there is a reason
(IEC 62304 6.2 treats a documented decision not to change the software as a
resolution outcome in its own right). If the ruling later changes, put the
item back to `open` and resolve it under §3.

## Red flags

| Thought | Reality |
|---|---|
| "Tiny bug, skip the PR item" | Tiny bugs in regulated software are still records. 30 seconds. |
| "Fix now, log later" | A deferred record does not get written. Record first. |
| "Close the PR, fix ships next week" | Resolved means the merging change contains the fix. |
| "The test would just duplicate the fix" | The failing reproduction is the evidence the fix works. |
| "Mark it accepted, the backlog is red" | `accepted` needs a `disposition:` — a ruling you can defend, with a date. No ruling, no exemption. |
