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

This overrides `merge-change` step 1's fetch. The squash commit's `Base:`
trailer states `Base: local main at <commit>, per AGENTS.md non-negotiable 4`,
so a later reader knows the remote was out of scope by policy. The
verification record stated it until ADR-f6ytg7 (2026-10-14) moved the base
commit it named into the `Base:` trailer.

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

**One maintainer is not one machine, and the condition is about the machine.**
Where the maintainer merges on more than one of them, local `main` holds every
ID merged *here* and none of the IDs merged elsewhere, so the condition above
holds only once local `main` has been reconciled with the remote. Reconciling
is the maintainer's call, for the same reason pushing is: an agent fetch blocks
on a hardware key only the maintainer can touch. Agents still never fetch and
never push, and still never take `origin/<branch>` as the base. An agent
carries out a reconciliation only where the maintainer directs that explicitly,
as the subject of a change whose verification record names whose decision it
was and which commit was merged; AGENTS.md non-negotiable 4 states the same
permission where an agent reads the rule. An
unreconciled `main` does not make a change unsafe — it makes step 4's
`DUPLICATE-ID` scan prove less than the Cost section above already allows,
against the IDs merged on the other machine rather than against none.
PR-z83ka9 recorded the condition lapsing in this repository.

**Reconciling here means the IDs, not the ancestry.** A change integrates as a
signed squash (non-negotiable 2), so commits merged on another machine never
become ancestors of local `main`: `main` ends up holding their content, which
is what step 4's scan reads, while `git merge-base main origin/<branch>` still
names the commit the two machines last shared. That fixes the scan and leaves
the remote relationship diverged, so the maintainer's next push is a deliberate
decision rather than a fast-forward. Nothing here makes that decision, and no
agent may make it.
