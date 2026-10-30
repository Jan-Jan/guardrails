# Problem report — the gate's proof moves into the squash commit

Recorded by change `gate-proof-in-trailers`. `affects:` names files.

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
