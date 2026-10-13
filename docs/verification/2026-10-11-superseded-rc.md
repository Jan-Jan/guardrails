# Verification — superseded-rc (2026-10-11)

branch: worktree-rc-out-of-force
reviewer: independent Claude subagents with fresh context, given the diff, the plan, the problem ledger, AGENTS.md and the review checklist (merge-change step 6a): round 1 at `4e7d0e4`, round 2 at `eb98311`, round 3 at `47d8886` after the base merge, round 4 at `f582837` after the guideline fixes and the deslop pass; the test-guidelines reviews (review-guidelines) at `97efd05` and `f582837`
verdict: converged at round 4: D1 to D4 and D6 met, D5 superseded by local `main`'s PR-8zcc72 fix, the round 4 reviewer's own suite run 1300 ok of 1300; every round 4 finding was low or a record finding and each was fixed mechanically, so no further reviewer was dispatched. Test-guidelines review round 2: no finding
reproduced: yes. The adopter's ledger shape, `check-trace: a superseded RC owes no implementing requirement`, printed UNIMPLEMENTED-CONTROL RC-46yapu on the unchanged script, which is the reported symptom. PR-ad4vmm was seen in this change's first gate run on this host (two check-signing failures with `gpg.ssh.allowedSignersFile` in `~/.gitconfig`, gone with `GIT_CONFIG_GLOBAL=/dev/null` three runs in three). PR-qm5gfy was reproduced by `check-signing: a gpgsig line in the message does not make a commit signed` (WARN-UNVERIFIED, exit 0, on the unchanged script). PR-nhf8cy was measured under load (66 of 200 calls) and is reproduced by local `main`'s `check-signing: a verdict git could not compute fails without --strict`

Change: an RC or HAZ superseded by a reciprocal pair within its family is out of force, so a superseded control owes no implementing requirement and mitigates nothing and a superseded hazard owes no `mitigates:`; the test fixtures read no global or system git config; `check-signing.sh` reads a signature from the commit header only. Resolves PR-x63ejd, PR-ad4vmm, PR-nhf8cy and PR-qm5gfy. Branched from `main` at `1967dc8`; base merged from local `main` at `cfa82e1`, per AGENTS.md non-negotiable 4.
Plan: `docs/plans/2026-10-11-superseded-risk-controls.md`.

## The gate

Measured on: `015ec14` — `git rev-parse HEAD` — tree `9d51082e6274eaf07dbb5e853691d327f8168bba`, clean worktree, `main` at `cfa82e1`. The ledger file was renamed before this round and step 1 pruned nothing, so this is the tree that merges, apart from this record.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh`, gawk 5.3.2 | 1..1301, 1301 ok, 0 not ok, 4 skipped, exit 0, 98 s |
| `sh tests/run-tests.sh`, mawk 1.3.4 first on `PATH` | 1..1301, 1301 ok, 0 not ok, 4 skipped, exit 0, 94 s |
| `sh tests/run-tests.sh`, BusyBox 1.37.0 awk first on `PATH` | 1..1301, 1301 ok, 0 not ok, 4 skipped, exit 0, 95 s |
| `check-ids.sh` (scratch config, change and `main`) | exit 1 on both, 69 lines each; the one differing line is an existing DRAFT-ID comment in `tests/check-trace.bats` moved from line 181 to 215 by the new tests: the change adds no finding |
| `check-trace.sh` (scratch config, change and `main`) | exit 1 on both, as on `main`. PR-x63ejd, PR-ad4vmm, PR-nhf8cy and PR-qm5gfy are counted and none is in the open roll-call: each entered resolved. The other differences are seven DANGLING-REF lines for fixture IDs of the new tests in `tests/check-trace.bats` (HAZ-k4wq8r, HAZ-m7c4xd, HAZ-n3hb5f, RC-46yapu, RC-q9xdv2, REQ-t8ej3q, REQ-uutw7x), the class of fixture line `main` already reports |
| `prune-plans.sh --base main --dry-run` | nothing to prune, exit 0 |
| Coverage | not configured |
| Working tree | clean before and after the runs |

The four skips in each run are the three real-BWK-awk contract tests and the real-BSD-date contract test: neither tool is on this host. The scratch configs are `templates/config.yaml` with `strict_paths: scripts` and one-line placeholder SRS, SAD and SOUP files. This record's draft stood untracked in the worktree for about a minute while the runs were in progress; no test reads `docs/verification` records except their `.mutations` directories, and the three runs agree.

## Red → green

The toolkit keeps no REQ ledger; the change implements the plan's decisions and resolves PR items, so those are the items. One row per test watched failing before its fix; the plan's Red -> green section carries the same lines.

| Item | Test | Watched red |
| --- | --- | --- |
| D1, PR-x63ejd | `check-trace: a superseded RC owes no implementing requirement` | UNIMPLEMENTED-CONTROL RC-46yapu, exit 1 |
| D1 | `check-trace: the successor of a superseded RC still owes an implementing requirement` | UNIMPLEMENTED-CONTROL RC-46yapu printed beside RC-q9xdv2 |
| D1 | `check-trace: an RC supersession cycle exempts nothing and is reported` | no MALFORMED-SUPERSESSION RC-46yapu |
| D2 | `check-trace: a hazard mitigated only by a superseded RC is unmitigated` | exit 1 on UNIMPLEMENTED-CONTROL only, no UNMITIGATED-HAZARD HAZ-k4wq8r |
| D3 | `check-trace: a hazard superseded together with its control owes nothing` | UNMITIGATED-HAZARD HAZ-m7c4xd, exit 1 |
| D3 | `check-trace: the successor of a superseded HAZ still owes a mitigates:` | UNMITIGATED-HAZARD HAZ-m7c4xd printed beside HAZ-n3hb5f |
| D6, PR-qm5gfy | `check-signing: a gpgsig line in the message does not make a commit signed` | expected exit 1, got 0: WARN-UNVERIFIED (signature present but did not verify) |

Written after the behavior existed, or green before the fix, and reddened by a mutant instead (mutation-reddened, not red-first); each mutant and the failure it produced is in the plan:
`check-trace: a REQ superseded by an RC still owes its test` (D1),
`check-trace: a mitigates: outside the risk ledger keeps no hazard mitigated` (D2),
`check-trace: a HAZ supersession cycle exempts nothing and is reported` (D3),
`check-trace: doc_rmf on doc_srs's directory still reads its mitigates: lines` (D2),
`check-trace: a failing orphan-scan awk is exit 2, not a clean backstop` (D1),
`check-trace: the host's global or system git config does not change the verdict` (PR-ad4vmm),
`check-trace: a one-sided superseded-by: on an RC exempts nothing` (D1),
`check-trace: an RC superseded by a requirement stays in force` (D1),
`check-trace: a HAZ superseded by an RC stays in force` (D3),
`check-trace: a retired: on an RC retires nothing` (D1),
`check-trace: a superseded RC's successor keeps its hazard mitigated` (D2; red before the fix only on the D1 defect).

`check-trace: an unreadable risk ledger fails the out-of-force scan` (D1) is the renamed `check-trace: an unreadable risk ledger fails the orphan scan`, which the RMF read made reach the out-of-force scan first; it failed on its old message before the rename.

The PR-ad4vmm test first written, `check-signing: a fixture reads no global or system git config`, was watched red and later replaced at the script seam (guideline finding-3). T5's two red-first tests for PR-nhf8cy were withdrawn with T5's script change at the base merge (D5).

No test was inherited.

## What was wrong, and what was built

A class B adopter upgrading from 17a0d58 to 1967dc8 went red on `UNIMPLEMENTED-CONTROL RC-46yapu` (PR-x63ejd). The control had been superseded by a narrower one on the day its only implementing REQ was superseded by a narrower one. The 2026-10-08 out-of-force change made an out-of-force REQ's `implements:` credit nothing (its D3) but defined out of force for REQ and LLR only (its D1), so the superseded control owed an in-force REQ for a behavior the software deliberately does not have, and every project-side remedy was false or deleted the record.

`check-trace.sh`'s out-of-force scan now also reads the RMF and opens blocks on RC and HAZ. A supersession pair takes an item out of force only within its family: RC to RC, HAZ to HAZ, REQ/LLR to REQ/LLR, by the existing chain rule, so a self-pair or a cycle exempts nothing and is MALFORMED-SUPERSESSION. An out-of-force RC owes no `implements:` (D1) and its `mitigates:` mitigates nothing (D2); an out-of-force HAZ owes no `mitigates:` (D3). The `mitigates:` reader is block-attributed and reads doc_rmf alone, file by file, so an overlap with doc_srs or doc_sad changes nothing. (As this record reaches local `main` the reader is `credit_scan` and nothing is intersected with a line-wise reader: the intersection this change built was withdrawn where it met the block-attributed-credits change, which allows one reader per keyword. PR-z83ka9's change records that resolution and carries this record in.) `retired:` stays REQ and LLR only. A scan that fails on the RMF is exit 2.

Two signing defects surfaced on the way. The test fixtures read the developer's global git config (PR-ad4vmm); `tests/helpers.bash` now exports `GIT_CONFIG_GLOBAL`, `GIT_CONFIG_SYSTEM` and `GIT_CONFIG_NOSYSTEM` for every test (D4), and `check-signing.bats`'s own narrower isolation from `main` is folded into it. `check-signing.sh` read `gpgsig` anywhere in the commit object, so a message line could make an unsigned commit read as signed (PR-qm5gfy); `carries_signature` reads the header only (D6). A SIGPIPE race giving a timing-dependent verdict (PR-nhf8cy) was fixed on local `main` as PR-8zcc72 while this change was open; this change took that fix at the base merge and withdrew its own.

`analyze-risks`, `grill-requirements/references/supersession.md`, the merge-change review checklist and the upgrade notes state the rules; the 2026-10-08 plan carries amendment notes on its D1 and D3.

## Review

### Round 1

**finding-1**: code, high — D2 moved PR-x63ejd's shape onto hazards: a HAZ superseded together with its control went red on UNMITIGATED-HAZARD, which `main` passed, with only false remedies.
disposition: ruled with the maintainer on 2026-10-11 as D3, a HAZ out of force by a HAZ pair (fb65c73); two tests watched red, one scope control, and a cycle test (6e74d31).

**finding-2**: code, medium — the REQ side of the family rule was untested; a mutant applying it only to an old RC survived.
disposition: `check-trace: a REQ superseded by an RC still owes its test`, reddened by that mutant (fb65c73).

**finding-3**: code, low — the `in_rmf` restriction on the `mitigates:` reader was unpinned.
disposition: `check-trace: a mitigates: outside the risk ledger keeps no hazard mitigated`, reddened with `in_rmf &&` dropped (fb65c73).

**finding-4**: code, low — a table directly under an out-of-force RC belongs to its block, so its `mitigates:` lines are dropped.
disposition: stated in `supersession.md` (fb65c73).

**finding-5**: code, low — RMF files are scanned for REQ/LLR blocks too, so a REQ misplaced in the RMF has its `retired:` read.
disposition: stated in the plan's T1; MISPLACED-ITEM keeps such a tree red, so nothing goes green.

### Round 2

**finding-1**: code, medium — `^gpgsig` was matched against the whole commit object, message included, in `main`'s code and in T5's new branch: an unsigned commit with such a message line read WARN-UNVERIFIED, exit 0.
disposition: recorded as PR-qm5gfy and fixed by D6, `carries_signature`, header only (9aa7304); one test watched red.

**finding-2**: code, low — a gpg-variant race (a commit reading `N` on an idle machine and a dead `git log` under load) could still give opposite verdicts; not reproduced, the sandbox refused the experiment.
disposition: not fixed; listed under Gaps. After the base merge the dead-`git log` path is `main`'s PR-8zcc72 branch.

**finding-3**: code, low — an in-force REQ whose `implements:` names only an out-of-force RC passes unreported.
disposition: a review-checklist item (9aa7304); left to review, as 2026-10-08 D3 leaves history references.

**finding-4**: record — the 2026-10-08 plan's amendment notes omitted the HAZ rule, and the upgrade notes had no signing entry.
disposition: both added (9aa7304).

### Round 3

**finding-1**: record — the plan's T5 section read as live work after its withdrawal.
disposition: marked withdrawn (e83c6a2).

**finding-2**: record — the plan said it delivered D1 to D6, D5 included.
disposition: D1 to D4 and D6, D5 superseded (e83c6a2).

**finding-3**: requirement, low — the upgrade notes said an older `check-signing.sh` passed these verdicts, true in default mode only.
disposition: "in default mode" added, and the `--strict` behavior stated (e83c6a2).

**finding-4**: code, low — `check-signing.bats`'s `isolate_git_config` was redundant with `helpers.bash`.
disposition: removed by the deslop pass (f582837); the PR-gw6wts test still verifies the isolation, through a HOME of its own.

**finding-5**: record — task order in the plan (T7 between T6 and T2).
disposition: left; the tasks are cited by number, not position.

### Round 4

**finding-1**: code, low — the per-file `in_rmf` for a doc_rmf overlapping doc_srs had no test; a mutant gave a false UNMITIGATED-HAZARD and survived.
disposition: `check-trace: doc_rmf on doc_srs's directory still reads its mitigates: lines`, reddened by that mutant (a300230).

**finding-2**: record — the plan's Red -> green prose still named the poisoned `GR_AWK_FRONT_MATTER` mechanism.
disposition: amended to the PATH awk stub (a300230).

**finding-3**: record — an uneven wrap in the upgrade notes.
disposition: reflowed (a300230).

## Guideline reviews

### docs/TEST_GUIDELINES.md

Governs: docs/plans/2026-10-08-out-of-force-items.md docs/plans/2026-10-11-superseded-risk-controls.md docs/problems/2026-10-11-superseded-rc.md scripts/check-signing.sh scripts/check-trace.sh skills/analyze-risks/SKILL.md skills/grill-requirements/references/supersession.md skills/merge-change/references/review-checklist.md skills/ratchet/references/upgrade-notes.md tests/check-signing.bats tests/check-trace.bats tests/helpers.bash

### Round 1

**finding-1**: guideline, medium — Seams 1, "a test verifies the problem report or the plan decision that states the behavior, at the same seam" — tests/check-trace.bats:2124, tests/check-trace.bats:2135
disposition: no written decision stated either scan-failure contract, so D1 gained one clause and both tests verify D1 (f56e60d).

**finding-2**: guideline, medium — Doubles 1, "No mock of code the project owns" — tests/check-trace.bats:2142-2150
disposition: the poisoned `GR_AWK_FRONT_MATTER` is replaced by a PATH `awk` stub failing only the backstop's invocation (f56e60d).

**finding-3**: guideline, low — Seams 1, "In this repository the interface is a script's command line" — tests/check-signing.bats:91-114
disposition: replaced by `check-trace: the host's global or system git config does not change the verdict`, at the script seam (f56e60d).

The review's floor note, that the scope controls had never been seen failing, was acted on: each was reddened by a mutant (f56e60d).

### Round 2

The review raised no finding; verdict "0 findings (0 high, 0 medium, 0 low); none above low; all round 1 findings resolved".

## Gaps

- BWK awk 20200816 and BSD `date` were not run: this host has neither, and their contract tests skipped. BWK awk is covered only by the `tests/portability.bats` stub; the new awk was checked by inspection for BWK constraints.
- Round 2 finding-2, a gpg-variant timing race, was not reproduced and is not fixed.
- An in-force REQ whose `implements:` names only an out-of-force RC is reported by no gate; the review checklist asks for it.
- The lost-letter half of PR-qm5gfy has no test: git calls no verifier for an unsigned commit, so the `failed` branch is unreachable there without a new seam.
- No test pins that `gpgsig-sha256` counts as a signature or that a mergetag continuation line does not; round 3's reviewer checked both against hand-built commit objects.
- The orphan-scan fault injector selects the backstop by its awk program text; rewording that printf would turn the test red with behavior unchanged.
- A `retired:` on an RC or HAZ retires nothing and is not reported; retiring a control or a hazard is a risk decision this change did not take.

## Process deviations

- T1 (the first fix and its tests) was written by the dispatcher in the change worktree, not by a subagent in a task worktree (AGENTS.md non-negotiable 1). Every later task, fix and review was dispatched.
- The deslop pass and the test-guidelines review (`develop-change`) ran after merge-change had begun, at `97efd05`; their fixes reran the sequence from step 1 and a fresh reviewer (round 4) reviewed the result.
- Review rounds 1 to 3 were dispatched without the `review dispatched` marker commit (merge-change step 6a); round 4 has it (8430333).
- The repository has no `.guardrails/config.yaml`, so `finalize-docs.sh` and `merge-preflight.sh` were not run: the draft ledger was renamed by hand, prune-plans ran from `scripts/`, and `check-ids.sh` and `check-trace.sh` ran on scratch copies, as in `docs/verification/2026-10-11-linux-suite.md`.
