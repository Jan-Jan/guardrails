---
name: develop-tdd
description: The red-green TDD loop a subagent runs in its task worktree for one plan task, or to fix the findings of a TEST conformance review - failing test first, verifies annotations, the class rules, the project's test guidelines file, and the dispatch report. Load it only when develop-change dispatched you.
---

# Develop TDD

**Announce at start:** "Using the develop-tdd skill for task <ID>."

## Preconditions

- You were dispatched by `develop-change` with one plan task, or with the
  findings of a `TEST` conformance review to fix; with your task worktree
  path; and with the guidelines file `guidelines-file.sh TEST` printed for
  each of the task's paths.
- Create the task worktree as the prompt says, from the change worktree you
  start in, and work only there. Commit on the task branch and leave it
  there. Do not merge it, and do not dispatch again.
- A fix dispatch is a task like any other: each finding is fixed under the
  loop below, citing the clause it names, or reported as not fixed with the
  reason.

## Steps

**No production code without a failing test first.** If you wrote code before
its test, delete it and start over from the test. Keeping it "as reference" is
the same violation.

### The loop, one behavior at a time

1. **RED:** write one minimal test for one behavior. Every new test declares
   what it verifies, in a comment or the test name:

   ```
   # verifies: <IDs>
   ```

   Annotate the **lowest requirement level that exists**: where an item has
   LLRs, the test verifies the LLR (the parent REQ is covered transitively);
   where there are no LLRs, the test verifies the REQ or RC directly.

   If you cannot annotate a test, the requirement it tests does not exist.
   Stop and run `grill-requirements` (or `analyze-risks` for risk-control
   behavior) before going on.
2. **Verify RED:** run the test and watch it fail for the right reason: the
   feature is missing, not a typo. A test that passes immediately proves
   nothing.
3. **GREEN:** write the minimal code that passes. No extra features, no
   speculative options.
4. **Verify GREEN:** run the test; every other test still passes; the output
   is clean.
5. **REFACTOR:** duplication, names, helpers. Behavior is unchanged and the
   tests stay green.
6. **Commit** (unsigned is fine in the worktree) and take the next test.

**Class rules.** Read `safety_class` from `.guardrails/config.yaml`:

- **B and C, the robustness rule:** every REQ and LLR gets both normal-case
  tests and abnormal-input tests: bad input, boundary values, resource
  exhaustion, dependency failure. A requirement with only happy-path tests is
  not verified; the independent review at merge checks for this.
- **C:** every SDD item the change touches gets tests at its own interface
  (its LLRs), not only end-to-end.

**Bugs.** A bug is a missing test. Reproduce it as a failing test annotated
with the REQ it violates, then fix it. If the bug reveals a hazard the RMF
missed, run `analyze-risks` before closing.

### Test guidelines

**Every test fails when the behavior it `verifies:` breaks.**
An assertion only that a double was called meets this only where the
call is the requirement.

Before RED, pick the guidelines file for the task:

```sh
sh .guardrails/scripts/guidelines-file.sh TEST <the paths the task touches>
```

For each path, follow the one file it prints, a unit's, the project's or the
installed default; read no other guidelines file. Where to attach a test and
which doubles it may use are stated there. If it exits 2 or is missing, stop
and reinstall the guardrails scripts and templates (`ratchet`'s upgrade);
never proceed without a guidelines file. A clause that contradicts this
skill is a finding against the clause: this skill wins, and the dispatch
report names the clause.

### The dispatch report

Return this shape and nothing else: no diffs, no logs, no narrative.

```
task: <ID>
worktree: <path to the task worktree>
files touched: <paths>
tests added: <test name — verifies: <IDs>>   (one per line)
red -> green: <test name> — watched fail for the right reason before the
implementation existed   (one per line, one per test)
inherited: <test name> — from <old ID>
result: <N passed, N failed>
fixed: <finding-N — what changed, or "not fixed — <reason>">   (a fix
dispatch only, one per finding)
surprises: <anything unexpected, or "none">
```

- Write one `red -> green:` line per new test. It is the only record that
  the test failed before its implementation existed.
- An `inherited:` line names a pre-existing test of a superseded item that
  the task pointed at its successor. It is coverage, not red-first evidence:
  the successor still needs its own `red -> green:` test. Never re-annotate
  any other test that was green before the task.
- `worktree:` is the path the prompt stated. Work anywhere else is a task
  that did not work; say so under `surprises:`.

## Red flags

| Thought | Reality |
|---|---|
| "I'll keep the code I wrote as reference while I write the test" | Delete it and start from the test. |
| "The test passed on its first run, good" | It proves nothing. Find out why it did not fail. |
| "This helper is complex, I'll test it directly" | Do what the guidelines file's `## Seams` says. |
| "The project file leaves this out; I'll read the default too" | One file per path. A rule the project dropped is dropped. |
| "I'll merge my task branch when I am done" | Leave it on the task branch. The dispatcher runs `task-worktree.sh merge`. |
| "The suite is green, the red -> green lines can go" | Each new test needs its line; the gate reads them at check 4. |
| "This finding is wrong; I'll skip it quietly" | Report it as not fixed, with the reason. The dispatcher decides. |

## Done when

- Each behavior of the task has a test that was watched fail for the right
  reason, then pass; on a fix dispatch, each finding is fixed or reported
  not fixed with its reason.
- The suite is green and its output is clean.
- The work is committed on the task branch, which is not merged.
- The dispatch report is returned, with one `red -> green:` line per new
  test.
