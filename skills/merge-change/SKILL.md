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

## The sequence

Halt on any failure, fix in the worktree, and rerun from step 1.

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
2. **Run the full verification suite** — every `verify_commands` entry.
   Conflict fallout and integration breakage stop the merge right here.
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
6. **Re-run the verification suite** — the renames moved files the tests may
   read; prove nothing broke.

6a. **Independent review** (DO-178C independence: the verifier is not the
   author). Dispatch a fresh subagent — or hand off to a human reviewer,
   per team policy — with ONLY: the diff, the relevant SRS/RMF/SAD
   excerpts, and the plan. No implementation narrative, no chat history.
   The reviewer answers:
   - Does the code satisfy each REQ/LLR the change claims to implement?
   - Do the tests actually verify what their `verifies:` annotations claim
     (verification of verification)? Would they fail if the behavior broke?
   - Are robustness (abnormal-input) cases present for every claimed ID
     (class B/C)?
   - Is there behavior with no requirement — unmarked derived work?

   Findings block the merge: fix in the worktree, rerun from step 1.
   Rigor scales with class — A may skip this step, B one reviewer, C a
   thorough review (consider two independent reviewers for critical items).

6b. **Verification record** — copy `.guardrails/templates/verification.md` to
   `docs/verification/<date>-<branch>.md` in the worktree, fill it in, and
   commit it (unsigned, like all worktree commits): test totals from step 6,
   coverage summary (if configured), each check script's result, open PR
   warnings, and the reviewer's verdict from 6a. The squash commit then carries
   the evidence on the base branch, and its `Verified:` line references this
   record.

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

7. **Signed squash merge onto the base branch:**

   ```sh
   cd <primary checkout>       # or exit the worktree via your harness tool
   git merge --squash <branch>
   git commit -S -m "<type>: <summary>

   Implements: <final REQ/RC/SDD/LLR IDs>
   Plan: docs/plans/<plan file>
   Verified: docs/verification/<record file>"
   ```

   Signing may require the user's hardware-key touch — tell them before
   running it. If signing fails (no key configured), **stop**: point to the
   ratchet setup checklist. There is no unsigned fallback, ever.
8. **Verify and clean up:**

   ```sh
   .guardrails/scripts/check-signing.sh   # verifies the new HEAD
   git worktree remove <worktree-path>    # or your harness's exit/cleanup tool
   git branch -D <branch>
   ```

   Cleanup happens only after the signature check passes — a failed check
   means investigate, not proceed. If the harness created the worktree
   (e.g. `EnterWorktree`), leave/remove it with the harness tool so its
   state stays consistent.

## Red flags

| Thought | Reality |
|---|---|
| "Skip re-verification, the rename touched no code" | It moved regulated documents. Re-run (step 6). |
| "Sign later, merge now" | An unsigned base branch is a broken audit trail. Stop instead. |
| "Merge the base branch in afterwards if something breaks" | Step 1 exists so breakage surfaces in the worktree. |
| "Leave the worktree around just in case" | Merged work lives on the base branch. Clean up (step 8). |
| "Checks fail but the change is obviously fine" | Fix the artifact or the genuine gap. Never bypass. |
| "The reviewer found nothing worth writing down" | Then `verdict:` says so. A record with no findings is legal; a record with no verdict is not. |
| "Drop the finding, I decided it was wrong" | Its disposition says that, with the reason. A deleted finding and a finding that never existed read identically. |
| "The record is prose, a gate cannot check it" | It checks presence, not quality — that a reviewer, a verdict and a `reproduced:` are there at all (step 6c). |
