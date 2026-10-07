# Roadmap: what the churn and parallel-session proposals still owe

**Status:** confirmed by the maintainer, 2026-10-06, in a requirements
interview. Travels on branch `test-runner` with phase 1 and merges in its
signed squash.
**Sources:** two proposal branches that never merged, discarded once this
roadmap was committed: `churn-proposal` (tip `733e6a2`, decisions D1 to D5 and
findings G1 to G3, 2026-09-17/18) and `parallel-session-proposals` (tip
`1319944`, proposals P1 to P12, 2026-09-18). Neither merged as written: their
figures were pinned to `650f090`, their branch-state claims had gone false,
and their verification record reviewed a document whose facts went stale.
What is still worth doing is restated here against `main` at `821e783`.

## Decisions

**D1 — AGENTS.md non-negotiable 4 ("Open one change at a time") is removed
outright.** It was overridden by hand at least five times between 2026-09-28
and 2026-10-06. No measured rule replaces it. The races its rationale names
are already handled: `merge-change` step 1 merges the latest base every round,
`new-id.sh` mints random tokens so two worktrees never contend, and each change
writes its own verification record.

**D2 — the shipped `merge-change` skill drops the same precondition**, with its
rationale section, and the rationale states why parallel changes are safe.
Guardrails is developed under the rules it ships, so the skill and AGENTS.md
change together.

**D3 — no overlap script.** P2's `check-overlap.sh` would predict conflicts that
step 1 surfaces and resolves anyway. It is not built.

**D4 — `worktree-discipline` gains a check to run before opening a change.**
(a) A status line per registered worktree: branch, commits ahead of `main`,
dirty-file count, last commit date. (b) For each item ID the new change will
resolve or amend, `git grep` the ID across every local branch; a hit on an
unmerged branch means another change claims the item, and the session stops
and asks the user. Evidence: on 2026-10-06 two sessions both resolved
PR-s8dcmp, and one change was discarded.

**D5 — step 7 keeps staging the squash (P1 rejected).** The staged squash in
the primary index is a first-come-first-served lock: another session sees it,
waits, and merges local `main` in after the user signs. `merge-change`'s
rationale records this, so the proposal is not made again.

**D6 — `tests/run-tests.sh <file>` runs only the named files (P4a).** Today it
appends the argument to the glob, so the named file runs twice and the whole
suite runs once. Recorded as a problem item and fixed under TDD.

**D7 — the suite runs in parallel by default, if measurement allows (P4c).** A
subagent runs the suite with and without `--jobs` on one tree and reports both
counts and times. If the counts match, `run-tests.sh` passes
`--jobs <CPU count>` whenever GNU `parallel` is on `PATH`, and
`RUN_TESTS_JOBS=1` restores a serial run. If a test fails only under `--jobs`,
it becomes a problem item and the default stays serial. (Phase 1 met the
condition after fixing the three tests that failed only under `--jobs`,
PR-2nxadp; its verification record gives the re-measured counts.)

**D8 — ratchet's setup checklist tells the user to install GNU `parallel`
(P4d)**, in `skills/ratchet/references/setup-checklist.md`. `SKILL.md` is at
its word limit.

**D9 — a verification record does not count itself, and narrates once (G1,
P12).** `templates/verification.md` states that the number of rounds, findings
and dispositions is derivable from the `### Round` headings and the
`**finding-` blocks, and must not be restated in prose; and that the prose
sections are written once, after the final round, without a round-by-round
account.

**D10 — P8 and P9 wait on D7's measurement.** If a full suite run takes under
about five minutes, PR-kc2pzm gains a note that a cheaper `record` lane no
longer pays for itself. Otherwise P8 (cheap gates for `record` findings after
convergence) and P9 (the reviewer's run scoped to the round's delta, with its
known defect: the pathspec misses README-only and skills-only reds) are added
to PR-kc2pzm as candidate formulations.

**D11 — plans are pruned at merge, on by default.** On the change branch,
before the review, `finalize-docs.sh` removes each fenced code block inside a
plan's task steps and leaves a one-line pointer to the merged path; every
heading and all prose stay, so the citations of plan steps that records make
still resolve. The reviewer checks the pruned plan against the diff. The
pre-review code then exists only on the change branch, and is lost when
`finish-merge.sh` deletes it: the maintainer accepted that, because the merged
code is in the squash commit and each deviation's reason is in the record.
Measured on 2026-10-06: 6,518 of 25,148 plan lines sit in code fences. A
`prune_plans` key in `templates/config.yaml` is on by default; an adopter opts
out. The ratchet upgrade notes name the key. An ADR records the decision. The
plans already on `main` are pruned by the script; a plan whose pruned code a
verification record cites is left whole and listed.

**D12 — `check-review.sh --cite` (D3 of the churn proposal), opt-in.** Each
disposition must contain one resolvable citation (a path in the tree, a test
name in `test_paths`, or an item ID that resolves), or read
`disposition: no change — <reason>`; otherwise `UNRESOLVABLE-DISPOSITION
<file>:<line>`. Before it ships it runs against this repository's own records.

**D13 — two findings become problem items, not phases.** G3: no gate tells a
sentence about an unmerged branch from one about the tree under merge. D4 of
the churn proposal: `analyze-risks` has no control-design guidance; the kill
line and `killed:` column it proposed would mostly restate the mutation
evidence already on `main`.

## Phases

One change per phase, each to its own signed squash. Ordered by return on
effort, ties to the least effort. Compact the session after each merge.

| # | Branch | Decisions | Waits for |
|---|---|---|---|
| 1 | `test-runner` | this roadmap; D6, D7, D8; the D13 problem items | — |
| 2 | `parallel-changes` | D1, D2, D4, D5 | — |
| 3 | `record-narrates-once` | D9, D10 | phase 1 (D7's measurement) |
| 4 | `prune-plans` | D11 | — |
| 5 | `check-review-cite` | D12 | — |

Phase 2 renumbers AGENTS.md non-negotiable 5 to 4 and every citation of it.

## Not adopted

- **P1**, the squash in the handed-over command: D5.
- **P2's overlap script**: D3.
- **G2**, a `swept:` line on dispositions: another claim written at the moment
  of greatest fatigue, with no gate behind it.
- **P3**, a diffstat re-merge trigger: superseded by the tree-hash comparison
  at `merge-change` steps 2 and 6.
- **P6**, a `resolves:` line in the resolver's own draft: low value while
  foreign-ledger conflicts stay rare.
- **P7**: the writing scan it scoped was removed in `97b230d`.
- **P10**, prose tests that compare two extracted sides: conflicts with
  agent-first D4, which keeps and rewords skill-text tests.
- **P11**, mutation evidence replayed at its own commit: decided otherwise in
  `skills/develop-change/references/mutation-anchors.md`.
- **Churn D1**: delivered by `821e783` (README orientation-only). **Churn
  D5**: its sequencing is replaced by the phases above.
