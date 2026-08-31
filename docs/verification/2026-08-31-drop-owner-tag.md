# Verification — drop-owner-tag (2026-08-31)

branch: worktree-drop-problem-owner
reviewer: one independent subagent review, dispatched fresh with the diff, the plan and repository access, no implementation narrative and no chat history; it ran the suite itself in its own review worktree
verdict: accept with findings — one minor finding (a stale DRAFT filename in the plan), fixed before merge; four mutation spot-checks all killed; grammar removal confirmed complete with opened:/status:/aging untouched
reproduced: yes. The old check-trace.sh was run against fixtures with no owner: line and observed printing `INCOMPLETE-PROBLEM PR-001 (open, no owner:)` and `owner unrecorded` in the roll-call, exit 1 — the required-field failure PR-dudg35 names — before the implementation existed; each red observation is quoted in the table below.

Change: the `owner:` field is removed from the problem-item grammar — an open
PR needs `opened:` and `status:` only, `UNRESOLVED-PR` carries age alone, and
a leftover `owner:` line anywhere in a problems ledger is inert prose
(PR-dudg35, `docs/problems/2026-08-31-drop-owner-tag.md`). Branched from
`main` at `55b5784`; the base then moved to `b7fbd7f` mid-change and was
merged in per step 1. **The base was merged from a local ref**: `git fetch
origin` fails on this machine (`Bad owner or permissions on
/etc/ssh/ssh_config.d/20-systemd-ssh-proxy.conf`, the same condition the
previous change's record documents, where the user confirmed the remote is
not a concern). The base merged was **`b7fbd7f`**.
Plan: `docs/plans/2026-08-30-drop-problem-owner.md`.

## The gate

Every figure derived from the tree under test, not carried forward. This
repository has no `.guardrails/config.yaml` (the machinery is not installed
on the guardrails tree itself), so its verify command is the bats suite, and
every config-gated script refuses with an environment error rather than
passing vacuously.

| Gate | Result |
| --- | --- |
| `tests/run-tests.sh` (final gate at `e070253`) | 435 ok, 0 not ok, 0 skips, TAP plan `1..435`; verdict from TAP counts, not exit code |
| same suite, run independently by the reviewer in its own worktree | 435 ok, 0 not ok, 0 skips |
| `check-ids.sh --allow-draft-files` | refused, exit 2: `config not found: .guardrails/config.yaml` (expected on this tree) |
| `check-trace.sh` | refused, exit 2: same environment error (expected on this tree) |
| `check-review.sh` | refused, exit 2: same environment error (expected on this tree) |
| Coverage, against the class target | no `coverage_command` configured on this tree |
| Working tree | clean (`git status --short` empty) at every gate run |

The suite was run with `SSH_AUTH_SOCK=` empty throughout: this machine's
ssh-agent wedges and hangs `ssh-keygen -Y sign` in check-signing.bats (same
bypass the previous change's record documents). Nothing skipped; all 435 ran.

## Red → green

One row per behavior this change implements, copied from the `red -> green:`
lines of the task dispatch reports (also parked in the plan as the reports
landed). All tests verify `PR-dudg35`.

| Item | Test | Watched red |
| --- | --- | --- |
| `PR-dudg35` | `check-trace: an open item needs no owner:` | old script printed `INCOMPLETE-PROBLEM PR-001 (open, no owner:)` and `owner unrecorded`, exit 1 |
| `PR-dudg35` | `check-trace: a leftover owner: line inside an item is inert` | old script printed `(open 2 days, owner jvdv)` and `INCOMPLETE-PROBLEM PR-p9r5wx (open, no owner:)` for the empty owner: |
| `PR-dudg35` | `check-trace: an owner: outside any item is inert, not an orphan` | old script printed `ORPHAN-ANNOTATION docs/problems/0001-01-01-base.md:1 (owner: belongs to no item)`, exit 1 |
| `PR-dudg35` | nine assertion-updated tests (complete-open-item age line, opened-today, CRLF, trailing whitespace, February span, first-opened-wins, century span, BOM, clock-skew) | each watched fail on the old owner-bearing output (`owner unrecorded` / INCOMPLETE-PROBLEM) before the script change |
| `PR-dudg35` | `problem grammar prose: no shipped file still carries owner:` (skills.bats) | watched fail: grep found `owner:` in all seven shipped prose files, so the zero-hits assertion failed |

Four further `verifies: PR-dudg35` tests pin behavior deliberately retained
across the change (`a resolved item needs no opened:`, `an opened: in another
ledger is out of scope`, the indented-`opened:` pair) — a red is impossible
for them by design, stated here rather than implied. The reviewer's mutation
sweep is the independent check on the same property: re-adding the owner
requirement, the owner output clause, the owner orphan scan, or an `owner:`
line in the shipped template each reddened the named tests.

## What was wrong, and what was built

The problem-item grammar required an `owner:` field on every open PR, and
`check-trace.sh` enforced it (`INCOMPLETE-PROBLEM … (open, no owner:)`) and
printed it on every `UNRESOLVED-PR` line. The information is redundant —
`git blame` on the ledger line already answers who wrote an item — and the
premise is wrong: problems are not personally owned, anyone may resolve
them. The field added a failure mode without adding triage value.

Built: `check-trace.sh` no longer reads, requires, or reports `owner:` (the
`who` computation, the owner INCOMPLETE-PROBLEM branch, the `own`/`own_seen`
state, the keyword scan and `check_orphans 'owner:'` are removed);
`UNRESOLVED-PR` output is `(open N days)` / `(open, age unrecorded)`.
Age-based triage — `opened:`, `problem_age_days`, `problem_open_max` — is
untouched. A leftover `owner:` line in an existing ledger is inert prose,
inside an item or outside every item, so already-written ledgers keep
passing unedited. All shipped prose (templates, ledger READMEs, the
resolve-problem / check-traceability / ratchet skills, README) documents the
two-field grammar, and a new skills.bats test fails if any of those files
carries `owner:` again. This repo's own ledgers dropped their seven inert
`owner:` lines.

## Review

**finding-1**: Stale file reference in the finalized plan: `docs/plans/2026-08-30-drop-problem-owner.md` line 3 still says "Fixes **PR-dudg35** (docs/problems/DRAFT-worktree-drop-problem-owner-drop-owner-tag.md)" — that file was renamed to `docs/problems/2026-08-31-drop-owner-tag.md` by the finalize commit (abeee70), so the plan now points at a path that no longer exists. Inert to every gate (it is a filename string, not an ID token), minor doc accuracy only.
disposition: fixed in `e070253` — the plan now cites the finalized path and notes the DRAFT origin. No test reddens on a plan prose path; the final gate (435/435, clean tree) covers the corrected file.

## Gaps

- The config-gated gates (`check-ids.sh`, `check-trace.sh`,
  `check-review.sh`) did not run on this tree — it has no
  `.guardrails/config.yaml` to run against, so this change's ledger edits
  were checked by the suite's own fixtures and the independent review, not
  by the shipped gates. Unchanged from every prior change on this repo.
- The base was merged from the local ref `b7fbd7f`, not from `origin` — the
  duplicate/ID scans saw only what this clone holds.
- Target projects whose open PR items carry `owner:` keep passing (the field
  is inert), but nothing migrates or strips those lines for them; the field
  simply stops being read.
