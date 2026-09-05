---
name: merge-change
description: The compliance chokepoint - integrate a worktree into the base branch via ID finalization, full checks, and a verified signed squash merge, then clean up the worktree. Use when a change has passed verify-before-merge and is ready to integrate.
---

# Merge Change

**Announce at start:** "Using the merge-change skill to integrate this change."

Precondition: `verify-before-merge` passed in the worktree. The **base
branch** — whatever branch the primary (non-worktree) checkout currently has
checked out; never assume `main` — only ever receives one verified,
**signed** squash commit per change. Every step until the squash happens
**in the worktree**. Detect the base once and use it throughout:

```sh
BASE=$(. .guardrails/scripts/lib.sh && gr_base_branch)
```

**One change at a time.** A change is carried all the way to its signed squash
before the next change is opened. Parallelism lives *inside* a change — several
task subagents under `develop-change`, each in its own task worktree off the
change branch — never across changes. Two open changes race on the base branch,
on the duplicate scan in step 4, and on the verification record, and every one
of those races surfaces here rather than where it was created.

## Multi-unit repositories

When `.guardrails/units.yaml` exists, the sequence below runs **per unit
over the impact set**, and the impact set is computed, not judged:

```sh
.guardrails/scripts/check-units.sh --impact "$BASE..HEAD"
```

One `<unit>\t<touched|dependent>` line per unit — consume it mechanically,
never hand-pick the unit list. The mode exits 2 on a changed path claimed by
no unit (fix default mode's UNCLAIMED-PATH first; a partial impact set would
read as complete), and maps a change under the root `.guardrails/` to every unit.
Then, wherever the sequence says to run the gates or the suite:

- run `check-units.sh` with no flag once — the repository-level gates;
- run `check-trace.sh`, `check-ids.sh` and that unit's `verify_commands`
  with `GR_CONFIG=<unit>/.guardrails/config.yaml`, for **every unit in the impact set**
  (dependents included — that is what the set is for);
- run `finalize-docs.sh` (step 3) once per touched unit, `GR_CONFIG`
  pointing at each — a dependent has no drafts to rename;
- `check-review.sh` is repository-level and runs exactly once, unchanged.

The record at 6b names the units touched, and the impact set beside its
`branch:` line, so the evidence says which units' gates the verdict covers.
One branch, one squash, one record — D6 — however many units ran.

## The sequence

Halt on any failure. Deciding what to fix is yours; writing the fix is
dispatched like any other task — into its own nested task worktree, at a path
you name in the prompt (`.worktrees/<change-branch>-<tag>`,
`worktree-discipline` step 1) — and it lands on the change branch, never on
the base branch. That dispatch ends the way every other one does: once its
report is green you merge the task branch into the change branch, then
remove the worktree and delete the task branch (`worktree-discipline`,
"Inside the worktree"). Then rerun from step 1.

The tag is yours to name, and it must be unique per dispatch. Not because two
findings rounds that both reach for the natural `fix` would collide when the
second is created: the removal above takes round 1's branch with it, so the
name is free again before round 2 dispatches. That is the same property
step 6a rests on when it keeps the review tag fixed at `review`. The rule is
insurance against a cleanup that was missed, and this is the dispatch where
that is likeliest — no numbered step of this sequence performs its removal,
which happens between rounds, at your hand, and which is the whole cleanup:
`git worktree remove` and then `git branch -d`. Met by a repeated tag, either
half left undone is `fatal: a branch named '<change-branch>-fix' already
exists` at the next round's creation — git validates the new branch name
before the worktree path. Met by a fresh tag the two part company. A
leftover branch alone is a stale branch, deletable whenever you notice it.
A wholly skipped cleanup also leaves a nested worktree still registered —
gitignored, so `git status` never shows it — which step 6d catches and which
guard 4 refuses at step 8, after a full `check-signing.sh --strict` run.
Nothing is lost either way, but the second costs a halt late in the sequence
rather than a deletion at your convenience. Date it, number it, or name it
after the finding — anything that does not repeat.

1. **Merge the latest base branch into the worktree branch.** *Latest* means
   latest on the remote, not latest in this clone — on a shared repository a
   stale local base is the whole hazard this step exists to remove:

   ```sh
   if [ -n "$(git remote)" ]; then
       # A FAILED fetch is not "no remote". Swallowing it merges against a
       # stale remote-tracking ref and reports success — the same shape as a
       # gate that exits 0 having proved nothing. Stop and fix the access.
       git fetch origin || { echo "fetch failed — fix it before merging" >&2; exit 1; }
       git merge "origin/$BASE"
   else
       git merge "$BASE"          # genuinely local-only: nothing to fetch
   fi
   ```

   If the fetch cannot succeed here — no credentials in this environment, a
   hardware key that is not present — that is a **stop**, not a warning to
   scroll past. Either fetch from a session that can, or record in the
   verification record that the base was merged from a local ref and name the
   commit, so the next reader knows what the duplicate scan in step 4 was
   actually compared against.

   Resolve conflicts here, never on the base branch. This step is load-bearing
   for step 4: `check-ids.sh` has no gate against the base branch, because
   after this merge every ID the base defines is in the tree its in-tree
   duplicate scan already reads. Skip the fetch and that stops being true.
2. **Dispatch the verification suite** the way `verify-before-merge` describes
   — a fresh subagent runs every `verify_commands` entry in the worktree
   (per unit over the impact set in a multi-unit repository — see
   "Multi-unit repositories"), logs
   the raw output outside the tree, and returns the **gate summary**. Don't
   re-run it in your own context. Conflict fallout and integration breakage
   stop the merge right here, read from the summary's pass/fail counts.
3. **Finalize the draft doc files:**
   `.guardrails/scripts/finalize-docs.sh` (preview with `--dry-run` first).
   This renames any `DRAFT-<branch>-<slug>.md` ledger file to
   `<merge-date>-<slug>.md`. Commit the renames:
   `git add -A && git -c commit.gpgsign=false commit -m "chore: finalize ledger files"`.

   There are no IDs to finalize. Every item was given its ID by `new-id.sh`
   when it was written, and that ID is allocated against nothing — which is
   why step 1 above is enough to make two parallel changes safe to merge in
   either order.
4. **`.guardrails/scripts/check-ids.sh`** — zero draft tokens, zero
   draft-named ledger files, zero duplicates, zero malformed IDs. Step 1 has
   already merged the base branch in, so the duplicate scan sees every ID the
   base defines; there is no separate base gate and no `--base`.

   **`MALFORMED-ID`** means a line opens with a definition form whose ID is
   not valid — a hand-typed token with no digit, or a legacy ID too short to
   have ever matched. The item it announces is invisible to every other gate.
   Give it an ID from `new-id.sh`; never widen a pattern to accept it.
5. **`.guardrails/scripts/check-trace.sh`** — all gates clean.
6. **Dispatch the verification suite again** — same dispatch as step 2. The
   renames moved files the tests may read; the fresh **gate summary** is what
   proves nothing broke.

6a. **Independent review** (DO-178C independence: the verifier is not the
   author). Dispatch a fresh subagent — or hand off to a human reviewer,
   per team policy — with the diff, the relevant SRS/RMF/SAD excerpts, and
   the plan, and with **no implementation narrative and no chat history**.
   What is withheld is the author's account of the work, never access to the
   code: the reviewer has the whole repository, which is what the re-run below
   needs. The reviewer answers:
   - Does the code satisfy each REQ/LLR the change claims to implement?
   - Do the tests actually verify what their `verifies:` annotations claim
     (verification of verification)? Would they fail if the behavior broke?
   - Are robustness (abnormal-input) cases present for every claimed ID
     (class B/C)?
   - Is there behavior with no requirement — unmarked derived work?

   **The reviewer runs the suite itself.** For any change touching more than
   documentation, independence covers the evidence as well as the code: the
   reviewer runs every `verify_commands` entry in its own task worktree off the
   change branch and reports the counts it saw, not the counts it was handed.
   Only when the diff is documentation alone may it rest on the step 6 gate
   summary — then that summary is handed over as evidence in place of the
   re-run, and the record says so.

   **The reviewer's worktree is nested**, and you name its path in the dispatch
   prompt: `.worktrees/<change-branch>-review`, on branch
   `<change-branch>-review`, inside the change worktree. The reviewer is a
   dispatched subagent like any other, so it is pinned to the change worktree's
   subtree and cannot discover that before violating it
   (`worktree-discipline` step 1) — and a reviewer whose worktree is unusable
   reports on a suite it could not run. You remove it again at the end of this
   step; leaving it registered blocks the cleanup at step 7.

   **When the diff touches documentation**, the reviewer also checks:
   - New items are in this change's draft ledger file, and no existing
     definition moved from the file that defines it to another one.
   - IDs are well-formed minted tokens, and an amendment edits the defining
     file in place rather than restating the item somewhere new.
   - Item form holds: `**<ID>**: The software shall <single, testable
     behavior>`.
   - `satisfies:` / `implements:` references resolve, and derived items are
     marked as derived.
   - Terms match `docs/CONTEXT.md`.
   - Anything removed or reworded carries its supersession annotations: the
     superseded item keeps its place and gains `superseded-by: <new ID>`, and
     the new item carries `supersedes: <old ID>`. A requirement that simply
     disappeared is a finding.
   - The test that verified the superseded item now names both IDs —
     `verifies: <old ID>, <new ID>`. `superseded-by:` exempts nothing: the old
     item keeps its definition, so `check-trace.sh` keeps demanding a test for
     it, and the dual annotation is what keeps MISSING-TEST clean for both.

   **Findings come back ready to file.** The reviewer returns each one in the
   shape step 6b's record already wants —

   ```markdown
   **finding-1**: <what the reviewer found>
   ```

   — plus a one-line verdict, so 6b copies them instead of re-summarizing
   them. A finding reworded by the author is the author's finding.

   **Remove the review worktree, every round that created one.** Findings or
   not, the dispatch is over the moment the report is in hand, and every task
   worktree dies with its dispatch, at the dispatcher's hand
   (`worktree-discipline`, "Inside the worktree"). For this one that dispatcher
   is `merge-change`, so this is where it happens. A review produces findings,
   not commits, so there is nothing to merge — the worktree and its branch go
   as they are:

   ```sh
   # in the change worktree, as soon as the reviewer's report is in hand
   git worktree remove .worktrees/<change-branch>-review
   git branch -d <change-branch>-review
   ```

   `git branch -d` and not `-D`: a review branch should be exactly where it
   started, and a refusal here means the reviewer committed something, which
   is worth reading before it is discarded.

   Not every round creates one. A human reviewer, where team policy sends the
   review to a person, works from their own checkout; and a class A change
   skips this step altogether. Where no review worktree was created there is
   nothing to remove, and `git worktree remove`
   fails on a path that was never created — which, in a sequence that halts on
   any failure, is a stop for no reason.

   **Here, and not in a later step, because a round that returns findings never
   reaches a later step.** The paragraph below sends the sequence back to
   step 1, so everything after it runs only on the final, finding-free round —
   while the path and the branch above are *fixed*. Put the removal downstream
   and every intermediate round leaves its worktree behind, until the next
   round's dispatch dies with `fatal: a branch named
   '<change-branch>-review' already exists`.

   `git worktree remove` refuses on untracked files as well as modified ones,
   and a reviewer leaves scratch behind — a log, a note, a file it wrote and
   did not delete. Nothing gitignored is among them: git does not see an
   ignored file, which is the same property guard 4 exists for. That refusal
   is not a reason to reach for `--force`, which destroys exactly what it
   caught: read the scratch, delete it, and remove the worktree again, keeping
   anything worth keeping by putting it in the record at 6b first.

   Findings block the merge: you decide the disposition, the fix is dispatched
   into a nested task worktree of its own — `.worktrees/<change-branch>-<tag>`,
   named in the prompt like every other (`worktree-discipline` step 1) — and
   merged onto the change branch, never onto the base branch, and the sequence
   reruns from step 1.
   Rigor scales with class — A may skip this step, B one reviewer, C a
   thorough review (consider two independent reviewers for critical items).

6b. **Verification record** — copy `.guardrails/templates/verification.md` to
   `docs/verification/<date>-<branch>.md` in the worktree, fill it in, and
   commit it (unsigned, like all worktree commits): test totals from the
   step 6 gate summary,
   coverage summary (if configured), each check script's result, open PR
   warnings, the `red -> green:` attestations from the dispatch reports, and
   the reviewer's verdict from 6a. The squash commit then carries the evidence
   on the base branch, and its `Verified:` line references this record.

   **Copy the red → green attestations in.** The record's red → green table
   takes one row per ID this change implements: the ID, the test that verifies
   it, and the statement that the test was watched failing for the right reason
   before it passed. The source is the `red -> green:` lines of the task
   subagents' dispatch reports (`develop-change`) — the subagent that ran the
   loop is the only party that saw the test fail, so it is the only party that
   can attest it. Those lines arrived in a conversation, and a conversation is
   not durable state (`worktree-discipline`, "The artifacts are the memory");
   step 8 then recommends compacting it. Uncopied, the evidence for the iron
   law dies at the boundary this skill draws.

   Nothing re-verifies these rows. `check-review.sh` does not parse the table,
   and 6a cannot re-observe a test failing once it passes — the table is durable
   evidence, not a gated field, and it adds no required field to the record. The
   independent check on the same property comes at 6a from the other side: "do
   the tests verify what their `verifies:` annotations claim, and would they fail
   if the behavior broke?" A test that could never have gone red is caught by
   that question whatever this table says.

   Four fields are required, each a plain annotation at column one:

   - `branch:` — the change this record covers. It is how the gate finds the
     record, matched whole; the filename is not.
   - `reviewer:` — who performed step 6a.
   - `verdict:` — what the review concluded. A review that raised nothing must
     still say so.
   - `reproduced:` — was the defect reproduced before the fix, and how, or why
     not. **The value is never judged.** "Root cause measured directly, the
     end-to-end failure never reproduced" is an honest, passing record; the
     field exists so that the absence of evidence is a visible omission rather
     than an optional act of honesty.

   In a multi-unit repository the record also names the units touched, and the impact set.

   Each finding from 6a gets a block with its disposition:

   ```markdown
   **finding-1**: <what the reviewer found>
   disposition: <what changed, and the test that reddens without it>
   ```

6c. **`.guardrails/scripts/check-review.sh`** — the record exists, declares
   this branch, carries all four fields with values, and leaves no finding
   without a disposition. Run it from the worktree; on the base branch it
   exits 2, because there is no change under review there.

   `MISSING-RECORD` means step 6b did not happen for this branch.
   `STALE-RECORD` means a record declares this branch but the change did not
   write it — a reused branch name, with the previous change's record
   answering for this one. `UNDISPOSED-FINDING` means a finding from 6a has no
   stated resolution; `ORPHAN-DISPOSITION` and `MALFORMED-FINDING` mean a
   finding header the rule cannot read, so a disposition is attached to the
   wrong finding or to none. Never answer any of them by deleting the finding.

6d. **Check that nothing is registered inside the change worktree.** Every
   worktree this change created should already be gone: the review worktree at
   the end of step 6a, and each task worktree at the dispatcher's hand when its
   dispatch ended (`worktree-discipline`, "Inside the worktree"). This is the
   structural check that it actually happened:

   ```sh
   # in the change worktree, before the squash is staged
   git worktree list
   ```

   Read the list for paths inside the change worktree: none may still be
   registered there. A worktree registered anywhere else is not this step's
   business — another change's, a piece of tooling, the primary checkout
   itself — and guard 4 never mentions it either, because removing the change
   worktree does not touch it. A path inside is a removal that was skipped or
   refused, so go back to where it was dispatched from and do it there —
   step 6a for the review worktree, `develop-change`'s merge-and-remove for a
   task worktree. If `git worktree remove` refuses one of them as dirty, then
   the remedy step 6a gives for the review worktree applies to any of them.

   **This step is not tidiness.** `finish-merge.sh` refuses to remove a change
   worktree that has a worktree registered inside it (guard 4, step 8's table),
   because removing the outer one destroys the inner one's uncommitted work at
   exit 0. A worktree left behind therefore blocks step 7's cleanup after the
   user has already spent a key touch — which is a much worse place to find out
   than here, before the squash is staged.

7. **Squash onto the base branch, then hand the signing over.** The squash is
   yours; the commit is the user's. Do the merge in the primary checkout, with
   the base branch checked out:

   ```sh
   cd <primary checkout>       # or exit the worktree via your harness tool
   git merge --squash <branch>
   ```

   Write the commit message to a file **outside the repository** — a temp
   directory such as `/tmp/merge-<branch>.msg`, never anywhere under the working
   tree. Not because a guard would catch it: none of them reads the primary
   checkout's working tree, so an untracked message file there is invisible to
   all four. The reason is plainer — a stray file in the repository is one
   `git add -A` away from being committed as part of the change, and it would
   be committed by the very commit it describes. The message is unchanged:

   ```
   <type>: <summary>

   Implements: <final REQ/RC/SDD/LLR IDs>
   Plan: docs/plans/<plan file>
   Verified: docs/verification/<record file>
   ```

   Then hand the user exactly one command, with the real paths and branch name
   substituted in — their shell has none of your variables — and **stop**:

   ```sh
   git commit -S -F /tmp/merge-<branch>.msg && sh .guardrails/scripts/finish-merge.sh <branch>
   ```

   **You never run `git commit -S` yourself.** Signing may require the user's
   hardware-key touch, and starting a blocking wait on their behalf is exactly
   what this handoff replaces. Tell them the touch is coming.

   The command is a compound for a reason. The half that needs their key is a
   plain `git commit` they can read before they touch it; the half that deletes
   things is a script, because `&&` guards nothing and the tail force-deletes a
   branch (`-D`, necessarily — git does not consider a squashed branch merged).
   `finish-merge.sh` proves four things before it removes anything: the new
   HEAD's signature verifies under `--strict`, `git diff HEAD <branch>` is
   empty, no registered worktree lies inside the one it is about to remove
   (step 6a removes the review worktree and step 6d checks that nothing is
   left), and that worktree is clean. Then, in that order, it removes the
   worktree and deletes the branch. **Cleanup happens
   only after the signature check passes** — that is the script's first guard,
   not a step anyone may take on their own judgment.

   If signing fails (no key configured), **stop**: point to the ratchet setup
   checklist. There is no unsigned fallback, ever.

   The script takes the branch name and finds the worktree itself, so it needs
   no path from you — a pasted path is a chance to remove the wrong directory.
   If the harness created the worktree (e.g. `EnterWorktree`) and you left or
   removed it with the harness tool so its state stays consistent, that is fine:
   with no worktree registered for the branch the script skips the removal and
   still deletes the branch.
8. **Confirm, then report.** On the user's word that the command succeeded,
   confirm it rather than take it — the base branch's HEAD is the signed squash:

   ```sh
   git log -1 --format='%h %G? %s'
   .guardrails/scripts/check-signing.sh --strict   # verifies the new HEAD
   ```

   `--strict`, not the bare form. The tolerant mode passes a signature it could
   not verify — printing `WARN-UNVERIFIED` and exiting 0 — so under the comment
   "verifies the new HEAD" it would confirm nothing on exactly the machine where
   confirmation matters. `finish-merge.sh` has already run the same check with
   `--strict` moments earlier in the same compound, so this costs one re-read of
   a commit whose signature is known good, and it means this line cannot report
   success where that guard would have refused.

   Then report the merge — the squash commit, the IDs it implements, the
   verification record it cites — and recommend compacting the conversation
   before the next change is opened. This is the safe boundary: the plan, the
   ledger and the verification record hold everything durable, and scrollback
   holds nothing they do not. If the harness offers a compaction step (e.g. a
   `/compact` command), name it so the user can run it.

   **If the script refused.** Every refusal exits non-zero having removed
   nothing and deleted nothing, and the signed commit is on the base branch
   either way — what is refused is the cleanup, which is a safe thing to refuse.
   Read which guard fired:

   | Refusal | What it means | What fixes it |
   |---|---|---|
   | `UNVERIFIED` / `UNSIGNED` from `check-signing.sh --strict` | The new HEAD's signature did not verify. **Read the reason the gate prints indented under the verdict** — it is the verifier's own, not a guess. A missing `gpg.ssh.allowedSignersFile` is only one of the things it says, and an OpenPGP-signed commit never reads that setting at all; `gpg: ... can't open ... trustdb.gpg: Operation not permitted` is an environment fault rather than a bad signature. `--strict` is unconditional here, so a signature nobody can verify never passes for cleanup. | Fix what the reason names — the signers file for ssh (ratchet's signing checklist), a readable trust root for OpenPGP — then re-run the script. |
   | The squash did not capture everything — `git diff HEAD <branch>` is non-empty | Step 1 merged the base into the change branch, so a correct squash leaves the two trees identical. A difference means something did not land: an unstaged file, a partial `git add`, or a base that moved between step 1 and the squash. Deleting the branch would destroy exactly that difference. | `git diff HEAD <branch>` to see what is missing. Bring it onto the base branch, or rerun the sequence from step 1, before re-running the script. |
   | `a registered worktree lies inside <path>` — plural, `registered worktrees lie inside <path>` | A task or review worktree is still registered inside the change worktree. Removing the outer one would delete that worktree's files while git still had it registered: uncommitted work gone, the registration left prunable, the branch orphaned. Guard 3 cannot catch it, because a nested worktree is invisible to the outer one's `git status`, so `git worktree remove` does not refuse it. | Deal with each path the refusal names — merge or abandon its branch, then `git worktree remove` the path — and re-run the script. Step 6a is where the review worktree should already have gone and step 6d is where its absence should already have been checked; a task worktree here means a dispatch was never cleaned up. |
   | `git worktree remove` refused | The worktree is dirty — uncommitted work still lives there. No `--force` is passed, and git's own refusal is the guard. | Inspect the worktree, commit or discard what is there, then re-run the script. |
   | A precondition error (exit 2) | The script is in the wrong place or was given the wrong branch: run from a linked worktree, run on a detached HEAD, no such branch, or the branch named *is* the base branch. | Run it from the primary checkout with the base branch checked out, naming the change branch. |

   **The fix is to re-run the script alone**, never the whole compound:

   ```sh
   sh .guardrails/scripts/finish-merge.sh <branch>
   ```

   Re-running the compound is safe — the squash is no longer staged, so
   `git commit` fails and `&&` short-circuits before the script, and nothing
   double-commits — but it spends a key touch to prove that, and it reads as
   though the merge itself needs redoing. It does not. The merge is done; only
   the cleanup is outstanding.

## Red flags

| Thought | Reality |
|---|---|
| "Skip re-verification, the rename touched no code" | It moved regulated documents. Re-dispatch the gate (step 6). |
| "Sign later, merge now" | An unsigned base branch is a broken audit trail. Stop instead. |
| "I'll run `git commit -S` myself, it's one command" | The commit is the user's: it may need their hardware touch, and waiting on their key on their behalf is what step 7 replaces. Hand over the compound and stop. |
| "The message file can live in the repo, it's temporary" | No guard would catch it, which is the problem: it is one `git add -A` from being committed by the commit it describes. Write it outside the repository (step 7). |
| "The script refused, I'll remove the worktree and branch by hand" | A guard caught something. `--force` and `-D` destroy exactly what it caught. Fix the cause, re-run the script (step 8). |
| "Cleanup failed, so re-run the whole command" | The merge is done and the commit survived. Re-run the script alone — the compound only spends another key touch to short-circuit (step 8). |
| "Merge the base branch in afterwards if something breaks" | Step 1 exists so breakage surfaces in the worktree. |
| "Leave the worktree around just in case" | Merged work lives on the base branch. Clean up (step 8). |
| "Checks fail but the change is obviously fine" | Fix the artifact or the genuine gap. Never bypass. |
| "The reviewer found nothing worth writing down" | Then `verdict:` says so. A record with no findings is legal; a record with no verdict is not. |
| "Drop the finding, I decided it was wrong" | Its disposition says that, with the reason. A deleted finding and a finding that never existed read identically. |
| "The record is prose, a gate cannot check it" | It checks presence, not quality — that a reviewer, a verdict and a `reproduced:` are there at all (step 6c). |
| "The suite passed for me, the reviewer needn't re-run it" | Independence covers the evidence. Only a documentation-only diff may rest on your step 6 gate summary (step 6a). |
| "I'll tidy the reviewer's findings as I write the record" | Copy them in the `**finding-N**:` shape they arrived in. Rewording is the author answering the review. |
| "Open the next change while this one waits on review" | One change reaches its signed squash first. Fix what the review found instead. |
| "The subagents reported red → green, that is on the record" | It is in the scrollback, which step 8 compacts away. Copy those lines into the record (step 6b) or nothing durable attests them. |
| "I'll keep this conversation going into the next change" | The plan, the ledger and the record carry it. Compact at the merge boundary (step 8). |
