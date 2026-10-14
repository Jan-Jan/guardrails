---
name: develop-refactor
description: Fix the findings of one CODE conformance review in a guardrails project - each finding against the project's code guidelines file, in a nested task worktree, with no behavior change. Load it only when develop-change dispatched you to fix CODE findings.
---

# Develop Refactor

**Announce at start:** "Using the develop-refactor skill on <file>'s findings."

## Preconditions

- You were dispatched by `develop-change` with the findings of one
  `review-conformance` review against a code guidelines file, that file, the
  diff range and your task worktree path.
- Create the task worktree as the prompt says, from the change worktree you
  start in, and work only there. Commit on the task branch and leave it
  there. Do not merge it, and do not dispatch again.
- You fix what the findings state. You did not review the diff, and you do
  not review your own fix: the next review round does.

## Steps

1. **Read the guidelines file and the findings.** Read the one file the
   prompt names and no other guidelines file. Each finding cites a clause
   as `Heading N` and a `file:line`.
2. **Fix each finding at its line, as its clause states.** Fix every place
   the same finding names; leave the rest of the code as it is.
3. **Change no behavior.** Do not change behavior: the suite must stay
   green. Run the project's `verify_commands` after each fix, and commit it
   unsigned (`git -c commit.gpgsign=false commit`). Never delete, skip or
   loosen a test to keep the suite green.
4. **Report a finding you cannot fix as not fixed, with the reason:** a fix
   that would change behavior, a finding the code does not bear out, or a
   clause that contradicts the floor, which is a finding against the clause.
   The floor: every test carries `verifies:`; every test fails when the
   behavior it `verifies:` breaks; class B and C keep abnormal-input tests
   for every REQ and LLR; class C keeps tests at every touched SDD item's
   interface. The dispatcher decides each one.
5. **Return the report** below and nothing else: no diffs, no logs.

### The report

```
task: <tag>
worktree: <path to the task worktree>
files touched: <paths>
fixed: <finding-N — what changed, or "not fixed — <reason>">   (one per line)
result: <N passed, N failed>
```

## Red flags

| Thought | Reality |
|---|---|
| "While I'm here, I'll tidy the rest of the file" | Fix the findings. Anything else is the next review's to find. |
| "This rewrite is cleaner and changes behavior only a little" | No behavior change. Report it as not fixed, with the reason. |
| "The test is in the way of the fix; I'll loosen it" | Never. The suite stays green as it is. |
| "This finding is wrong; I'll skip it quietly" | Report it as not fixed, with the reason. The dispatcher decides. |
| "I'll merge my task branch when I am done" | Leave it on the task branch. The dispatcher runs `task-worktree.sh merge`. |

## Done when

- Each finding is fixed or reported not fixed with its reason.
- Each fix is committed on the task branch, which is not merged.
- The suite is green.
- The report is returned.
