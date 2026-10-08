---
name: develop-change
description: TDD implementation loop for guardrails projects - failing test first, verifies-annotations mandatory, minimal code to green, plan tasks dispatched to subagents. Use when implementing any feature, fix, or refactor.
---

# Develop Change

**Announce at start:** "Using the develop-change skill (TDD)."

## Preconditions

- You are in a worktree (`worktree-discipline`).
- For a non-trivial change, a plan exists (`plan-change`).
- If you are a dispatched subagent, run the loop below yourself in the task
  worktree your prompt names, return the dispatch report, and do not dispatch
  again.

## Steps

**No production code without a failing test first.** If you wrote code before
its test, delete it and start over from the test. Keeping it "as reference" is
the same violation.

### The loop, one behavior at a time

1. **RED:** write one minimal test for one behavior. Every new test declares
   what it verifies, in a comment or the test name:

   ```
   # verifies: <IDs>
   ```

   Annotate the **lowest requirement level that exists**: where an item has
   LLRs, the test verifies the LLR (the parent REQ is covered transitively);
   where there are no LLRs, the test verifies the REQ or RC directly.

   If you cannot annotate a test, the requirement it tests does not exist.
   Stop and run `grill-requirements` (or `analyze-risks` for risk-control
   behavior) before going on.
2. **Verify RED:** run the test and watch it fail for the right reason: the
   feature is missing, not a typo. A test that passes immediately proves
   nothing.
3. **GREEN:** write the minimal code that passes. No extra features, no
   speculative options.
4. **Verify GREEN:** run the test; every other test still passes; the output
   is clean.
5. **REFACTOR:** duplication, names, helpers. Behavior is unchanged and the
   tests stay green.
6. **Grep the mutation anchors for each line you changed in a script.** Each
   `docs/verification/*.mutations/M*.sh` quotes a line of the script it
   mutates, and an edit to that line stops the mutation applying. From the
   repository root, one grep per changed line:

   ```sh
   grep -rn 'the exact line you changed' docs/verification/*.mutations/
   ```

   On a hit, keep your edit, re-cut the anchor to the new text, and prove the
   re-cut anchor applies and still kills tests (`references/mutation-anchors.md`).
7. **Commit** (unsigned is fine in the worktree) and take the next test.

**Class rules.** Read `safety_class` from `.guardrails/config.yaml`:

- **B and C, the robustness rule:** every REQ and LLR gets both normal-case
  tests and abnormal-input tests: bad input, boundary values, resource
  exhaustion, dependency failure. A requirement with only happy-path tests is
  not verified; the independent review at merge checks for this.
- **C:** every SDD item the change touches gets tests at its own interface
  (its LLRs), not only end-to-end.

**Bugs.** A bug is a missing test. Reproduce it as a failing test annotated
with the REQ it violates, then fix it. If the bug reveals a hazard the RMF
missed, run `analyze-risks` before closing.

### Where a test attaches

**A test calls only an interface that a REQ or LLR describes.** A private
helper is covered through the interface above it. Without LLRs, the seam is
the REQ level: the public interface. A user journey is a REQ only when it
states an outcome none of its steps states; otherwise it verifies theirs.

**A deeper interface gets a direct test only once it has an LLR**
(`design-architecture`). It earns one only when a case cannot be triggered
from above without faking code the project owns, when its cases multiply past
enumeration from above, or when it is maths, parsing, encoding or a numerical
transform. A case reachable from above is tested there.

**Test doubles.** Never mock code the project owns or assert how it was
called. Fake only at the codebase boundary, behind an adapter the project
owns, and give every fake a contract test that runs against the real
dependency wherever it is reachable. A service the project owns runs for real
on the normal path; its failures may be injected or faked. Assert an
interaction only where the interaction is the requirement.

**Permutations and evidence.** Prefer a property test where cases are
combinatorial or the code is maths, parsing or encoding;
fix or print its seed, and pin each counterexample as an
example test before the fix. A surviving mutant means a missing test at the
seam, or dead code: never a test below the seam.

**UI.** The REQ interface is what the user perceives and does, plus what the
app sends out. A markup snapshot carries no `verifies:` annotation.

These rules bind the tests a change writes or edits. An existing test that
breaks them and must be edited moves to the seam; one that still passes is
left alone.

### Delegation: dispatch every plan task

You orchestrate the loop: a subagent runs it for one plan task, and you keep
the plan, the trace and the decisions.

- **Dispatch every plan task**, including a plan of one task. Do not ask the
  user for permission to dispatch; it is the normal path.
- **At most five at once, and only across disjoint files.** Fan out only
  across tasks whose **Files touched:** sets do not intersect (`plan-change`).
  Run everything else serially.
- **Keep the prompt to a pointer** to the plan task. Use whatever your harness
  offers for dispatching a subagent (a `Task` or `Agent` tool, an `/agent`
  command):

  ```
  Execute task 3 of docs/plans/2026-08-30-<topic>.md under the develop-change
  skill. Create your task worktree with
  `sh .guardrails/scripts/task-worktree.sh start t3` from the change worktree
  you are in; it is .worktrees/<change-branch>-t3, on branch
  <change-branch>-t3 off <change-branch>. Commit your work on that branch and
  leave it there — do not merge it. Once your task worktree exists,
  do not commit on <change-branch> and do not keep working in the change
  worktree. Return the dispatch report.
  ```

  **Name the task worktree path in the prompt.** The subagent is pinned to the
  change worktree's subtree and cannot discover the pin before it violates it
  (`worktree-discipline` step 1). It starts in the change worktree and runs
  `task-worktree.sh start` there; what the prompt forbids begins once the task
  worktree exists: commits on the change branch, and further work in the
  change worktree.

  Do not restate the task. The plan already contains the paths, the code and
  the expected output.
- **Merge each task branch yourself.** The subagent commits on its task branch
  and does not merge. When its report is green, run in the change worktree:

  ```sh
  sh .guardrails/scripts/task-worktree.sh merge <tag>
  ```

  It merges the task branch into the change branch, then removes the task
  worktree and the task branch. The base branch is never touched.

### The dispatch report

The subagent returns this shape and nothing else: no diffs, no logs, no
narrative.

```
task: <ID>
worktree: <path to the task worktree>
files touched: <paths>
tests added: <test name — verifies: <IDs>>   (one per line)
red -> green: <test name> — watched fail for the right reason before the
implementation existed   (one per line, one per test)
inherited: <test name> — from <old ID>
result: <N passed, N failed>
surprises: <anything unexpected, or "none">
```

- A `worktree:` line naming any path other than the one the prompt stated is a
  task that did not work. Do not merge it. Send the task back to its subagent
  to redo in the stated worktree, or run
  `sh .guardrails/scripts/task-worktree.sh discard <tag>` and dispatch the
  task again. `discard` acts only on the nested path, and rejects a task
  branch checked out anywhere else.
- The `red -> green:` lines are the only record that each test failed before
  its implementation existed. Require one line per new test. `verify-before-merge` check 4 reads them back.
- **Write these and any `inherited:` lines into the plan as each report
  arrives**, beside their task, and mark the task done. `merge-change` step
  6b copies them from the plan into the verification record.

### Derailment: the one stop this skill adds

**Stop only when the answer is the user's.** Repeated failure at the same
point qualifies:

- the same task fails its red -> green cycle twice, or
- review returns findings on the same task twice.

Then stop, report what is stuck and what was tried, and put the choice to the
user: raise the effort level, or decompose the task differently. A task that
is hard is not a reason to stop.

Below that threshold, keep looping and re-dispatch, but **change the approach**
in the new prompt. A re-dispatch that restates the same task the same way
produces the same failure.

Two other stops are deliberate and are the user's call:
`worktree-discipline` step 4 (a red baseline) and `verify-before-merge`
check 5 (accepting a documented coverage gap). Outside those, keep looping.

**Read code only when a decision requires it:** a dispatch report states
something unexpected, two tasks look like they diverge, or a finding needs
adjudicating.

### The deslop pass

When the last task branch is merged and the suite is green, dispatch **one**
subagent over the whole change diff before handing off:

```
Review main...<change-branch> under the code rules in AGENTS.md.
Work in the change worktree at <path>, on <change-branch>. Do NOT create a task
worktree — this pass fixes on the change branch directly.
Report and fix, on <change-branch>: slop, unclear names, duplication between
tasks, and anything that can be simpler. Do not change behavior — the suite
must stay green. Return the report shape below.
```

**This is the one dispatch that does not get its own task worktree**, so the
prompt states the change worktree path and the prohibition together. Without
them the subagent follows the other dispatches and creates a task worktree.

It returns:

```
files changed: <paths>
fixed: <one line per fix>
left alone: <anything it judged not worth changing, with the reason>
suite: <N passed, N failed>
```

It is the only agent that sees the whole change, so it is the only place
cross-task duplication is caught: two tasks adding the same helper, or one
concept with a different name in each.

Run it here, not at `merge-change` step 6a: that sequence **reruns from step 1** on
any finding.

## Red flags

| Thought | Reality |
|---|---|
| "I'll keep the code I wrote as reference while I write the test" | Delete it and start from the test. |
| "The test passed on its first run, good" | It proves nothing. Find out why it did not fail. |
| "One task, no concurrency, I'll do it myself" | Dispatch it. The code and test output stay out of your context. |
| "The subagent can merge its own branch" | Git rejects an update to the change branch, which your worktree has checked out, and `git merge <change-branch>` from the task worktree merges the wrong direction and exits 0. You run `task-worktree.sh merge`. |
| "The result line is green, so every test was red once" | Only a `red -> green:` line states that. |
| "Re-dispatch with the same prompt" | Change the approach first. |
| "Fix the names at `merge-change` step 6a" | That reruns the merge sequence. Run the deslop pass here. |
| "This helper is complex, I'll test it directly" | Give it an LLR first, or test it through the interface above (`references/test-seams.md`). |

## Done when

- Every plan task is complete and its `red -> green:` lines are in the plan.
- The suite is green.
- The deslop pass was run and its findings are fixed.
- `check-traceability` and `verify-before-merge` follow. Never claim done
  without them.

## References

- `references/mutation-anchors.md` — read when the step 6 grep finds a hit.
- `references/test-seams.md` — read when you are about to add an LLR to get a
  test seam or write a test double, or when a mutant survives.
- `references/ui-seams.md` — read when the change has a user interface.
- `references/rationale.md` — read when a rule here seems wrong for your case,
  or before proposing to change one.
