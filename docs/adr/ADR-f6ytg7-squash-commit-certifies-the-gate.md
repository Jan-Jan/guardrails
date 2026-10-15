**ADR-f6ytg7**: The signed squash commit certifies its own gate: its `Gate-tree:`, `Gate:` and `Base:` trailers name the tree the `merge-change` step 6a gate measured, the gate's totals and the base merged, `finish-merge.sh` refuses the cleanup unless `Gate-tree:` is the commit's own tree, and the verification record names no commit or tree the gate measured, no base commit and no gate figure.

Date: 2026-10-14
Status: accepted

## Context

Until this decision the verification record (`templates/verification.md`)
named the commit the change branched from, the commit and tree the gate
measured, the gate's totals and, in this repository, the base commit merged at
`merge-change` step 1. The record is committed in the change it certifies, so
it named a commit and a tree it was itself part of (PR-k4y59t).

- Every base update, and every rebase after a shared remote moves, made those
  lines stale.
- The record was then rewritten and committed again, which changed the tree
  it named: a loop, and a late commit on the review evidence.

The maintainer ruled on 2026-10-14 that the record must stop certifying a
commit it is part of, and that local signed squash merges stay: the
maintainer signs locally before pushing to open a pull request.

## Decision

D1–D6 of `docs/plans/2026-10-14-gate-proof-in-trailers.md`:

- `merge-change` step 7's message ends in one trailer paragraph, with every
  trailer, `Co-Authored-By:` included, in it and no blank line inside it,
  because git reads trailers nowhere else:
  - `Base: <base ref> at <its commit>`, the ref step 1 merged and its commit
    at that merge;
  - `Gate-tree: <tree>`, the hash step 6a recorded on a clean worktree and
    step 6b confirmed. It is never computed with `git write-tree` at step 7: a
    tree computed there describes what is staged, which is the thing the
    check questions;
  - `Gate: <command> <passed>/<total>`, one per `verify_commands` entry, one
    for `coverage_command` where it is configured, and one per unit and
    command in a multi-unit repository. None for the pre-flight, the ID and
    trace checks or the working-tree check: the sequence halts when any of
    them fails, so a squash exists only after they passed; the pre-flight's
    tree checks, `check-ids.sh` and `check-trace.sh`, can be rerun on the tree
    `Gate-tree:` names.
- Step 7 compares `git write-tree` with the step 6a tree after the message is
  written and before the hand-over. A mismatch means the branch changed after
  the gate: reset the merge and rerun from step 1. It costs no key touch.
- `finish-merge.sh` guard 5 refuses the cleanup, removing nothing, unless
  HEAD's message has exactly one `Gate-tree:` trailer with a value, and that
  value is HEAD's own tree. It reads the trailer with git's own parser,
  `%(trailers:key=Gate-tree,valueonly,unfold)`, which needs git 2.22 or
  later; an older git prints the placeholder unexpanded, which equals no
  tree, so the guard fails closed.
- The verification record names no commit or tree the gate measured, no base
  commit and no gate figure; a disposition may still cite a fix commit.
  It keeps what the commit cannot prove: the change and plan, the IDs
  resolved, accepted or opened, red → green, the reviews, and the Gaps.
- The base statement this repository wrote in the record is the `Base:`
  trailer: `Base: local main at <commit>, per AGENTS.md non-negotiable 4`.
  This amends the Decision sentence of ADR-y8jmes, in place.

Ruled by the maintainer on 2026-10-14. (Amended 2026-10-14: step
labels in this file are those of D5 of
`docs/plans/2026-10-14-base-move-round.md`, which renumbered the sequence.
Its D4 moved the gate after the record, which changed the second
consequence below.)

## Consequences

- The record is a fixed point of the sequence: with nothing in it measured
  from the tree, a gate rerun does not change it, so the tree the gate
  measured is the tree squashed.
- The record is written at step 5, before the step 6a gate, in every round,
  so it never costs a gate run of its own. As this decision was first ruled,
  the gate preceded the record, and a record first written after the last
  gate cost one more gate run, which step 7's comparison caught; D4 of
  `docs/plans/2026-10-14-base-move-round.md` removed that cost.
- An adopter's `finish-merge.sh` refuses a squash written by an older copy of
  the `merge-change` skill until the installed skills are refreshed with the
  scripts.
- A `Gate:` total is copied from the gate summary, not checked: checking it
  means running the gate again. What is checked is the tree it describes.
- A forge that rebases or squash-merges a pull request after the push
  replaces the signed squash with a commit whose tree its `Gate-tree:` may
  not name, and nothing in guardrails re-checks `Gate-tree:` after that:
  guard 5 runs once, at signing. How pull requests land on the shared base is
  not decided; PR-m7gcuq records it as open.
- Merged records keep their gate sections; nothing rewrites them.

## Alternatives considered

- **Keep the figures in the record and accept the rewrite loop.** That is the
  defect PR-k4y59t records.
- **Commit the record after the squash, as a second commit.** It breaks one
  signed commit per change (AGENTS.md non-negotiable 2).
- **`git notes` on the squash.** Notes are not pushed or fetched by default,
  and the signature does not cover them.
- **Compute `Gate-tree:` at step 7 with `git write-tree`.** Guard 5 would then
  compare a value with itself, and prove nothing about the gate.
- **Merge on the forge and drop local signing.** Ruled out by the maintainer.
- **Check the `Gate:` totals mechanically.** That is running the gate again.
