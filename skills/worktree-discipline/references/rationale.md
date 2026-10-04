# Why worktree-discipline's rules are what they are

Read this when a rule in `worktree-discipline` seems wrong for your case, or
before proposing to change one. Each heading names the step or rule it
explains.

## Step 1: the dispatcher merges, not the subagent

"The subagent finishes its own work" is the intuitive answer, and git does not
permit it. Git will not update a branch that another worktree has checked out,
and the change branch is checked out in the change worktree. From a task
worktree every route fails: `git merge <change-branch>` merges into the task
branch, leaves the change branch where it was, and exits 0 as if it had
worked; `git checkout`, `git push .` and `git fetch .` are rejected. The one
place the merge is possible is the change worktree, and a task subagent must
not work there, because parallel subagents in one tree collide. So the
subagent commits and reports, and the dispatcher merges.

## Step 1: one worktree per subagent

Parallel subagents in one worktree collide on files and on `index.lock`. They
also destroy the evidence TDD depends on: watching a test fail for the right
reason means nothing if another agent is committing to the same tree at the
same time.

## Step 1: the gate runs in the change worktree

`verify-before-merge` checks for a clean `git status`. A task worktree branched
fresh off the change branch is clean because it is new, so the check would
pass having proved nothing about the change worktree's uncommitted state.

## Step 1: containment decides where the task worktree goes

The harness the rule was measured on pins a dispatched subagent to the subtree
of the worktree it was dispatched into. A task worktree beside the change worktree is
created successfully, and then every later operation on it is rejected from
inside the pin: `git -C`, the write tool, the commit and the test suite. A
harness worktree tool given that path reports success and then rejects every
shell call, `pwd` included. Each of these failures arrives after the worktree
exists, so the subagent cannot discover the pin before it has violated it.
That is why the dispatcher, which is outside the pin, names the path.

The rule is stated without a condition because nesting also works under a
harness that does not pin, at no cost. Stated as a conditional, it would ask
every project to measure its harness first.

## Step 1: the ignore entry is the dispatcher's

A subagent cannot add the `.worktrees/` entry. The commit would be made on the
change branch from the change worktree, where no task subagent works, and five
subagents fanned out would race the same commit.

## Step 1: proving arrival with `git -C <path> status`

An agent that entered the worktree with a harness tool could run `pwd` or a
bare `git status`. An agent that remained where it was and drives the worktree
by path cannot use either in the target. `git -C <path> status` answers on
both routes.

## Step 5: IDs are minted, not chosen

The token is random, minted once, and allocated against nothing, so two
worktrees, or two pull requests, never contend for it and nothing is
renumbered at merge. The alphabet drops the characters that are read wrong
(`0`/`o`, `1`/`l`/`i`), and every token contains a digit, which is what stops
`REQ-argued` in prose from reading as an ID. A hand-typed token can break
either property.

## Step 6: one draft file per change

Each change writes its new items to its own draft file, so parallel worktrees
never edit the same file, and the dated rename at merge keeps the ledger in
chronological order. A definition moved between files breaks that order and
the history of the item.

## Step 8: when a task worktree is removed

Task worktrees are removed with their dispatch so that `merge-change` sees
exactly one worktree, the change worktree, and the base branch sees exactly one
squash per change.

The review worktree is removed at the end of `merge-change` step 6a and at no
later step. A review that returns findings sends the sequence back to step 1,
so no later step runs on that round, and the review worktree's path and branch
are fixed, so what one round left behind would collide with the next round's
dispatch. A later step of that sequence checks that nothing is registered
inside the change worktree, because `finish-merge.sh` will not remove a change
worktree that still has one.

## Step 9: the artifacts are the memory

Scrollback is not durable: it is summarized away, it is dropped, and a
subagent never had it. A decision that exists only in the transcript is
already lost. Written to the plan, the ledger and the record as the work
happens, the state of a change is independent of the conversation, which is
also what makes compacting between changes cost nothing.
