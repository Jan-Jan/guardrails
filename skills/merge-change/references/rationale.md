# Why merge-change's rules are what they are

Read this when a rule in `merge-change` seems wrong for your case, or before
proposing to change one. Each heading names the step or rule it explains. This
file gives the reasons behind the rules only. What a script does is stated in
the script's own comments; read the script.

## Changes open in parallel

Several changes may be open at once, each in its own change worktree. Step 1
merges the latest base every round, so a change merged before that round
reaches every other change before its gate runs again. Step 1 alone does not
close the gap: a change signed after another change's last step 1 and before
its step 7 is not in the tree that change's gate saw. Step 7's tree comparison
catches that base move (see "Step 7: the agent stages the squash"). Item IDs
are random tokens, so two worktrees do not contend for an ID, and
`DUPLICATE-ID` catches the improbable collision after the base merge. Each
change writes its own verification record, and the gate finds it by its
`branch:` field, not by its filename.

A base that moved also changes what the review saw. When the base and the
change edited different files, each side's review still holds, and the gate
rerun tests the combination. When they edited the same file, git may merge it
cleanly and still break what the reviewer checked: two changes that each add
tests to one file can contradict each other's assumptions. So step 1 lists the
files the base edited after the last reviewed commit that this change also
edits, and any shared file sends the whole change to a fresh reviewer, even
after the last review round. A conflict is not the test: a clean merge of a
shared file carries the same risk. The maintainer ruled this on 2026-10-07.

Step 1 compares against the last reviewed commit, not the last base merge,
because the obligation must survive a rerun. A shared merge followed by a
failed gate and a fix reruns step 1, and that run merges nothing: a list taken
against the last base merge is empty there, and the merge would be signed
unreviewed. The empty `review dispatched` commit step 4 makes marks the reviewed
commit on the change branch itself. Every rerun finds it again, it changes no
tree, so no gate summary goes stale, and the squash drops it. The base side
starts at the base the reviewed commit contained, so a later reviewer moves
that start forward. The change side is everything the change edits now, so a
file a fix touched after the review counts too. Before any reviewer there is
no marker and nothing to list: the first review sees the whole change.
`--no-renames` makes a file the base renamed show under its old path, which is
the path the change edited; `grep -Fx` matches whole paths, so `tests.bats`
does not match `my-tests.bats`.

Two changes meet at step 1, where the second merges the first in once the
first is on the base and resolves any conflict there, and at step 7. The
primary checkout's index holds one staged squash only because step 7 checks
the index before staging its own.

## Steps, opening paragraph: the fix dispatch tag is unique

Dating the tag, numbering it, or naming it after the finding makes it unique.
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

A base merged from a local ref is named with its commit in step 7's `Base:`
trailer, so that a later reader knows
what the duplicate scan at step 2 was compared against.

A project may still put the remote out of scope, as this toolkit's own
repository does, because its fetch blocks on a hardware key only the user can
touch. That trade is sound only where one person merges, because then the
local base branch contains every ID that was merged.

## Step 1: plans are pruned after the base merge

A plan repeats the code its change merges, and the copy drifts from the merged
code as review rounds fix it. Pruning replaces each code block in a plan's
task sections with a one-line pointer naming its line count and the task's
`**Files touched:**` value, and the squash commit holds the merged code.

Pruning runs at step 1, after the base merge, because it changes the tree on
nearly every merge. Run after the step 6a gate, it would fail step 6b's hash
comparison and dispatch a second full suite run. Run at step 1, the change is
in the tree the step 6a gate measures. The maintainer ruled this on
2026-10-08, and `ADR-bh4xgr` records it.

The commit is conditional: on a rerun the plans are already pruned, nothing
changes, and an unconditional commit would halt the sequence for no defect. The prune and its commit are chained on the merge's
success: run after a conflicted merge, the commit would conclude the merge
with its conflict markers staged. The commit names the plans directory, so an
unrelated edit pending in the worktree stays out of it. Diffing against the
ref the step merged, not the local base branch, keeps a plan the remote base
added out of this change's plans.

A plan that any tracked Markdown file cites by line after its first code
block is left whole, because pruning would move the cited line. Records cite
plans as evidence, and so do other plans. Listing it in the record shows the
reviewer which plan still carries its code.

## Step 1: a staged squash stops the round

The base moves only when the user signs. While another change's squash is
staged in the primary checkout's index, the base is about to move, and a gate
started now measures a tree that step 7 will reject once the signing lands:
the squash no longer matches the branch, and the sequence reruns from step 1
for a second gate run. Step 1 reads the primary checkout's index before it
merges anything and stops there. The cost is that the agent waits on the user
instead of gating; the gate it skips would have been spent for nothing. Once
the user signs or clears the squash, the rerun merges the new base in and the
one gate run that follows measures the tree that will be squashed.

## Step 1: two ledger files with one name

A change names its ledger file when it creates it (`ADR-cy7ahd`), so two
changes can choose one name. Git reports that as an add/add conflict at the
base merge, which is where every conflict is resolved. The renamed file is
this change's, because the base's is already merged and other changes may cite
it. No gate checks a reference to a dated name, so the author finds this
change's citations with `git grep`. The rename it replaces suffixed `-2`
against the local disk only.

## Step 2: skipped when no reviewer is dispatched

The pre-flight before review exists to catch a broken trace before a reviewer
spends a round on it. A round that dispatches no reviewer, such as the rerun
after the last review round or after a base move found at step 7, has no
round to save, and 6c runs the same checks with the review check added, a
few minutes later. Running step 2 there repeats them and finds nothing 6c
would not.

A base-move round reruns only what the moved base can change: the merge
(step 1), a fresh review (steps 2 to 4) only where a `shared:` line shows the
base edited a file this change edits, whose rerun writes the record at step 5;
otherwise the record (step 5) only where the merge left a new plan whole; then
the gate and everything after it, 6a to 7. A review that step 4 ran always
leads, through its rerun, to step 5 before the gate, so the record names the
shared files and that review round.

## Step 3: a draft name another change left behind

A `DRAFT-FILE` report names no change. A draft name a change merged before
ledger files were named at creation fails step 2 for every later change. A
`DRAFT-FILE` on a path this change did not add, ruled on at step 3, is that
case.

Whether the name opens `DRAFT-<this branch>-` is not a discriminator, because
the draft convention, before `ADR-cy7ahd` retired it, did not require a draft
to embed its branch, so a legacy draft name need not carry one.

## Step 3: `MALFORMED-ID`

Widening the definition pattern to accept the token makes the item visible to
every gate, and admits everywhere an ID that was not minted and whose form the
pattern exists to reject.

## Step 4: independence, and findings copied verbatim

The review is DO-178C independence: the verifier is not the author. A finding
the author rewords is the author's, no longer the reviewer's, so the record
copies each one verbatim.

## Step 4: the reviewer runs the suite

Independence covers the evidence as well as the code. The reviewer reports
the counts it saw, not the counts it was handed.

## Step 4: the review worktree is nested

The reviewer is a dispatched subagent, pinned to the change worktree's subtree
like any other, and it cannot detect the pin before it violates it. A reviewer
whose worktree is unusable reports on a suite it could not run.

## Step 4: the tag and the last review round

The tag exists for the convergence rule, which needs to know whether a round
found a defect in the software or in the account of it.

The rule stops at one round with nothing above `low`, not two. A second such
round buys one independent read of the first round's corrections at the cost
of a full review dispatch, and the regress has no end: the verification record
is the one artifact this process does not verify. The gates are cheap and run
again every round; the review and its round-trip are the cost.

The stop is at `low` severity rather than at a round with no `code` or
`requirement` finding, because a fresh reviewer finds something in every
round: a rule that waits for an empty round does not end. A `low` finding
needs a rare state, or is reported correctly by the error beside it, or is a
documentation gap over a correct tree, so recording it as an open problem item
loses nothing a further round would have found. A mechanical fix costs less
than the item, so it is made in the same round. The ruling of 2026-10-04,
in `docs/plans/2026-09-29-agent-first-skills-change-2.md`, set this rule.

Bounding what a `record` finding costs inside a round, dispositioning it in
place without a rerun, by a class of files no gate reads fails: there is none,
because the `DUPLICATE-ID` scan reads every file in the tree but the toolkit's
installed scripts. Every formulation of that boundary has failed review on
that point. `PR-kc2pzm` records two candidates that answer it per gate
instead, by running the cheap gates (P8) or by scoping the reviewer's run to
the round's delta (P9); neither is adopted.

A round whose findings, if any, are all `low` is the last, and a round that
found nothing is one of them. Its rerun dispatches no reviewer, so steps 2 to
4 are skipped, and the record and then the gate follow on the tree that is
signed.

## Step 4: where the review worktree is removed

The dispatcher removes each task worktree when its dispatch ends
(`worktree-discipline`). For the review worktree, the dispatcher is `merge-change`.

The review worktree's path and branch are fixed. A round that returns
any finding at all goes back to step 1, whatever the findings were tagged,
and never reaches a later step. A round that found nothing, or only `low`
findings, is the last review round: it too reruns from step 1, with steps 2 to
4 skipped. Only a round that dispatched no reviewer reaches step 5. A removal
placed downstream would therefore leave every intermediate round's worktree
behind, until the next dispatch fails on the existing branch.

## Step 4: a round with no review worktree

Removing a review worktree that was never created fails. In a sequence
that halts on any failure, that is a stop with no defect behind it.

## Step 4: a review commits nothing

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

## Step 4: a review worktree with scratch in it

The removal rejects untracked files. It never reports an ignored file,
because git does not see one, and that is the property guard 4 exists for.
Forcing the removal would delete the scratch the rejection reported.

## Step 5: the record is committed in the worktree

The record is committed on the change branch, so the squash commit contains the evidence
on the base branch, and its `Verified:` line cites the record.

## Step 5: the record names no tree

A record that names the commit, the tree, the base commit or the gate totals
of its change is part of the tree it names. Every base update, and every
rebase after a shared remote moves, made those lines stale, so the record was
rewritten and committed again, which changed the tree it named: a loop, and a
late commit on the review evidence. The commit can carry what the record could
not, because nothing it carries changes its tree. So the record holds only
what the commit cannot prove, and nothing in it is measured from the tree. It
does not change when the sequence reruns, and the tree the gate measured is
the tree squashed. `ADR-f6ytg7` records the decision.

## Step 5: the delta, never the total

An open count, a roll-call or an oldest age describes the whole ledger at one
instant, and the next merge makes it false. A record is read months later,
when nobody can tell a wrong figure from an aged one. The delta is a property
of this change alone, so it remains true as long as the diff does. A reader
who needs the current totals counts them from the ledger on the day they need
them. There is no gate against count-shaped prose: a shape check loses to
respellings.

## Step 5: the red → green attestations

Nothing re-verifies these rows. Step 4 cannot observe a test failing once it
passes. The independent check comes from the other side: step 4 asks whether each
test would fail if the behavior broke.

## Step 5: the `reproduced:` field

The field exists so that a change with no reproduction states so, and the
missing evidence is visible in the record. An honest "not reproduced" passes:
the gate never judges the value.

## Step 5: the units in a multi-unit record

A multi-unit record names the units touched and the impact set, so that it
states the units whose gates the verdict covers.

## Step 6a: recording the tree

A gate summary with no tree beside it cannot be re-identified one round
later, and step 6b compares against this hash. Step 7 writes the same hash as
the `Gate-tree:` trailer: the tree the gate measured, not one computed again
at step 7.

## Step 6a: the gate runs after the record

The gate runs once the record is committed, so the tree it measures is the
tree step 7 squashes and the user signs. A record committed after the gate
changed the tree: step 7's comparison failed and the sequence reran from step
1 for a second gate run, unless the record was written before that rerun. With
the record first, one gate runs per round, and step 7's comparison fails only
when something changed after the gate. Before the review, the only suite run
is the reviewer's own, on the tree an earlier gate would have measured. The
user ruled this on 2026-10-14.

Two costs are accepted. A gate failure surfaces after the review, and its fix
is code no reviewer has read, so it dispatches a reviewer unless it touches
only the record or the plan. A documentation-only diff has no gate summary to
hand its reviewer, so the reviewer skips the suite, the record says so, and
the gate at 6a covers the tree.

The record now follows the review, so no reviewer reads the record of its own
round. A reviewer in a later round reads the record the earlier rounds wrote
and raises what is wrong in it; the last round's record has no reviewer, and
the pre-flight at 6c is its check.

## Step 6b: the tree hash decides re-verification

The suite runs in the background for minutes, and anything that changes the
worktree meanwhile leaves a summary describing a tree that is no longer there;
a fresh summary is what shows nothing broke. Where the tree is unchanged, a
second run would reproduce an answer already in hand. No step between 6a and
6b edits the tree, and every fix reruns from step 1, so the check is needed
once per round. The hash makes it a mechanical test rather than a judgment
about what the round touched.

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

The command is handed over with real paths and the branch name, because
their shell has none of your variables.

Signing may need the user's hardware-key touch. An agent that runs
`git commit -S` itself starts a blocking wait on the user's behalf, and the
hand-over exists to replace that wait.

## Step 7: the agent stages the squash

The staged squash in the primary index is a lock, first come, first served.
`git merge --squash` does not refuse to run over one already staged. When the
two changes touch different files and the second squash fast-forwards, it
exits 0 and stacks its files onto the first. When they share a file, git
refuses with "Your local changes to the following files would be overwritten
by merge", fast-forward or not, even when the edits are on different lines.
So the squash is a lock only if the agent checks the index before staging its
own. The check is joined to the squash with `&&`: run as two lines in one
shell call, a failed check does not stop the squash.

A gate result describes the branch's tree, and nothing else. Whatever the
index holds beyond that tree was never verified, so it must not be signed.
`git diff --cached --quiet <branch>` runs after every squash, not only when
the index check fails, because an empty index does not prove the squash is the
branch's tree. If another change was signed onto the base after this change's
last step 1, the squash is a three-way merge: it exits 0 and stages the branch
plus the other change. Only the comparison sees that. It exits 0 only when
the index holds exactly the branch's tree.

When the comparison fails, the first line's output says which case applies.
Git prints its merge output whenever the squash ran: "Squash commit -- not
updating HEAD", and a `CONFLICT` line when it stopped on a conflict. Either
way the base moved after step 1, and the staged tree is this change's own, so
the agent clears it. One output is not that case: "Your local changes to the
following files would be overwritten" or "untracked working tree files would
be overwritten" means the primary checkout has an edit or a file in the
squash's way. `git reset --merge` keeps that edit, so the rerun would meet the
same refusal and loop. The user decides what the edit is. `git reset --merge` resets the index to HEAD, removes the
conflicted entries, and keeps unstaged edits to files the squash did not
touch; `git merge --abort` does not work here, because a squash records no
`MERGE_HEAD`. Step 1 then merges the new base in and the gate runs on the
result.

When the first line prints nothing, the index check stopped it: a squash was
staged before. Comparing file names cannot tell whose it is, because parallel
changes often edit the same files. `git diff --cached --quiet <branch>` can:
step 1 merged the base into the branch, so this change's squash stages exactly
the branch's tree, and the command exits 0. Then the squash is this change's
own, left when its signing failed, and waiting on it would wait forever. The
command exits 1 when another change's squash is staged, and when an outdated
squash of this change is: the branch has moved since it was staged. Signing
either under this change's message would put the wrong content on the base
branch, and the cleanup's tree check would catch it only after the signed
commit landed. So the agent stops and the user signs or clears it. A session
that finds another change's squash waits for the user to sign it, then reruns
from step 1, which merges the new base in.

Two sessions that run step 7 at the same instant can still race: the index
check and the squash are two commands, so both may find the index empty. The
second squash then stacks onto the first, or git refuses it on a shared file.
Either way its comparison exits 1, so it never hands over the stacked tree.
But on a stack, its `git reset --merge` also clears the first session's
squash, and that session's signing then fails with "nothing to commit". If
the user signed in the seconds between the second squash and its reset, the
signed commit holds both changes; the cleanup's tree check catches that, after
the commit landed. This is accepted because step 7 takes seconds and a
second, simultaneous session is rare.

Staging the squash inside the handed-over command instead would leave the
index empty until the key touch, so no other session could see that a squash
was pending.

## Step 7: `Resolves:` and `Opens:`

These lines repeat the step 5 delta in the commit that is the change on the
base branch. No script parses these two lines, so each costs one line, and
anyone can check them against the diff without a ledger to compare them to.

## Step 7: the trailers certify the gate

`Gate-tree:` is the hash step 6a recorded, not `git write-tree` at step 7: a
tree computed at step 7 describes what is staged, which is what the check
questions. The comparison before the hand-over catches a branch that changed
after the gate, such as a fix committed while the gate ran, before the key touch; the
cleanup would refuse the same squash after it.

`Base:` names the commit of the base ref that step 1 merged. At step 7 that is
`git rev-parse <base ref>` in the primary checkout: the squash is staged, not
committed, so the base has not moved onto it, and `git diff --cached --quiet
<branch>` exits 0 only when no other commit reached the base after step 1.

git reads trailers only in a message's last paragraph. A blank line before
`Co-Authored-By:`, or a wrapped trailer line that does not open with
whitespace, leaves `Gate-tree:` in the body, and the cleanup is refused.

The `Gate:` lines are copied from the step 6a summary. No script checks them:
checking a total means running the gate again. What is checked is the tree
they describe. Coverage gets a `Gate:` line because it is a measured figure
and the record no longer holds one. The pre-flight has no trailer: the
sequence halts when it fails, so every squash exists only after it passed. Not
all of it reads the tree: `BASE-MERGED` reads ancestry, `NESTED-WORKTREE` the
worktree registry, and the `DUPLICATE-ID` scan the base's IDs. But its ID and
trace checks read the tree, and can be rerun on the tree `Gate-tree:` names.

## Step 7: the branch name, never a path

A path from the caller is a chance to remove the wrong directory. A branch
name identifies at most one registered worktree.

## Step 8: no re-verification

Step 8 used to re-run the signature check under `--strict` after the user
reported success. Guard 1 makes that check moments earlier, in the
compound, in the user's shell, so a pass added nothing. A failure was usually
the agent's own environment: a sandbox with a read-only `~/.gnupg` makes gpg
read a good signature as `N`. The agent takes the user's word, and acts only
on a reported problem or a non-zero exit. Step 7 tells the user what success
prints, so a rejection does not pass for success.

## Step 8: re-running the cleanup alone

When the cleanup is rejected, the signed commit is already on the base branch.
Re-running the whole compound redoes nothing: the squash is no longer staged,
so `git commit` fails and `&&` stops before the cleanup runs. The merge is
done, and only the cleanup is outstanding.
