# Problem report — the gate's proof moves into the squash commit

Recorded by change `gate-proof-in-trailers`
(`docs/plans/2026-10-14-gate-proof-in-trailers.md`). `affects:` names files,
because guardrails keeps no REQ/SDD/LLR ledger of its own.

**PR-nyw3ww**: With `log.showSignature` set to true, `check-signing.sh --strict` reports a good signature as `UNVERIFIED` and exits 1, because `git log --format=%G?` then prints the verifier's output above the verdict letter.
affects: scripts/check-signing.sh.
opened: 2026-10-14
status: resolved
Resolved: the verdict is read with `git log --no-show-signature`, so the setting no longer reaches the letter. Reproduced by "check-signing: a good signature passes --strict with log.showSignature set" in `tests/check-signing.bats`; mutation `M01` of `docs/verification/2026-10-14-gate-proof-in-trailers.mutations/` removes the flag and reddens it.

Measured in a scratch repository signed with ssh: with the setting true,
`UNVERIFIED <sha> (signature present but did not verify)` followed by the
verifier's own "Good" line; with it false, exit 0. `finish-merge.sh` guard 1
runs the same check, so a user with the setting cannot finish a merge.

**PR-k4y59t**: The verification record names the commit, tree, base commit and gate totals of the change it is committed in, so every base update or rebase makes them stale and the rewrite changes the tree they name: the record certifies a tree it is part of, and the signed squash then holds a tree no gate measured.
affects: templates/verification.md, skills/merge-change/SKILL.md, scripts/finish-merge.sh, AGENTS.md.
opened: 2026-10-14
status: resolved
Resolved: the squash commit carries the gate's tree, totals and base as `Gate-tree:`, `Gate:` and `Base:` trailers (ADR-f6ytg7), `finish-merge.sh` guard 5 refuses a squash whose `Gate-tree:` is not its own tree, and the record names no commit or tree the gate measured, no base commit and no gate figure, so a rerun no longer rewrites it. Reproduced by "finish-merge: a record committed after the gate leaves a squash its Gate-tree does not name" in `tests/finish-merge.bats`; the template is pinned by "verification template: the gate's figures and their tree are in the squash commit, not the record" in `tests/skills.bats`.

**PR-yd4pug**: `merge-change` step 1 merges `origin/$BASE` into the change branch where a remote exists, but step 7 squashes onto the local base branch, so in a fetched flow the squash's parent can lag the base the gate merged.
affects: skills/merge-change/SKILL.md.
opened: 2026-10-14
status: open
Found by independent review round 1 of change `gate-proof-in-trailers`; it predates that change. Step 1's fence sets `base_ref="origin/$BASE"` after `git fetch origin` and merges it; step 7 runs `git merge --squash <branch>` in the primary checkout with the local base branch checked out, which nothing fast-forwards to `origin/$BASE`. The squash's tree is still the branch's, but its parent is the older local commit, so the signed commit does not descend from the base its `Base:` trailer names, and a later push or rebase onto the remote changes the tree its `Gate-tree:` names. This repository never fetches (AGENTS.md non-negotiable 4), so it does not reach here.

**PR-m7gcuq**: A squash that a forge rebases or squash-merges after the push no longer carries a `Gate-tree:` naming its own tree, and nothing re-checks it; how pull requests land on the shared base (fast-forward, squash, rebase or merge commit) is undecided.
affects: skills/merge-change/SKILL.md, scripts/finish-merge.sh, skills/ratchet/references/setup-checklist.md.
opened: 2026-10-14
status: open
Found by independent review round 3 of change `gate-proof-in-trailers`. `finish-merge.sh` guard 5 compares `Gate-tree:` with the tree once, at signing, in the local checkout. A forge that rebases or squash-merges the pull request makes a new commit on a newer base, with another tree and the same trailers, or none. The user ruled on 2026-10-14 to cut forge-flow handling from that change and decide it once they decide how pull requests land on GitHub. It is related to PR-yd4pug: both are a squash whose parent is not the base the gate merged, here made by the forge after the push, there by a fetched step 1 before it.
