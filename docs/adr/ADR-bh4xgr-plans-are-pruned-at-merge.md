**ADR-bh4xgr**: At `merge-change` step 1, after the base merge, `prune-plans.sh` replaces each fenced code block in a plan's task sections with a one-line pointer naming its line count and the task's `**Files touched:**` value, on by default.

Date: 2026-10-08
Status: accepted

## Context

A plan written under `plan-change` carries complete code in its task steps.
That code repeats what the change merges, and it drifts from the merged code
as review rounds fix the implementation and not the plan. Measured on
2026-10-06, 6,518 of 25,148 lines in `docs/plans/` sat in code fences
(`docs/plans/2026-10-06-salvage-churn-and-parallel.md`, D11). An agent that
reads a merged plan reads that code, and may take a superseded version of it
for the merged one.

## Decision

D11 of `docs/plans/2026-10-06-salvage-churn-and-parallel.md`, as built in
`docs/plans/2026-10-08-prune-plans.md`:

- `scripts/prune-plans.sh` replaces each fenced code block inside a task
  section of a plan this change adds or modifies with one line,
  `*(Code pruned at merge: <N> lines. Files touched: <value>.)*`, where
  `<value>` is the task's `**Files touched:**` value, or
  `*(Code pruned at merge: <N> lines.)*` where the task has none. Every
  heading and every line of prose stays. Fences outside task sections stay,
  and so does a fence with a line that opens with `red -> green`: the
  attestations `merge-change` step 6b copies into the record.
- `merge-change` step 1 runs it only after a base merge that succeeded,
  diffing against the ref it merged, and commits the plans it changed,
  unsigned and only where something changed; the commit takes nothing outside
  `docs/plans`. The step 6a reviewer
  checks the pruned plan against the diff.
- `prune_plans` in `.guardrails/config.yaml` is `on` when absent; `off` opts
  out. `--all` prunes the plans already on a base branch.

**Deviation from D11.** D11 put the pruning in `finalize-docs.sh`. That script
runs at `merge-change` step 3, after the step 2 gate, and pruning changes the
tree on nearly every merge, so step 6's tree-hash comparison would dispatch a
second full suite run each time. The maintainer ruled on 2026-10-08 that
pruning is its own script, run at the end of step 1, so the step 2 gate
measures the pruned tree. `finalize-docs.sh` is unchanged. The script reads
its key without the config check the gates run, so a project with no
`.guardrails/config.yaml`, such as this repository, runs it as an adopter
does.

## Consequences

- The code a plan held before review exists only on the change branch, and is
  lost when `finish-merge.sh` deletes that branch. The maintainer accepted
  this: the merged code is in the squash commit, and each deviation's reason
  belongs in the verification record.
- The prose of a merged plan is its only account of the code, so the reviewer
  checks that prose against the diff
  (`skills/merge-change/references/review-checklist.md`).
- Pruning moves every line after the first pruned block. A plan that any
  tracked `*.md` file cites as `<plan>:<line>` or `<plan>` line `<line>` at or
  after that block is left whole, and the script names it in a `left whole`
  line; a citation before it stays true. Records are not the only citers:
  plans cite each other's lines as evidence, as
  `docs/plans/2026-09-16-scan-scope.md` cites
  `docs/plans/2026-09-04-units-implementation.md`.
- A plan's fenced code outside task sections, such as a design section's
  sample, is never pruned.
