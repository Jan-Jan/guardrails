---
name: merge-change
description: The compliance chokepoint - integrate a change into the base branch as one verified, signed squash merge. Use when develop-change is done, to integrate the change.
---

# Merge Change

**Announce at start:** "Using the merge-change skill to integrate this change."

## Preconditions

- `develop-change` is done, its suite green.
- Every step before step 7 runs **in the change worktree**.
- The base branch is the primary checkout's branch. Never assume `main`.
  Detect it once:

  ```sh
  BASE=$(. .guardrails/scripts/lib.sh && gr_base_branch) && [ -n "$BASE" ]
  ```

## Steps

Halt on any failure. Dispatch your fix into the nested
task worktree `.worktrees/<change-branch>-<tag>`, named in the prompt and
created with `sh .guardrails/scripts/task-worktree.sh start <tag>`.
When its report is green, run
`sh .guardrails/scripts/task-worktree.sh merge <tag>` in the change worktree
to merge the task branch, remove the worktree and delete the task branch. Then
rerun from step 1.

The tag must be unique per dispatch.

1. **Merge the latest base branch into the worktree branch:**

   ```sh
   primary=$(git worktree list --porcelain | sed -n '1s/^worktree //p')
   [ -n "$primary" ] || { echo "no primary checkout" >&2; exit 1; }
   git -C "$primary" diff --cached --quiet || case $? in
       (1) echo "the index of $primary is not empty" >&2; exit 1 ;;
       (*) echo "cannot read the index of $primary" >&2; exit 1 ;;
   esac
   if [ -n "$(git remote)" ]; then
       git fetch origin || { echo "fetch failed — fix it before merging" >&2; exit 1; }
       base_ref="origin/$BASE"
   else
       base_ref=$BASE
   fi
   reviewed=$(git rev-list -1 --grep='^review dispatched$' "$base_ref..HEAD")
   [ -z "$reviewed" ] || git diff --name-only --no-renames "$(git merge-base "$reviewed" "$base_ref")" "$base_ref" |
       grep -Fx "$(git diff --name-only --no-renames "$base_ref...HEAD")" | sed 's/^/shared: /'
   git merge "$base_ref" &&
   sh .guardrails/scripts/prune-plans.sh --base "$base_ref" &&
   { git diff --quiet -- docs/plans || git -c commit.gpgsign=false commit -m "chore: prune plans" -- docs/plans; }
   ```

   - A staged squash in the primary checkout is a **stop**: tell the user,
     and once they sign or clear it, rerun this step.
   - A failed fetch is a **stop**. Fetch from a session that can, or merge
     the local ref and name it in step 7's `Base:` trailer.
   - A project may put the remote out of scope only if its AGENTS.md and
     the `Base:` trailer state why. Never adopt that by analogy.
   - Run this step every round. Resolve conflicts here, never on the base
     branch, then rerun.
   - An add/add conflict on a ledger file: keep the base's file,
     `git checkout --theirs -- <path>`, after
     saving this change's version under a new slug,
     `git show :2:<path> > <new path>`. Then `git add` both, and write the new
     name wherever this change cites it.
   - A `shared:` line names a file this change edits that the base edited
     after the last reviewed commit: step 4 then reviews the whole change
     again, even after the last review round. Otherwise the gate rerun covers
     it.
   - List each `left whole` plan in the record (step 5).
2. **Run the pre-flight** before the review:

   ```sh
   sh .guardrails/scripts/merge-preflight.sh --before-review <change-branch>
   ```

   Pass `--local-base` here and at 6c where step 1 put the remote out of
   scope. Skip this step in a round that dispatches no reviewer: 6c runs
   every check it runs.

   Read the warnings a passing check prints. The first failing check stops
   the run with its tool's output and a `fix <CHECK>:` line: exit 1 is
   a failed check, exit 2 a
   usage or environment error from the pre-flight or a tool it runs. Follow
   the `fix` lines, except where step 3 rules otherwise.
3. **Rule on what the pre-flight cannot.**

   - `MALFORMED-ID`: give the item an ID from `new-id.sh`. Never widen a
     pattern to accept the token.
   - `DRAFT-FILE` on a path this change did not add is a draft name another
     change left behind, renamed by a separate change.
4. **Independent review** — dispatch a fresh subagent (or a human reviewer
   where team policy requires one) with the diff, the plan and
   `.guardrails/scripts/find-items.sh show` of each ID the change claims or
   amends, and **no implementation narrative and no chat history**.
   Name its worktree in the prompt: `.worktrees/<change-branch>-review`,
   created with `task-worktree.sh start review`. First mark the commit it
   reviews:

   ```sh
   git -c commit.gpgsign=false commit --allow-empty -m 'review dispatched'
   ```

   The reviewer answers: does the code satisfy each claimed REQ/LLR; would
   each test fail if the behavior its `verifies:` names broke; has every
   claimed ID abnormal-input cases (class B/C); is any behavior unrequired
   (unmarked derived work)?

   **Hand the reviewer `references/review-checklist.md`**, every round.

   **The reviewer runs the suite itself** in its worktree and reports the
   counts. A documentation-only diff's reviewer skips the suite; the record
   states it, and 6a's gate covers it.

   **Every finding opens with its tag** — `code`, `requirement` or `record`:
   `code` when the implementation is wrong; `requirement` when an item, a
   skill or a template misstates or omits what the tree does; `record` when
   the record, plan or ledger misstates correct work. A `code` or
   `requirement` tag is followed by a severity, `high`, `medium` or `low`.
   The reviewer returns a one-line verdict. Copy findings verbatim.

   **Every finding still sends the sequence back to step 1, whatever its tag.**
   The tag decides only whether **another reviewer is dispatched**.
   Dispositioning a `record` finding in place, without a rerun, is
   deliberately not taken.

   **A round whose `code` and `requirement` findings, if any,
   are all `low` is the last review round.** Fix each low finding whose fix is
   mechanical, record each other one as an open problem item, and rerun from
   step 1 — but no further reviewer is dispatched, so steps 2 to 4 are skipped.
   A later round's reviewer reads the record earlier rounds wrote, and raises
   what is wrong.

   A 6a gate failure's fix dispatches a reviewer unless it touches only
   the record or plan.

   **Remove the review worktree, every round that created one**, when the
   report arrives:

   ```sh
   sh .guardrails/scripts/task-worktree.sh remove review
   ```

   - `remove` rejects a review branch with commits. Record each as a
     finding, then run `task-worktree.sh discard review`; never merge them.
   - Not every round creates one: a human reviewer uses their checkout.
     `remove` fails on a tag that was never started, so skip it there.
   - `remove` rejects untracked files as well as modified ones.
     Nothing gitignored is among them. Copy anything worth keeping into the
     record, then read the scratch, delete it, and run `remove` again.

   Dispatch each fix into `.worktrees/<change-branch>-<tag>`. Class A may
   skip this step, B needs one reviewer, C a thorough review; for class C,
   consider two independent reviewers for critical items.

5. **Verification record** — copy `.guardrails/templates/verification.md` to
   `docs/verification/<date>-<branch>.md`, fill it in, and commit it unsigned:
   the IDs this change resolves, accepts or opens,
   `red -> green:` and any `inherited:` lines from the plan, its guideline
   reviews (`## Guideline reviews`), the reviewer's verdict and every finding
   with its disposition.

   Four fields are required, each a plain annotation
   at column one: `branch:`, `reviewer:`, `verdict:` and `reproduced:`. 6c
   rejects a record unless it contains all four fields with values
   (`INCOMPLETE-RECORD`).

6a. **Dispatch the verification suite** as `verify-before-merge` describes, and
   read the verdict from the pass and fail counts of the **gate summary** it
   returns. Do not run it in your own context.

   **Record the tree the summary describes**, beside the summary:

   ```sh
   git rev-parse HEAD^{tree}   # clean worktree, at dispatch
   ```

6b. **Confirm the step 6a summary describes this tree**, when it arrives:

   ```sh
   git status --porcelain      # must be empty
   git rev-parse HEAD^{tree}   # the step 6a hash
   ```

   Same hash and a clean worktree: **the step 6a summary stands**. Otherwise
   dispatch the suite again.

6c. **Run the pre-flight again, with the review check:**

   ```sh
   sh .guardrails/scripts/merge-preflight.sh <change-branch>
   ```

   Read it as at step 2. Never answer a `REVIEW` failure by deleting a finding.
6d. **Remove a worktree the pre-flight named.** Retire each worktree a
   `NESTED-WORKTREE` failure lists as its fix line states:
   `task-worktree.sh remove <tag>`, `discard <tag>` after recording the
   commits `remove` rejects on, or the plain git commands for a worktree
   `task-worktree.sh` did not create. If `remove` rejects one as dirty,
   the remedy step 4 gives applies.

   A worktree registered anywhere else is not this step's business.
7. **Squash onto the base branch, then hand the signing over.** In the primary
   checkout, with the base branch checked out:

   ```sh
   git diff --cached --quiet && git merge --squash <branch>
   git diff --cached --quiet <branch>
   ```

   The second line exits 0 when the index holds exactly the branch's tree:
   go on to the message. Otherwise:

   - The first line printed that files "would be overwritten": the primary
     checkout is dirty. Stop and tell the user.
   - It printed other output: the base moved after step 1. Run
     `git reset --merge`, then rerun from step 1 as a base-move round:
     steps 2 to 4 only on a `shared:` line, as a review round whose rerun
     reaches step 5; otherwise 5 only for a new `left whole` plan; then 6a
     to 7.
   - It printed nothing: a squash was already staged, another change's or an
     outdated one of this change. Stop and tell the user; once they sign or
     clear it, rerun from step 1.

   Write the commit message to a file **outside the repository**:

   ```
   <type>: <summary>

   Implements: <final REQ/RC/SDD/LLR IDs>
   Resolves: <PR IDs this change closes>
   Opens: <PR IDs this change raises>
   Plan: docs/plans/<plan file>
   Verified: docs/verification/<record file>
   Base: <base ref> at <its commit>
   Gate-tree: <step 6a tree>
   Gate: <verify_commands entry> <passed>/<total>
   Gate: <coverage_command> <figure>
   ```

   Omit an empty `Resolves:` or `Opens:` line. Write one `Gate:` line per
   `verify_commands` entry, and one for `coverage_command` where configured.
   `<its commit>` is `git rev-parse <base ref>`.
   Keep every trailer, `Co-Authored-By:` included, in this last paragraph.

   Before the hand-over, compare the index with the step 6a tree:

   ```sh
   [ "$(git write-tree)" = <step 6a tree> ]
   ```

   A mismatch: run `git reset --merge`, then rerun from step 1.

   Hand the user this one command, filled in, and **stop**:

   ```sh
   git commit -S -F /tmp/merge-<branch>.msg && sh .guardrails/scripts/finish-merge.sh <branch>
   ```

   **Never run `git commit -S` yourself.** Tell them signing may need a
   hardware-key touch. Success ends with three
   `finish-merge:` lines; otherwise, they paste the output.
   `finish-merge.sh` proves five things before it removes anything. Pass it
   the branch name, never a path. If the harness created the worktree,
   leave or remove it with the harness tool.
   With no worktree registered for the branch, the script still deletes the
   branch.

   If signing fails because no key is configured, **stop** and point to the
   ratchet setup checklist. There is no unsigned fallback.
8. **Report.** On the user's word of success, write one
   closing line from the message file: branch, IDs, record.
   Run no git command: `finish-merge.sh` verified the signature.
   Recommend compacting before the next change; if the harness has a
   compaction step, name it so the user can run it.

   If the user reports a problem or `finish-merge.sh` exited non-zero, read
   `references/cleanup-rejections.md`.
   Fix the cause, then re-run the script alone, never the whole
   compound:

   ```sh
   sh .guardrails/scripts/finish-merge.sh <branch>
   ```

## Red flags

| Thought | Reality |
|---|---|
| "I'll run `git commit -S` myself, it's one command" | The commit is the user's. Hand over the compound and stop (step 7). |
| "The script rejected the cleanup; I'll remove the worktree and branch by hand" | `--force` and `-D` destroy what the guard caught. Fix the cause and re-run the script (step 8). |

## Done when

- The base branch HEAD is one squash commit for this change, whose message
  names its plan, record and gated tree,
  verified by `finish-merge.sh`.
- The change worktree and branch are gone, removed by `finish-merge.sh`.
- You reported the merge and recommended compacting.

## References

- `references/multi-unit.md` — read when `.guardrails/units.yaml` exists,
  before step 1.
- `references/review-checklist.md` — read when step 4 dispatches a
  reviewer.
- `references/cleanup-rejections.md` — read when `finish-merge.sh` exits
  non-zero at step 7 or 8.
- `references/rationale.md` — read when a rule here seems wrong, or
  before proposing to change one.
