---
name: merge-change
description: The compliance chokepoint - integrate a worktree into the base branch via ID finalization, full checks, and a verified signed squash merge, then clean up the worktree. Use when a change has passed verify-before-merge and is ready to integrate.
---

# Merge Change

**Announce at start:** "Using the merge-change skill to integrate this change."

## Preconditions

- `verify-before-merge` passed in the change worktree.
- Every step before step 7 runs **in the change worktree**. The base branch
  receives exactly one verified, **signed** squash commit per change.
- The base branch is whatever the primary checkout has checked out. Never
  assume `main`. Detect it once:

  ```sh
  BASE=$(. .guardrails/scripts/lib.sh && gr_base_branch)
  ```

- **One change at a time.** Take this change to its signed squash before the
  next change opens. Parallelism exists only inside a change, across task
  worktrees.
- If `.guardrails/units.yaml` exists, read `references/multi-unit.md` first.
  It changes which gates run and how often.

## Steps

Halt on any failure. You decide the fix. Dispatch the fix like any other task,
into a nested task worktree at a path you name in the prompt:
`.worktrees/<change-branch>-<tag>` (`worktree-discipline` step 1). When its
report is green, merge the task branch into the change branch, then
remove the worktree and delete the task branch:
`git worktree remove` and then `git branch -d`. Then rerun from step 1.

The tag must be unique per dispatch. Date it, number it, or name it after the
finding. With a repeated tag, a missed cleanup makes the next round's
dispatch fail.

1. **Merge the latest base branch into the worktree branch.** Latest means
   latest on the remote:

   ```sh
   if [ -n "$(git remote)" ]; then
       git fetch origin || { echo "fetch failed — fix it before merging" >&2; exit 1; }
       git merge "origin/$BASE"
   else
       git merge "$BASE"
   fi
   ```

   - A failed fetch is a **stop**. Fetch from a session that can, or record in
     the verification record that the base was merged from a local ref, and
     name the commit.
   - A project may put the remote out of scope only if its own AGENTS.md states
     why, and the record states it too. Never adopt that by analogy. With
     sequential IDs, or several people merging to a shared remote, the fetch is
     required. See `references/rationale.md`.
   - Run this step every round. `Already up to date` leaves the tree hash
     unchanged, and the figures downstream of it remain valid.
   - Resolve conflicts here, never on the base branch.
2. **Dispatch the verification suite** as `verify-before-merge` describes. A
   fresh subagent runs every `verify_commands` entry in the change worktree,
   logs raw output outside the tree, and returns the **gate summary**. Do not
   run it in your own context. Read the verdict from the pass and fail counts.

   **Record the tree the summary describes**, beside the summary:

   ```sh
   git rev-parse HEAD^{tree}   # clean worktree, at the moment of the dispatch
   ```

3. **Finalize the draft doc files.** Preview, then run:

   ```sh
   .guardrails/scripts/finalize-docs.sh --dry-run
   .guardrails/scripts/finalize-docs.sh
   ```

   It renames each `DRAFT-<branch>-<slug>.md` ledger file to
   `<finalize-date>-<slug>.md`, then rewrites every root-relative path and bare
   name that refers to it across the ledger directories and the SOUP file.
   Read every line it prints:

   - `rewrote FILE: old -> new` — it edited prose somebody else wrote. Check it.
   - `left FILE: …` — two drafts share a bare name. Write the reference as a
     path by hand.
   - `unrewritten FILE:LINE: NAME` (`would leave unrewritten` under
     `--dry-run`) — an old name outside the rewrite scope, in a plan or a
     verification record. Rule on each: narration of the rename stays; a
     citation meant to resolve is dead, so repair it. This line does not change
     the exit status, and nothing later repeats it.
   - A rename you do not recognise is a draft another change left behind.
     Stop: its repair is a separate change.

   A relative link such as `../risk/DRAFT-x.md`, a name in emphasis, or a name
   joined to a longer word is not rewritten. Step 5 reports it as
   `DANGLING-FILE`; write the dated name by hand. Plans and verification
   records are never rewritten. The date is the day this step first retired the
   draft name, not the day of the merge.

   Commit the renames **only where there were renames**:

   ```sh
   git add -A
   git diff --cached --quiet || git -c commit.gpgsign=false commit -m "chore: finalize ledger files"
   ```

   There are no IDs to finalize. `new-id.sh` minted each ID when its item was
   written.
4. **`.guardrails/scripts/check-ids.sh`** — zero draft tokens, zero draft ledger
   files, zero duplicates, zero malformed IDs. Step 1 merged the base, so the
   duplicate scan already sees every ID the base defines.

   - `MALFORMED-ID`: give the item an ID from `new-id.sh`. Never widen a
     pattern to accept the token.
   - `DRAFT-FILE` on a path this change did not create is another change's
     unfinished step 3. Its repair is a separate change.
5. **`.guardrails/scripts/check-trace.sh`** — all gates clean.
6. **Dispatch the verification suite again, where step 3 renamed something.**
   Decide by the tree, not by judgment:

   ```sh
   git status --porcelain      # must be empty
   git rev-parse HEAD^{tree}   # compare with the hash recorded at step 2
   ```

   Same hash and a clean worktree: **the step 2 summary stands**, and 6b
   records which tree the figures describe. A different hash, or anything
   uncommitted: dispatch the suite again.

6a. **Independent review** (DO-178C independence: the verifier is not the
   author). Dispatch a fresh subagent, or a human reviewer where team policy
   requires one. Give it the diff, the relevant SRS/RMF/SAD excerpts and the
   plan. Give it **no implementation narrative and no chat history**. It has
   the whole repository.

   Name its worktree in the prompt: `.worktrees/<change-branch>-review`, on
   branch `<change-branch>-review`, nested inside the change worktree. A
   dispatched subagent is pinned to the change worktree's subtree
   (`worktree-discipline` step 1).

   The reviewer answers:
   - Does the code satisfy each REQ/LLR the change claims to implement?
   - Do the tests verify what their `verifies:` annotations claim? Would they
     fail if the behavior broke?
   - Are robustness (abnormal-input) cases present for every claimed ID
     (class B/C)?
   - Is there behavior with no requirement, that is, unmarked derived work?

   **The reviewer runs the suite itself** in its own worktree and reports the
   counts it saw. Only a documentation-only diff may use the step 6 gate
   summary instead; the record then states the substitution.

   **When the diff touches documentation**, the reviewer also checks:
   - New items are in this change's draft ledger file, and no definition moved
     to another file.
   - IDs are minted tokens. An amendment edits the defining file in place.
   - Item form: `**<ID>**: The software shall <single, testable behavior>`.
   - `satisfies:` / `implements:` references resolve; derived items are marked.
   - Terms match `docs/CONTEXT.md`.
   - Anything removed or reworded is superseded, not deleted: the old item
     keeps its place and gains `superseded-by: <new ID>`, and the new item
     contains `supersedes: <old ID>`. A requirement that disappeared is a
     finding.
   - The test that verified the superseded item names both IDs:
     `verifies: <old ID>, <new ID>`. `superseded-by:` exempts nothing from
     `MISSING-TEST`, so the dual annotation keeps it clean for both.
   - Every other site that names the superseded ID. `check-trace.sh` enforces
     the supersession pair (`NON-RECIPROCAL-SUPERSESSION`,
     `MALFORMED-SUPERSESSION`) and only the pair. An `affects:`, `traces:` or
     table row may name an old ID as history, so that sweep stays a review job.

   **Every finding opens with its tag** — `code`, `requirement` or `record`,
   the first word of the value — in the shape 6b files:

   ```markdown
   **finding-1**: record — the gate table states 214 tests, the summary 218.
   ```

   - `code` — the implementation is wrong.
   - `requirement` — an item, a skill or a template states something the tree
     does not do, or omits something it must state.
   - `record` — the verification record, plan or ledger is inaccurate about
     work that is itself correct.

   The reviewer also returns a one-line verdict. Copy findings as they
   arrived; a reworded finding is the author's.

   **Every finding still sends the sequence back to step 1, whatever its tag.**
   The tag decides only whether **another reviewer is dispatched**.
   Dispositioning a `record` finding in place, without a rerun, is
   deliberately not taken; read `references/rationale.md` before proposing it.

   **A round raising no `code` and no `requirement` finding is the last review
   round.** Answer its findings in the record, book anything outstanding there
   as a gap, and rerun from step 1 — but no further reviewer is dispatched, and
   the rerun ends at 6b. The reviewer still reads the record and raises what is
   wrong with it. What changes is the price of a finding against it.

   **Remove the review worktree, every round that created one**, as soon as the
   report is in hand. A review produces no commits, so nothing is merged:

   ```sh
   git worktree remove .worktrees/<change-branch>-review
   git branch -d <change-branch>-review
   ```

   - Use `-d`, not `-D`. A rejection means the reviewer committed something.
     Read it first.
   - Not every round creates one. A human reviewer uses their own checkout,
     and class A may skip this step. `git worktree remove`
     fails on a path that was never created, so skip the removal there.
   - Remove it here. A round that returns any finding at all goes back to
     step 1 whatever the findings were tagged, so no later step runs on that
     round, and the next round's dispatch reuses the same path and branch.
   - `git worktree remove` fails on untracked files as well as modified ones.
     Nothing gitignored is among them. Do not use `--force`:
     read the scratch, delete it, and remove the worktree again.
     Copy anything worth keeping into the 6b record first.

   Findings block the merge. Decide each disposition and dispatch each fix into
   `.worktrees/<change-branch>-<tag>`, merged onto the change branch, never onto
   the base branch. Rigor scales with class: A may skip this step, B needs one
   reviewer, C a thorough review. For class C, consider two independent
   reviewers for critical items.

6b. **Verification record** — copy `.guardrails/templates/verification.md` to
   `docs/verification/<date>-<branch>.md`, fill it in, and commit it unsigned.
   It contains:

   - test totals from the gate summary, and the tree they describe;
   - coverage, if configured, and each check script's result;
   - the problem-ledger delta: the IDs this change resolves, accepts or opens.
     Never the open count or the oldest age; the next merge makes those false;
   - the `red -> green:` attestations from the dispatch reports, one row per
     implemented ID. The task subagent is the only party that saw each test
     fail, and scrollback does not persist;
   - the reviewer's verdict and every finding with its disposition.

   Four fields are required, each a plain annotation at column one:

   - `branch:` — the change this record covers, matched whole. The gate finds
     the record by this field, not by its filename.
   - `reviewer:` — who performed step 6a.
   - `verdict:` — what the review concluded, including "nothing found".
   - `reproduced:` — was the defect reproduced before the fix, and how, or why
     not. The value is never judged; an honest "not reproduced" passes.

   ```markdown
   **finding-1**: <code | requirement | record> — <what the reviewer found>
   disposition: <what changed, and the test that reddens without it>
   ```

6c. **`.guardrails/scripts/check-review.sh`** from the change worktree. On the
   base branch it exits 2. It checks that the record exists, declares this
   branch, contains all four fields with values, and leaves no finding without
   a disposition. Never answer a report by deleting a finding.

   - `MISSING-RECORD` — step 6b did not happen for this branch.
   - `INCOMPLETE-RECORD` — a required field is missing or has no value.
   - `STALE-RECORD` — a record declares this branch but this change did not
     write it. A reused branch name.
   - `UNDISPOSED-FINDING` — a finding has no disposition.
   - `ORPHAN-DISPOSITION`, `MALFORMED-FINDING` — a finding header the gate
     cannot read, so a disposition is attached to the wrong finding or none.

6d. **Check that nothing is registered inside the change worktree:**

   ```sh
   sh .guardrails/scripts/finish-merge.sh --check <change-branch>
   ```

   - Exit 0 with `nothing is registered inside <path>`: pass.
   - Exit 0 with `no worktree is registered for <branch>, so nothing was
     inspected`: not a pass. You named the wrong branch.
   - Exit 1 naming paths: a removal was skipped or failed. Go back to where
     that worktree was dispatched from and remove it there — step 6a for the
     review worktree, `develop-change`'s merge-and-remove for a task worktree.
     If `git worktree remove` fails on one as dirty, the remedy step 6a gives
     for the review worktree applies.

   It removes nothing. A worktree registered anywhere else is not this step's
   business. This check answers guard 4 of step 7 only. Guards 1 and 2 read
   the squash commit, which does not exist yet, and guard 3 is the removal
   itself.
7. **Squash onto the base branch, then hand the signing over.** The squash is
   yours; the commit is the user's. In the primary checkout, with the base
   branch checked out:

   ```sh
   git merge --squash <branch>
   ```

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

   `Resolves:` and `Opens:` repeat the 6b delta. Leave out a line that would be
   empty.

   Hand the user exactly one command, with real paths and branch name
   substituted, because their shell has none of your variables, and **stop**:

   ```sh
   git commit -S -F /tmp/merge-<branch>.msg && sh .guardrails/scripts/finish-merge.sh <branch>
   ```

   **Never run `git commit -S` yourself.** Signing may need the user's
   hardware-key touch; tell them it is coming.
   `finish-merge.sh` proves four things, and deletes the branch only when all
   four pass. The script numbers them as guards and proves them in this order:

   - Guard 1: the new HEAD's signature verifies under `--strict`.
   - Guard 2: `git diff HEAD <branch>` is empty.
   - Guard 4: no registered worktree is inside the one it removes. It is
     proved before guard 3, because the removal would take a nested worktree
     with it.
   - Guard 3: that worktree is clean. The script removes it without `--force`,
     so git rejects the removal on a dirty worktree.

   It finds the worktree from the
   branch name; never pass it a path. If the harness created the worktree,
   leave or remove it with the harness tool so its state stays consistent.
   With no worktree registered for the branch, the script skips the removal
   and still deletes the branch.

   If signing fails because no key is configured, **stop** and point to the
   ratchet setup checklist. There is no unsigned fallback.
8. **Confirm, then report.** On the user's word that the command succeeded,
   confirm it:

   ```sh
   git log -1 --format='%h %G? %s'
   .guardrails/scripts/check-signing.sh --strict   # verifies the new HEAD
   ```

   Use `--strict`. The bare form passes a signature it could not verify.

   Report the squash commit, the IDs it implements and the record it cites.
   Recommend compacting the conversation before the next change; the plan, the
   ledger and the record contain everything durable. If the harness offers a
   compaction step, such as a `/compact` command, name it so the user can run it.

   If `finish-merge.sh` exited non-zero, read `references/cleanup-rejections.md`.
   The signed commit is on the base branch either way, and nothing was removed.
   Fix the cause, then re-run the script alone, never the whole compound:

   ```sh
   sh .guardrails/scripts/finish-merge.sh <branch>
   ```

## Red flags

| Thought | Reality |
|---|---|
| "Skip re-verification, the rename touched no code" | Ask the tree. Only an unchanged `git rev-parse HEAD^{tree}` lets the step 2 summary stand (step 6). |
| "It is only a `record` finding, disposition it here and skip the rerun" | The tag does not shorten the sequence. Every finding reruns from step 1 (step 6a). |
| "Put the open-problem count in the record so the reader knows where we are" | The next merge makes it false. Name the IDs this change resolves, accepts or opens (step 6b). |
| "Sign later, merge now" | An unsigned base branch is a broken audit trail. Stop instead. |
| "I'll run `git commit -S` myself, it's one command" | The commit is the user's. Hand over the compound and stop (step 7). |
| "The message file can live in the repo, it's temporary" | It is one `git add -A` from being committed by the commit it describes (step 7). |
| "The script rejected the cleanup, I'll remove the worktree and branch by hand" | A guard caught something. `--force` and `-D` destroy it. Fix the cause and re-run the script (step 8). |
| "Cleanup failed, so re-run the whole command" | The merge is done. Re-run the script alone (step 8). |
| "Merge the base branch in afterwards if something breaks" | Step 1 exists so breakage surfaces in the worktree. |
| "Leave the worktree around just in case" | Merged work is on the base branch. Clean up (step 8). |
| "Checks fail but the change is obviously fine" | Fix the artifact or the genuine gap. Never bypass. |
| "The reviewer found nothing worth writing down" | Then `verdict:` records that. `check-review.sh` rejects a record with no verdict (step 6c). |
| "Drop the finding, I decided it was wrong" | Its disposition states that, with the reason. |
| "The record is prose, a gate cannot check it" | It checks presence: a reviewer, a verdict and `reproduced:` (step 6c). |
| "The suite passed for me, the reviewer needn't re-run it" | Only a documentation-only diff may use your gate summary (step 6a). |
| "I'll tidy the reviewer's findings as I write the record" | Copy them as they arrived. Rewording is the author answering the review. |
| "Open the next change while this one waits on review" | One change reaches its signed squash first. |
| "The subagents reported red → green, that is on the record" | It is in scrollback. Copy those lines into the record (step 6b). |
| "I'll keep this conversation going into the next change" | Compact at the merge boundary (step 8). |

## Done when

- The base branch HEAD is one squash commit for this change, and
  `check-signing.sh --strict` verifies it.
- The commit message names the plan and the verification record.
- The record contains `branch:`, `reviewer:`, `verdict:` and `reproduced:`,
  and every finding has a disposition.
- The change worktree and branch are gone, and nothing was removed with
  `--force` or `-D` by hand.
- You reported the merge and recommended compacting.

## References

- `references/multi-unit.md` — read when `.guardrails/units.yaml` exists,
  before step 1.
- `references/cleanup-rejections.md` — read when `finish-merge.sh` exits
  non-zero at step 7 or 8.
- `references/rationale.md` — read when a rule here seems wrong for your case,
  or before proposing to change one.
