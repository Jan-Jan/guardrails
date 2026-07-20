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
**Implements:** <REQ/RC/SDD IDs this change delivers — draft or final>
**Safety class:** <from .guardrails/config.yaml, plus per-item overrides>
**Verification:** <the verify_commands that must pass>
```

## Task rules

- Each task = smallest unit with its own test cycle: write failing test →
  see it fail → minimal implementation → see it pass → commit.
- **Every task lists its trace IDs.** The tests written in the task carry
  `verifies: <IDs>` annotations — put the exact annotation text in the plan.
- Test deliverables are explicit steps with actual test code, never "add
  tests later".
- Steps that change documentation items (SRS/RMF/SAD) mint draft IDs and say
  so in the step.
- No placeholders: "TBD", "handle edge cases", "similar to task N" are plan
  failures.

## Self-review before handing off

1. Every ID in **Implements:** has at least one task whose test verifies it.
2. Every task's code steps show real code, real commands, expected output.
3. Names/signatures used across tasks are consistent.

## Execution

Execute with `develop-change` (TDD) task by task, then `check-traceability`,
`verify-before-merge`, and `merge-change`.
