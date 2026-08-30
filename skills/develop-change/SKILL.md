---
name: develop-change
description: TDD implementation loop for guardrails projects - failing test first, verifies-annotations mandatory, minimal code to green, plan tasks dispatched to subagents. Use when implementing any feature, fix, or refactor.
---

# Develop Change

**Announce at start:** "Using the develop-change skill (TDD)."

Preconditions: you are in a worktree (`worktree-discipline`) and, for
non-trivial changes, a plan exists (`plan-change`).

## The iron law

**No production code without a failing test first.** Wrote code before its
test? Delete it and start over from the test. Keeping it "as reference" is
the same violation.

## Red — Green — Refactor

1. **RED:** write one minimal test for one behavior. Every new test declares
   what it verifies, in a comment or test name:

   ```
   # verifies: <IDs>
   ```

   Annotate the **lowest requirement level that exists**: where an item has
   LLRs, tests verify the LLR (the parent REQ is covered transitively);
   where there are no LLRs, tests verify the REQ/RC directly.

   A test you can't annotate is testing a requirement that doesn't exist —
   stop and run `grill-requirements` (or, if it's risk-control behavior,
   `analyze-risks`) before proceeding.
2. **Verify RED:** run it; watch it fail for the right reason (feature
   missing, not a typo). A test that passes immediately proves nothing.
3. **GREEN:** minimal code to pass. No extra features, no speculative
   options.
4. **Verify GREEN:** run it; all other tests still pass; output pristine.
5. **REFACTOR:** duplication, names, helpers — behavior unchanged, tests
   stay green.
6. **Commit** (unsigned is fine in the worktree) and take the next test.

## Delegation

The loop above is the work; you orchestrate it. A subagent runs the loop for
one plan task, and you keep the plan, the trace and the decisions. If you *are*
the dispatched subagent, run the loop yourself — do not dispatch again.

- **Dispatch by default.** Every plan task goes to a subagent, even when there
  is one task and no concurrency to gain. The gain is not wall-clock; it is
  that the code, the diffs and the test output never enter your context. Do not
  ask the user for permission to dispatch — this is the normal path, not an
  escalation.
- **A task worktree each — and you merge it back.** The subagent creates its
  own task worktree off the change branch, commits there, and returns its
  report. It does not merge, and cannot: git refuses to update a branch another
  worktree has checked out, and the change branch is checked out in yours. From
  the task worktree `git merge <change-branch>` merges the wrong direction, into
  the task branch, and still exits 0 (`worktree-discipline` step 1 lists every
  closed route). So when a dispatch report comes back green, *you* merge that
  task branch into the change branch from the change worktree, then remove the
  task worktree and the task branch. Parallel tasks touch disjoint files, so
  those merges do not conflict with each other. The base branch is never
  touched.
- **At most five at once, disjoint files only.** Fan out only across tasks whose
  **Files touched:** sets do not intersect (`plan-change`). Everything else runs
  serially.
- **The prompt is a pointer, not a copy.** Use whatever your harness offers for
  dispatching a subagent (e.g. a `Task`/`Agent` tool, a `/agent` command), and
  keep the prompt to a pointer:

  ```
  Execute task 3 of docs/plans/2026-08-30-<topic>.md under the develop-change
  skill. Work in a task worktree on branch <change-branch>-t3, off
  <change-branch>. Commit your work on that branch and leave it there — do not
  merge it, do not enter the change worktree. Return the dispatch report.
  ```

  Do not restate the task. `plan-change` already put the exact paths, the real
  code and the expected output in the plan; restating them doubles the cost at
  both ends and lets the two copies disagree.

### The dispatch report

The subagent returns this shape and nothing else — no diffs, no logs, no
narrative:

```
task: <ID>
worktree: <path to the task worktree>
files touched: <paths>
tests added: <test name — verifies: <IDs>>   (one per line)
red -> green: <test name> — watched fail for the right reason before the
implementation existed   (one per line, one per test)
result: <N passed, N failed>
surprises: <anything unexpected, or "none">
```

Without the fixed shape the code simply arrives in the reply instead of in a
read, and the delegation has bought nothing.

The `worktree:` line is how the path reaches you. Only the subagent knows
where its harness put the worktree, and the two usual locations resolve
differently — `.worktrees/` relative to the change worktree, a harness
location beside it (`worktree-discipline` step 1) — so you cannot rebuild the
path from the branch name. You need it to run `git worktree remove` once the
task branch is merged; `git worktree list` is the fallback if a report omits
it.

The `red -> green:` lines are the reason the iron law survives delegation: the
subagent that ran the loop is the only party that saw the test fail, so it is
the only party that can state it, and this line is the only channel by which
that observation reaches you and the gate. State it explicitly, one line per
test — a pass count says the test is green now, never that it was ever red.
`verify-before-merge` check 4 reads these lines back.

**Write those lines into the plan as each report lands**, beside the task they
belong to, along with marking the task done. `merge-change` step 6b copies
them into the verification record, and that is many steps away and reruns from
step 1 on any finding; until then their only holder is this conversation,
which is not durable state (`worktree-discipline`, "The artifacts are the
memory"). Parked in the plan they are an artifact from the moment they arrive,
and 6b copies them from a file instead of from scrollback.

### Derailment — the only stop this skill adds

The test is not a count of stops. **Stop only when the answer is genuinely the
user's.** Repeated failure at the same point qualifies:

- the same task fails its red → green cycle twice, or
- review returns findings on the same task twice.

Then stop and report what is stuck, what was tried, and put the choice to the
user: raise the effort level, or decompose the task differently. Below that
threshold, keep looping and re-dispatch. A task that is merely hard is not a
reason to stop; a task stuck twice in the same place is.

Two other stops in the workflow pass the same test and are deliberate, so do
not treat them as violations of this one: `worktree-discipline` step 4 — a red
baseline needs an explicit decision before you build on it — and
`verify-before-merge` check 5 — accepting a documented coverage gap. Both are
the user's call, not yours. Outside those, keep looping.

### Read code for a decision, not for comfort

State the cost honestly: delegation raises total tokens and wall-clock, and it
costs you your feel for drift across tasks — each subagent sees one task, and
nobody but you sees the shape.

You pay that to keep the context that holds the plan and the trace. So read the
code when a decision genuinely requires it — a dispatch report says something
surprising, two tasks look like they are diverging, a finding needs
adjudicating. The rule is "read for a decision", not "never look".

## Class awareness

`safety_class` from `.guardrails/config.yaml`:
- **B and C — robustness rule:** every REQ/LLR gets BOTH normal-case tests
  and abnormal-input tests (bad input, boundary values, resource
  exhaustion, dependency failure). A requirement with only happy-path
  tests is not verified; the independent review at merge checks for this.
- **C:** unit-level verification is required per software item — every SDD
  item touched needs tests at its own interface (its LLRs), not only
  end-to-end.

## Bugs

A bug is a missing test. Reproduce it as a failing test first (annotated
with the REQ it violates), then fix. If the bug reveals a hazard the RMF
missed, run `analyze-risks` before closing.

## Done when

Plan tasks complete, suite green — then `check-traceability` and
`verify-before-merge`. Never claim done without them.
