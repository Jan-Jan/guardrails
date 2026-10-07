**ADR-y8jmes**: Agents in this repository never fetch, never push, and never read `origin/<branch>` as the base; local `main` is the base branch.

Date: 2026-10-04
Status: accepted

## Context

`merge-change` step 1 fetches `origin` and merges `origin/<base>` into the
change branch, so that the `DUPLICATE-ID` scan at step 4 reads every ID merged
anywhere. In this repository an agent fetch or push needs a hardware key that
only the maintainer can touch, and the agent blocks on it.

`AGENTS.md`'s non-negotiable on the base branch stated this argument in full
until D10 of `docs/plans/2026-09-28-agent-first-skills.md` moved it here.
`AGENTS.md` keeps the rule and points to this file.

## Decision

Agents in this repository never fetch, never push, and never read
`origin/<branch>` as the base. Local `main` is the base branch: a change
branches from it, `merge-change` step 1 merges it in, and the signed squash is
merged onto it. Pushing is the maintainer's, done when they choose.

This overrides `merge-change` step 1's fetch. The verification record states
"base merged from local `main` at `<commit>`, per AGENTS.md non-negotiable 4",
so a later reader knows the remote was out of scope by policy.

## Cost

Skipping the fetch makes step 4 prove less. The `DUPLICATE-ID` scan sees
exactly the IDs in the merged tree, so a base merged from a local ref while
`origin` is ahead gives it a smaller set to check.

## Why the cost is accepted here

IDs are random, so a collision between branches is improbable. The header
of `scripts/new-id.sh` states the scheme: an ID is minted once, when the item
is written, and no ID is allocated against a base branch. Collisions are
detected, not prevented. `new-id.sh` discards a candidate that is already
present anywhere in the tree and draws another; a collision with an ID that
exists only on another branch cannot be seen from the worktree, and
`DUPLICATE-ID` reports it after the base merge. At a thousand items the
probability of one is under 0.1%. An ID is six characters from the 31-symbol
alphabet that `GR_ID_ANY` in `scripts/lib.sh` defines: 23 letters with the
confusable ones dropped, plus 8 digits. The header of `scripts/check-ids.sh`
overstates the scheme, as PR-2jr4pj records.

The residual risk is that such a collision is not seen until the other branch
is merged locally, where the same scan reports it. Agents do not push, so nothing
an agent does reaches a shared history unreviewed.

## Scope

This reasoning applies to a single-maintainer repository with random IDs, where
local `main` contains every ID that was merged. It does not generalise. A
project with sequential IDs, or with several people merging to a shared remote,
keeps step 1's fetch, and that is why `merge-change` still mandates it.
