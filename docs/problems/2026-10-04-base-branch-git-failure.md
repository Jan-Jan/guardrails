# Problem report — a failed `git worktree list` read as a detached checkout

Found and fixed by the git-call audit of `agent-first-scripts` after its
review round 16, in a function that predates that change; review round 17
found that no item had been opened for it. `affects:` names files, because guardrails
keeps no REQ/SDD/LLR ledger of its own.

**PR-tz6gsp**: `gr_base_branch` discards the status of `git worktree list`, so a git failure reads as a detached primary checkout, and `check-review.sh --branch` then passes at exit 0.
affects: scripts/lib.sh, `gr_base_branch`; scripts/check-review.sh, its base-branch read; scripts/finish-merge.sh, its base-branch reads in `--check` mode and on the main path.
opened: 2026-10-04
status: resolved
`gr_base_branch` piped `git worktree list --porcelain 2>/dev/null` into awk,
so a failure printed nothing and returned 0: the result for a detached primary
checkout. `check-review.sh` with `--branch` accepts an empty base and exited 0;
without it, and in `finish-merge.sh`, the run exited 2 with a reason that named
detachment instead of the git failure, and `finish-merge.sh --check` blamed
its second `git worktree list` call.
Fixed by the change `agent-first-scripts`
(`docs/plans/2026-09-29-agent-first-skills-change-2.md`, after review round
16): `gr_base_branch` returns git's status, and each caller exits 2 and names
the failure. The tests in `tests/lib.bats`, `tests/check-review.bats` and
`tests/finish-merge.bats` that verify this item were each red before the fix.
