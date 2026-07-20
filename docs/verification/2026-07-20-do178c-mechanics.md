# Verification Record — do178c-mechanics

**Change:** DO-178C mechanics (design: `docs/plans/2026-07-20-do178c-mechanics-design.md`,
plan: `docs/plans/2026-07-20-do178c-mechanics-implementation.md`)
**Branch:** worktree-do178c-mechanics → main (signed squash merge)
**Date:** 2026-07-20

## Test results

- `tests/run-tests.sh`: **47/47 bats tests pass, 0 failures** (was 29 before
  this change; +18: LLR/PR prefix handling, LLR trace rules, transitive REQ
  coverage, derived-requirements rules, PR warnings, review-finding
  regressions).
- Coverage command: not configured for this repo (shell scripts; the bats
  suite is behavior-complete per rule — every check rule has a positive and
  negative test). Accepted gap, consistent with `coverage_command` being
  optional.

## Check scripts

- `check-ids.sh` / `check-trace.sh`: not applicable as gates to this repo
  (guardrails itself has no `.guardrails/config.yaml`; it is the tool, not a
  ratcheted project). Script behavior verified by the bats suite above.
- `check-signing.sh`: run on main HEAD after the squash merge (see merge
  commit).

## Independent review (merge-change step 6a)

Fresh reviewer agent, given only the spec, the diff vs main, and the test
suite. Verdict: REQUEST-CHANGES → all findings addressed:

- Fixed (with regression tests): LLR/PR/derived-REQ block termination at
  headings and other definitions; UNANALYZED-DERIVED substring false-match;
  open-draft-PR status leaking into a resolved PR; problems log added to
  DANGLING-REF scope; AGENTS-block now names the new config keys; added
  LLR duplicate-definition and PR draft check-ids tests.
- Dispositioned (accepted, no change): `coverage_command` ships commented
  out (spec treats the gate as "if configured"); block-terminator prefix
  lists are hardcoded rather than config-derived (consistent with existing
  script style; custom-prefix support is out of scope for v1).
- Reviewer's own test run: 41/41 at review time (pre-fix baseline).

## Verification-of-verification note

Reviewer confirmed the transitive-coverage tests genuinely bite (the good
fixture routes all REQ coverage through a tested LLR, so breaking
transitivity fails the suite) and UNANALYZED-DERIVED tests were
mutation-checked (rule neutered → exactly those tests fail).
