# Verification — finish-merge.sh parses on bash 3.2; case patterns gated

branch: finish-merge-posix-parse
reviewer: one independent subagent, dispatched fresh with the diff, the problem report, and repository access — no implementation narrative, no chat history; it re-ran the full suite in its own task worktree (code change, so independence covers the evidence)
verdict: accept-with-findings — the fix resolves the defect (defect reproduced against main, gone on the branch); the 78-line sweep verified mechanical hunk by hunk (exactly one inserted `(` each); the new lint calibrated in both directions; four findings (one IMPORTANT, three MINOR), all dispositioned below
reproduced: yes, twice over — `sh -n scripts/finish-merge.sh` fails at main with `syntax error near unexpected token ';;'` (line 212) on macOS /bin/sh (bash 3.2), and 11 tests fail (`sh tests/run-tests.sh`: 452 ok / 11 not ok at the merge f859341). The reviewer reproduced both independently before verifying the fix.

**Change:** `finish-merge-posix-parse` — resolves **PR-vh6cud**
(docs/problems/2026-09-02-bash32-case-parse.md): every case pattern in
executable shell opens with the POSIX-optional leading `(`, because bash 3.2's
`$(...)` parser cannot carry a pattern's unbalanced `)`; a segment-scanning
lint in tests/portability.bats enforces the rule permanently, and AGENTS.md's
Rules list documents it beside the other portability rules.
**Plan:** none — resolve-problem flow; the problem report is the driving
artifact. The defect arrived on the base in remote commit `5bc6495`
(task-worktree containment), whose own verification evidently ran on a shell
whose parser accepts the parenless form.
**Base:** merged **from the local ref** three times as `main` advanced:
`f859341` (the signed sync merge) at step 1 and again after the finding
fixes; then `bd41d7a` (the hardware-key retrofit squash, merged and pushed by
the user) at integration. The fetch cannot succeed in this environment
(hardware-key signing refused non-interactively); each ref is named here per
the skill so the next reader knows what the duplicate scan was compared
against. The `bd41d7a` merge carried one conflict — `check-signing.sh`, this
change's leading parens against the retrofit's new `trust_root_env_guard`
call — resolved by taking both; `sh -n` and the case-pattern lint pass on the
resolution. `bd41d7a` also resolves the same parse defect independently as
**PR-xyu6en** (narrow: the three guard-4 patterns, with a comment kept
verbatim); the collision is recorded in this change's problem report, whose
remaining scope is the tree-wide sweep and the gate.
**Class:** the toolkit is unclassified.

## Test evidence

All suite runs dispatched per `verify-before-merge`, raw logs outside the
tree, counts read from the logs:

- Red at base `f859341` (the defect): **452 ok / 11 not ok** — "every script
  parses as POSIX sh" plus ten finish-merge tests; identical failures
  confirmed at pure `origin/main` (`5bc6495`) in a detached scratch checkout.
- Task t1 (sweep + lint), in its task worktree: **464/464, exit 0.**
- Step 2, change worktree after t1 merge (at `617916b`): **464/464, exit 0.**
- Step 6, after ledger finalization (at `77516c1`): **464/464, exit 0.**
- Independent review's own run, in its review worktree: **464/464, exit 0.**
- Task t2 (finding fixes), in its task worktree: **464/464, exit 0.**
- Final run after the finding fixes (at `b6de86c`): **464/464, exit 0.**
- Integration run after the `bd41d7a` base merge and its conflict
  resolution (at `ea508a5`): **475/475, exit 0** — the suite grew by the
  retrofit's own tests, all green beside this change's gate.

Red → green attestations, copied from the dispatch reports as they landed:

| verifies | test | attestation |
|---|---|---|
| PR-vh6cud | every case pattern in executable shell opens with a parenthesis (tests/portability.bats) | t1: watched fail for the right reason — 78 parenless patterns listed, finish-merge.sh:212 among them — before the sweep; defect also reproduced directly (`sh -n` syntax error, gone after) |
| PR-vh6cud | same test, five new red calibration controls (bad-oneline, bad-subst, bad-second, bad-comment, bad-lonein) | t2: each shape probed individually against the old awk and MISSED, watched red before the segment-scanner rework; bad-subst/good-subst confirmed against real bash 3.2 |

Check scripts were not run against this repository: not yet self-hosted (no
`.guardrails/config.yaml`, blocker in docs/plans/2026-08-22-ratchet-gap-analysis.md),
consistent with every prior change. The draft problem file was renamed to its
dated name manually for the same reason (commit `77516c1`).

## Review findings and dispositions

**finding-1**: (IMPORTANT) The lint's awk armed only on `case … in` at
end-of-line and `;;` at end-of-line, so a one-line
`case … in pat) … ;; esac` was never scanned — including the exact defect
class: `x=$(case $y in foo) echo a ;; esac)` fails bash 3.2 `sh -n` yet
passed the lint clean.
disposition: the awk is now a segment scanner — a line is split on `;;`,
pattern position opens after `case … in` on the same segment and after every
`;;`, `in` on its own line arms a pending case, and state resets per file.
Five red calibration controls (one per missed shape) were watched fail
against the old awk before the rework; the test reddens without it
(commit `2f86c90`, merged at `b6de86c`).

**finding-2**: (MINOR) Five parenless patterns survived the sweep — all
one-liners invisible to the original lint (scripts/lib.sh, two each in
tests/check-trace.bats and tests/lib.bats) — so the test's name and the
problem report's resolution claim were factually false against the tree.
disposition: the segment scanner flags all five; each is swept to the
leading-`(` form in the same commit, making the stated invariant true; the
resolution sentence now also records that the review found and closed the
one-liner blind spot (`2f86c90`).

**finding-3**: (MINOR) AGENTS.md's Rules list — the documented home of the
shell-portability rules, each citing tests/portability.bats — did not gain
the new rule, so the doc and the gate disagreed.
disposition: the leading-paren case-pattern rule is added to that list in the
sibling entries' voice, citing the test; skills.bats' AGENTS.md assertions
still pass (`2f86c90`).

**finding-4**: (MINOR) Further probe-verified blind spots: `;;` with a
trailing comment did not re-arm; a second pattern after `;;` on one line was
unscanned; `case "$x"` with `in` on its own line never armed.
disposition: all three are covered by the same segment-scanner rework, each
pinned by its own red-watched calibration control (`2f86c90`).

## Reviewer's negative findings, recorded

Explicitly clean: the sweep is mechanical (every hunk in scripts/,
tests/evidence.sh, tests/helpers.bash, tests/finish-merge.bats is exactly one
inserted `(` character — verified by a diff-pair checker); the lint test
calibrates both ways (stripping one paren in a copy made both `sh -n` and the
lint fail naming that file:line; restored, both pass; the .bats file does not
trip its own lint); the diff contains nothing beyond report + sweep + test;
the problem item's grammar is complete and the resolution merged with its fix.

## Notes for the next reader

The t2 rework surfaced two false-positive sources inside
tests/portability.bats itself — the @test name parses like `case WORD in`,
and that prose arm leaked across mid-line `;;` occurrences — resolved by
quote-parity gating on the case keyword and by arming `;;` only inside an
open case construct. Recorded here because the next person to touch the
scanner will meet both within minutes.
