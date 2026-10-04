---
name: verify-before-merge
description: Evidence-based completion gate - run every verification and paste real output before claiming work is done or starting a merge. Use before any "done", "fixed", "passing" claim and always before merge-change.
---

# Verify Before Merge

**Announce at start:** "Using the verify-before-merge skill."

## Preconditions

- You are about to claim "done", "fixed" or "passing", or to start
  `merge-change`. The evidence rule at the top of the steps applies to every
  such claim, by any agent: a dispatcher, a task subagent, or a gate
  subagent.
- For the gate itself ("Dispatch the gate" onward): you are the dispatcher of
  a change, in its change worktree, and every plan task branch is merged onto
  the change branch (`develop-change`).

## Steps

**Evidence before assertions, always.** A claim of "done", "fixed", or
"passing" without freshly executed command output is a violation. "Should
pass", "I'm confident" and passing-from-memory do not count.

### Dispatch the gate

Do not run the gate in your own context. Dispatch a fresh subagent, with
whatever your harness offers for dispatching one (a `Task` or `Agent` tool, an
`/agent` command), into the change worktree to run every check below. Check 7 reads
that worktree's `git status`, so the gate runs nowhere else.

The subagent:

- runs each check in the change worktree and captures its raw output to a log
  file **outside the repository, or at a gitignored path** (for example
  `$TMPDIR/<branch>-gate.log`). A log in the tree dirties check 7, and a log
  under `docs/` is read by `check-ids.sh` and `check-trace.sh`;
- returns the **gate summary** and nothing else: no diffs, no pasted logs.

The **gate summary** has a fixed shape, with an answer for every check the
subagent owns:

- per-command result with pass/fail/skip counts (checks 1, 2, 3);
- suite totals;
- coverage figures, where `coverage_command` is configured, judged against the
  class target, with any shortfall reported as a shortfall (check 5);
- the **Implements map** (check 4): for every ID the plan states the change
  **Implements**, the `verifies:` test that contains it, and, listed
  explicitly, every Implements ID for which no such test was found;
- robustness coverage (check 6): for each Implements ID, whether a normal-case
  test and an abnormal-input test are both present;
- the `git status` result (check 7): clean, or the files that dirty it;
- the tail of every command's output;
- the log path.

Two checks have a half the subagent cannot answer. Check 4's other half is
yours, from the dispatch reports. Check 5's other half is the user's: only
they can accept a documented coverage gap, which is why `develop-change` names
it a deliberate stop. Check 8 is wholly yours, so the gate summary has no line
for it.

### The checks

1. Every command in `verify_commands` (`.guardrails/config.yaml`): full test
   suite, type checks, linters. Zero failures, pristine output.
2. `.guardrails/scripts/check-trace.sh`: clean.
3. `.guardrails/scripts/check-ids.sh --allow-draft-files`: no duplicate and
   no malformed IDs. The flag covers the change's own
   `DRAFT-<branch>-<slug>.md` ledger file, which `merge-change` renames; it
   relaxes nothing about IDs. A draft ID token is a failure at this gate and
   at every other one.
4. The change's own claims, split between the two parties who can answer:
   - **the subagent's half:** every ID the plan states it **Implements** has a
     `verifies:` test present in the change worktree, and the gate summary
     names which test verifies which ID;
   - **your half:** each of those tests was watched failing for the right
     reason before it passed. Read that from the `red -> green:` lines of the
     dispatch reports (`develop-change`). The gate subagent watched nothing
     fail, and a green run cannot imply it.

   An Implements ID with no `verifies:` test fails the check; so does a
   `verifies:` test with no `red -> green:` attestation behind it. Fix either
   in the change worktree and re-dispatch. Never re-annotate a test that was
   green from the start.
5. **Coverage gate:** if `coverage_command` is configured, run it and judge
   the report against the class target: **A** none required · **B**
   statement coverage · **C** statement + decision coverage (MC/DC beyond
   that is optional). A shortfall is a failure unless the user explicitly
   accepts a documented gap; record the acceptance in the verification
   record.
6. **Robustness completeness** (class B/C): every Implements ID has both
   normal-case and abnormal-input tests, per `develop-change`'s robustness
   rule.
7. `git status`: no uncommitted work, no stray files.
8. **The deslop pass was run** and the dispatcher fixed its findings
   (`develop-change`). Answer it from the pass's report, as you answer check
   4's other half from the dispatch reports; the tree cannot show whether a
   diff was reviewed.

Do not add `check-review.sh` to this list. The verification record it reads is
written at `merge-change` step 6b and checked at 6c.

### Exit 0 is not a pass

Read the verdict from the reported pass/fail counts, never from the status
code. The tail of each command's output goes into the gate summary whether the
command exited 0 or not. A command that reports no counts at all is a finding
to investigate, not a pass to assume.

### On a failure

- Any failure: stop. You decide what to fix. Dispatch the fix like any other
  task, into its own task worktree at `.worktrees/<change-branch>-<tag>`,
  nested inside the change worktree and named in the dispatch prompt
  (`worktree-discipline` step 1). Merge it onto the change branch, never onto
  the base branch. Then dispatch the whole gate again; results from a partial
  pass do not count.
- The subagent reports; it does not fix. Its findings come back to you and
  follow the same route.
- Never weaken a check to get through it (skipping tests, loosening the
  config, `--allow-draft-files` beyond check 3, editing expected outputs), and
  never weaken one in the dispatch prompt.
- If you must stop, report the failure faithfully: what failed, the actual
  output, what you tried.

### After the gate

1. Answer your half of check 4: match the IDs in the summary's Implements map
   against the `red -> green:` lines of your dispatch reports, and state in
   the completion report that every one is covered. Answer check 8 there too.
   A green summary is not a green gate until both are answered.
2. Quote the gate summary in your completion report and cite the log path.
   Do not re-run the commands to see the output; the summary is the report.
3. Copy the `red -> green:` lines into the verification record
   `merge-change` step 6b writes.
4. Anything that record needs from the gate (totals, per-command results,
   coverage summary, verdict) must be in the gate summary. If a figure is
   missing, ask the subagent for it rather than running the command again.

Only a fully green gate authorizes `merge-change`.

## Red flags

| Thought | Reality |
|---|---|
| "I'll run the suite myself, it is quicker" | Dispatch it. The logs stay out of your context. |
| "It exited 0, so it passed" | Read the counts. A runner can report failures and exit 0. |
| "The summary is green, the gate is green" | Not until your half of check 4 and check 8 are answered. |
| "Add `--allow-draft-files` to the other checks too" | That weakens a check. It applies to check 3 only. |
| "Re-run only the check that failed" | Dispatch the whole gate again. |

## Done when

- The gate summary reports every line it contains green, with counts: checks
  1, 2, 3, 5, 6, 7 and the subagent's half of check 4.
- You, the dispatcher, answered your half of check 4 and check 8 in the
  completion report.
- The completion report quotes the gate summary and cites the log path.
- `git status` in the change worktree is clean.

## References

- `references/rationale.md` — read when a rule here seems wrong for your case,
  or before proposing to change one.
