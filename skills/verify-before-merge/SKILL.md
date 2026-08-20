---
name: verify-before-merge
description: Evidence-based completion gate - run every verification and paste real output before claiming work is done or starting a merge. Use before any "done", "fixed", "passing" claim and always before merge-change.
---

# Verify Before Merge

**Announce at start:** "Using the verify-before-merge skill."

**Evidence before assertions, always.** A claim of "done", "fixed", or
"passing" without freshly executed command output is a violation — "should
pass", "I'm confident", and passing-from-memory don't count.

## The gate

Run, in the worktree, and show actual output for each:

1. Every command in `verify_commands` (`.guardrails/config.yaml`) — full
   test suite, type checks, linters. Zero failures, pristine output.
2. `.guardrails/scripts/check-trace.sh` — clean.
3. `.guardrails/scripts/check-ids.sh --allow-drafts` — no duplicates
   (drafts are allowed here; `merge-change` finalizes them). An
   `UNANCHORED-DEF` line is a report, not a violation, and does not count
   against "pristine output" above — see `check-traceability` for what it
   means. The same goes for `UNANCHORED-DEF-UNREADABLE`.
4. The change's own claims: every ID the plan says it **Implements** has a
   `verifies:` test that you watched fail before it passed
   (`develop-change`).
5. **Coverage gate** — if `coverage_command` is configured, run it and judge
   the report against the class target: **A** none required · **B**
   statement coverage · **C** statement + decision coverage (MC/DC beyond
   that is optional extra credit). A shortfall is a failure unless the user
   explicitly accepts a documented gap (record the acceptance in the
   verification record).
6. **Robustness completeness** (class B/C) — every Implements: ID has both
   normal-case and abnormal-input tests, per `develop-change`'s robustness
   rule.
7. `git status` — no uncommitted work, no stray files.

## Rules

- Any failure: stop, fix in the worktree, re-run the whole gate. Partial
  passes don't carry over.
- Never weaken a check to get through it (skipping tests, loosening the
  config, `--allow-drafts` beyond step 3, editing expected outputs).
- Report failures faithfully if you must stop: what failed, actual output,
  what you tried.

## After the gate

Only a fully green gate authorizes `merge-change`. Quote the outputs in your
completion report — the merge commit's `Verified:` line lists exactly what
ran.
