---
name: merge-change
description: The compliance chokepoint - integrate a worktree into main via ID finalization, full checks, and a verified signed squash merge, then clean up the worktree. Use when a change has passed verify-before-merge and is ready to integrate.
---

# Merge Change

**Announce at start:** "Using the merge-change skill to integrate this change."

Precondition: `verify-before-merge` passed in the worktree. Main only ever
receives one verified, **signed** squash commit per change. Every step until
the squash happens **in the worktree**.

## The sequence

Halt on any failure, fix in the worktree, and rerun from step 1.

1. **Merge latest main into the worktree branch:**
   `git merge main` (resolve conflicts here, never on main).
2. **Run the full verification suite** — every `verify_commands` entry.
   Conflict fallout and integration breakage stop the merge right here.
3. **Finalize IDs:**
   `.guardrails/scripts/finalize-ids.sh --base main` (preview with
   `--dry-run` first). Commit the rewrite:
   `git -c commit.gpgsign=false commit -am "chore: finalize trace IDs"`.
4. **`.guardrails/scripts/check-ids.sh --base main`** — zero drafts, zero
   duplicates.
5. **`.guardrails/scripts/check-trace.sh`** — all gates clean.
6. **Re-run the verification suite** — the ID rewrite touched code and tests;
   prove it broke nothing.
7. **Signed squash merge onto main:**

   ```sh
   cd <main checkout>          # or exit the worktree via your harness tool
   git merge --squash <branch>
   git commit -S -m "<type>: <summary>

   Implements: <final REQ/RC/SDD IDs>
   Plan: docs/plans/<plan file>
   Verified: <verify commands + check scripts that passed>"
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
| "Skip re-verification, finalize only touched IDs" | It rewrote code and tests. Re-run (step 6). |
| "Sign later, merge now" | Unsigned main is a broken audit trail. Stop instead. |
| "Merge main in afterwards if something breaks" | Step 1 exists so breakage surfaces in the worktree. |
| "Leave the worktree around just in case" | Merged work lives on main. Clean up (step 8). |
| "Checks fail but the change is obviously fine" | Fix the artifact or the genuine gap. Never bypass. |
