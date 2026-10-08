---
name: tailor-guidelines
description: Make one guidelines file (such as docs/TEST_GUIDELINES.md) the project's own - seed a complete copy of the default, walk its clauses one question at a time, keep the compliance floor, and adopt a new default clause by clause on upgrade. Use when ratchet sets up or upgrades a project, or when a project wants to change its test guidelines.
---

# Tailor Guidelines

**Announce at start:** "Using the tailor-guidelines skill to tailor `<KIND>_GUIDELINES.md`."

## Preconditions

- You are in a change worktree (`worktree-discipline`). A guidelines file is
  a change like any other.
- You know the kind: `TEST` (`docs/TEST_GUIDELINES.md`). Where
  `.guardrails/units.yaml` exists, you know whether the file is for the root
  or for one unit; ask if you were not told.
- A guidelines file holds the project's preferences. The floor, which a
  standard or a gate needs, stays in the skills, and no clause overrides it.

## Steps

1. **Find or seed the target.** The target is `docs/<KIND>_GUIDELINES.md`,
   or `<unit>/docs/<KIND>_GUIDELINES.md` for a unit; a unit's file
   replaces the root file entirely for that unit, and the two are never
   merged. Absent, seed it as a complete copy,
   of the root file for a unit that has one, otherwise of the installed
   default `.guardrails/templates/<KIND>_GUIDELINES.md`.
   Never write a reference to the source in the copy. The reader is handed
   this one file, and a rule it cannot open is a rule it cannot apply.
2. **Walk the clauses one per message.** Show the clause and its reason, and
   ask: keep, change or drop? Recommend an answer. A change rewrites the
   reason and the examples with the rule, so the reason still fits it.
3. **Make the examples the project's.** For each clause under `## Seams` and
   `## Doubles`, ask for an example in the project's own stack (its language,
   test runner and dependencies), and replace the generic one with it.
4. **Drop `## UI` where the project has no user interface.** Ask; do not
   infer it from the file tree.
5. **Reject a change that contradicts the floor**, and say which floor item
   it breaks. The floor, listed here in full:
   - every test carries `verifies:`;
   - every new test was watched red;
   - every test fails when the behavior it `verifies:` breaks, so an assertion
     only that a double was called meets it only where the call is the
     requirement;
   - class B and C: abnormal-input tests for every REQ and LLR;
   - class C: tests at every touched SDD item's interface.

   A clause may tighten the floor, never loosen it.
6. **Check the file stands alone.** No clause refers to another guidelines
   file, to the installed default, or to a document the project does not
   contain.
7. **Commit** in the worktree; `merge-change` integrates it.

### Upgrade mode

Run this when `ratchet` upgrades a project, before the new template is
copied over the installed default.

1. Where the project has no file of this kind, it follows the installed
   default and there is nothing to walk; stop.
2. Diff the installed default (old) against the shipped template (new):
   `git diff --no-index .guardrails/templates/<KIND>_GUIDELINES.md
   <guardrails>/templates/<KIND>_GUIDELINES.md`.
3. Walk each changed clause one per message, showing the old and new text
   and the new reason: adopt into the project file, adapt, or decline.
   Apply step 5's floor check to each adoption.
4. Never overwrite the project file. A declined clause stays as the project
   wrote it.
5. Commit; `ratchet` then copies the new template with the scripts.

## Red flags

| Thought | Reality |
|---|---|
| "I'll write 'see the default for the rest'" | The file stands alone. Copy what is kept. |
| "The new default is better, I'll replace the file" | Clause by clause. Never overwrite. |
| "This clause is only a preference, the floor can bend here" | The floor wins. Reject the change and say why. |
| "I'll ask about all the clauses in one message" | One clause per message, with its reason. |
| "The generic examples will do" | Ask for the project's own for Seams and Doubles. |

## Done when

- The target file exists as a complete copy with no reference to its source.
- Every clause was kept, changed or dropped with the user, and every changed
  clause has a reason and examples that fit it.
- No clause contradicts the floor.
- In upgrade mode, every changed clause of the template was adopted, adapted
  or declined, and the project file was never overwritten.
- The change is committed in the worktree for `merge-change`.
