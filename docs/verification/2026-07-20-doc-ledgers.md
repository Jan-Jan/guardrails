# Verification Record — doc-ledgers

**Change:** Per-change document ledgers (design:
`docs/plans/2026-07-20-doc-ledgers-design.md`, plan:
`docs/plans/2026-07-20-doc-ledgers-implementation.md`)
**Branch:** worktree-doc-ledgers → main (signed squash merge)
**Date:** 2026-07-20

## Test results

- `tests/run-tests.sh`: **60/60 bats tests pass, 0 failures** (58 before
  review fixes; +2: same-run rename-collision regression, template-README
  false-positive regression).
- Coverage command: not configured (accepted gap; the bats suite covers every
  rule positively and negatively, including single-file back-compat and
  cross-file ledger behaviors).

## Independent review (merge-change step 6a)

Fresh reviewer agent, spec + diff + self-run tests. Verdict: **APPROVE**
(58/58 at review time), with findings addressed after the verdict anyway:

- **Fixed + regression-tested:** same-run rename collision could silently
  overwrite a file (collision loop now also checks planned targets; the
  rename step refuses to clobber and dies instead); template READMEs in
  ledger directories now have a false-positive regression test; ratchet
  step-3 bullet list structure repaired.
- **Dispositioned (accepted):** space-containing draft filenames break the
  rename bookkeeping — whitespace-splitting is the repo-wide convention and
  the failure is safe (draft file left in place, DRAFT-FILE check blocks the
  merge); detached-HEAD branch-prefix stripping skipped (unreachable via the
  documented flow); unquoted doc-path expansion (pre-existing convention,
  paths are repo-controlled).

## Reviewer's positive verification

All spec items implemented with evidence; tests confirmed to bite (reviewer
sandbox-verified collision, dry-run, back-compat, and README cases);
branch names with slashes verified end-to-end (`feature/x` →
`DRAFT-feature-x-dose.md` → `<date>-dose.md`).
