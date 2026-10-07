# Verification — record-narrates-once (2026-10-08)

branch: record-narrates-once
reviewer: an independent Claude subagent with fresh context, given the diff, the plans, the amended item, AGENTS.md and the review checklist only (merge-change step 6a), at `34f6c9a`
verdict: converged at round 1 — nothing above low; both low requirement findings were mechanical and are fixed, so no further reviewer was dispatched
reproduced: no problem item is resolved; the change implements roadmap decisions D9 and D10 and amends `PR-kc2pzm`, which stays open. The reviewer reddened each new test by mangling the text it checks, and the fix round watched each new assertion fail before its fix

Change: a verification record does not count itself and narrates once, and `PR-kc2pzm` carries the parallel-session proposals P8 and P9 as candidate formulations. Branched from `main` at `2a59e0e`; base merged from local `main` at `2a59e0e`, per AGENTS.md non-negotiable 4.
Plan: `docs/plans/2026-10-08-record-narrates-once.md`, phase 3 of `docs/plans/2026-10-06-salvage-churn-and-parallel.md`.

## The gate

Measured on: `e15a636` — `git rev-parse HEAD` — tree `6889ca37f702c95b0b76c5ad06d214f4a6d9e762`, clean worktree, `main` at `2a59e0e`. Step 3 renamed nothing, so this is the tree that merges, apart from this record.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` (parallel) | 1..1109, 1109 ok, 0 not ok, exit 0, 1290 s (2026-10-08 01:23 to 01:44) |
| `check-ids.sh` (scratch copies, base and change) | exit 1 on both, as on `main`; output diff empty |
| `check-trace.sh` (scratch copies, base and change) | exit 1 on both, as on `main`; output diff empty. `PR-kc2pzm` neither entered nor left the roll-call: it was open before and stays open |
| `check-review.sh --branch record-narrates-once` (scratch copy, run from `main`) | exit 0; this record found, every finding dispositioned |
| Coverage | not configured |
| Working tree | clean |

The repository has no `.guardrails/config.yaml`, so `check-ids.sh` and `check-trace.sh` ran on scratch copies built from `main` and from the change with `templates/config.yaml`, and `merge-preflight.sh` was not run, as in `docs/verification/2026-10-07-parallel-changes.md`.

## Red → green

| Item | Test | Watched red |
| --- | --- | --- |
| D9 | `verification template: a record does not count itself, and narrates once` | failed at its first assertion on the unedited template, which had no "The `### Round <N>` headings and the `**finding-` blocks are the count" (T1); after finding-1, failed with no `### Round 1` line before the example `**finding-1**` |
| D10 | `PR-kc2pzm carries P8 and P9 as candidates, with P9's defect` | found the item, then failed at "Candidate formulations, neither adopted" on the unedited ledger (T2); after finding-2, failed on the rationale paragraph as it stood |

## What was wrong, and what was built

A verification record counted its own contents. A total of a record's rounds or findings, written in that record, is falsified by the next commit that adds a finding block, the commit that writes it included; G1 of the churn proposal (`733e6a2`) traced findings in several of that change's own review rounds to exactly this. And a record's prose was rewritten round by round, so later rounds reviewed narrative that restated earlier ones (P12 of the parallel-session proposals, `1319944`).

`templates/verification.md` now tells the author to put each round's findings under its own `### Round <N>` heading, that those headings and the finding blocks are the count, and that no number of rounds, findings or dispositions is stated in prose. The prose sections and the Gaps are written once, after the final round, as the change stands at merge, with no round-by-round account. The template's own example findings sit under a `### Round 1` heading.

D10 made P8 and P9 wait on the suite time phase 1 measured. That was 650 s for a parallel run (`docs/verification/2026-10-07-test-runner.md`), over the five minutes below which a cheaper `record` lane would not pay for itself. So `PR-kc2pzm` now carries both as candidates, neither adopted: P8 checks a `record` disposition after the converging round by running the cheap gates, without a suite run; P9 scopes the reviewer's own run to the round's delta, with its known defect stated. `merge-change`'s rationale, which `SKILL.md` step 6a sends a reader to before proposing such a lane, now says the file-class formulations failed and points to those candidates.

## Review

### Round 1

**finding-1**: requirement, low — The new text at templates/verification.md:72 says "Put each review round's blocks under its own `### Round <N>` heading". The template's own example blocks, `**finding-1**` at :81 and `**finding-2**` at :87, still sit directly under `## Review` with no `### Round 1` heading. So the example an author copies does not follow the instruction three lines above it. Wrapping the examples in `### Round` headings is safe. I checked this on a scratch clone: I built a record from the new template with `### Round 1` and `### Round 2` headings around the two example findings, and `check-review.sh --branch demo` exited 0 with `findings 2`.
disposition: the example findings in `templates/verification.md` sit under a `### Round 1` heading; `verification template: a record does not count itself, and narrates once` asserts the heading comes before the example `**finding-1**`, and was red without it.

**finding-2**: requirement, low — The new P8 text in docs/problems/2026-09-15-field-report-two.md (lines 53-58 of the PR-kc2pzm item) describes a way to bound a `record` finding's cost by running `check-ids.sh`, `check-trace.sh`, `check-review.sh` and `tests/skills.bats`. That formulation names no class of files. skills/merge-change/references/rationale.md:173-177, which SKILL.md step 6a tells readers to consult "before proposing it", still says bounding that cost "would need a class of files no gate reads. There is none". The item marks P8 as an untried candidate, so nothing is adopted against the rationale. But the rationale states as settled that bounding needs a file class, and the item now records a formulation that does not. The rationale could say "every formulation tried so far" needed one and point to PR-kc2pzm's candidates.
disposition: `skills/merge-change/references/rationale.md` now says bounding by a class of files no gate reads fails, and that `PR-kc2pzm` records two candidates that answer it per gate instead, neither adopted; `PR-kc2pzm carries P8 and P9 as candidates, with P9's defect` asserts that sentence, and was red without it.

## Gaps

- The D9 test checks that the rule's text is in the template, not where: the reviewer moved the count rule into the template's HTML comment and the test still passed. D9 fixes no location.
- No gate enforces the rule. A record that states its own finding total still passes `check-review.sh`; the template states the rule and the review applies it. G1's second proposal, pinning a figure over a corpus the record belongs to a commit outside the change, is not part of D9 and was not built.
- The suite time D10 rests on is phase 1's measurement on one 12-CPU host. A slower or faster host would put the five-minute line elsewhere.
- Open and not filed: `check-trace: trailing whitespace on a field is not part of its value` fails when a run crosses local midnight, because its fixture is dated with `days_ago 4` before midnight and its age is read after it. Recorded in `docs/verification/2026-10-07-parallel-changes.md`; it did not affect this change's gate.
