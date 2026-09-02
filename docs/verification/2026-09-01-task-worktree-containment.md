# Verification — task worktrees are nested inside the change worktree (2026-09-01)

branch: worktree-task-worktree-fallback
reviewer: seven rounds of independent review, each a fresh subagent dispatched
at step 6a with the artifacts and no implementation narrative; each ran the
suite itself in its own nested task worktree and reported the counts it saw.
verdict: the seventh round returned no findings — "nothing blocks; the change
is complete, internally consistent, and the newest prose in both the problem
record and merge-change is accurate under direct probe". The six earlier rounds
returned 8, 11, 7, 7, 4 and 2 findings; every one is dispositioned in its own
section of the plan.
reproduced: yes. The defect was reproduced before it was understood, by a
dispatched probe subagent that created a task worktree in each candidate
location and recorded what each refused; and again by every fix task, each
dispatched into a nested task worktree, so the new rule was executed before it
was believed. The hazard the fix introduced was reproduced separately in a
scratch repository: a change worktree holding a nested task worktree shows a
clean `git status`, and `git worktree remove` without `--force` exits 0 and
destroys the nested worktree's uncommitted work.

Change: a dispatched subagent's task worktree must be nested inside the change
worktree, because a harness that isolates the subagent pins it to that subtree.
Branched from `main` at `b7fbd7f`; `main` moved to `860dce4` mid-change and was
merged in at step 1.
Plan: `docs/plans/2026-09-01-task-worktree-containment.md`.

## The gate

Every figure derived from the tree under test, not carried forward. Seven gate
runs were dispatched, one after each round of fixes; the figures below are the
final one.

| Gate | Result |
| --- | --- |
| `tests/run-tests.sh` | 463 ok, 0 not ok. TAP plan `1..463` agrees with the result count; numbering contiguous, no gaps, duplicates, SKIP or TODO. Exit 0 was not taken as the verdict. |
| `check-ids.sh` | Not run — guardrails is not gated on itself. It has no `.guardrails/config.yaml`, so the script exits 2 here. Its behaviour is exercised inside the suite as a fixture. |
| `check-trace.sh` | Not run, same reason. |
| `check-review.sh` | Cannot run here for the same reason, so this record was copied into a scratch project seeded with `templates/config.yaml` and checked there: `checked: records 1, for worktree-task-worktree-fallback 1, findings 6; provenance NOT checked (--branch)`. No error reported. Provenance is the one thing that check cannot make — the scratch repository has no history of this branch. |
| Coverage, against the class target | Not configured for this repository. |
| `dash -n` and `bash -n` on `scripts/finish-merge.sh` | Both exit 0. `/bin/sh` here is dash, so `bash -n` was added as a genuinely independent parser. |
| Working tree | Clean. No worktree registered inside the change worktree. |

## Red → green

One row per test carrying `verifies: PR-n57ayn`, copied from the `red -> green:`
lines of the dispatch reports. Twenty-eight tests: twenty in `tests/skills.bats`
and eight in `tests/finish-merge.bats`.

| Item | Test | Watched red |
| --- | --- | --- |
| `PR-n57ayn` | `worktree-discipline: the task worktree is nested inside the change worktree` | yes — the phrase was absent from the skill |
| `PR-n57ayn` | `develop-change: the dispatch prompt names the nested task worktree path` | yes — the prompt template named no path |
| `PR-n57ayn` | `the repository ignores the nested task-worktree directory` | yes — `.gitignore` held only `.claude/worktrees/`, `tests/.bats-core`, `*.bak` |
| `PR-n57ayn` | `develop-change: the dispatch prompt forbids the change branch, not the change worktree` | yes — on the removal assertion, after the first draft's negation was found toothless and rewritten |
| `PR-n57ayn` | `worktree-discipline: a fresh task worktree has none of the ignored artifacts` | yes — the passage did not exist |
| `PR-n57ayn` | `merge-change: the review dispatch names the reviewer's worktree path` | yes — no reviewer path anywhere in the skill |
| `PR-n57ayn` | `worktree-discipline: the location rule is scoped to a pinning harness` | yes — the rule was stated as a law about harnesses |
| `PR-n57ayn` | `worktree-discipline: the task worktree passage says how to get inside` | yes — "harness tool first" had been deleted and the path form was undefined |
| `PR-n57ayn` | `the repository ignores the nested task-worktree directory exactly once` | yes — the count was 2 after the base merge |
| `PR-n57ayn` | `finish-merge: a worktree nested inside the change worktree fails with everything intact` | yes — the pre-guard script exited 0 and the nested worktree's new file was gone from disk |
| `PR-n57ayn` | `finish-merge: a nested worktree is refused even when it holds nothing uncommitted` | yes — same, and it kills a guard that fires only on a dirty nested worktree |
| `PR-n57ayn` | `finish-merge: a backslash in the change worktree's path does not defeat the guard` | yes — the guard failed OPEN: exit 0, a mangled path in the removal message, work destroyed |
| `PR-n57ayn` | `finish-merge: every nested worktree is named, not just the first` | yes — the refusal named only the first |
| `PR-n57ayn` | `merge-change: the sequence removes the review worktree before the squash` | yes — twice, the second time on the cross-reference |
| `PR-n57ayn` | `merge-change: step 8 maps guard 4's refusal to a remedy` | yes — step 7 still said the script proves three things |
| `PR-n57ayn` | `merge-change: the review worktree dies at the end of its own dispatch` | yes — the only removal sat in a step a findings round never reaches |
| `PR-n57ayn` | `merge-change: a review worktree left dirty by scratch has a remedy` | yes — the remedy prose did not exist |
| `PR-n57ayn` | `merge-change: step 6d's criterion is containment, not an empty registry` | yes — the criterion condemned every unrelated worktree |
| `PR-n57ayn` | `merge-change: the review worktree removal is conditioned on one existing` | yes — it read "Every round, findings or not" |
| `PR-n57ayn` | `merge-change: a fix dispatch's tag is unique, and AGENTS.md defers on tags` | yes — twice: the uniqueness rule, then its honest rationale |
| `PR-n57ayn` | `AGENTS.md: non-negotiable 1 nests the task worktree and names its path` | no — characterization pin, see below |
| `PR-n57ayn` | `verify-before-merge: the fix dispatch names the nested task worktree path` | no — characterization pin, see below |
| `PR-n57ayn` | `ratchet: both worktree directories are gitignored, and why each is` | no — characterization pin, see below |
| `PR-n57ayn` | `finish-merge: a failing git worktree list refuses instead of deleting the branch` | no — characterization pin, see below |
| `PR-n57ayn` | `finish-merge: a failing awk refuses instead of deleting the branch` | no — characterization pin, see below |
| `PR-n57ayn` | `merge-change: every fix dispatch names the nested task worktree path` | no — characterization pin, see below |
| `PR-n57ayn` | `finish-merge: a sibling whose path merely starts with the change worktree's is not nested` | no — regression cover, see below |
| `PR-n57ayn` | `finish-merge: a space in the change worktree's path does not defeat the guard` | no — regression cover, see below |

Eight rows say **no**, and the difference between them matters. Six pin prose or
behaviour that already existed and that nothing asserted — a review found the
gap, and pinning it is the whole point, so no red was possible. Each was instead
mutation-checked individually: its subject deleted, that one test watched
failing on exactly that assertion, the subject restored byte-for-byte. The
other two were added as regression cover when guard 4 was rewritten, were green
against both the old and the new implementation, and were never mutation-checked
individually. They are not attestations and are not counted as such.

## What was wrong, and what was built

`worktree-discipline` told a dispatched subagent to put its task worktree "in
whichever directory this project already uses for worktrees", and offered two
locations as equivalent, distinguished only by whether they need a gitignore
entry — which reads in favour of the harness's own directory. Convention is the
wrong selector. The property that decides whether a task worktree is usable is
containment: a harness that isolates a dispatched subagent pins it to a subtree,
so only a worktree nested inside the change worktree is reachable. Measured from
inside a dispatched subagent on 2026-08-31, a task worktree beside the change
worktree can be created and then nothing else — `git -C` refused, the write tool
refused, and the harness's own worktree tool reporting success and then refusing
every shell call including `pwd`. Nested, everything works.

Three false successes hid it. Creation succeeds in both locations. A plain shell
redirect to an out-of-pin path is not blocked even though the write tool is, so
a file appears to be written. And the worktree tool's success is a lie with no
shell-level recovery. That is why the first diagnosis — "this harness blocks
task worktrees" — was wrong, and why the failure surfaced only after a subagent
had already planned around it.

The rule now states containment, scoped to the one harness the measurement was
taken on and with a probe another project can run against its own; it defines
the path form, says how a subagent gets inside what it created, and warns that
a fresh task worktree holds only tracked files, so every gitignored artifact the
test command needs must be copied in. Every skill that dispatches into a task
worktree names the path in the prompt, because a subagent cannot discover its
pin before violating it.

Nesting created a hazard, and closing it is the only code in this change. A
nested worktree is gitignored, so it is invisible to the change worktree's
`git status` — and `git worktree remove` therefore does not refuse. The removal
destroys the nested worktree's uncommitted work at exit 0, leaving a prunable
registration and an orphan branch. `finish-merge.sh` gains guard 4, proved
before anything is removed, which refuses when any registered worktree lies
inside the one about to go, and names every such worktree rather than the first.
It is written in plain shell with no `awk -v`, because `awk -v` escape-processes
its value and a backslash in the path made the first version fail open — the one
guard whose failure loses work rather than withholding cleanup.

## Review

Seven rounds. The seventh returned nothing; the six before it returned 39
findings, each dispositioned in its own section of
`docs/plans/2026-09-01-task-worktree-containment.md`, which is the durable
record of all of them. Reproduced here are the findings that changed what this
change *is*, rather than what it says.

**finding-1**: `git worktree remove` does not refuse a change worktree that has
a worktree registered inside it, so nesting put every task worktree inside the
blast radius of merge cleanup — uncommitted work destroyed at exit 0, a prunable
registration and an orphan branch left behind.
disposition: `finish-merge.sh` guard 4, proved before any removal. Reddens
without it via `finish-merge: a worktree nested inside the change worktree fails
with everything intact`, which was watched destroying the work.

**finding-2**: guard 4 failed open. `awk -v` escape-processes its value, so a
change worktree path containing a backslash arrived with the escape expanded,
the prefix test never matched, and the guard passed — destroying the work it
existed to protect.
disposition: rewritten in plain shell with `while IFS= read -r`, `case` and a
prefix strip, none of which has an escape layer. Reddens without it via
`finish-merge: a backslash in the change worktree's path does not defeat the
guard`, watched failing open first.

**finding-3**: the change deadlocked its own process. Step 6a dispatches every
reviewer into a nested worktree at a fixed path, and the only step that removed
it was one a findings round never reaches — so a second round's dispatch
collided with the first round's leftover branch.
disposition: the removal moved to the end of step 6a, where the dispatch ends
and every round arrives. Pinned by position rather than presence, so relocating
it reddens `merge-change: the review worktree dies at the end of its own
dispatch`.

**finding-4**: a test was made vacuous by another fix in the same round — an
unanchored grep whose literal had since appeared elsewhere in the same file, so
mutating its actual subject survived the suite.
disposition: anchored by position like its sibling, and confirmed by re-running
the exact mutant the reviewer reported surviving.

**finding-5**: the skill asserted that a gitignored test runner copied into a
worktree would make `git worktree remove` refuse — the negation of the property
guard 4's own rationale depends on, and reproducibly false.
disposition: the false example removed from both the skill and the pinning
test's comment; the remedy kept. Reddens via `merge-change: a review worktree
left dirty by scratch has a remedy`.

**finding-6**: the `red -> green:` attestations for every task existed only in
the dispatcher's scrollback — the state these skills exist to prevent — and once
fixed, recurred for the next task, because the attestations section sat above
the sections that keep growing.
disposition: all ten task blocks written into the plan, and the section now
states where a new block goes and why.

## Gaps

- **The measurement is one harness, once.** The containment table was taken on a
  single harness on 2026-08-31. The rule is stated flat because nesting is safe
  either way, but a project whose harness does not pin its subagents has not
  been measured — the skill hands it a probe to run rather than a promise.
- **macOS is reasoned about, not executed.** The path comparisons in
  `tests/finish-merge.bats` were fixed for symlinked `TMPDIR` and verified under
  a deliberately symlinked `TMPDIR` on Linux. No run on macOS was performed.
- **This repository's own gates did not run on it.** guardrails has no
  `.guardrails/config.yaml`, so `check-ids.sh` and `check-trace.sh` exit 2 here
  and could not check this change. The suite exercises them as fixtures, which
  is not the same as being gated by them. `check-review.sh` was run against
  this record in a scratch project and passed, but only for grammar: it could
  not check provenance, since that scratch repository has no history of this
  branch.
- **`git fetch` is unavailable on this machine** (a bad-permissions SSH config
  file), so the base merge at step 1 used the local `main` ref. If the remote
  has moved beyond `860dce4`, this change has not been merged against it.
- **Two guard-4 mutants survive**, judged equivalent independently three times:
  dropping `IFS=` from `while IFS= read -r` (trailing-whitespace stripping can
  only shorten a path's tail, never break a prefix — though it does degrade the
  reported path text, which is why `IFS=` stays) and unquoting the `case` word
  (POSIX performs neither field splitting nor pathname expansion there).
- **Step 3 ran out of order.** The ID finalization — renaming the draft problem
  file to its merge date and updating the plan's five references — was done
  after the review rather than before it. Nothing the reviewers read changed:
  the rename touches a filename and references to it, not the item, its
  grammar, or any prose or test they examined. The gate was re-dispatched
  afterwards, which is what step 6 exists for, and confirmed 463 ok / 0 not ok,
  no surviving `DRAFT-` file anywhere under `docs/`, no stale reference to the
  old name, and the item definition intact. Recorded because a sequence
  deviation that nobody writes down is indistinguishable from one nobody
  noticed.
- **One known defect is deferred.** `merge-change` step 3 stages and commits
  unconditionally while `finalize-docs.sh` is idempotent, so a rerun stages
  nothing and exits 1 under a sequence headed "halt on any failure". It is
  recorded in the plan and left to its own change; no ledger item is opened
  here, because the change that investigates it should own it.
