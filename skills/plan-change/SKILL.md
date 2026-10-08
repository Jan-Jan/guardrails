---
name: plan-change
description: Write a bite-sized, trace-aware implementation plan for a change in a guardrails project. Use after requirements/risks/design exist and before writing any code.
---

# Plan Change

**Announce at start:** "Using the plan-change skill to write the implementation plan."

## Preconditions

- The REQs this change implements exist in the SRS:
  `.guardrails/scripts/find-items.sh show ID` prints each one, and exits 1
  with `NOT-FOUND` for an ID that is not defined. If one is missing, run
  `grill-requirements` first.
- Read each item the plan cites with `find-items.sh show ID`, not by reading
  the ledger files whole.
- A safety-relevant change has RMF coverage. If not, run `analyze-risks`
  first.
- A structural change has SDD items. If not, run `design-architecture` first.
- You are in a worktree (`worktree-discipline`).

## Steps

1. **Write for an engineer with no context, whose judgment you cannot rely
   on:** exact paths, complete code in steps, exact commands with expected
   output. Save the plan to `docs/plans/YYYY-MM-DD-<topic>.md` in the change's
   worktree.

   Fenced code inside a task section is replaced by a pointer at merge
   (`prune-plans.sh`, `merge-change` step 1), and the merged code is in the
   squash commit. So state each step's intent in prose, and put each
   deviation's reason in the verification record. A fence with a line that
   opens with `red -> green` is kept.
2. **Open the plan with the mandatory plan header:**

   ```markdown
   # <Change> Implementation Plan

   **Goal:** <one sentence>
   **Implements:** <REQ/RC/SDD IDs this change delivers>
   **Safety class:** <from .guardrails/config.yaml, plus per-item overrides>
   **Verification:** <the verify_commands that must pass>
   ```

3. **Make each task the smallest unit with its own test cycle:** write the
   failing test, see it fail, write the minimal implementation, see it pass,
   commit.
4. **List each task's trace IDs.** Put the exact `verifies: <IDs>` annotation
   text of each test the task writes in the plan.
5. **Head each task with its files and its parallelism:**

   ```markdown
   ### T<N> — <title>

   **Files touched:** <exact paths, one list, no globs>
   **Parallel:** yes | no (serial, after T<N>)
   ```

   Mark tasks parallel only where their file sets do not intersect. Two tasks
   that touch the same file run serially, however independent they look: the
   file sets decide, not your judgment about them.
6. **Write test deliverables as explicit steps with the test code.** Never
   "add tests later".
7. **Mint documentation IDs in the step that writes the item.** A step that
   changes an SRS, RMF or SAD item mints its ID with
   `.guardrails/scripts/new-id.sh <PREFIX>` and states so. A minted ID is
   final, so the plan names it.
8. **Write no placeholders.** "TBD", "handle edge cases" and "similar to task
   N" are plan failures.
9. **Self-review before handing off:**
   1. Every ID in **Implements:** has at least one task whose test verifies
      it.
   2. Every task's code steps show real code, real commands and expected
      output.
   3. Names and signatures used across tasks are consistent.
   4. Every task states **Files touched:** and **Parallel:**, and no two tasks
      marked parallel name the same file.
10. **Hand off for execution:** `develop-change` (TDD) task by task, then
    `check-traceability`, `verify-before-merge` and `merge-change`.

## Red flags

| Thought | Reality |
|---|---|
| "These two tasks are independent, they can share a file in parallel" | Same file, serial. The file sets decide. |
| "The tests can follow in a later task" | Each task contains its own test code. |
| "Similar to task 2" | A placeholder. Write the steps out. |

## Done when

- The plan is saved under `docs/plans/` with the four header fields.
- Every task states **Files touched:**, **Parallel:**, its `verifies:`
  annotations and its test code.
- The step 9 self-review passes.
