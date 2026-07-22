# Verification Record — base-branch-detection

**Change:** Detect the base branch instead of hardcoding `main`. New
`gr_base_branch()` in `scripts/lib.sh` resolves the branch checked out in
the primary (non-worktree) checkout; `finalize-ids.sh` and `check-ids.sh`
default to it (`--base REF` still overrides). Skills, templates, and README
now speak of "the base branch" rather than `main`.
**Branch:** worktree-base-branch-detection → main (signed squash merge)
**Date:** 2026-07-22

## Test results

- `tests/run-tests.sh`: **65/65 bats tests pass, 0 failures**, after merging
  latest main into the worktree (60 before this change; +5: three
  `gr_base_branch` cases in lib.bats, default-base detection in
  finalize-ids.bats and check-ids.bats, all written failing-first).
- Coverage command: not configured (accepted gap, as in prior records).

## Independent review (merge-change step 6a)

Fresh reviewer agent, given only the spec, the diff vs main, and the test
command. Verdict: **APPROVE**, no must-fix findings.

- Reviewer confirmed no hardcoded `main` remains except deliberate prose
  ("never assume `main`") and an example range comment in
  `check-signing.sh`; `AGENTS.md` (not shipped, governs this repo, which
  does use main) intentionally unchanged.
- Reviewer verified `gr_base_branch` beyond the bats suite: slash branch
  names (`release/2026.1`) survive; detached and bare primaries yield empty
  (never a linked worktree's branch); the merge-change skill's
  `BASE=$(. .guardrails/scripts/lib.sh && gr_base_branch)` snippet works in
  POSIX sh.
- Reviewer confirmed the new tests bite for all three regression modes
  (hardcoded-main default, no-default-check, detection picking the linked
  worktree's branch) — fixtures rename `main` to `trunk` so a hardcoded
  default cannot pass.
- **Dispositioned (accepted):** check-ids now runs the vs-base duplicate
  check by default — a no-op on the primary checkout and skipped when no
  base is detectable (detached/CI), so existing invocations are safe; the
  finalize-ids "primary checkout detached?" error message doesn't mention
  the bare-primary case (remedy `--base REF` is stated either way); CI
  should pass an explicit `--base` to get the vs-base check (unchanged from
  before); a slash-branch bats test would be a nice-to-have.
- Environment note: 4 `check-signing.bats` tests hang **in the reviewer's
  sandbox** because `ssh-keygen -Y sign` itself hangs there standalone —
  host environment defect, unrelated to this diff (which does not touch
  signing); the full suite including those tests passes 65/65 in the
  primary session environment.
