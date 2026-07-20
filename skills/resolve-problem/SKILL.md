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

```
**PR-DRAFT-<branch>-<n>**: <observable symptom, one sentence>.
affects: <REQ/RC/SDD/LLR IDs implicated — best current guess>.
status: open
```

Recording first is the discipline: if investigation dead-ends, the open PR
survives and shows up at every merge (`check-trace.sh` prints
`UNRESOLVED-PR` warnings until it's resolved).

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

## Red flags

| Thought | Reality |
|---|---|
| "Tiny bug, skip the PR item" | Tiny bugs in regulated software are still records. 30 seconds. |
| "Fix now, log later" | Later never comes. Record first. |
| "Close the PR, fix ships next week" | Resolved means the merging change contains the fix. |
| "The test would just duplicate the fix" | The failing reproduction is the evidence the fix works. |
