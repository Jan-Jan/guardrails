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

**Dispatch the gate; don't run it in your own context.** Send a fresh subagent
— your harness's subagent mechanism (e.g. an `Agent` or `Task` tool, a
`/subagent` command) — into the change worktree to run every check below. Test
logs, type-checker noise and coverage tables are exactly the material that
crowds out the plan and the trace, and none of it has to sit in the main
context to be evidence.

The subagent:

- runs each check in the change worktree and captures its raw output to a log
  file **outside the repository, or at a gitignored path** (e.g.
  `$TMPDIR/<branch>-gate.log`);
- returns the **gate summary** — nothing else. No diffs, no pasted logs.

The log lives outside the tree for two concrete reasons. Step 7 below requires
a clean `git status`, and an untracked log fails the gate that produced it. And
a test log quotes item IDs in test names, so a log under `docs/` is read by
`check-ids.sh` and `check-trace.sh`, where a line shaped like an item
definition becomes a duplicate ID or a dangling reference. Evidence that breaks
the gates is not evidence.

The **gate summary** has a fixed shape, and it carries an answer for every
check the subagent owns:

- per-command result with pass/fail/skip counts (checks 1, 2, 3);
- suite totals;
- coverage figures, where `coverage_command` is configured, judged against the
  class target, with any shortfall named as a shortfall (check 5);
- the **Implements map** (check 4): for every ID the plan says the change
  **Implements**, the `verifies:` test that carries it — and, listed
  explicitly, every Implements ID for which no such test was found;
- robustness coverage (check 6): for each Implements ID, whether a normal-case
  test and an abnormal-input test are both present;
- the `git status` result (check 7): clean, or the files that dirty it;
- the tail of every command's output;
- the log path.

Evidence before assertions is untouched by this. The evidence moves from the
chat log to the log file plus the verification record; it does not become
anyone's recollection.

In the change worktree — step 7 reads its `git status`, so the gate can run
nowhere else — the subagent runs and captures actual output for each of the
checks below. Two checks have a half the subagent cannot answer. Check 4's
other half is yours: you answer it from the dispatch reports once the summary
is back. Check 5's other half is the user's: only they can accept a documented
coverage gap, which is why `develop-change` names it a deliberate stop.

1. Every command in `verify_commands` (`.guardrails/config.yaml`) — full
   test suite, type checks, linters. Zero failures, pristine output.
2. `.guardrails/scripts/check-trace.sh` — clean.
3. `.guardrails/scripts/check-ids.sh --allow-draft-files` — no duplicate and
   no malformed IDs. The flag covers the change's own
   `DRAFT-<branch>-<slug>.md` ledger file, which is legitimate here and is
   renamed by `merge-change`; it does not relax anything about IDs. A draft ID
   token is a failure at this gate and at every other one.
4. The change's own claims — split between the two parties who can answer,
   because neither half is the check on its own:
   - **the subagent's half:** every ID the plan says it **Implements** has a
     `verifies:` test present in the change worktree, and the gate summary
     names which test carries which ID;
   - **your half:** each of those tests was watched failing for the right
     reason before it passed. Read that from the `red -> green:` lines of the
     dispatch reports you hold (`develop-change`). The gate subagent watched
     nothing fail, so it cannot attest to this, and a green run cannot imply
     it.

   An Implements ID with no `verifies:` test fails the check; so does a
   `verifies:` test with no `red -> green:` attestation behind it. Fix either
   in the change worktree and re-dispatch — never by re-annotating a test that
   was green from the start.
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

`check-review.sh` is deliberately NOT in this list. The verification record it
reads does not exist yet — `merge-change` step 6b writes it, after the
independent review at 6a, and 6c checks it there. Adding it here would fail
every change for a record it is not yet time to write.

## Exit 0 is not a pass

The tail of a command's output goes into the gate summary whether the command
exited 0 or not, and the verdict is read from the reported pass/fail counts,
never from the status code. Say why, because the shortcut is tempting: a zero
status proves the runner ran, not that the tests passed. Storybook-style test
runners, some integration harnesses, and anything wrapped in a script that
forgets `set -e` report failures and exit 0 anyway.

So "exit 0, therefore green" is not a gate result. A command that reports no
counts at all is a finding to chase — not a pass to assume.

## Rules

- Any failure: stop. Deciding what to fix is yours; writing the fix is
  dispatched like any other task, and it lands in the change worktree, never on
  the base branch. Then dispatch the whole gate again — partial passes don't
  carry over.
- The subagent reports; it does not fix. Findings come back to you: you decide
  what to change, the fix is dispatched into the change worktree — never onto
  the base branch — and the gate is re-dispatched from the top.
- Never weaken a check to get through it (skipping tests, loosening the
  config, `--allow-draft-files` beyond step 3, editing expected outputs) — and
  never weaken one in the dispatch prompt either.
- Report failures faithfully if you must stop: what failed, actual output,
  what you tried.

## After the gate

Only a fully green gate authorizes `merge-change`. Quote the gate summary in
your completion report and cite the log path — the merge commit's `Verified:`
line lists exactly what ran. Don't re-run the commands yourself to see the
output with your own eyes; the summary is the report.

Then answer your half of check 4 before you call the gate green: match the
Implements IDs the summary's Implements map names against the `red -> green:`
lines of your dispatch reports, and state in the completion report that every
one is covered. A green summary is not a green gate until that half is
answered.

Those `red -> green:` lines are conversation, and the conversation is not
durable. Carry them into the verification record `merge-change` step 6b
writes, so the evidence for the iron law outlives this conversation.

The log dies with the change worktree, and that is fine — the durable evidence
is the verification record `merge-change` step 6b writes: totals, per-command
results, coverage summary, verdict. Anything that record needs from the gate
must therefore be in the gate summary. If a figure is missing, ask the
subagent for it rather than running the command again.
