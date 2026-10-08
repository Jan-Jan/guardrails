# Why develop-change's rules are what they are

Read this when a rule in `develop-change` seems wrong for your case, or before
proposing to change one. Each heading names the rule it explains.

## The mutation-anchor grep (step 6)

A mutation that no longer applies is past evidence that can no longer be
reproduced. Most changes edit no quoted line, so the step costs one grep.
`references/mutation-anchors.md` states what the suite checks and what it does
not.

## Dispatch every plan task

Dispatching does not save wall-clock time. It keeps the code, the diffs and
the test output out of the dispatcher's context, which contains the plan and
the trace. That applies to a plan of one task as much as to a plan of ten.

Delegation costs total tokens and wall-clock time, and the dispatcher loses
its view of the code across tasks: each subagent sees one task. The dispatcher
accepts that cost to keep its context, and reads code when a decision requires
it, which is why the rule is "read for a decision" and not "never read".

## Disjoint files only

Parallel tasks touch disjoint files, so the dispatcher's merges of their task
branches do not conflict with each other.

## The dispatcher merges, and names the task worktree path

Both rules come from `worktree-discipline` step 1, and its
`references/rationale.md` states the reasons: git rejects a merge into a
branch another worktree has checked out, and a dispatched subagent cannot
discover its pin before it has violated it.

## The prompt forbids the change branch, not the change worktree

Under containment the subagent starts in the change worktree, and it must run
`task-worktree.sh start` from there, so an instruction not to enter the change
worktree cannot be followed. The prohibition begins once the task worktree
exists: no commit on the change branch, and no further work in the change
worktree.

## Keep the prompt to a pointer

`plan-change` already put the exact paths, the code and the expected output in
the plan. Restating them doubles the cost at both ends and lets the two copies
disagree.

## The fixed report shape

Without the fixed shape the code arrives in the reply instead of in a read,
and the delegation gains nothing.

The `worktree:` line repeats a path the prompt already stated. A report naming
any other path is a task that did not work, and one line shows that sooner
than the failures do.

The `red -> green:` lines enforce the failing-test-first rule under
delegation. The subagent that executed the loop is the only party that saw the
test fail, and this line is the only channel by which that observation reaches
the dispatcher and the gate.

## An inherited line is coverage, not evidence

An `inherited:` line names a pre-existing test of a superseded item that the
task pointed at its successor. It is coverage, not red-first evidence: the
successor still needs its own `red -> green:` test. Any other test that was
green before the task is not re-annotated with a new ID
(`verify-before-merge` check 4).

## Write the red -> green lines into the plan

`merge-change` step 6b copies them into the verification record, many steps
later, and the merge sequence reruns from step 1 on any finding. Until they
are written down they exist only in the conversation, which is not durable
state (`worktree-discipline` step 9). In the plan they are a file from the
moment they arrive.

## Derailment

The test is whether the answer is the user's, not a count of stops. A task
stuck twice at the same point needs a choice only the user can make: more
effort, or a different decomposition. A red baseline and an accepted coverage
gap are the user's call for the same reason, so those two stops are not
violations of this rule.

## The deslop pass dispatch has no task worktree

Every other dispatch in these skills names a nested task worktree, so a
subagent given no location follows that pattern and creates one. Its fixes
then are on a task branch the dispatcher has to merge, for a pass whose
purpose is to edit the change branch in place.

## The deslop pass is the only whole-change view

The dispatcher keeps the plan and the trace and does not read the code, and
each task subagent sees one task. Cross-task duplication is invisible to every
other party.

## The deslop pass runs before merge-change

- The merge sequence reruns from step 1 on any finding, so a variable name
  reported at 6a costs a full restart.
- By 6a every task branch is merged and the change is staged for the squash,
  so a fix there costs more than the same fix before the merge sequence.
- 6a is an independence review. Mixing style into it produces one verdict for
  correctness and style together, and the style findings dilute the
  correctness findings.
