---
name: merge-change
description: The compliance chokepoint - integrate a worktree into the base branch via ID finalization, full checks, and a verified signed squash merge, then clean up the worktree. Use when a change has passed verify-before-merge and is ready to integrate.
---

# Merge Change

**Announce at start:** "Using the merge-change skill to integrate this change."

## Preconditions

- `verify-before-merge` passed in the change worktree.
- Every step before step 7 runs **in the change worktree**.
- The base branch is the primary checkout's branch. Never assume `main`.
  Detect it once:

  ```sh
  BASE=$(. .guardrails/scripts/lib.sh && gr_base_branch) && [ -n "$BASE" ]
  ```

## Steps

Halt on any failure. You decide the fix, and dispatch it into a nested task
worktree at a path you name in the prompt, `.worktrees/<change-branch>-<tag>`,
created with `sh .guardrails/scripts/task-worktree.sh start <tag>`
(`worktree-discipline` step 1). When its report is green, run
`sh .guardrails/scripts/task-worktree.sh merge <tag>` in the change worktree
to merge the task branch, remove the worktree and delete the task branch. Then
rerun from step 1.

The tag must be unique per dispatch: date it, number it, or name it after the
finding.

1. **Merge the latest base branch into the worktree branch:**

   ```sh
   if [ -n "$(git remote)" ]; then
       git fetch origin || { echo "fetch failed — fix it before merging" >&2; exit 1; }
       base_ref="origin/$BASE"
   else
       base_ref=$BASE
   fi
   reviewed=$(git rev-list -1 --grep='^review dispatched$' "$base_ref..HEAD")
   [ -z "$reviewed" ] || git diff --name-only --no-renames "$(git merge-base "$reviewed" "$base_ref")" "$base_ref" |
       grep -Fx "$(git diff --name-only --no-renames "$base_ref...HEAD")" | sed 's/^/shared: /'
   git merge "$base_ref"
   ```

   - A failed fetch is a **stop**. Fetch from a session that can, or record
     the local ref and commit the base was merged from.
   - A project may put the remote out of scope only if its own AGENTS.md states
     why, and the record states it too. Never adopt that by analogy.
   - Run this step every round. Resolve conflicts here, never on the base
     branch.
   - A `shared:` line names a file this change edits that the base edited
     after the last reviewed commit: 6a then reviews the whole change again,
     even after the last review round. Otherwise the gate rerun covers it.
2. **Dispatch the verification suite** as `verify-before-merge` describes, and
   read the verdict from the pass and fail counts of the **gate summary** it
   returns. Do not run it in your own context.

   **Record the tree the summary describes**, beside the summary:

   ```sh
   git rev-parse HEAD^{tree}   # clean worktree, at dispatch
   ```

3. **Finalize the draft doc files.** Preview, then run:

   ```sh
   .guardrails/scripts/finalize-docs.sh --dry-run
   .guardrails/scripts/finalize-docs.sh
   ```

   Read every line it prints:

   - `rewrote FILE: old -> new` — check the edited prose.
   - `left FILE: …` — write the reference as a path by hand.
   - `unrewritten FILE:LINE: NAME` (`would leave unrewritten` under
     `--dry-run`) — narration of the rename stays; a citation meant to resolve
     is dead, so repair it.
   - A rename you do not recognise is a draft another change left behind.
     Stop: its repair is a separate change.

   Only root-relative paths and bare names are rewritten. Step 4 reports a
   relative link as `DANGLING-FILE`; write the dated name by hand.

   Commit the renames **only where there were renames**:

   ```sh
   git add -A
   git diff --cached --quiet || git -c commit.gpgsign=false commit -m "chore: finalize ledger files"
   ```

4. **Run the pre-flight** before the review:

   ```sh
   sh .guardrails/scripts/merge-preflight.sh --before-review <change-branch>
   ```

   `BASE-MERGED` also reads `origin/<base>`; pass `--local-base` here and at
   6c where step 1 put the remote out of scope.

   Each check prints `ok` or `skipped (<reason>)`. Read the warnings a passing
   check prints. The first failing check prints its tool's output and a
   `fix <CHECK>:` line, and stops the run: exit 1 is a failed check, exit 2 a
   usage or environment error from the pre-flight or a tool it runs. Follow
   the `fix` lines, except where step 5 rules otherwise.
5. **Rule on what the pre-flight cannot.**

   - `MALFORMED-ID`: give the item an ID from `new-id.sh`. Never widen a
     pattern to accept the token.
   - `DRAFT-FILE` on a path this change did not create is another change's
     unfinished step 3. Its repair is a separate change.
6. **Dispatch the verification suite again, where step 3 renamed something.**

   ```sh
   git status --porcelain      # must be empty
   git rev-parse HEAD^{tree}   # compare with the hash recorded at step 2
   ```

   Same hash and a clean worktree: **the step 2 summary stands**. Otherwise
   dispatch the suite again.

6a. **Independent review** — dispatch a fresh subagent (or a human reviewer
   where team policy requires one) with the diff, the plan and
   `.guardrails/scripts/find-items.sh show` of each ID the change claims or
   amends, and **no implementation narrative and no chat history**.
   Name its worktree in the prompt: `.worktrees/<change-branch>-review`,
   created with `task-worktree.sh start review`. First mark the commit it
   reviews:

   ```sh
   git -c commit.gpgsign=false commit --allow-empty -m 'review dispatched'
   ```

   The reviewer answers:
   - Does the code satisfy each REQ/LLR the change claims to implement?
   - Do the tests verify what their `verifies:` annotations claim, and would
     they fail if the behavior broke?
   - Are abnormal-input cases present for every claimed ID (class B/C)?
   - Is there behavior with no requirement (unmarked derived work)?

   **Hand the reviewer `references/review-checklist.md`**, every round.

   **The reviewer runs the suite itself** in its worktree and reports the
   counts it saw. Only a documentation-only diff may use the step 6 gate
   summary instead; the record states the substitution.

   **Every finding opens with its tag** — `code`, `requirement` or `record`:
   `code` when the implementation is wrong; `requirement` when an item, a
   skill or a template misstates or omits what the tree does; `record` when
   the record, plan or ledger misstates correct work. A `code` or
   `requirement` tag is followed by a severity, `high`, `medium` or `low`:
   `**finding-N**: code, medium — <text>`. The reviewer returns a one-line
   verdict. Copy findings verbatim.

   **Every finding still sends the sequence back to step 1, whatever its tag.**
   The tag decides only whether **another reviewer is dispatched**.
   Dispositioning a `record` finding in place, without a rerun, is
   deliberately not taken; read `references/rationale.md` before proposing it.

   **A round whose `code` and `requirement` findings
   are all `low` is the last review round.** Fix each low finding whose fix is
   mechanical, record each other one as an open problem item, and rerun from
   step 1 — but no further reviewer is dispatched, and the rerun ends at 6b.
   The reviewer still reads the record and raises what is wrong.

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

   Dispatch each fix into `.worktrees/<change-branch>-<tag>`, merged onto the
   change branch, never the base branch. Class A may skip this step, B
   needs one reviewer, C a thorough review; for class C,
   consider two independent reviewers for critical items.

6b. **Verification record** — copy `.guardrails/templates/verification.md` to
   `docs/verification/<date>-<branch>.md`, fill it in, and commit it unsigned:
   the gate summary's totals and the tree they describe, coverage if
   configured, each check's result, the IDs this change
   resolves, accepts or opens (never the open count or the oldest age), the
   `red -> green:` attestations from the plan, and the reviewer's verdict and
   every finding with its disposition.

   Four fields are required, each a plain annotation at column one. 6c
   rejects a record unless it contains all four fields with values
   (`INCOMPLETE-RECORD`):

   - `branch:` — the change, matched whole.
   - `reviewer:` — who performed step 6a.
   - `verdict:` — the review's conclusion, including "nothing found".
   - `reproduced:` — whether and how the defect was reproduced before the fix,
     or why not.

6c. **Run the pre-flight again, with the review check:**

   ```sh
   sh .guardrails/scripts/merge-preflight.sh <change-branch>
   ```

   Read it as at step 4. Never answer a `REVIEW` failure by deleting a finding.
6d. **Remove a worktree the pre-flight named.** Retire each worktree a
   `NESTED-WORKTREE` failure lists as its fix line states:
   `task-worktree.sh remove <tag>`, `discard <tag>` after recording the
   commits `remove` rejects on, or the plain git commands for a worktree
   `task-worktree.sh` did not create. If `remove` rejects one as dirty,
   the remedy step 6a gives applies.

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
     `git reset --merge`, then rerun from step 1.
   - It printed nothing: a squash was already staged, another change's or an
     outdated one of this change. Stop and tell the user; once they sign or
     clear it, rerun from step 1.

   Write the commit message to a file **outside the repository**, such as
   `/tmp/merge-<branch>.msg`:

   ```
   <type>: <summary>

   Implements: <final REQ/RC/SDD/LLR IDs>
   Resolves: <PR IDs this change closes>
   Opens: <PR IDs this change raises>
   Plan: docs/plans/<plan file>
   Verified: docs/verification/<record file>
   ```

   `Resolves:` and `Opens:` repeat the 6b delta. Leave out an empty line.

   Hand the user exactly one command, with real paths and branch name
   substituted, and **stop**:

   ```sh
   git commit -S -F /tmp/merge-<branch>.msg && sh .guardrails/scripts/finish-merge.sh <branch>
   ```

   **Never run `git commit -S` yourself.** Signing may need the user's
   hardware-key touch; tell them so. Success ends with three
   `finish-merge:` lines; otherwise, they paste the output.
   `finish-merge.sh` proves four things before it removes anything. Pass it
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
   compaction step, such as `/compact`, name it so the user can run it.

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
| "The script rejected the cleanup, I'll remove the change worktree and branch by hand" | A guard caught something. `--force` and `-D` on them destroy it. Fix the cause and re-run the script (step 8). |

## Done when

- The base branch HEAD is one squash commit for this change, whose message
  names the plan and the record, verified by `finish-merge.sh`.
- The change worktree and branch are gone, removed by `finish-merge.sh` and
  not by hand with `--force` or `-D`.
- You reported the merge and recommended compacting.

## References

- `references/multi-unit.md` — read when `.guardrails/units.yaml` exists,
  before step 1.
- `references/review-checklist.md` — read when step 6a dispatches a
  reviewer, and hand it over.
- `references/cleanup-rejections.md` — read when `finish-merge.sh` exits
  non-zero at step 7 or 8.
- `references/rationale.md` — read when a rule here seems wrong for your case,
  or before proposing to change one.
