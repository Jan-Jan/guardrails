---
name: plan-change
description: Write a bite-sized, trace-aware implementation plan for a change in a guardrails project. Use after requirements/risks/design exist and before writing any code.
---

# Plan Change

**Announce at start:** "Using the plan-change skill to write the implementation plan."

Write the plan for an engineer with zero context and questionable taste:
exact paths, complete code in steps, exact commands with expected output.
Save to `docs/plans/YYYY-MM-DD-<topic>.md` in the change's worktree.

## Preconditions

- The REQs this change implements exist in the SRS (else `grill-requirements`
  first); safety-relevant changes have RMF coverage (else `analyze-risks`);
  structural changes have SDD items (else `design-architecture`).
- You are in a worktree (`worktree-discipline`).

## Plan header (mandatory)

```markdown
# <Change> Implementation Plan

**Goal:** <one sentence>
**Implements:** <REQ/RC/SDD IDs this change delivers>
**Safety class:** <from .guardrails/config.yaml, plus per-item overrides>
**Verification:** <the verify_commands that must pass>
```

## Task rules

- Each task = smallest unit with its own test cycle: write failing test →
  see it fail → minimal implementation → see it pass → commit.
- **Every task lists its trace IDs.** The tests written in the task carry
  `verifies: <IDs>` annotations — put the exact annotation text in the plan.
- **Every task states its files and its parallelism.** Head each task with the
  exact paths it touches and whether it may run alongside another:

  ```markdown
  ### T<N> — <title>

  **Files touched:** <exact paths, one list, no globs>
  **Parallel:** yes | no (serial, after T<N>)
  ```

  Fan-out is permitted only across tasks whose file sets do not intersect. Two
  tasks that touch the same file run serially however independent they look —
  the gate is the file sets, not your judgment about them.
- Test deliverables are explicit steps with actual test code, never "add
  tests later".
- Steps that change documentation items (SRS/RMF/SAD) mint their IDs with
  `.guardrails/scripts/new-id.sh <PREFIX>` and say so in the step. The IDs are
  final from the moment they are minted, so the plan can name them.
- No placeholders: "TBD", "handle edge cases", "similar to task N" are plan
  failures.

## Self-review before handing off

1. Every ID in **Implements:** has at least one task whose test verifies it.
2. Every task's code steps show real code, real commands, expected output.
3. Names/signatures used across tasks are consistent.
4. Every task carries **Files touched:** and **Parallel:**, and no two tasks
   marked parallel name the same file.

## Execution

Execute with `develop-change` (TDD) task by task, then `check-traceability`,
`verify-before-merge`, and `merge-change`.
