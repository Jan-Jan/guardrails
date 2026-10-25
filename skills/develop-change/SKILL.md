---
name: develop-change
description: Implementation orchestrator for guardrails projects - dispatch every plan task to a subagent under develop-tdd, merge the task branches, then run one review-conformance review per guidelines file and dispatch the fixes. Use when implementing any feature, fix, or refactor.
---

# Develop Change

**Announce at start:** "Using the develop-change skill to dispatch the plan."

## Preconditions

- You are in a worktree (`worktree-discipline`).
- For a non-trivial change, a plan exists (`plan-change`).
- You are the dispatcher. A task subagent loads `develop-tdd`, a reviewer
  loads `review-conformance`, and a fixer loads `develop-tdd` or
  `develop-refactor`, never this skill.

## Steps

### Delegation: dispatch every plan task

You orchestrate the loop: a subagent runs it for one plan task under
`develop-tdd`, and you keep the plan, the trace and the decisions.

- **Dispatch every plan task**, including a plan of one task. Do not ask the
  user for permission to dispatch; it is the normal path.
- **At most five at once, and only across disjoint files.** Fan out only
  across tasks whose **Files touched:** sets do not intersect (`plan-change`).
  Run everything else serially.
- **Keep the prompt to a pointer** to the plan task. Use whatever your harness
  offers for dispatching a subagent (a `Task` or `Agent` tool, an `/agent`
  command):

  ```
  Execute task 3 of docs/plans/2026-08-30-<topic>.md under the develop-tdd
  skill. Create your task worktree with
  `sh .guardrails/scripts/task-worktree.sh start t3` from the change worktree
  you are in; it is .worktrees/<change-branch>-t3, on branch
  <change-branch>-t3 off <change-branch>. Commit your work on that branch and
  leave it there — do not merge it. Once your task worktree exists,
  do not commit on <change-branch> and do not keep working in the change
  worktree. For each of the task's paths, follow
  the guidelines file `guidelines-file.sh TEST` printed for it:
  <file>: <paths>   (one line per file it printed)
  Return the dispatch report.
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

The subagent returns the report shape `develop-tdd` states, and nothing
else: no diffs, no logs, no narrative.

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
  5 copies them from the plan into the verification record. A fix
  dispatched after step 5 (a 6a or 6c failure's fix, a base-move round's
  review) writes its lines into the verification record directly.

### Derailment and the other stops

**Stop only when the answer is the user's.** Repeated failure at the same
point qualifies:

- the same task fails its red -> green cycle twice,
- review returns findings on the same task twice, or
- a conformance review reports a finding again after the fix dispatched for
  it was merged.

A conformance round with new findings is the loop working, not a repeat:
only a recurring finding counts, the same guideline clause at the same
place. A place is the file and lines the earlier finding cited; the same
clause at another site is a new finding, not a recurrence. Only a finding
above low counts: a round with nothing above low is the last, whatever
recurs in it. Compare against the findings already written in the plan; the
reviewer is fresh each round and does not know them.

Then stop, report what is stuck and what was tried, and put the choice to the
user: raise the effort level, or decompose the task differently; for a
recurring conformance finding, accept the finding, or rule against the
guideline clause. A task that is hard is not a reason to stop.

Below that threshold, keep looping and re-dispatch, but **change the approach**
in the new prompt. A re-dispatch that restates the same task the same way
produces the same failure.

Three other stops are deliberate and are the user's call:

- `worktree-discipline` step 4 (a red baseline),
- `verify-before-merge` check 5 (accepting a documented coverage gap), and
- an architecture finding `develop-refactor` returns as needing a design
  change, which `design-architecture` takes up: the alternatives are the
  user's.

Outside those, keep looping.

**Read code only when a decision requires it:** a dispatch report states
something unexpected, two tasks look like they diverge, or a finding needs
adjudicating.

### The conformance reviews

When the last task branch is merged, pick the guidelines files for the
change diff:

```sh
sh .guardrails/scripts/guidelines-file.sh TEST \
    $(git diff --name-only main...<change-branch>)
sh .guardrails/scripts/guidelines-file.sh CODE \
    $(git diff --name-only main...<change-branch>)
sh .guardrails/scripts/guidelines-file.sh ARCHITECTURE \
    $(git diff --name-only main...<change-branch>)
```

If any exits 2 or is missing, stop and reinstall the guardrails scripts
and templates (`ratchet`'s upgrade). For each file any prints, dispatch
one subagent under the `review-conformance` skill, all at once: each reads
one file and changes nothing, so no two can conflict.

```
Review main...<change-branch> under the review-conformance skill against
<file>, for these paths: <paths>. Read the change worktree at <path>; do not
create a task worktree, edit, or commit. Return the report review-conformance
states.
```

**A reviewer changes nothing and gets no task worktree.** The prompt states
the change worktree path and the prohibition together; without them the
subagent follows the other dispatches and creates a task worktree.

Once every review has reported, dispatch the fixes: one subagent per review
with findings, in a nested task worktree as any task, `develop-refactor` for
a `CODE` or `ARCHITECTURE` file's findings and `develop-tdd` for a `TEST`
file's, and merge each with `task-worktree.sh merge`. An architecture finding
`develop-refactor` returns as needing a design change goes to
`design-architecture` (Derailment). Fan out only across disjoint files. The agent
that fixes a finding never reviews it.

```
Fix the findings below, from the review of main...<change-branch> against
<file>, under the develop-refactor skill (develop-tdd for a TEST file).
Create your task worktree with
`sh .guardrails/scripts/task-worktree.sh start <tag>` from the change worktree
you are in; it is .worktrees/<change-branch>-<tag>. Commit there and leave it
there — do not merge it.
<the findings, verbatim>
Return the report the skill states.
```

Then run the reviews again; the first round with nothing above low is the
last. No round count bounds the loop; it stops at the first finding that
recurs (Derailment). Write each finding and its disposition into the plan as
it arrives, as the `red -> green:` lines are; `merge-change` step 5 copies
them into the record's `## Guideline reviews`. These reviews run here, before
`merge-change`, not at its step 4: that sequence **reruns from step 1** on any
finding.

## Red flags

| Thought | Reality |
|---|---|
| "One task, no concurrency, I'll do it myself" | Dispatch it. The code and test output stay out of your context. |
| "The subagent can merge its own branch" | Git rejects an update to the change branch, which your worktree has checked out, and `git merge <change-branch>` from the task worktree merges the wrong direction and exits 0. You run `task-worktree.sh merge`. |
| "The result line is green, so every test was red once" | Only a `red -> green:` line states that. |
| "Re-dispatch with the same prompt" | Change the approach first. |
| "Fix the names at `merge-change` step 4" | That reruns the merge sequence. Run the conformance reviews here. |
| "The reviewer saw the problem; it can fix it too" | A reviewer changes nothing. The fix is a separate dispatch, and the next round reviews it. |
| "One reviewer can check every file" | One file per review. A reviewer with one file misses less. |

## Done when

- Every plan task is complete and its `red -> green:` lines are in the plan.
- Each conformance review, for `TEST`, `CODE` and `ARCHITECTURE`, ran in
  its last round
  with nothing above low, and every finding is fixed or dispositioned.
- `check-traceability` follows, then `merge-change`, whose step 6a gate is
  `verify-before-merge`. Never claim the change done before that gate passes.

## References

- `references/rationale.md` — read when a rule here seems wrong for your case,
  or before proposing to change one.
