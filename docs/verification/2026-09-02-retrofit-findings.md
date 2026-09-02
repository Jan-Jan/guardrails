# Verification — retrofit-findings (2026-09-02)

One record per change, written at `merge-change` step 6b and checked at step
6c by `check-review.sh`. The squash commit references it on its `Verified:`
line, so this file is the evidence that travels with the change.

branch: retrofit-findings
reviewer: independent agent — fresh subagent dispatched 2026-09-02 with the diff, the plan and the ledger file, and no author narrative; it re-ran the suite in its own task worktree and rebuilt the red states against pre-change code itself
verdict: PASS — no findings raised; all seven fixes match their problem items, every red-first test was re-observed red against pre-change code by the reviewer's own runs, ledger grammar clean, suite 474/474 at exit 0 in the reviewer's independent run
reproduced: yes, all seven — six as failing tests watched red in this change before their fixes (the exact red statuses are quoted in the plan's red -> green lines and in the table below), and the seventh (PR-xyu6en) as eleven suite failures on macOS at the step-1 base merge, all one parse-error cause, plus `sh -n` exit 2 on main's finish-merge.sh re-measured independently by the reviewer

Change: resolves seven problem reports from a macOS hardware-key `/ratchet`
retrofit — two check-signing.sh defects, four prose/schema gaps, and a bash
3.2 parse failure in finish-merge.sh found at the base merge. Branched from
`main`; base merged in at `d5aca68` (step 1 re-run 2026-09-02: `git fetch
origin` succeeded and `origin/main` was already merged — the duplicate scan
saw everything the base defines).
Plan: `docs/plans/2026-09-01-retrofit-findings.md`.

## The gate

Every figure derived from the tree under test, not carried forward.

| Gate | Result |
| --- | --- |
| `./tests/run-tests.sh` (this repo's verify command) | 474/474 ok, 0 not ok, suite exit 0 — step-6 gate dispatch after ledger finalization; identical counts in the step-2 gate and in the reviewer's own run |
| `check-ids.sh` | not runnable on this tree: the guardrails repo carries no `.guardrails/config.yaml` (see the note atop `docs/problems/2026-08-27-macos-awk.md`); all seven IDs were minted by `new-id.sh`, which scanned the tree for collisions at mint time |
| `check-trace.sh` | not runnable on this tree, same reason |
| Coverage, against the class target | not configured (no `coverage_command`; the repo has no configured safety class) |
| Working tree | clean — `git status --porcelain` empty in the step-6 gate dispatch |

`finalize-docs.sh` is likewise not runnable here (its config names ledger
directories this repo does not have); the draft ledger file was renamed
directly, `git mv DRAFT-retrofit-findings-hardware-key-retrofit.md
2026-09-02-hardware-key-retrofit.md`, the same rename it performs.

## Red → green

One row per problem item this change resolves. The reds for the first six
were watched in this change's own TDD loop before each fix existed; the
reviewer independently rebuilt each red against pre-change code (main's
scripts with this branch's tests) and confirmed every one.

| Item | Test | Watched red |
| --- | --- | --- |
| `PR-mvqm4s` | `check-signing.bats: --strict exits 2 when the trust root exists but cannot be read` | red: exit 1 UNVERIFIED before the guard; also its two `--setup` twins (red at exit 1 UNREADABLE and exit 1 UNPROVED); `--strict stays exit 1 when the trust root path is absent` is a deliberate inverse pin, green from the start, constraining the fix from overreaching |
| `PR-2qdy9c` | `check-signing.bats: --setup ignores a worktree-scoped commit.gpgsign false` | red: exit 1, false `MISSING commit.gpgsign`; `--setup still reports a real commit.gpgsign gap from a worktree` is the deliberate inverse pin |
| `PR-uavq3f` | `skills.bats: ratchet: updating the scripts also refreshes the ledger READMEs` | red: grep found no refresh step in the upgrade guidance |
| `PR-dcn2xc` | `lib.bats: gr_check_config accepts a guardrails_commit key` | red: exit 2, unknown config key; `skills.bats: ratchet: the qualification basis names a commit, not just a version` red the same way |
| `PR-geb5db` | `skills.bats: verification template warns that a range in a finding header opens no block` | red: the template carried no such sentence |
| `PR-nzpp57` | `skills.bats: ratchet: tool qualification warns that a pipe eats the suite's exit status` | red: the clause did not exist |
| `PR-xyu6en` | `check-ids.bats: every script parses as POSIX sh` (pre-existing) | red on macOS at the step-1 base merge — 11 failures, all one cause: bash 3.2 cannot parse main's guard-4 `case` inside `$()` without leading parens; green after, and `sh -n` on the branch's finish-merge.sh exits 0 |

## What was wrong, and what was built

Measured on a stock Mac with GPG hardware signing: `check-signing.sh
--strict` convicted the project (exit 1, UNVERIFIED) when only the
environment was broken — a trust root the process lacked permission to read
reads exactly like an untrusted signature; and `--setup` reported a false
`MISSING commit.gpgsign` from inside every worktree, because
worktree-discipline deliberately leaves worktree commits unsigned. Built: a
lazy `trust_root_env_guard` that exits 2 naming `--setup` for the
permission-denied shape (ssh signers file and openpgp keyring alike, absent
paths still exit 1), and a worktree-scope filter on the `commit.gpgsign`
read. Four prose/schema gaps from the same retrofit: the script-update path
now refreshes the grammar's prose carriers; `guardrails_commit` is an
accepted config key so the qualification basis is checkable; the
verification template teaches that a range header opens no block; the
qualification clause warns that a pipe eats the suite's exit status. The
base merge then surfaced PR-xyu6en — main's new nested-worktree guard in
finish-merge.sh did not parse under macOS `/bin/sh` (bash 3.2), exit 2 on
every invocation there — fixed with the leading `(` bash 3.2 demands on case
patterns inside `$()`.

## Review

The review raised no findings — `verdict:` above says so. Two non-finding
observations from the reviewer, left as they are by design: the ledger
file's header sentence says "six problems reported" over a seven-item file
(the seventh item states its own base-merge provenance), and the plan
references the pre-finalization `DRAFT-` ledger path (a historical record;
the rename does not rewrite prose).

## Gaps

What this change did not establish: no mechanical staleness gate runs in a
target project between script updates (PR-uavq3f's resolution names this —
the fix closes the update-path drift only); the openpgp keyring guard tests
`-r`/`-x` permission bits, so an environment that denies gpg's *write* open
of the trustdb while leaving the directory readable (macOS TCC does this to
some process trees) still reads as UNVERIFIED, not exit 2; and the
trace/ID/coverage gates could not run on this tree at all, for the standing
reason above.
