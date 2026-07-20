---
name: develop-change
description: TDD implementation loop for guardrails projects - failing test first, verifies-annotations mandatory, minimal code to green. Use when implementing any feature, fix, or refactor.
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
   # verifies: <IDs — draft IDs fine>
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
