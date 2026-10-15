# Why develop-change's rules are what they are

Read this when a rule in `develop-change` seems wrong for your case, or before
proposing to change one. Each heading names the rule it explains.

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

## Write the red -> green lines into the plan

`merge-change` step 5 copies them into the verification record, many steps
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

A conformance finding stops the loop only when it recurs, not after a count of
rounds. A second round with new findings is what the loop is for: in
`code-guidelines` the round-1 fix covered only the cited lines, round 2 found
the same kind of problem elsewhere, and round 3 was the last. A finding that
recurs after its fix was merged shows the fixer cannot fix it as dispatched,
and what to do next is the user's choice, as it is for a task stuck at
red -> green.

A recurring low does not stop the loop. A round with nothing above low has
converged, so the stop that bounds a loop that does not converge does not
apply.

## A reviewer gets no task worktree

Every other dispatch in these skills names a nested task worktree, so a
subagent given no location follows that pattern and creates one. A reviewer
changes nothing, so it has nothing to commit or merge, and the prompt says so.

## Reviews and fixes are separate dispatches

The agent that fixes a finding does not review its own fix: the next round's
reviewers do, in fresh contexts. The reviews run all at once because each
only reads; the fixes run in task worktrees because each writes. Each
reviewer reads one guidelines file, and a reviewer with one file misses
less.

## The conformance reviews run before merge-change

- The merge sequence reruns from step 1 on any finding, so a variable name
  reported at step 4 costs a full restart.
- By step 4 every task branch is merged and the change is staged for the
  squash, so a fix there costs more than the same fix before the merge
  sequence.
- Step 4 is an independence review. Mixing style into it produces one verdict
  for correctness and style together, and the style findings dilute the
  correctness findings.
