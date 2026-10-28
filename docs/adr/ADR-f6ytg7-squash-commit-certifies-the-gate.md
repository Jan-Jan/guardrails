**ADR-f6ytg7**: The signed squash commit certifies its own gate: `finish-merge.sh` removes nothing unless its message passes the ADR-3hsvvq check with `Gate-tree:` naming the commit's own tree.

Date: 2026-10-14
Status: accepted

## Context

A record committed in the change it certifies cannot name the commit or tree
it is part of (PR-k4y59t): every base update made those lines stale, and
rewriting them changed the tree they named. The squash message is outside
the tree, so it can name the tree the gate measured. The maintainer signs
locally before pushing to open a pull request.

## Decision

- The squash message is the change's record (ADR-k3nkv3). Its last
  paragraph holds every trailer, with no blank line inside it, because git
  reads trailers nowhere else. `merge-change` step 6b writes `Base:`,
  `Gate-tree:`, `Tests:` and `Coverage:` on a confirmed tree, in the counts
  ADR-3hsvvq states:
  - `Base: <base ref> at <its commit>`, the commit step 1 merged;
  - `Gate-tree: <tree>`, the hash step 6a recorded on a clean worktree and
    step 6b confirmed;
  - `Tests: <command> <passed>/<total>`, the gate's totals for a
    `verify_commands` entry;
  - `Coverage: <command> <figure>`, the figure a `coverage_command`
    measured.
- Step 7 compares `git write-tree` with `Gate-tree:` before the hand-over. A
  mismatch means the branch changed after the gate: reset the merge and rerun
  from step 1.
- `finish-merge.sh` guard 5 refuses the cleanup, removing nothing, unless the
  signed message passes the ADR-3hsvvq check with `Gate-tree:` naming HEAD's
  tree.
- This repository's base statement is the `Base:` trailer:
  `Base: local main at <commit>, per AGENTS.md non-negotiable 4`
  (ADR-y8jmes).

## Consequences

- No trailer certifies the pre-flight, the ID and trace checks or the
  working-tree check: the sequence halts when any fails; the pre-flight's
  tree checks, `check-ids.sh` and `check-trace.sh`, can be rerun on the tree
  `Gate-tree:` names.
- Nothing in the tree is measured from the tree, so a gate rerun changes no
  committed file, and the tree the gate measured is the tree squashed.
- An adopter's `finish-merge.sh` refuses a squash written by an older copy of
  the `merge-change` skill until the installed skills are refreshed with the
  scripts.
- A `Tests:` total is copied from the gate summary, not checked: checking it
  means running the gate again. What is checked is the tree it describes.
- A forge that rebases or squash-merges a pull request after the push
  replaces the signed squash with a commit whose tree its `Gate-tree:` may
  not name, and nothing in guardrails re-checks `Gate-tree:` after that:
  guard 5 runs once, at signing. PR-m7gcuq records how pull requests land as
  open.
