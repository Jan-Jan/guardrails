# Why merge-change's rules are what they are

Read this when a rule in `merge-change` seems wrong for your case, or before
proposing to change one. Each heading names the step or rule it explains. This
file gives the reasons behind the rules only. What a script does is stated in
the script's own comments; read the script.

## Preconditions: one change at a time

Two open changes race on the base branch, on the duplicate scan in step 4,
and on the verification record. Each race surfaces here, at merge, rather
than where it was created.

## Steps, opening paragraph: the fix dispatch tag is unique

The unique tag is insurance against a cleanup that was missed. The removal
after each fix dispatch deletes the task branch, so a reused `fix` tag is free
again before the next round. That is the same property that
keeps the review tag fixed at `review`. But no numbered step performs the fix dispatch's
cleanup; you do, between rounds. With a repeated tag, a missed cleanup leaves
the task branch or its worktree in place, and
the next round cannot create its worktree on that path and branch. With a
fresh tag, the new dispatch does not collide with the leftover, and a leftover
branch is merely stale.

A wholly skipped cleanup also leaves a nested worktree still registered. It is
gitignored, so `git status` never shows it. Step 6c catches it. Otherwise
guard 4 rejects at step 8, after the key touch and the signature check under `--strict`.

## Step 1: the fetch, and putting the remote out of scope

The `DUPLICATE-ID` scan reads only the tree. It sees the base's IDs because
step 1 merged the base first.

Skip the fetch and the scan checks a smaller set. A failed fetch that is
swallowed merges against a stale remote-tracking ref and reports success.

A base merged from a local ref is recorded with its commit so that a later
reader knows what the duplicate scan at step 4 was compared against.

A project may still put the remote out of scope, as this toolkit's own
repository does, because its fetch blocks on a hardware key only the user can
touch. That trade is sound only where one person merges, because then the
local base branch contains every ID that was merged.

## Step 2: recording the tree

A gate summary with no tree beside it cannot be re-identified one round
later, and step 6 compares against this hash.

## Step 3: the conditional commit and the unrewritten report

On the second and later findings rounds the drafts are already dated, so
an unconditional commit exits 1 with nothing to commit: a halt for no
defect, in a sequence that stops at any failure.

Nothing later repeats the `unrewritten` report. `DANGLING-FILE` reads the
scope the rewrite reads, so a dead name in a plan or a verification record is
found at step 3 or not at all.

## Step 3: the finalize date

The date in the new name is the day step 3 first retired the draft name, and
it is not derived again. The filename is a handle for the file; git records the day
of the merge.

## Steps 3 and 5: a draft another change left behind

Step 3 renames every draft ledger file it finds, including one another change
left behind, and nothing distinguishes the two mechanically. Such a draft
is adopted into this change silently: it is renamed into this diff, this
record and this change's `Implements:` line, with no item to explain it. A rename you
do not recognise at step 3 is that case.

A `DRAFT-FILE` report names no change. A draft leaked by a change that already merged fails step 4 for every later change.
A `DRAFT-FILE` on a path this change did not create, ruled on at step 5, is
that case.

Whether the name opens `DRAFT-<this branch>-` is not a discriminator, because
the convention does not require a draft to embed its branch. That gap is a
problem item in this toolkit's own ledger.

## Step 5: `MALFORMED-ID`

Widening the definition pattern to accept the token makes the item visible to
every gate, and admits everywhere an ID that was not minted and whose form the
pattern exists to reject.

## Step 6: the tree hash decides re-verification

The renames at step 3 move files the tests may read, so a fresh gate summary
is what shows that nothing broke.

Where step 3 renamed nothing, step 3 was a no-op, step 4 only reads, and
step 1 merged a base already merged. The tree is the tree step 2 measured, and
a second suite run would reproduce an answer already in hand. The hash makes
that a mechanical test rather than a judgment about what the round touched.

## Step 6a: the reviewer runs the suite

Independence covers the evidence as well as the code. The reviewer reports
the counts it saw, not the counts it was handed.

## Step 6a: the review worktree is nested

The reviewer is a dispatched subagent, pinned to the change worktree's subtree
like any other, and it cannot detect the pin before it violates it. A reviewer
whose worktree is unusable reports on a suite it could not run.

## Step 6a: the tag and the last review round

The tag exists for the convergence rule, which needs to know whether a round
found a defect in the software or in the account of it.

The rule stops at one clean round, not two. A second clean round buys one
independent read of the first round's corrections at the cost of a full review
dispatch, and the regress has no end: the verification record is the one
artifact this process does not verify. The gates are cheap and run again every
round; the review and its round-trip are the cost.

Bounding what a `record` finding costs inside a round, dispositioning it in
place without a rerun, would need a class of files no gate reads. There is
none: the `DUPLICATE-ID` scan reads every file in the tree but the toolkit's
installed scripts. Every formulation of that boundary so far has failed review
on that point.

## Step 6a: where the review worktree is removed

The dispatcher removes each task worktree when its dispatch ends
(`worktree-discipline`). For the review worktree, the dispatcher is `merge-change`.

The review worktree's path and branch are fixed. A round that returns findings
goes back to step 1 and never reaches a later step, and the round that does
reach 6b dispatches no reviewer. A removal placed downstream would therefore
leave every intermediate round's worktree behind, until the next dispatch
fails on the existing branch.

## Step 6a: a round with no review worktree

Removing a review worktree that was never created fails. In a sequence
that halts on any failure, that is a stop with no defect behind it.

## Step 6a: a review commits nothing

Three commands retire a task worktree, and only one of them merges. `merge`
is the dispatcher's step after a green task report: it merges the task branch
into the change branch and then removes the worktree and the branch. `remove`
and `discard` retire a task worktree without merging: `remove` rejects a branch
with commits, and `discard` deletes those commits after each one is recorded. A
reviewer's commit merged into the change branch would put the reviewer's work
into the change it reviewed, and the reviewer would then be an author of that
change. The review worktree is therefore retired with `remove`, which rejects a
review branch with commits, so a commit made by a reviewer is read and recorded
as a finding instead.

## Step 6a: a review worktree with scratch in it

The removal rejects untracked files. It never reports an ignored file,
because git does not see one, and that is the property guard 4 exists for.
Forcing the removal would delete the scratch the rejection reported.

## Step 6b: the record is committed in the worktree

The record is committed on the change branch, so the squash commit contains the evidence
on the base branch, and its `Verified:` line cites the record.

## Step 6b: the delta, never the total

An open count, a roll-call or an oldest age describes the whole ledger at one
instant, and the next merge makes it false. A record is read months later,
when nobody can tell a wrong figure from an aged one. The delta is a property
of this change alone, so it remains true as long as the diff does. A reader
who needs the current totals counts them from the ledger on the day they need
them. There is no gate against count-shaped prose: a shape check loses to
respellings.

## Step 6b: the red → green attestations

Nothing re-verifies these rows. Step 6a cannot observe a test failing once it
passes. The independent check comes from the other side: 6a asks whether each
test would fail if the behavior broke.

## Step 6b: the `reproduced:` field

The field exists so that a change with no reproduction states so, and the
missing evidence is visible in the record.

## Step 6b: the units in a multi-unit record

A multi-unit record names the units touched and the impact set, so that it
states the units whose gates the verdict covers.

## Step 6c: a finding is never deleted

A deleted finding and a finding that never existed read identically. So a
finding judged wrong keeps its block, and its disposition states the reason.

## Steps 6c and 6d: a worktree registered elsewhere

A worktree registered elsewhere, such as another change's or the primary
checkout, is not guard 4's concern, because
removing the change worktree does not touch it.

## Steps 6c and 6d: why the check comes before the squash

Found at step 8, a leftover blocks the cleanup after the user has already
spent a key touch. Found at 6c, it costs one removal.

## Step 7: the message file and the signing hand-over

A message file inside the repository is one `git add -A` from being committed
by the commit it describes.

Signing may need the user's hardware-key touch. An agent that runs
`git commit -S` itself starts a blocking wait on the user's behalf, and the
hand-over exists to replace that wait.

## Step 7: `Resolves:` and `Opens:`

These lines repeat the step 6b delta in the commit that is the change on the
base branch. No script parses the message, so each costs one line, and anyone
can check them against the diff without a ledger to compare them to.

## Step 7: the branch name, never a path

A path from the caller is a chance to remove the wrong directory. A branch
name identifies at most one registered worktree.

## Step 8: `--strict`

Without `--strict`, step 8 would confirm nothing on exactly the machine where
confirmation matters.

Guard 1 made the same check under `--strict` moments earlier, in the compound.
Step 8 therefore costs
one re-read of a commit whose signature is known good, and it cannot report
success where that guard would have rejected the commit.

## Step 8: re-running the cleanup alone

When the cleanup is rejected, the signed commit is already on the base branch.
Re-running the whole compound redoes nothing: the squash is no longer staged,
so `git commit` fails and `&&` stops before the cleanup runs. The merge is
done, and only the cleanup is outstanding.
