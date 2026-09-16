---
name: develop-change
description: TDD implementation loop for guardrails projects - failing test first, verifies-annotations mandatory, minimal code to green, plan tasks dispatched to subagents. Use when implementing any feature, fix, or refactor.
---

# Develop Change

**Announce at start:** "Using the develop-change skill (TDD)."

Preconditions: you are in a worktree (`worktree-discipline`) and, for
non-trivial changes, a plan exists (`plan-change`).

## The iron law

**No production code without a failing test first.** Wrote code before its
test? Delete it and start over from the test. Keeping it "as reference" is
the same violation.

## Red — Green — Refactor

1. **RED:** write one minimal test for one behavior. Every new test declares
   what it verifies, in a comment or test name:

   ```
   # verifies: <IDs>
   ```

   Annotate the **lowest requirement level that exists**: where an item has
   LLRs, tests verify the LLR (the parent REQ is covered transitively);
   where there are no LLRs, tests verify the REQ/RC directly.

   A test you can't annotate is testing a requirement that doesn't exist —
   stop and run `grill-requirements` (or, if it's risk-control behavior,
   `analyze-risks`) before proceeding.
2. **Verify RED:** run it; watch it fail for the right reason (feature
   missing, not a typo). A test that passes immediately proves nothing.
3. **GREEN:** minimal code to pass. No extra features, no speculative
   options.
4. **Verify GREEN:** run it; all other tests still pass; output pristine.
5. **REFACTOR:** duplication, names, helpers — behavior unchanged, tests
   stay green.
6. **Did you change a line a mutation script quotes?** Every
   `docs/verification/*.mutations/M*.sh` embeds a line of the script it mutates
   as a literal `old = '''…'''` and asserts `s.count(old) == 1`, so editing a
   quoted line leaves a mutation that can no longer apply — a past change's
   evidence, silently unreproducible. Nothing in the suite catches it:
   `portability.bats` reads that directory only for `sed -i` spellings. One
   grep per changed output line, from the repository root:

   ```sh
   grep -rn 'the exact line you changed' docs/verification/*.mutations/
   ```

   A hit is not a reason to leave the line alone. Re-cut the anchor to the new
   text — the precedent is `bb7eee5`, which amended *earlier* changes'
   mutations for the same reason, because these scripts are kept runnable
   rather than frozen with the change that wrote them — and then **prove the
   re-cut anchor applies AND still kills tests**. An anchor that applies and
   kills nothing means the tests never covered that mutation, which is a
   finding of its own, not a green.

   Most changes edit no such line and this costs one grep. It earns its place
   because the failure is invisible: the mutation is not run by any gate, so
   nothing goes red at the time, and the loss shows up only when someone tries
   to reproduce the old verification and cannot.
7. **Commit** (unsigned is fine in the worktree) and take the next test.

## Delegation

The loop above is the work; you orchestrate it. A subagent runs the loop for
one plan task, and you keep the plan, the trace and the decisions. If you *are*
the dispatched subagent, run the loop yourself — do not dispatch again.

- **Dispatch by default.** Every plan task goes to a subagent, even when there
  is one task and no concurrency to gain. The gain is not wall-clock; it is
  that the code, the diffs and the test output never enter your context. Do not
  ask the user for permission to dispatch — this is the normal path, not an
  escalation.
- **A task worktree each — and you merge it back.** The subagent creates its
  own task worktree off the change branch, commits there, and returns its
  report. It does not merge, and cannot: git rejects an update to a branch
  another worktree has checked out, and the change branch is checked out in
  yours. From the task worktree `git merge <change-branch>` merges the wrong
  direction, into the task branch, and still exits 0 (`worktree-discipline`
  step 1 lists every route that fails). So when a dispatch report comes back
  green, *you* merge that task branch into the change branch from the change
  worktree, then remove the task worktree and the task branch. Parallel tasks
  touch disjoint files, so those merges do not conflict with each other. The
  base branch is never touched.
- **At most five at once, disjoint files only.** Fan out only across tasks whose
  **Files touched:** sets do not intersect (`plan-change`). Everything else runs
  serially.
- **The prompt is a pointer, not a copy.** Use whatever your harness offers for
  dispatching a subagent (e.g. a `Task`/`Agent` tool, a `/agent` command), and
  keep the prompt to a pointer:

  ```
  Execute task 3 of docs/plans/2026-08-30-<topic>.md under the develop-change
  skill. Create your task worktree at .worktrees/<change-branch>-t3, nested
  inside the change worktree you are in, on branch <change-branch>-t3 off
  <change-branch>. Commit your work on that branch and leave it there — do not
  merge it. Once your task worktree exists, do not commit on <change-branch>
  and do not keep working in the change worktree. Return the dispatch report.
  ```

  **Name the path; do not leave it to be chosen.** A dispatched subagent is
  pinned to the change worktree's subtree, and it cannot discover that pin
  before it has already violated it — a worktree created outside is created
  successfully and is then unusable (`worktree-discipline` step 1). You are
  outside the pin and know the path; state it.

  **What is forbidden is the change branch, not the change worktree.** Under
  containment the subagent *starts* in the change worktree — that is where its
  pin puts it, and where it must run `git worktree add` from — so "do not enter
  the change worktree" is an instruction it cannot follow. The prohibition that
  is actually meant is narrower and begins once the task worktree exists: no
  commit on the change branch, and no further work in the change worktree.

  Otherwise, do not restate the task. `plan-change` already put the exact
  paths, the real code and the expected output in the plan; restating them
  doubles the cost at both ends and lets the two copies disagree.

### The dispatch report

The subagent returns this shape and nothing else — no diffs, no logs, no
narrative:

```
task: <ID>
worktree: <path to the task worktree>
files touched: <paths>
tests added: <test name — verifies: <IDs>>   (one per line)
red -> green: <test name> — watched fail for the right reason before the
implementation existed   (one per line, one per test)
result: <N passed, N failed>
surprises: <anything unexpected, or "none">
```

Without the fixed shape the code arrives in the reply instead of in a read,
and the delegation gains nothing.

The `worktree:` line confirms the subagent went where you sent it. The prompt
already states `.worktrees/<change-branch>-t<N>`, so the path is not new
information — but a report naming anything else is a task that will not have
worked, and it is cheaper to see that on one line than to infer it from the
failures. You also need the path to run `git worktree remove` once the task
branch is merged; `git worktree list` is the fallback if a report omits it.

The `red -> green:` lines are how the iron law stays enforced under
delegation: the subagent that executed the loop is the only party that saw the
test fail, so it is the only party that can state it, and this line is the
only channel by which that observation reaches you and the gate. State it
explicitly, one line per test — a pass count shows only that the test is
green now, never that it was ever red. `verify-before-merge` check 4 reads
these lines back.

**Write those lines into the plan as each report arrives**, beside the task
they belong to, along with marking the task done. `merge-change` step 6b copies
them into the verification record, and that is many steps away and reruns from
step 1 on any finding; until then they exist only in this conversation,
which is not durable state (`worktree-discipline`, "The artifacts are the
memory"). Written into the plan they are an artifact from the moment they
arrive, and 6b copies them from a file instead of from scrollback.

### Derailment — the only stop this skill adds

The test is not a count of stops. **Stop only when the answer is genuinely the
user's.** Repeated failure at the same point qualifies:

- the same task fails its red → green cycle twice, or
- review returns findings on the same task twice.

Then stop and report what is stuck, what was tried, and put the choice to the
user: raise the effort level, or decompose the task differently. A task that is
merely hard is not a reason to stop; a task stuck twice in the same place is.

Below that threshold, keep looping and re-dispatch — but **change the approach**
rather than repeating it. A re-dispatch that restates the same task the same
way produces the same failure.

Two other stops in the workflow pass the same test and are deliberate, so do
not treat them as violations of this one: `worktree-discipline` step 4 — a red
baseline needs an explicit decision before you build on it — and
`verify-before-merge` check 5 — accepting a documented coverage gap. Both are
the user's call, not yours. Outside those, keep looping.

### Read code only when a decision requires it

State the cost honestly: delegation raises total tokens and wall-clock, and it
costs you your view of drift across tasks — each subagent sees one task, and
nobody but you sees the whole change.

You pay that to keep the context that contains the plan and the trace. So read
the code when a decision genuinely requires it — a dispatch report states
something surprising, two tasks look like they are diverging, a finding needs
adjudicating. The rule is "read for a decision", not "never look".

## Class awareness

`safety_class` from `.guardrails/config.yaml`:
- **B and C — robustness rule:** every REQ/LLR gets BOTH normal-case tests
  and abnormal-input tests (bad input, boundary values, resource
  exhaustion, dependency failure). A requirement with only happy-path
  tests is not verified; the independent review at merge checks for this.
- **C:** unit-level verification is required per software item — every SDD
  item touched needs tests at its own interface (its LLRs), not only
  end-to-end.

## Bugs

A bug is a missing test. Reproduce it as a failing test first (annotated
with the REQ it violates), then fix. If the bug reveals a hazard the RMF
missed, run `analyze-risks` before closing.

## The deslop pass

When the last task branch has merged and the suite is green, dispatch **one**
subagent over the whole change diff before handing off:

```
Review main...<change-branch> under the writing and naming rules in AGENTS.md.
Work in the change worktree at <path>, on <change-branch>. Do NOT create a task
worktree — this pass fixes on the change branch directly.
Report and fix, on <change-branch>: slop, unclear names, duplication between
tasks, and anything that can be simpler. Do not change behavior — the suite
must stay green. Return the report shape below.
```

**This is the one dispatch that does not get its own task worktree**, and the
prompt has to state that. Every other dispatch in these skills names a nested
task worktree, so a subagent given no location follows that pattern and creates
one — and then its fixes are on a task branch the dispatcher has to merge, for
a pass whose whole purpose is to edit the change branch in place. State the
change worktree path and the prohibition together.

It returns:

```
files changed: <paths>
fixed: <one line per fix>
left alone: <anything it judged not worth changing, with the reason>
suite: <N passed, N failed>
```

This is the only agent that sees the whole change. The dispatcher keeps the
plan and the trace and never reads the code; each task subagent sees one task.
So **cross-task** duplication — two tasks adding the same helper, one concept
with a different name in each — is invisible to every other party, and this
pass is the only place it can be caught.

It runs here rather than at `merge-change` 6a for three reasons. The merge
sequence **reruns from step 1** on any finding, so a variable name reported
there costs a full restart. By 6a every task branch is merged and the change is
staged for the squash, so a fix there costs more than the same fix costs here.
And 6a is an independence review — mixing craft into it produces one verdict for
correctness and style together, and the style half weakens the correctness half.

## Done when

Plan tasks complete, suite green, the deslop pass run and its findings fixed —
then `check-traceability` and `verify-before-merge`. Never claim done without
them.
