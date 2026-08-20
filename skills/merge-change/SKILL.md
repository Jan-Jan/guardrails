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

1. **Merge the latest base branch into the worktree branch:**
   `git merge "$BASE"` (resolve conflicts here, never on the base branch).
2. **Run the full verification suite** — every `verify_commands` entry.
   Conflict fallout and integration breakage stop the merge right here.
3. **Finalize IDs and draft doc files:**
   `.guardrails/scripts/finalize-ids.sh` (preview with `--dry-run` first;
   the base branch is auto-detected, `--base REF` overrides). This mints
   final sequential IDs AND renames any
   `DRAFT-<branch>-<slug>.md` ledger files to `<merge-date>-<slug>.md`.
   Commit the rewrite (renames included):
   `git add -A && git -c commit.gpgsign=false commit -m "chore: finalize trace IDs"`.

   **Exit 1 with `UNMINTED-DRAFT` lines** means a draft ID was never a
   candidate to mint. Two causes, and the output names the file and line of
   each: the item has no bold header (`**PREFIX-DRAFT-slug-n**:`, at line
   start, colon immediately after), or its prefix is missing from
   `id_prefixes` so nothing ever looked for it. Fix the header, or add the
   prefix. Nothing was rewritten or renamed. Never hand-edit the draft IDs to
   finals instead.
4. **`.guardrails/scripts/check-ids.sh`** — zero drafts, zero duplicates
   (also checks against the auto-detected base branch). If it prints
   `SKIPPED-DUPLICATE-BASE`, the duplicate-vs-base half did not run — pass
   `--base "$BASE"` and rerun, because that is the half that catches an ID the
   base branch already defines. `UNANCHORED-DEF` is **not** a violation and
   does not block the merge: it names a `**ID**:` written somewhere other than
   the start of its line, numbered above the highest ID actually defined, which
   used to reserve that number and no longer does. Read it, then proceed.
   `UNANCHORED-DEF-UNREADABLE` says that scan could not run because a filename
   contains a newline — also not a violation, and also not a blocker.
5. **`.guardrails/scripts/check-trace.sh`** — all gates clean.
6. **Re-run the verification suite** — the ID rewrite touched code and tests;
   prove it broke nothing.

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

6b. **Verification record** — write `docs/verification/<date>-<branch>.md`
   in the worktree and commit it (unsigned, like all worktree commits):
   test totals from step 6, coverage summary (if configured), each check
   script's result, open PR warnings, and the reviewer's verdict from 6a.
   The squash commit then carries the evidence on the base branch, and its
   `Verified:` line references this record.

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
| "Skip re-verification, finalize only touched IDs" | It rewrote code and tests. Re-run (step 6). |
| "Sign later, merge now" | An unsigned base branch is a broken audit trail. Stop instead. |
| "Merge the base branch in afterwards if something breaks" | Step 1 exists so breakage surfaces in the worktree. |
| "Leave the worktree around just in case" | Merged work lives on the base branch. Clean up (step 8). |
| "Checks fail but the change is obviously fine" | Fix the artifact or the genuine gap. Never bypass. |
