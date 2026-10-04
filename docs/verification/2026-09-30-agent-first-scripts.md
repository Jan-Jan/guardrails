# Verification — agent-first-scripts (2026-09-30)

branch: agent-first-scripts
reviewer: rounds 1 to 21, each a fresh subagent with the diff, the change 2 plan, the proposal, the two problem items and (from round 2) this record, and no implementation narrative
verdict: round 1 REJECT on four requirement findings and two record findings, no code finding; round 2 REJECT on one code, three requirement and two record findings; round 3 REJECT on five code, one requirement and three record findings; round 4 REJECT on five code, two requirement and two record findings, after which the maintainer ruled that no fix line merges; round 5 REJECT on three code, two requirement and two record findings; round 6 REJECT on three code, one requirement and three record findings; round 7 REJECT on two code, two requirement and one record finding; round 8 REJECT on one code and one requirement finding; round 9 REJECT on two code, one requirement and one record finding; round 10 REJECT on two code findings and one record finding; round 11 REJECT on two code findings; round 12 REJECT on two code and two record findings, after which the maintainer chose a test of every command against every worktree state; round 13 REJECT on two code and two record findings; round 14 REJECT on one code finding; round 15 REJECT on two code findings and one record finding; round 16 REJECT on one code finding and one record finding; round 17 REJECT on two requirement findings and two record findings, no code finding; round 18 REJECT on one code, one requirement and three record findings; round 19 REJECT on one code finding and one requirement finding; round 20 REJECT on four code findings: a failing test (86) and three of low severity (87 to 89), after which the maintainer ruled that the review ends on the first round with nothing above low severity; round 21 found three code findings of low severity and one record finding, which ends the review under that ruling
reproduced: `PR-sa5y4k` was reproduced before the fix: the test "finish-merge: a failed branch deletion with no worktree registered does not claim a removal" failed on `main`'s message. `PR-zmzav3` is a comment defect with no behaviour to reproduce; the measurement behind it is in `docs/problems/2026-09-29-inherited-cleanup-claims.md`. `PR-tz6gsp` was reproduced before the fix: its five tests, in `tests/lib.bats`, `tests/check-review.bats` and `tests/finish-merge.bats`, each failed on the old `gr_base_branch` (the "Red → green" table). The scripted procedures (D7, D8) are new behaviour, not defect repairs.

Change: D7 and D8 of `docs/plans/2026-09-28-agent-first-skills.md` (three procedures scripted, one remedy line per rule), and D5 for `merge-change`. Branched from `main` at `ff6bb34`; `main` at `ab74ca5` (documentation of the `assertion-gate` change) merged in after round 3, and `main` at `051becc` (the ruling that accepts `PR-x4nb48`, documentation only) after round 8. The base was merged from local `main`, per AGENTS.md non-negotiable 5.
Plan: `docs/plans/2026-09-29-agent-first-skills-change-2.md`, under the proposal `docs/plans/2026-09-28-agent-first-skills.md`.

## The gate

The toolkit has no `.guardrails/config.yaml`, so the check scripts run under a
synthesized config: `id_prefixes: PR`, `doc_problems: docs/problems`,
`doc_verification: docs/verification`, `strict_paths: scripts`,
`test_paths: tests`. `check-ids.sh` and `check-trace.sh` are red on `main`
already, so the criterion is no finding on the branch that `main` lacks.

### Round 1 gate

Measured on `b0bcddf`, tree `7b34ef5bbc754541f39cdb6786c37bc8dcddf192`, clean
at start and end, against a clone of `main` at `ff6bb34`.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..805`: 805 ok, 0 not ok, 0 skipped, counted from TAP lines |
| `check-trace.sh` | exit 1 on branch and `main`; nothing new; `UNRESOLVED-PR` for `PR-zmzav3` and `PR-sa5y4k` gone |
| `check-ids.sh`, with and without `--allow-draft-files` | exit 1 on both; two new `DRAFT-ID` findings, both literal fixture tokens in `tests/merge-preflight.bats` and `tests/remedies.bats` |
| Coverage | not configured; the toolkit is unclassified |

The two `DRAFT-ID` findings failed the criterion. They were fixed with the
round 1 findings: each token is now built at run time.

The baseline run at the opening of the change is not evidence: tasks were
merged into the change worktree during the run, so it measured no single tree.
`main`'s tree was measured green in change 1's final gate.

### Round 2 gate

Measured on `f063805`, tree `9eaf6bc765349d57a3d981c1ec8f35bc2984a3c9`, clean
at start and end, against `main` at `ff6bb34`.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..809`: 809 ok, 0 not ok, 0 skipped, counted from TAP lines, with `GR_CONFIG` unset |
| `check-trace.sh` | exit 1 on both; nothing new; `UNRESOLVED-PR` for the two resolved items gone |
| `check-ids.sh`, with and without `--allow-draft-files` | exit 1 on both; 52 violation lines each side, identical once line numbers are normalised |
| `check-review.sh` | exit 0: `records 44, for agent-first-scripts 1, findings 6` |

The gate's first suite run had `GR_CONFIG` exported, which leaked into the test
fixtures and failed 17 or more tests; that run was discarded and the suite run
again with it unset.

### Round 3 gate

Measured on `551f202`, tree `222f13ea334d8156a487a837c5d71736ad54b830`, clean
at start and end, against `main` at `ff6bb34`.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..817`: 817 ok, 0 not ok, 0 skipped, counted from TAP lines, with `GR_CONFIG` unset |
| `check-trace.sh` | exit 1 on both; nothing new |
| `check-ids.sh`, with and without `--allow-draft-files` | exit 1 on both; 51 `DRAFT-ID` and one `DUPLICATE-ID` on each side; nothing new |
| `check-review.sh` | exit 0: `records 44, for agent-first-scripts 1, findings 12` |
| `merge-preflight.sh --local-base --before-review agent-first-scripts` | exit 1 at IDS on the findings `main` also reports; CLEAN-TREE and BASE-MERGED (local base only) printed `ok` |

### Round 4 gate

Measured on `1b2875f`, tree `1c898d73f09fb4e105ab3ba19583dbdf66827d3c`, clean
at start and end, against `main` at `ab74ca5`, which the branch contains.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..825`: 825 ok, 0 not ok, 0 skipped, counted from TAP lines, with `GR_CONFIG` unset |
| `check-trace.sh` | exit 1 on both; nothing new |
| `check-ids.sh`, with and without `--allow-draft-files` | exit 1 on both; nothing new |
| `check-review.sh` | exit 0: `records 45, for agent-first-scripts 1, findings 21` |
| `merge-preflight.sh --local-base --before-review agent-first-scripts` | exit 1 at IDS on the findings `main` also reports |

### Round 5 gate

Measured on `ee2e6e5`, tree `090a9dbbd40102fa1fc25d0aaee5469dd0cf2001`, clean
at start and end, against `main` at `ab74ca5`, which the branch contains.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..833`: 833 ok, 0 not ok, 0 skipped, counted from TAP lines, with `GR_CONFIG` unset |
| `check-trace.sh` | exit 1 on both; nothing new |
| `check-ids.sh`, with and without `--allow-draft-files` | exit 1 on both; nothing new |
| `check-review.sh` | exit 0: `records 45, for agent-first-scripts 1, findings 30` |
| `merge-preflight.sh --local-base --before-review agent-first-scripts` | exit 1 at IDS on the findings `main` also reports |

### Round 6 gate

Measured on `23456a6`, tree `a4a03cbbcc53b0c08d0195c1b1df90e3984be607`, clean
at start and end, against `main` at `ab74ca5`, which the branch contains.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..837`: 837 ok, 0 not ok, 0 skipped, counted from TAP lines, with `GR_CONFIG` unset |
| `check-trace.sh` | exit 1 on both; nothing new |
| `check-ids.sh`, with and without `--allow-draft-files` | exit 1 on both; nothing new |
| `check-review.sh` | exit 0: `records 45, for agent-first-scripts 1, findings 37` |
| `merge-preflight.sh --local-base --before-review agent-first-scripts` | exit 1 at IDS on the findings `main` also reports |

### Round 7 gate

Measured on `782b9f3`, tree `82cd7c5971ae23298a0a423015fcb0f72cdbf7d6`, clean
at start and end, against `main` at `ab74ca5`, which the branch contains.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..843`: 843 ok, 0 not ok, 0 skipped, counted from TAP lines, with `GR_CONFIG` unset |
| `check-trace.sh` | exit 1 on both; nothing new |
| `check-ids.sh`, with and without `--allow-draft-files` | exit 1 on both; nothing new |
| `check-review.sh` | exit 0: `records 45, for agent-first-scripts 1, findings 44` |
| `merge-preflight.sh --local-base --before-review agent-first-scripts` | exit 1 at IDS on the findings `main` also reports |

### Round 8 gate

Measured on `5f1eecc`, tree `9781d2fa6288c0d5d7abc0bb3dd8e98d9e69e5f5`, clean
at start and end, against `main` at `ab74ca5`, which the branch contains.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..845`: 845 ok, 0 not ok, 0 skipped, counted from TAP lines, with `GR_CONFIG` unset |
| `check-trace.sh` | exit 1 on both; nothing new |
| `check-ids.sh`, with and without `--allow-draft-files` | exit 1 on both; nothing new |
| `check-review.sh` | exit 0: `records 45, for agent-first-scripts 1, findings 49` |
| `merge-preflight.sh --local-base --before-review agent-first-scripts` | exit 1 at IDS on the findings `main` also reports |

### Round 9 gate

Measured on `aadfdf5`, tree `1dbc2beb4fce3d5855805ddb6b882af26574db91`, clean
at start and end, against `main` at `051becc`, which the branch contains.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..846`: 846 ok, 0 not ok, 0 skipped, counted from TAP lines, with `GR_CONFIG` unset |
| `check-trace.sh` | exit 1 on both; one new finding, `MISPLACED-ITEM PR-h7c4n2` |
| `check-ids.sh`, with and without `--allow-draft-files` | exit 1 on both; nothing new |
| `check-review.sh` | exit 0: `records 46, for agent-first-scripts 1, findings 51` |
| `merge-preflight.sh --local-base --before-review agent-first-scripts` | exit 1 at IDS on the findings `main` also reports |

The new `MISPLACED-ITEM` failed the criterion. Its source was a fixture line in
the round 8 test "merge-preflight: a passing UNITS shows a unit's check-trace.sh
warnings under that unit's header", which wrote a definition-shaped
`**PR-…**:` line literally. The fixture now builds the ID at run time, and the
file contains no copy of it; a scan of the fixed tree prints nothing for it.

### Round 10 gate

Measured on `ddef453`, tree `ab0609499da92ea932b998e3654bb70a2dc4d8c6`, clean
at start and end, against `main` at `051becc`, which the branch contains.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..861`: 861 ok, 0 not ok, 0 skipped, counted from TAP lines, with `GR_CONFIG` unset |
| `check-trace.sh` | exit 1 on both; nothing new |
| `check-ids.sh`, with and without `--allow-draft-files` | exit 1 on both; nothing new |
| `check-review.sh` | exit 0: `records 46, for agent-first-scripts 1, findings 55` |
| `merge-preflight.sh --local-base --before-review agent-first-scripts` | exit 1 at IDS on the findings `main` also reports |

### Round 11 gate

Measured on `2f904b6`, tree `87fda2a19a998c2a4dadbd49f50b006b68a820ae`, clean
at start and end, against `main` at `051becc`, which the branch contains.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..865`: 865 ok, 0 not ok, 0 skipped, counted from TAP lines, with `GR_CONFIG` unset |
| `check-trace.sh` | exit 1 on both; nothing new |
| `check-ids.sh`, with and without `--allow-draft-files` | exit 1 on both; nothing new |
| `check-review.sh` | exit 0: `records 46, for agent-first-scripts 1, findings 58` |
| `merge-preflight.sh --local-base --before-review agent-first-scripts` | exit 1 at IDS on the findings `main` also reports |

### Round 12 gate

Measured on `99871cf`, tree `d886e0f06f15e46ffd2af6c56b36de08043678ea`, clean
at start and end, against `main` at `051becc`, which the branch contains.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..868`: 868 ok, 0 not ok, 0 skipped, counted from TAP lines, with `GR_CONFIG` unset |
| `check-trace.sh` | exit 1 on both; nothing new |
| `check-ids.sh`, with and without `--allow-draft-files` | exit 1 on both; nothing new |
| `check-review.sh` | exit 0: `records 46, for agent-first-scripts 1, findings 60` |
| `merge-preflight.sh --local-base --before-review agent-first-scripts` | exit 1 at IDS on the findings `main` also reports |

### Round 13 gate

Measured on `0bd1b2c`, tree `2874549e982f78250d7820c775acb034ad187ffd`, clean
at start and end, against `main` at `051becc`, which the branch contains.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..910`: 910 ok, 0 not ok, 0 skipped, counted from TAP lines, with `GR_CONFIG` unset |
| `check-trace.sh` | exit 1 on both; nothing new |
| `check-ids.sh`, with and without `--allow-draft-files` | exit 1 on both; nothing new |
| `check-review.sh` | exit 0: `records 46, for agent-first-scripts 1, findings 64` |
| `merge-preflight.sh --local-base --before-review agent-first-scripts` | exit 1 at IDS on the findings `main` also reports |

### Round 14 gate

Measured on `4e3ce2a`, tree `46083e7675fdba970cdcbc099559bf4bb6326371`, clean
at start and end, against `main` at `051becc`, which the branch contains.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..913`: 913 ok, 0 not ok, 0 skipped, counted from TAP lines, with `GR_CONFIG` unset |
| `check-trace.sh` | exit 1 on both; nothing new |
| `check-ids.sh`, with and without `--allow-draft-files` | exit 1 on both; nothing new |
| `check-review.sh` | exit 0: `records 46, for agent-first-scripts 1, findings 68` |
| `merge-preflight.sh --local-base --before-review agent-first-scripts` | exit 1 at IDS on the findings `main` also reports |

### Round 15 gate

Measured on `1fa2d16`, tree `93628672d69736a1652103eb768f6cb38135f821`, clean
at start and end, against `main` at `051becc`, which the branch contains.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..918`: 918 ok, 0 not ok, 0 skipped, counted from TAP lines, with `GR_CONFIG` unset |
| `check-trace.sh` | exit 1 on both; nothing new |
| `check-ids.sh`, with and without `--allow-draft-files` | exit 1 on both; nothing new |
| `check-review.sh` | exit 0: `records 46, for agent-first-scripts 1, findings 69` |
| `merge-preflight.sh --local-base --before-review agent-first-scripts` | exit 1 at IDS on the findings `main` also reports |

### Round 16 gate

Measured on `38ff779`, tree `59d6265958eb27dec78505169726f244eab59e2e`, clean
at start and end, against `main` at `051becc`, which the branch contains.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..934`: 934 ok, 0 not ok, 0 skipped, counted from TAP lines, with `GR_CONFIG` unset |
| `check-trace.sh` | exit 1 on both; nothing new |
| `check-ids.sh`, with and without `--allow-draft-files` | exit 1 on both; nothing new |
| `check-review.sh` | exit 0: `records 46, for agent-first-scripts 1, findings 72` |
| `merge-preflight.sh --local-base --before-review agent-first-scripts` | exit 1 at IDS on the findings `main` also reports |

### Round 17 gate

Measured on `ab3c666`, tree `11bb6b1a05426e7f1ea7ad3546e9e0f87810bf9a`, clean
at start and end, against `main` at `051becc`, which the branch contains.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..955`: 955 ok, 0 not ok, 0 skipped, counted from TAP lines, with `GR_CONFIG` unset |
| `check-trace.sh` | exit 1 on both; nothing new |
| `check-ids.sh`, with and without `--allow-draft-files` | exit 1 on both; nothing new |
| `check-review.sh` | exit 0: `records 46, for agent-first-scripts 1, findings 74` |
| `merge-preflight.sh --local-base --before-review agent-first-scripts` | exit 1 at IDS on the findings `main` also reports |

### Round 18 gate

Measured on `ee043fa`, tree `472610ca7718db0184459f0c7a3749effff27e5d`, clean
at start and end, against `main` at `051becc`, which the branch contains.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..955`: 955 ok, 0 not ok, 0 skipped, counted from TAP lines, with `GR_CONFIG` unset |
| `check-trace.sh` | exit 1 on both; nothing new |
| `check-ids.sh`, with and without `--allow-draft-files` | exit 1 on both; nothing new |
| `check-review.sh` | exit 0: `records 46, for agent-first-scripts 1, findings 78` |
| `merge-preflight.sh --local-base --before-review agent-first-scripts` | exit 1 at IDS on the findings `main` also reports |

### Round 19 gate

Measured on `089f0e3`, tree `b0e47ff2c714b07a60a6b4cd547019ca2a88b2cd`, clean
at start and end, against `main` at `051becc`, which the branch contains.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..957`: 957 ok, 0 not ok, 0 skipped, counted from TAP lines, with `GR_CONFIG` unset |
| `check-trace.sh` | exit 1 on both; nothing new |
| `check-ids.sh`, with and without `--allow-draft-files` | exit 1 on both; nothing new |
| `check-review.sh` | exit 0: `records 46, for agent-first-scripts 1, findings 83` |
| `merge-preflight.sh --local-base --before-review agent-first-scripts` | exit 1 at IDS on the findings `main` also reports |

### Round 20 gate

Measured on `01613b8`, tree `bfc10b03faf5e80c57b2ed216b679f5ba586cc24`, clean
at start and end, against `main` at `051becc`, which the branch contains. The
gate FAILED on one test; finding 86 is that failure, and `a0c9186` fixed it.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..958`: 957 ok, 1 not ok (`clanker: no file in scope contains the replaced vocabulary`), 0 skipped, exit 1, with `GR_CONFIG` unset |
| `check-trace.sh` | exit 1 on both; nothing new |
| `check-ids.sh`, with and without `--allow-draft-files` | exit 1 on both; nothing new |
| `check-review.sh` | exit 0: `records 46, for agent-first-scripts 1, findings 85` |
| `merge-preflight.sh --local-base --before-review agent-first-scripts` | exit 1 at IDS on the findings `main` also reports |

### Round 21 gate

Measured on `22a5e3e`, tree `350df74188d2c4190c77c1705f51bc04cd9c2b5e`, clean
at start and end, against `main` at `fd9a867`, which the branch contains: the
base was merged from local `main` at `fd9a867`, per AGENTS.md non-negotiable 5,
and the conflict in `tests/helpers.bash`, where both sides added functions at
one place, was resolved by keeping both.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..972`: 972 ok, 0 not ok, 0 skipped, counted from TAP lines, with `GR_CONFIG` unset |
| `check-trace.sh` | exit 1 on both; nothing new |
| `check-ids.sh`, with and without `--allow-draft-files` | exit 1 on both; nothing new |
| `check-review.sh` | exit 0: `records 47, for agent-first-scripts 1, findings 89` |
| `merge-preflight.sh --local-base --before-review agent-first-scripts` | exit 1 at IDS on the findings `main` also reports |

### Final gate

Measured after the last review round, on `82b697a`, tree
`b874d0b98cfcc27d348c0ddfccab3508b880aa9c`, clean at start and end, against
`main` at `fd9a867`, which the branch contains (base merged from local `main`
at `fd9a867`, per AGENTS.md non-negotiable 5). Only this record changed after
it.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` | `1..978`: 978 ok, 0 not ok, 0 skipped, counted from TAP lines, with `GR_CONFIG` unset |
| `check-trace.sh` | exit 1 on both; nothing new; `main` also reports `UNRESOLVED-PR` for `PR-zmzav3` and `PR-sa5y4k`, which this change resolves |
| `check-ids.sh`, with and without `--allow-draft-files` | exit 1 on both; nothing new |
| `check-review.sh` | exit 0: `records 47, for agent-first-scripts 1, findings 93` |
| `merge-preflight.sh --local-base --before-review agent-first-scripts` | exit 1 at IDS on the 51 DRAFT-ID lines and the DUPLICATE-ID `PR-001` that `main` also reports |

## Red → green

| Item | Test | Watched red |
| --- | --- | --- |
| D8 | check-trace: one fix line per rule that fired, after the violations | no fix line; violations went straight to `checked:` |
| D8 | check-trace: every report in the roster has a remedy | all 25 roster tokens had no remedy entry |
| D8 | check-trace: a warning-only run prints its fix lines and exits 0 | no `fix UNRESOLVED-PR` line |
| D8 | check-ids: one fix line per rule that fired | violations printed, no fix line |
| D8 | check-ids: the remedy for a draft ID names new-id.sh | no fix line |
| D8 | check-ids: --allow-draft-files prints no fix line for a draft file | the no-flag half found no `fix DRAFT-FILE` line |
| D8 | check-trace: a clean run prints no fix line; violation lines are unchanged | green on arrival: regression guards |
| D7 | check-traceability: the fix table is a pointer to the remedy lines | the `## Fixing each rule` heading was present |
| D7 | the 20 tests of `tests/task-worktree.bats` | exit 127 before the script existed; "copies ignored entries, but not .worktrees/ or .claude/" failed again on a real defect (`tests/.bats-core` copied into itself) |
| D7 | tests 1 to 19 of `tests/merge-preflight.bats` | exit 127 before the script existed |
| D7 | merge-preflight: passes under an awk that rejects a newline in -v | green on arrival; failed against a mutated impact-set parse once the script failed closed |
| D7 | merge-preflight: a passing TRACE shows the warnings check-trace.sh printed | exit 0 with no `UNRESOLVED-PR` line |
| D7 | merge-change: the mechanical checks are the pre-flight | "step 4 does not run merge-preflight.sh --before-review" |
| D7 | develop-change: the dispatch prompt names task-worktree.sh | "the dispatch prompt does not name task-worktree.sh start" |
| D5 | skill shape: every SKILL.md is at most 2,000 words | "merge-change:3132" once the exemption was removed |
| PR-sa5y4k | finish-merge: a failed branch deletion with no worktree registered does not claim a removal | `main`'s "the worktree was removed" message on the path that removed none |
| PR-sa5y4k | finish-merge: a failed branch deletion after a removal reports the worktree removed | green on arrival: it pins the existing message where it is true |
| PR-zmzav3 | none | a comment defect with no behaviour to test; the substitution is stated here |
| PR-6d2jvt, PR-9xxz3b, PR-4fwfjp, PR-n274s7, PR-58zsvf | five tests retargeted into `tests/remedies.bats` (D4) | green on arrival; each shown to fail by altering its remedy text or case, then reverted |
| D7 | task-worktree finish --no-merge: the three round 1 tests | exit 2, three arguments not accepted; `--no-merge` read as a tag |
| D7 | merge-preflight: a tool that exits 2 makes the pre-flight exit 2 with the tool's output | green on arrival; failed with `gr_fail`'s exit 2 mutated to exit 1 |
| D7 | merge-preflight: NESTED-WORKTREE names finish --no-merge review for the review worktree | the old fix line had no `--no-merge` remedy |
| D7 | finish-merge: --check names the task-worktree.sh remedy for each kind of nested worktree | the old "merge or abandon the branch, then `git worktree remove`" message |
| D7 | merge-preflight: the four `--local-base` tests | "unknown argument: --local-base", or a usage line without it |
| D7 | finish-merge: guard 4's rejection names the task-worktree.sh remedy, as --check does | guard 4's old "merge or abandon the branch, then `git worktree remove`" rejection |
| D7 | task-worktree finish: merges unsigned when commit.gpgsign is true and signing fails | green on arrival; failed ("gpg failed to sign the data" from a stub signer) with `-c commit.gpgsign=false` removed |
| D7 | the five `task-worktree discard` tests | "unknown command: discard"; the listing test also fails with `-D` changed to `-d` |
| D7 | task-worktree finish: rejects a task worktree with a worktree registered inside it (changed) | the old "merge or abandon each worktree" remedy |
| D7 | task-worktree finish --no-merge: rejects a task branch with a commit (changed) | the old TASK-HAS-COMMITS remedy, which named no next step |
| D7 | finish-merge: guard 4 after the squash names finish --no-merge and discard for a task branch with a commit | the remedy printed plain `finish <tag>` |
| D7 | merge-preflight: IDS fails on a draft-named ledger file, because check-ids.sh runs without --allow-draft-files | green on arrival; failed (`IDS ok`) with the flag added |
| D7 | the `task-worktree` tests renamed from `finish` to `merge` and from `finish --no-merge` to `remove` | `unknown command` before the commands existed |
| D7 | task-worktree: merge, remove and discard reject a task branch checked out outside the change worktree | `discard other` removed the sibling worktree and deleted its branch at exit 0 |
| D7 | task-worktree remove: the TASK-DIRTY fix line names remove | failed with the line mutated to name `finish` |
| D7 | task-worktree merge and remove: removes without --force; a locked task worktree is not removed | the submodule tests fail with `--force` added; the locked tests with `--force --force` |
| D7 | task-worktree: finish and --no-merge are usage errors | `finish t1` merged and exited 0 |
| D7 | the TASK-CONFLICT remedy names an unsigned commit (conflict test) | failed with the `-c commit.gpgsign=false` clause cut |
| D7 | merge-preflight: IDS fix line pinned (in "IDS fails on a draft ID") | green on arrival; failed with `gr_ids_remedy`'s wording mutated |
| D7 | merge-preflight: NESTED-WORKTREE names remove and discard, and no merging command | the old fix line |
| D7 | finish-merge: the four guard 4 and `--check` remedy tests | the old `gr_nested_remedy` text |
| D7 | finish-merge: guard 4 after the squash names remove and discard for a task branch with a commit (keep-work wording) | "copy its branch first" absent: the line named a rerun of this change |
| D7 | merge-change: step 6d and the cleanup reference name remove and discard, and no remedy merges | 6d did not name `remove`; the reference lacked it |
| D7 | task-worktree merge: rejects a task worktree with an uncommitted change and changes nothing (retargeted) | the line read "then run merge t1 again" |
| D7 | task-worktree merge: the TASK-NESTED fix line returns the task to its subagent and names no merge | "goes back to its subagent" absent |
| D7 | task-worktree merge: the TASK-NESTED fix line covers a worktree task-worktree.sh did not create | the two-case remedy absent |
| D7 | merge-preflight: an awk failure while reading a check's warnings exits 2 | green on arrival; failed with the guard replaced by `|| true` |
| D7 | merge-preflight: an awk failure while reading the impact set's unit column exits 2 | green on arrival; failed with the guard replaced by `|| true` |
| D8 | check-trace: a TMPDIR that does not exist changes neither the exit nor the fix lines | exit 2, "mktemp failed: the violation lines cannot be collected" |
| D8 | check-trace: every report it prints has a remedy line (extraction retargeted to `print_violations`) | "found 11 report sites, expected at least 18" after the print sites moved |
| D7 | task-worktree: start and remove reject a tag that begins with - | with the rejection deleted, `start -x` exited 0 |
| D7 | task-worktree start: copies an ignored entry whose name begins with - or contains a quote | cp read `-n.bak` as options and was given the C-quoted name |
| D7 | task-worktree start: skips an ignored entry whose name contains a newline, and states it | the C-quoted name failed to copy and start exited 1 |
| D7 | task-worktree start: an ignored entry that cannot be copied exits 1 and names the worktree | "expected exit 1, got 0" with the exit removed |
| D7 | skill references: no blank line separates two rows of one table | failed on `cleanup-rejections.md:15` |
| D7 | task-worktree start: a failed listing of ignored entries exits 2 and creates no worktree | green on arrival; failed with the sentinel deleted, and with the `case` block deleted (exit 1, worktree created) |
| D7 | task-worktree start: skips an ignored entry whose name contains the byte \001, and states it | the old message named only a newline |
| D7 | task-worktree start: skips an ignored entry whose name contains a newline, and states it (changed) | the old message |
| D7 | merge-preflight: a passing UNITS shows a unit's check-trace.sh warnings under that unit's header | failed with the per-unit `check-trace.sh` warnings call replaced by `:` |
| D7 | merge-change: step 6d and the cleanup reference name remove and discard, and no remedy merges (changed) | "step 6d lacks '`discard <tag>` after recording'" |
| D7 | task-worktree merge: a merge that fails without a conflict exits 1 and removes nothing | with the exit deleted, the script removed the worktree |
| D7 | task-worktree start: rejects a tag whose path already exists, and … whose branch already exists (changed) | the old TASK-EXISTS line, which named `discard` before recording |
| D7 | merge-change: text the first rewrite lost is stated again (changed) | the class C advice without its scope |
| D7 | task-worktree start: an ignored entry named like a failure line is copied and start exits 0 | exit 1: the name matched the search of the progress output |
| D7 | task-worktree merge, remove and discard: rejects a task worktree that is not on the task branch and changes nothing (three tests) | merge and discard exited 0 and deleted the branch; remove reported TASK-HAS-COMMITS; under merge, the first fix line named `run merge t1 again` |
| D7 | task-worktree merge, remove and discard: lists a commit on a detached task worktree HEAD and names record (three tests) | the plain checkout remedy, with no listing; following it lost the commit |
| D7 | task-worktree remove, discard, merge and start in a deleted, still-registered task directory (finding 61, matrix) | exit 2 at `git status failed` with no fix line |
| D7 | task-worktree: a failing `rev-list` and a failing `git log` under TASK-NOT-ON-BRANCH (finding 62) | green on arrival; each failed with its `|| gr_die` mutated to `|| true` |
| D7 | task-worktree merge, off-branch with a commit: the line names no checkout (finding 62, changed) | failed with the merge-specific remedy deleted |
| D7 | the worktree state matrix, 30 tests added from 58 to 88 (`8f3829e`, `7d8a9bb`) | each state test red before its fix (locked, deleted directory, detached and deleted, registered without a branch); tests of behaviour already correct each shown red against a named sweep mutant |
| D7 | nested worktrees under a deleted task directory; TASK-NOT-REMOVED under merge (`dbeb746`, `aa35918`) | remove stopped at TASK-HAS-COMMITS, discard left the nested registration, merge listed no nested path; no TASK-NOT-REMOVED line |
| D7 | TASK-NESTED keyed on the task path (detached, other branch, registered leftover, unregistered directory); TASK-NOT-REMOVED under remove and discard (`86b0829`) | TASK-NOT-ON-BRANCH, TASK-MISSING or TASK-EXISTS printed instead; no TASK-NOT-REMOVED line |
| D7 | TASK-NOT-CREATED, TASK-COPY-FAILED, TASK-MERGE-FAILED, TASK-BRANCH-NOT-DELETED (`221a22c`) | no fix line for each path |
| D7 | task-worktree merge, remove and discard: a task directory that is not a registered worktree is TASK-NOT-REGISTERED (finding 65) | merge and discard exited 0; remove printed no such line |
| D7 | the eight tests of the second TASK-NESTED form now pin the change worktree as the place to run from (finding 66, changed) | each failed with the reviewer's mutant (`from $task_path`) |
| D7 | task-worktree merge: a merge, or a cherry-pick conflict, left in progress is CHANGE-BUSY (finding 69) | TASK-CONFLICT printed for a merge that never began |
| D7 | task-worktree merge, start and remove: a rebase stopped on a conflict is CHANGE-BUSY (finding 69 follow-up) | bare exit 2, "HEAD is detached" |
| D7 | task-worktree remove and discard: the merge of this task left in progress is CHANGE-BUSY (finding 71) | remove printed TASK-HAS-COMMITS; discard exited 0 and deleted the branch mid-merge |
| D7 | CHANGE-BUSY for a revert, unmerged entries from a stash pop, a `rebase --apply`, and a merge of an unnamed commit (finding 70) | each failed with its branch mutated: condition false, alternative deleted, short-SHA fallback replaced by `:` |
| D7 | ten tests: a failing `git rev-parse --git-path` (five names), `git ls-files -u` (two sites), `git rev-parse --verify MERGE_HEAD`, `git for-each-ref --points-at` and `git rev-parse --short` exit 2 and change nothing | most exited 0 and retired the task, or printed a wrong CHANGE-BUSY line; each also failed with only its `|| gr_die` removed |
| D7 | task-worktree discard: a failed read of the task branch tip with the merge of this task in progress exits 2 and changes nothing (finding 73) | exit 1 with the CHANGE-BUSY line for another merge: "abort it (git merge --abort), then run discard t2 again" |
| D7 | task-worktree discard: a failed `git show-ref` of the task branch with the merge of this task in progress exits 2 and changes nothing (finding 73) | exit 1 with the CHANGE-BUSY line for this task's merge; the block made no `show-ref` call, so no status was checked |
| D7 | task-worktree remove: a failed `git branch --show-current` exits 2 and states the failure (finding 73) | exit 2 with "HEAD is detached, so there is no change branch" |
| D7 | task-worktree: a failed `git rev-parse --git-dir` or `--git-common-dir` in the primary-checkout check (two tests) | start exited 0 and created the task worktree |
| D7 | task-worktree remove: a failed `git show-ref` of the task branch is not read as an absent branch | exit 1 with TASK-MISSING, whose remedy removes the registration of a worktree with a commit |
| D7 | task-worktree start: a failed `git check-ignore` is not read as `.worktrees/` not ignored | exit 1 with WORKTREES-NOT-IGNORED |
| D7 | task-worktree remove: a failed `git log` of the commits TASK-HAS-COMMITS lists | exit 1 with TASK-HAS-COMMITS and no commit listed |
| D7 | task-worktree merge: a failed `git rev-parse --verify MERGE_HEAD`, or of the task branch tip, after a conflicting merge (two tests) | exit 1 with TASK-MERGE-FAILED, which states that nothing was merged while the conflict is in progress |
| D7 | merge-preflight: a failed `git rev-parse --git-dir` or `--git-common-dir` (two tests) | every check passed, exit 0 |
| D7 | merge-preflight: a failed `git branch --show-current` is not read as a detached HEAD | exit 2 with "HEAD is on 'a detached HEAD'" |
| D7 | merge-preflight: a failed `git rev-parse` of `origin/<base>` is not read as an absent `origin/<base>` | the origin half of BASE-MERGED was skipped, and the run exited 0 with `origin/main` ahead of HEAD |
| D7 | merge-preflight: a failed `git merge-base --is-ancestor` is not read as a base HEAD lacks | exit 1 with BASE-MERGED and the remedy "merge the base branch" |
| PR-tz6gsp | lib: `gr_base_branch` returns git's status when `git worktree list` fails, and prints nothing | status 0 and empty output, the result for a detached primary checkout |
| PR-tz6gsp | finish-merge (main path and `--check`), check-review (default and `--branch`): a failed `git worktree list` in `gr_base_branch` exits 2 and is not read as a detached checkout (four tests) | finish-merge and check-review exited 2 stating a detached checkout; `finish-merge.sh --check` blamed its second `worktree list` call; `check-review.sh --branch` exited 0 |
| D7 | merge-preflight: a failed `git worktree list` in `gr_base_branch` exits 2 and is not read as a detached primary checkout | exit 2 stating that the primary checkout is detached |
| D7 | task-worktree merge: a merge commit that a `commit-msg` or a `pre-merge-commit` hook rejects leaves this task's merge in progress, and the fix line states it was not committed (two tests, finding 79) | `fix TASK-MERGE-FAILED: … nothing was merged or removed` while MERGE_HEAD was the task tip and the task change was staged |
| D8 | check-ids: the DRAFT-FILE fix line names both the mid-change flag and the merge step that renames the file (finding 84) | the old line, which said only to leave the file |
| D7 | merge-preflight: IDS fails on a draft-named ledger file (changed: asserts the merge half of the fix line, finding 84) | the old line had no merge half |
| D7 | task-worktree merge, remove, discard and start with a tag named like the task or change branch (seven tests, finding 87) | merge merged the tag and printed a false TASK-BRANCH-NOT-DELETED; remove removed the worktree; discard listed no commit and deleted the branch at exit 0; start failed with an ambiguous object name |
| D7 | task-worktree: every command rejects a tag that makes an invalid branch name, with exit 2 (finding 88) | start exited 1 with TASK-NOT-CREATED, "run start t..x again"; the other commands exited 1 |
| D7 | task-worktree: the TASK-CONFLICT and cherry-pick CHANGE-BUSY remedies run as printed with no editor (finding 89); five existing tests assert `--no-edit` (changed) | "error: Terminal is dumb, but EDITOR unset", exit 1 |
| D7 | task-worktree merge: the CHANGE-BUSY remedy for a rebase concludes it with no editor, exactly as printed (finding 90) | "error: Terminal is dumb, but EDITOR unset", exit 1, rebase still in progress |
| D7 | task-worktree start: the CHANGE-BUSY remedy for a rebase, a merge, and the merge of the task named leaves it to the dispatcher, and a dispatched subagent stops and reports (three tests, finding 92) | the line told the agent that runs start to conclude or abort the operation, including `git merge --abort` |
| D7 | merge-preflight: `--local-base` fails BASE-MERGED when a tag named like the base branch is merged and the branch is not; UNITS reads the impact range from the branch (two tests, finding 91) | BASE-MERGED passed at exit 0 with "refname 'main' is ambiguous"; UNITS read the tag and failed MISSING-TEST |
| D8 | check-trace: an exit 2 after a collected violation still prints the violation | green on arrival; failed with the EXIT trap's `cat` removed (only the scan error printed, no MISSING-TEST line). That was in round 2; round 6 removed the trap and the temporary file, and the test now covers violations printed as they are found |

Mutations `M21`, `M24` and `M54` of `2026-08-22-id-tokens` quoted the removed
`check-ids.sh` stderr lines. They were re-cut; each applies and fails tests.

## What was wrong, and what was built

Change 1 showed that skill text describing a script's behaviour draws review
findings, and that most of `merge-change`'s length was procedure. This change
moves three procedures into scripts. `task-worktree.sh` creates, merges back
and retires a nested task worktree. `merge-preflight.sh` runs `merge-change`'s
mechanical checks in order and stops at the first failure. `check-trace.sh`
and `check-ids.sh` print one `fix <RULE>:` line per rule that fired, which
replaces check-traceability's fix table. `merge-change` now points at the
scripts and is within the 2,000-word ceiling, which `tests/skills.bats` checks. `finish-merge.sh` no longer
claims a removal on the path that removed no worktree.

## Review

The dispositions of rounds 1 to 3 name the commands as they were then. After
round 4, `task-worktree.sh finish` was renamed `merge` and `finish --no-merge`
was renamed `remove`; the behaviour each disposition describes is unchanged.

### Round 1

**finding-1**: requirement — `task-worktree.sh finish review` merges any reviewer commit into the change branch. I reproduced this: a reviewer commit became `Merge branch 'ch-review' into ch`. `skills/merge-change/SKILL.md:167-171` tells the dispatcher to run `git log` and "read it before `finish`, which merges it", and `references/rationale.md` ("a review commits nothing") says the same. Neither the skill nor the script offers a way to retire a review worktree without merging its commits. Reading the commit does not stop it entering the change, so reviewer-authored work can reach the squash, against the independence 6a exists for. The skill needs a way to retire the worktree without merging when the log is not empty, or `finish` must refuse a review tag that has commits.
disposition: Fixed. `task-worktree.sh finish --no-merge <tag>` merges nothing, and exits 1 with `fix TASK-HAS-COMMITS:` and changes nothing when the task branch has commits; step 6a, `references/rationale.md` and `references/cleanup-rejections.md` retire the review worktree with it. "task-worktree finish --no-merge: rejects a task branch with a commit and changes nothing" reddens without it.

**finding-2**: requirement — `skills/worktree-discipline/SKILL.md:224-226` says a review task worktree "has nothing to merge — `task-worktree.sh finish` removes the worktree and its task branch as they are". The script merges whatever the branch holds (`scripts/task-worktree.sh:180`), so "as they are" holds only when the branch has no commits.
disposition: Fixed. The passage names `finish --no-merge`, which rejects a branch with commits.

**finding-3**: requirement — `skills/check-traceability/SKILL.md:190-191` says every run of `check-trace.sh` and `check-ids.sh` prints its fix lines "after the violation lines and before `checked:`". `check-ids.sh` prints no `checked:` line. A run of either script that exits 2 part-way prints no fix lines (`check-trace.sh:348` trap, `check-ids.sh` gr_die). "Every run" should be narrowed to runs that complete.
disposition: Fixed. The sentence covers runs that complete, and places the fix lines before the summary lines, which `check-ids.sh` does not print.

**finding-4**: requirement — the header of `scripts/merge-preflight.sh:42-44` says the script exits 2 "when a tool the checks run exits 2" (`gr_fail`, line 103). The plan's T4 says a failing check exits 1. No test in `tests/merge-preflight.bats` covers the exit-2 case: the P5 mutation, which turns it into exit 1, survives all 21 tests. Merge-change step 4 does not mention it either. Either the plan and skill should state it and a test should cover it, or the behaviour should go.
disposition: Kept and covered. "merge-preflight: a tool that exits 2 makes the pre-flight exit 2 with the tool's output" fails with the reviewer's mutation applied; step 4 states that exit 1 is a failed check and exit 2 a usage or environment error.

**finding-5**: record — the plan header of `docs/plans/2026-09-29-agent-first-skills-change-2.md` says "`tests/check-trace.bats` is not touched by this change", and T1's Deviations say "One line … changed after all". The diff also replaces that file's `setup()` fixture (19 lines) with `write_traced_docs`. That edit is in b0bcddf, a deslop commit, and those are hunks the open `assertion-gate` change may also edit. The plan has no status for b0bcddf at all. Its "After T6" section still describes the deslop pass as future work, although b0bcddf has done it: it moved `gr_nested_worktrees` into `scripts/lib.sh` and edited `check-trace.sh`, `finish-merge.sh`, `task-worktree.sh`, `merge-preflight.sh`, three skill texts and six test files. The T6 note "Left for the deslop pass: …" is also stale, because both items are done.
disposition: Fixed in the plan (`5e1a1ba`). The header names both edits to `tests/check-trace.bats` and records that `git merge-tree` of `b0bcddf` with `assertion-gate` exits 0. "After T6" records the deslop pass and `b0bcddf`, and the T6 note states that both leftovers were fixed.

**finding-6**: record — T3's interface in the plan says `start` copies "every ignored top-level entry". The script copies every entry `git ls-files --others --ignored --directory` lists, which includes nested ones such as `tests/.bats-core`. It skips a target that already exists (`scripts/task-worktree.sh:128-141`). The script header ("every ignored entry") is accurate; the plan is not.
disposition: Fixed in the plan (`5e1a1ba`): "every ignored entry", nested ones included, a target that already exists skipped.

### Round 2

**finding-7**: code — the pre-flight's `NESTED-WORKTREE` remedy tells you to merge a review worktree. `scripts/merge-preflight.sh:207` prints "run task-worktree.sh finish <tag> for each .worktrees/$branch-<tag> listed above" for every nested worktree. For a review worktree, plain `finish` merges the reviewer's commits into the change branch, which is the defect round 1 finding-1 fixed. `skills/merge-change/SKILL.md` step 4 says "Follow the `fix` lines", so a leftover review worktree found at 6c is merged, not retired with `finish --no-merge`. Step 6d and `references/cleanup-rejections.md` get this right; the script does not. The tool output printed above that fix line gives a second, different remedy: `scripts/finish-merge.sh:182-184` (the `--check` message) still says "merge or abandon the branch, then `git worktree remove` the path", which is the hand procedure this change replaced. No test pins either remedy text.
disposition: Fixed. The pre-flight's fix line names `task-worktree.sh finish --no-merge review` for the review worktree and `finish <tag>` for a task worktree; the `--check` message gives the same remedy, and so does guard 4's rejection on the post-squash run, which had a second copy of the old text; both now print it from one function, `gr_nested_remedy`, and "finish-merge: guard 4's rejection names the task-worktree.sh remedy, as --check does" reddens on the old guard 4 text. "merge-preflight: NESTED-WORKTREE names finish --no-merge review for the review worktree" and "finish-merge: --check names the task-worktree.sh remedy for each kind of nested worktree" redden on the old text.

**finding-8**: requirement — BASE-MERGED cannot honour a remote that the project put out of scope. `scripts/merge-preflight.sh:140-147` requires `origin/<base>` to be an ancestor of HEAD whenever that ref exists. `skills/merge-change/SKILL.md` step 1 allows a project to put the remote out of scope, and this repository's `AGENTS.md` non-negotiable 5 requires it ("no reading `origin/<branch>` as though it were authoritative"). The pre-flight has no mode for that case. If `origin/<base>` is ahead of local base, the check fails with the remedy "merge the base branch … as merge-change step 1 states", and that cannot be met without consulting origin. It passes here today only because `origin/main` (70cd996) is behind local `main` (ff6bb34). D7 names "the base merge" and T4 specifies origin, but no decision covers the out-of-scope case, and the skill does not say the pre-flight reads origin.
disposition: Fixed. `merge-preflight.sh --local-base` checks the local base only and prints `ok (local base only)`; step 4 states that the pre-flight reads `origin/<base>` otherwise and that a project with the remote out of scope passes the flag. "merge-preflight: --local-base passes BASE-MERGED with origin/<base> ahead of HEAD, and prints that it did" reddens without it.

**finding-9**: requirement — `README.md:137` and `templates/AGENTS-block.md:104` document `task-worktree.sh start TAG | finish TAG` and leave out `finish --no-merge`. The script's usage line (`scripts/task-worktree.sh:4`) has that form, and step 6a requires it for the review worktree. The README row describes `finish` only as "merge its branch into the change branch … and remove the worktree", so both documents understate what the script does and give no safe way to retire a review.
disposition: Fixed. Both rows name `finish --no-merge` and what it does, and the `merge-preflight.sh` rows name `--local-base`.

**finding-10**: requirement — a claim in the `check-trace.sh` header has no test. Lines 343-349 send stdout to a temp file, and the header says "An exit before the summary (exit 2 from any gr_die below) still prints what was collected". I removed the `cat "$violation_file" >&3` from the EXIT trap and `tests/check-trace.bats` stayed fully green (0 not ok). `tests/remedies.bats` has no exit-2 case either. `main` printed violations before an exit 2 directly; this change moved that behaviour into a new mechanism with nothing testing it (AGENTS.md: every behaviour change to a script needs a bats test).
disposition: Fixed. "check-trace: an exit 2 after a collected violation still prints the violation" collects a MISSING-TEST line, then fails the reference scan; it reddens with the reviewer's mutation applied.

**finding-11**: record — the Gaps section of `docs/verification/2026-09-30-agent-first-scripts.md` says "`check-traceability` is 2,473 words". The tree has 2,490 (`wc -w`, the test's own count), and has since `81611fc`; 2,473 was true from `7522636` to `b0bcddf`. The merge-change figure of 1,996 is correct.
disposition: Fixed (`3f0b210`): the Gaps line states 2,490.

**finding-12**: record — the same Gaps section says "`tests/check-ids.bats:71` contains a literal draft token that `main` already reports". That file has many such tokens that `main` reports (for example lines 20, 27, 31, 405, 429, 572, 592, 797). Line 71 is not in any hunk this change touched. As worded, the gap reads as a single leftover.
disposition: Fixed (`3f0b210`): the gap names the file's many inherited tokens, none in a hunk this change touched.

### Round 3

**finding-13**: code — A review branch with commits cannot be retired by any documented route. `scripts/task-worktree.sh:194-201`: `finish --no-merge` exits 1 with `fix TASK-HAS-COMMITS: … read each one and record it as a finding. Do not merge them.` and gives no next step. `skills/merge-change/SKILL.md:173-174` says "Record each commit as a finding; never merge it" and also stops there. The worktree therefore stays registered. At 6c, `NESTED-WORKTREE` fails, and its fix line (`scripts/merge-preflight.sh:219`) says to run `finish --no-merge review`, which rejects again. Plain `finish` merges the commits, which 6a forbids. The only way out is `git worktree remove` / `git branch -D` by hand, and neither the skill nor the scripts state it. Reproduced in a fixture: one reviewer commit, then `finish --no-merge review` exits 1 with the line above.
disposition: Fixed. `task-worktree.sh discard <tag>` lists the branch's commits, removes the worktree without `--force` and deletes the branch with `-D`; it rejects a dirty or nested task worktree and changes nothing. The TASK-HAS-COMMITS fix line, step 6a and `worktree-discipline` name it after recording the commits as findings. "task-worktree discard: lists the commits, removes the worktree and the branch, and the change branch does not move" reddens without it.

**finding-14**: code — After the squash, guard 4 names `task-worktree.sh finish <tag>` for a task worktree (`scripts/finish-merge.sh:81-89` `gr_nested_remedy`, and `skills/merge-change/references/cleanup-rejections.md:13`). When that task branch has commits the change branch lacks, the remedy merges unreviewed work into the change branch, and the re-run of `finish-merge.sh` then fails guard 2. Reproduced in a fixture (signed squash, nested `my-change-t1` with one commit): the first run was guard 4's rejection; `task-worktree.sh finish t1` then exited 0 and merged `src/late.txt`; the second run exited 1 with "HEAD and my-change differ … redo the squash". Before the squash that text is right. After the squash it is wrong for any task branch that was never merged.
disposition: Fixed. `gr_nested_remedy` takes a mode; after the squash it names `finish --no-merge <tag>` for every nested worktree, and `discard <tag>` for a branch whose commits are not in the squash. The pre-squash `--check` remedy is unchanged. `references/cleanup-rejections.md` matches. "finish-merge: guard 4 after the squash names finish --no-merge and discard for a task branch with a commit" reddens on the old remedy.

**finding-15**: code — The `TASK-NESTED` remedy still gives the hand-written procedure. `scripts/task-worktree.sh:189-190` says "merge or abandon each worktree listed above and remove it". Every other remedy from round 2 (finding 7) now names `task-worktree.sh finish`. A worktree nested inside a task worktree was made by `start` run there, so its remedy is `task-worktree.sh finish <tag>` run from the task worktree.
disposition: Fixed. The remedy names `task-worktree.sh finish <tag>` run from the task worktree that contains it; "task-worktree finish: rejects a task worktree with a worktree registered inside it" asserts it.

**finding-16**: code — The "merged unsigned" claim has no test. D7 procedure 1, `README.md:137` and the script header all state it. I removed `-c commit.gpgsign=false` from `scripts/task-worktree.sh:202` and all 23 tests in `tests/task-worktree.bats` still passed. No fixture sets `commit.gpgsign=true`, and a signed-by-default project is exactly where this matters (a key prompt per task merge).
disposition: Fixed. "task-worktree finish: merges unsigned when commit.gpgsign is true and signing fails" sets `commit.gpgsign=true` with a stub signer that exits 1; it fails with the reviewer's mutation applied.

**finding-17**: code — The pre-flight's "IDS — check-ids.sh, with no --allow-draft-files" has no test (`scripts/merge-preflight.sh:18,198`; plan T4 check 3). I added `--allow-draft-files` to the IDS call and all 27 tests in `tests/merge-preflight.bats` still passed. The only IDS test (`tests/merge-preflight.bats:187`) uses a `DRAFT-ID`, which fails under either flag. A `DRAFT-FILE` fixture is needed.
disposition: Fixed. "merge-preflight: IDS fails on a draft-named ledger file, because check-ids.sh runs without --allow-draft-files" fails with the reviewer's mutation applied.

**finding-18**: requirement — `README.md:137` says `start` copies "the ignored entries the verify commands need", and D7 procedure 1 says "copies the ignored artifacts the verify commands need". The script copies every ignored entry except `.worktrees/` and `.claude/`, with no selection and no opt-out (`scripts/task-worktree.sh:11-15,142-155`). Examples: a multi-GB build directory, an `.env` holding secrets, a virtualenv whose scripts name the change worktree's paths. The header states this accurately, but no decision covers copying everything, and the README row reads as a selection.
disposition: Ruled: the script keeps copying every ignored entry. The task worktree is on the same machine, inside the change worktree, so no copy crosses a trust boundary, and a selection list is configuration nobody maintains. The `README.md` and `templates/AGENTS-block.md` rows state exactly what is copied. D7's "the ignored artifacts the verify commands need" is a subset of what is copied.

**finding-19**: record — The plan's interface sections are behind the tree: T3 (`docs/plans/2026-09-29-agent-first-skills-change-2.md:201-234`) has no `finish --no-merge`; T4 (`:267-294`) has no `--local-base`, and says the failing check "exits 1" (`:274-275`), and gives only three exit-2 cases (`:293-294`), where the script also exits 2 when a tool it runs exits 2 (`scripts/merge-preflight.sh:46-48,106-110`). The status word counts disagree with the record: T2 says check-traceability "is 2,473 words" (`:119`) and T6 says merge-change is "1,984 words" (`:359`); the tree and record say 2,490 and 1,996.
disposition: Fixed in the plan (`ee9318a`): T3 names `finish --no-merge` and `discard`; T4 names `--local-base`, every exit-2 case and `skipped (<reason>)`; both word counts are stated as measured at their task, with the later figure beside each.

**finding-20**: record — The plan says every new test body has no `[[ ]]` (`docs/plans/2026-09-29-agent-first-skills-change-2.md:30-32`). The two round 2 tests in `tests/finish-merge.bats:561-581` and `:664-682` use `[[ "$output" == … ]] || { …; false; }`. The `|| false` makes the assertions work, so the plan's claim is what is wrong, not the tests.
disposition: Fixed in the tests, so the plan's rule is true: both assertions are rewritten without `[[ ]]`, with the same checks.

**finding-21**: record — The ledger cites the fix for both items by a commit subject, "fix: finish-merge.sh names what it removed when the branch deletion fails" (`docs/problems/2026-09-29-inherited-cleanup-claims.md:17-20,29-35`). That commit is task commit `ffd6ef6`, which the squash does not bring to `main`. Once merged, the citation names no commit on `main`. Other resolved items in `docs/problems/` describe the fix itself, or cite a hash that is on `main`.
disposition: Fixed (`ee9318a`): both items cite the change `agent-first-scripts` and its plan's task T5, and describe the fix.

### Round 4

**finding-22**: code — `task-worktree.sh discard <tag>` and `finish <tag>` act on any branch named `<change-branch>-<tag>`, wherever its worktree is registered. They do not check that the registered path is `$task_path`, the path inside the change worktree (`scripts/task-worktree.sh:180-182`, and `worktree_of_branch` at :108-116). I reproduced this in a scratch repo with signing off. The primary is on `main`, the change worktree `.worktrees/ch` is on `ch`, and a sibling worktree `.worktrees/ch-other` is on `ch-other` with one commit. Running `discard other` from `ch` exited 0. It printed "worktree removed: …/.worktrees/ch-other" and "branch deleted: ch-other": the sibling worktree was removed and its branch deleted with `-D`, commit included. Plain `finish other` would merge that branch into `ch`. The header (lines 7-9) and step 1 of `worktree-discipline` define the task worktree as the nested path. The script does not enforce this, and no test covers a branch whose worktree is registered outside the change worktree.
disposition: Fixed. Every command checks the registered path and exits 1 with `fix TASK-NOT-NESTED:` and changes nothing when it is not the nested path. "task-worktree: merge, remove and discard reject a task branch checked out outside the change worktree" reproduces the reviewer's case and reddens without the check.

**finding-23**: code — When `finish --no-merge` rejects, the TASK-DIRTY and TASK-NESTED remedies drop `--no-merge`. After `set -- "$1" "$3"` (`scripts/task-worktree.sh:72-75`), `$subcommand` is `finish`, so :190 and :197 print "run finish review again". I reproduced this: with an untracked file in the review worktree, `finish --no-merge review` printed "fix TASK-DIRTY: commit or discard the changes in …/ch-review, then run finish review again." If the operator commits and then follows that line, the reviewer's commit is merged into the change branch. Round 1 finding 1 fixed exactly that defect. No test asserts the TASK-DIRTY or TASK-NESTED remedy text under `--no-merge`.
disposition: Fixed by the maintainer's ruling after this round: no fix line merges. `task-worktree.sh` has `start`, `merge`, `remove` and `discard`; `finish` and `--no-merge` are usage errors; each rejection names the command that was run. "task-worktree remove: the TASK-DIRTY fix line names remove" reddens with the line mutated.

**finding-24**: requirement — Step 6a of `skills/merge-change/SKILL.md`, at :180-182, tells the dispatcher to handle a dirty review worktree by deleting the scratch and running "`finish` again". Step 6d (:220-221) defers to that remedy. Both name plain `finish` for the review worktree, where :170 and the rest of 6a require `finish --no-merge review`.
disposition: Fixed. Step 6a and step 6d name `remove`; "merge-change: step 6d and the cleanup reference name remove and discard, and no remedy merges" reddens on the old text.

**finding-25**: code — The after-squash remedy still offers a merge for a nested worktree that `task-worktree.sh` did not create. `gr_nested_remedy` prints "merge or abandon its branch, then `git worktree remove` the path" in both modes (`scripts/finish-merge.sh:103-105`), and `references/cleanup-rejections.md:13` says the same after the squash. After the squash, merging that branch into the change branch makes the re-run fail guard 2. Round 3 finding 14 was this defect, fixed only for task-worktree-created worktrees. No test covers the after-squash text for this case.
disposition: Fixed. For such a worktree both modes name the git commands that do not merge: record its commits, `git worktree remove <path>` without `--force`, `git branch -D <branch>`. "finish-merge: guard 4 after the squash names the plain git commands for a worktree task-worktree.sh did not create" pins it.

**finding-26**: requirement — At step 6c, the pre-flight's NESTED-WORKTREE remedy merges an unreviewed task branch and then passes. It says "task-worktree.sh finish <tag> for a task worktree …, then run the pre-flight again" (`scripts/merge-preflight.sh:219`); the `--check` text (`scripts/finish-merge.sh:94-95`) and step 6d say the same. A task worktree left over at 6c whose commits the change branch lacks was never gated or reviewed. `finish` merges it, and on the second run CLEAN-TREE, IDS, TRACE, REVIEW (the record is unchanged) and NESTED-WORKTREE all pass. The squash then contains commits that neither the 6a reviewer nor the step 2 gate saw. The general rule in Steps ("Then rerun from step 1") is not repeated at 6c or 6d, and the fix line says to rerun the pre-flight only. I derived this from the code and did not reproduce it end to end.
disposition: Fixed. The NESTED-WORKTREE and `--check` remedies name only `remove` and `discard`, and state that commits `remove` rejects were never gated or reviewed: record and discard them, or return to `develop-change` and rerun `merge-change` from step 1 to keep them. After the squash, keeping them is a new change. "merge-preflight: NESTED-WORKTREE names remove and discard, and no merging command" reddens on the old line.

**finding-27**: code — The TASK-CONFLICT remedy says "resolve the conflicts … and commit the merge" (`scripts/task-worktree.sh:216`) without `-c commit.gpgsign=false`. In a project that signs by default, that commit asks for the key or fails with "gpg failed to sign". Keeping task merges unsigned is the reason for the unsigned merge that the header and D7 state. The conflict test (`tests/task-worktree.bats:210`) does not check the remedy text.
disposition: Fixed. The remedy names `git -c commit.gpgsign=false commit`, then `remove <tag>`; the conflict test asserts it and runs the remedy as stated.

**finding-28**: code — Two remedy claims have no test. (a) The IDS remedy text was altered (`gr_ids_remedy` "fix" changed to "ignore", `scripts/merge-preflight.sh:162`) and all 28 tests in `tests/merge-preflight.bats` still pass. (b) `task-worktree.sh` claims its removal is "`git worktree remove` without --force" (header :33, README row). `--force` was added at :231 and all 29 tests in `tests/task-worktree.bats` still pass, because the pre-check with `git status --porcelain` rejects first. (b) differs in behaviour only for locked or submodule worktrees, so the stated claim is not what is tested.
disposition: Fixed. (a) "IDS fails on a draft ID" pins the IDS fix line. (b) Tests with a submodule worktree, which `git status` reports clean and plain removal rejects, fail with `--force` added; tests with a locked worktree fail with `--force --force`.

**finding-29**: record — The record says "`merge-change` now points at the scripts and is 1,996 words" (`docs/verification/2026-09-30-agent-first-scripts.md`, "What was wrong, and what was built"). The tree has 2,000 (`wc -w`), and has since `4e45b08`, the round 3 fix: `ad9628f` had 1,984, `81611fc` and `18eca64` had 1,996. The file is exactly at the ceiling. Plan line 371 ("1,996 after the round 1 and 2 fixes") is true as a dated figure, but the tree is now at 2,000.
disposition: Fixed (`07aa525`): the record states that `merge-change` is within the ceiling, which `tests/skills.bats` checks, rather than a count the next edit makes false.

**finding-30**: record — The disposition of round 3 finding 20 says the tests were fixed "so the plan's rule is true" (plan :30-32: no `[[ ]]` in any new test body). Three `[[ ]]` assertions remain in the new file `tests/merge-preflight.bats`, at :174, :283 and :285. They were added in `18eca64`. Each has `|| { …; false; }`, so they do fail, but the plan's claim and the disposition are both false of the tree.
disposition: Fixed. The three assertions are rewritten without `[[ ]]`.

### Round 5

**finding-31**: code — Under `merge`, two fix lines name the merging command. `scripts/task-worktree.sh:203` (TASK-DIRTY) prints "commit or discard the changes in <task wt>, then run merge t1 again", and `:210` (TASK-NESTED) ends "then run merge t1 again". Both are `$subcommand`, which is `merge` here. I reproduced both in a scratch repo with signing off. TASK-DIRTY is the hazard: the dirty state is uncommitted work the subagent left after a green report, so following the line ("commit … then run merge again") merges work that no gate or report covered. This contradicts the script's own header, `scripts/task-worktree.sh:20-21` ("No fix line printed by this script or any other names it"); `README.md:137` ("no fix line names it"); `templates/AGENTS-block.md` ("never as a remedy"); `skills/worktree-discipline/SKILL.md` ("no remedy for a rejection names it"); and the ruling at plan `docs/plans/2026-09-29-agent-first-skills-change-2.md:501-503`. `tests/task-worktree.bats:215` asserts `output_has "run merge t1 again"`. The test at `:232-247` asserts `output_lacks "task-worktree.sh merge"`, which passes only because the line reads "run merge t1 again" without the script name. The finding-24 disposition ("each rejection names the command that was run") is the origin.
disposition: Fixed. Under `merge`, TASK-DIRTY states that the changes are not covered by the task's dispatch report and the task goes back to its subagent (`develop-change`); TASK-NESTED ends the same way. Under `remove` and `discard` each line still names the command that was run. The retargeted TASK-DIRTY test and "task-worktree merge: the TASK-NESTED fix line returns the task to its subagent and names no merge" assert that neither line names `merge`.

**finding-32**: code — The TASK-NESTED remedy (`scripts/task-worktree.sh:210`) names only `task-worktree.sh remove <tag>` / `discard <tag>`, run from the task worktree. A worktree nested in a task worktree that `task-worktree.sh` did not create has no `<change>-<tag>` branch, so `remove <tag>` stops at TASK-MISSING. Reproduced with `git -C <task wt> worktree add .worktrees/inner -b inner`: the fix line gives no usable command. `gr_nested_remedy` in `scripts/finish-merge.sh` covers this case with the non-merging git commands (round 4 finding 25); this remedy does not.
disposition: Fixed. TASK-NESTED gives the two cases `gr_nested_remedy` gives, in the same wording: `remove` or `discard` for a `.worktrees/<task-branch>-<tag>` path, and for any other, record its commits, `git worktree remove <path>` without `--force` and `git branch -D <branch>`. "task-worktree merge: the TASK-NESTED fix line covers a worktree task-worktree.sh did not create" reproduces the reviewer's case.

**finding-33**: code — Two fail-closed guards in `scripts/merge-preflight.sh` have no test: `:179-181`, where a failed awk on the impact set's unit column would otherwise gate no unit and pass, as the comment at `:177-178` states; and `:119-121`, `gr_warnings`' awk failure. I replaced each `|| gr_fail …` with `|| true` (mutations M10 and M12). `tests/merge-preflight.bats` stayed fully green both times (0 not ok). The strict-awk test (`:450`) uses an awk that works, so it never reaches either path. AGENTS.md requires a bats test for every behaviour change to a script.
disposition: Fixed. Two tests put a stub `awk` on `PATH` that fails only for the guarded call; each fails with the reviewer's mutation applied.

**finding-34**: requirement — `skills/merge-change/references/rationale.md:145` states "Retiring a task worktree merges its branch into the change branch." That describes the retired `finish`. Retiring is now `remove` or `discard`, and neither merges; only `merge` merges. The rest of the paragraph (`:146-150`) argues from that premise.
disposition: Fixed. The paragraph states that the dispatcher's merge after a green report is the only step that merges, and that removing or discarding a worktree merges nothing.

**finding-35**: record — The plan's T3 interface is behind the round 4 rename: `docs/plans/2026-09-29-agent-first-skills-change-2.md:204-207` lists `task-worktree.sh finish <tag>`; `:209-213` describes `finish --no-merge <tag>`; `:233-243` specifies `finish`; `:249-252` gives finish-based RED cases. `finish` and `--no-merge` are now usage errors (`tests/task-worktree.bats:385`). `:214-215` is an empty fenced code block left in the text. The finding-19 disposition says the T3 interface was brought up to the tree. The record's note on the renames (`docs/verification/2026-09-30-agent-first-scripts.md:145-147`) covers the dispositions, not the plan.
disposition: Fixed (`0390bb0`). T3's interface lists `start`, `merge`, `remove` and `discard`, states the renames, and its specification and RED cases use the current names; the empty code block is gone. Status lines that record a merge done with `finish` before the rename are history and stay.

**finding-36**: record — The ruling sentence at plan `:503`, "Every fix line in every script, skill and reference file names only `remove` or `discard`", is false of the tree read literally: `check-trace.sh` and `check-ids.sh` fix lines name other remedies; BASE-MERGED (`scripts/merge-preflight.sh:154`) states "merge the base branch into $branch"; TASK-CONFLICT (`scripts/task-worktree.sh:231`) states "conclude the merge with git -c commit.gpgsign=false commit". Those lines are correct work. The sentence needs to be scoped to remedies for a task or review worktree, so that a later reviewer does not read them as violations.
disposition: Fixed (`0390bb0`). The ruling covers remedies for a task or review worktree, and names the remedies outside its scope.

**finding-37**: requirement — Formatting. `skills/develop-change/SKILL.md:87` is a blank line in the middle of a sentence ("…`task-worktree.sh merge <tag>` in" / blank / "the change worktree, which merges…"), added in `4234d6e`; it splits the bullet into two paragraphs. `skills/merge-change/SKILL.md` step 6d has two consecutive blank lines before "A worktree registered anywhere else".
disposition: Fixed. The sentence is joined, and step 6d has one blank line.

### Round 6

**finding-38**: code — Since this change, `check-trace.sh` cannot run without `mktemp` and a writable `$TMPDIR`. `scripts/check-trace.sh:346-348` sends every violation line to `mktemp "${TMPDIR:-/tmp}/check-trace.XXXXXX"` and calls `gr_die` when that fails. I reproduced it in a scratch repository with a clean config: with `TMPDIR=/nonexistent-dir`, `main`'s check-trace.sh exits 0, and this branch prints "mktemp: mkstemp failed … guardrails: mktemp failed: the violation lines cannot be collected" and exits 2. That makes the TRACE check of the pre-flight exit 2 as well. `mktemp` is not a POSIX utility, and AGENTS.md "Rules" allows no dependencies beyond git, grep, awk and sed. The only other use, `check-signing.sh:301`, falls back when `mktemp` fails; this one is fatal. No decision covers the dependency and no test covers the failure. The trap is EXIT only (:348), so an interrupted run also leaves the temporary file behind. D8's ordering does not need a file: the fired rules can be collected in a variable.
disposition: Fixed. No temporary file: each violation print site calls `print_violations`, which prints the line and adds its rule to `fired_rules`, and the fix lines print just before the summary. "check-trace: a TMPDIR that does not exist changes neither the exit nor the fix lines" reddened on the old script (exit 2).

**finding-39**: code — Abnormal input: `task-worktree.sh start` fails on some ignored entry names, after it has already created the worktree. `scripts/task-worktree.sh:138-167` passes each `git ls-files --others --ignored --directory` entry straight to `cp -R "$entry" …`. A name that begins with `-` is read by cp as an option. git C-quotes a name that contains `"`, a backslash or a tab, even with `core.quotePath=false`, so cp is given a path that does not exist. I reproduced both in a scratch repository with signing off. An ignored `-n.log` gave "cp: illegal option -- ." and an ignored `q"uote.log` gave `cp: "q\"uote.log": No such file or directory`. Each time `start` exited 1 with "the worktree was created … but an ignored entry was not copied". A second `start` then rejects with TASK-EXISTS, so in such a project `start` can never exit 0. `cp -R -- …` would fix the first case, and `ls-files -z` the second.
disposition: Fixed. The list is read with `ls-files -z`, converted with `tr`, so names are not C-quoted; cp is given `--`; a name containing a newline is skipped with a stated reason. "task-worktree start: copies an ignored entry whose name begins with - or contains a quote" and "… skips an ignored entry whose name contains a newline, and states it" reddened on the old script. `tr` is outside the AGENTS.md tool list; `check-trace.sh` already uses it.

**finding-40**: code — Two script behaviours have no test. I mutated a copy under $TMPDIR and ran `tests/task-worktree.bats`: (a) I deleted the `(-*)` tag rejection at `scripts/task-worktree.sh:98-99`, which the header claims at :66. All tests still pass. Every `--no-merge` case in the file is three arguments, so it is rejected by the argument count first. (b) At `:169-173` I changed the copy-failure `exit 1` to fall through to exit 0. All tests still pass. AGENTS.md requires a bats test for every behaviour change to a script.
disposition: Fixed. "task-worktree: start and remove reject a tag that begins with -" and "task-worktree start: an ignored entry that cannot be copied exits 1 and names the worktree" each redden with the reviewer's mutation applied.

**finding-41**: record — The plan states one remedy form for "every script this change touches": `fix <RULE>: <one imperative sentence, at most 200 characters>` (`docs/plans/2026-09-29-agent-first-skills-change-2.md:38-46`). The tree does not follow it outside check-trace and check-ids: the NESTED-WORKTREE remedy (`scripts/merge-preflight.sh:219`) is a 563-character source line with five sentences; TASK-NESTED (`scripts/task-worktree.sh:226`) is 465 characters, before path substitution; `finish-merge.sh` prints no `fix` line at all. Only `tests/remedies.bats:47-51` (`remedies_within_limit`) enforces the limit, and only for check-trace and check-ids. The longer remedies are the result of review rounds 3 to 5 and appear intended. The plan should scope the form to `check-trace.sh` and `check-ids.sh`, or the other scripts should conform.
disposition: Fixed in the plan (`e0e38c1`): the one-sentence form is scoped to `check-trace.sh` and `check-ids.sh` (D8); the plan states that the other two scripts share the `fix <RULE>:` prefix with longer remedies, and that `finish-merge.sh` prints none.

**finding-42**: requirement — Formatting. `skills/merge-change/references/cleanup-rejections.md:14` is a blank line inside the rejection table, added in `4234d6e`. It ends the table, so the next three rows (`git worktree remove` rejected it, the branch-deletion row that resolves `PR-sa5y4k`, and the exit-2 row, lines 15-17) render as plain pipe text. `README.md:138-139` and `templates/AGENTS-block.md:114-115` each have two blank lines in a row after the new rows. This is the same class of defect as finding-37.
disposition: Fixed. The blank line and the doubled blank lines are removed, and "skill references: no blank line separates two rows of one table" now checks every reference file.

**finding-43**: record — The plan header (`docs/plans/2026-09-29-agent-first-skills-change-2.md:11`) states "This change adds three scripts and changes the output of two." `git diff --name-status main...agent-first-scripts` shows two added scripts, `merge-preflight.sh` and `task-worktree.sh`. Output changed in three: `check-trace.sh`, `check-ids.sh` and `finish-merge.sh`.
disposition: Fixed (`e0e38c1`): the header names the two added scripts and the three whose output changed.

**finding-44**: record — T6's specification at plan `:410-411` still states "Fix dispatches and the review worktree use `task-worktree.sh start` and `finish`". That retires the review worktree with the merging command the ruling forbids. The disposition of finding-35 says the specification and RED cases were updated to the current names, but only T3's were. This is a step instruction, not one of the history status lines the disposition exempts.
disposition: Fixed (`e0e38c1`): T6 names `merge` for fix dispatches and `remove` for the review worktree, and the names they had when T6 was run.

### Round 7

**finding-45**: code — The guard for a failed ignored-entry listing has no test. That guard is the `|| printf '/\000'` sentinel and the `case "$ignored"` check, at `scripts/task-worktree.sh:145-150`. Round 6 rewrote it as a sentinel scheme, and the header comment at :143-144 states the behaviour. I ran two mutations on a copy under $TMPDIR, and `tests/task-worktree.bats` passed in full (0 not ok) after each: (M1) I deleted `|| printf '/\000'`; (M2) I deleted the whole `case` block. Without the guard, a failed `git ls-files` is not detected: the entry `/` becomes the worktree's own path, which already exists, so it is skipped. `start` then exits 0 and copies nothing. I checked the guard itself with a stub git whose `ls-files` prints one entry and exits 128. Under both /bin/sh (bash 3.2) and dash it exits 2 with "git ls-files failed…" and creates no worktree. The guard works, but no test covers it, and AGENTS.md requires a bats test for every behaviour change to a script.
disposition: Fixed. "task-worktree start: a failed listing of ignored entries exits 2 and creates no worktree" uses the reviewer's stub git; it fails with each of the reviewer's two mutations.

**finding-46**: code — An ignored entry whose name contains the byte \001 is reported as containing a newline, and `start` skips it at exit 0 (`scripts/task-worktree.sh:146,151,171-174`). `tr` uses \001 to mark a newline inside a name, so a name that already contains \001 cannot be told apart from one with a newline. I reproduced this in a scratch repository with signing off: an ignored file named `ctl<0x01>x.bak` printed "task-worktree: not copied, the name contains a newline: ctl?x.bak", the file was not copied, and `start` exited 0, under both /bin/sh and dash. Names containing a tab, a backslash, a double quote or a leading `-` all copied correctly. The case is rare. The fix is to make the message state what was detected (a newline or a \001 byte), or to reject such a name instead of skipping it.
disposition: Fixed. The message states "the name contains a newline or a \001 byte", and "task-worktree start: skips an ignored entry whose name contains the byte \001, and states it" reddens on the old message.

**finding-47**: requirement — Several places say every ignored entry is copied, and since round 6 that is not true. The script header (`scripts/task-worktree.sh:11-15`), the `README.md:137` row, the `templates/AGENTS-block.md` row and the plan's T3 specification (`docs/plans/2026-09-29-agent-first-skills-change-2.md`, the `start` bullets) all state that `start` copies "every ignored entry … except `.worktrees/` and `.claude/`". Since round 6 it skips a name that contains a newline, and exits 0 when it does. Only a comment inside the code (:142, :171) states this. The finding-18 disposition says the README and AGENTS-block rows "state exactly what is copied", and that is no longer true. Separately, the T3 `start` bullet lists the exit-2 tags as "empty or contains `/` or whitespace" and leaves out the `-`-prefixed tag that round 6 added (header :66, tested at `tests/task-worktree.bats:112`).
disposition: Fixed. The script header, the README row and the `templates/AGENTS-block.md` row state the skip; the plan's T3 `start` bullets (`6e81201`) state the skip, the `-` tag and the failed listing.

**finding-48**: requirement — The merge-change skill forbids the `-D` that its own remedies prescribe. Done when (`skills/merge-change/SKILL.md:299-300`) requires "nothing was removed with `--force` or `-D` by hand", and the Red flags row at :292 says that for a rejected cleanup "`--force` and `-D` destroy it". The step 4/6c NESTED-WORKTREE fix line (`scripts/merge-preflight.sh:219`) says otherwise, and so do guard 4 and `--check` (`scripts/finish-merge.sh` `gr_nested_remedy`, "git branch -D <branch>"), TASK-NESTED (`scripts/task-worktree.sh:243`) and `references/cleanup-rejections.md:13`. For a nested worktree that `task-worktree.sh` did not create, each of these tells the operator to run `git branch -D <branch>` by hand. Step 4 says "Follow the `fix` lines", so an operator who does so cannot then meet Done when as written. Either Done when and the red flag should be limited to the change worktree and branch, or the hand `-D` should be named there as the one exception.
disposition: Fixed. Done when and the red flag are scoped to the change worktree and branch: "removed by `finish-merge.sh` and not by hand with `--force` or `-D`".

**finding-49**: record — The record has no gate for the tree under review. Its "Round N gate" sections end at round 6, measured on `23456a6`, and nothing yet covers the round 6 fixes (`bf76341`, merged as `101ea24`) at tip `782b9f3`. The other round 6 dispositions match the tree. This is an expected gap for the round 7 gate, which should be measured on `782b9f3` or later and recorded. It is listed so the record is not read as covering the current tree.
disposition: Fixed. "Round 7 gate" records the gate measured on `782b9f3`, tree `82cd7c59`. Every round's fixes are measured by the next round's gate; the final gate is recorded before the squash.

### Round 8

**finding-50**: code — One script behaviour still has no test, against the AGENTS.md rule that every behaviour change to a script needs a bats test. `scripts/merge-preflight.sh:41-42` says a passing UNITS check prints its tool's warnings, and `README.md` (the merge-preflight row) says "a passing check also prints its tool's warnings". The per-unit warnings come from `gr_warnings "unit $gr_unit: check-ids.sh"` and `gr_warnings "unit $gr_unit: check-trace.sh"` at `scripts/merge-preflight.sh:188` and `:193`. I replaced the `:193` call with `:` on a copy under $TMPDIR, and `tests/merge-preflight.bats` stayed fully green (0 not ok of 30). The record books this as a gap ("No test covers pre-flight warnings under UNITS", Gaps, and plan T7). Findings 33, 40 and 45 were the same class and were fixed with a test, not booked as gaps. Each per-unit `gr_warnings` call needs a test: a multi-unit fixture with one open problem report in a unit of the impact set, where UNITS passes and the `UNRESOLVED-PR` line is printed under the `unit <u>: check-trace.sh` header.
disposition: Fixed for `:193`. "merge-preflight: a passing UNITS shows a unit's check-trace.sh warnings under that unit's header" fails with the reviewer's mutation applied, and the gap is removed from Gaps. The `:188` call has no output to test: every line `check-ids.sh` prints makes it exit 1, so it has no warning-only run, and a passing unit prints nothing from it.

**finding-51**: requirement — Step 6d of `skills/merge-change/SKILL.md:218-221` says to retire "each worktree a `NESTED-WORKTREE` failure lists with `task-worktree.sh remove <tag>`, as its fix line states". The fix line (`scripts/merge-preflight.sh:219`) and `--check`'s `gr_nested_remedy` (`scripts/finish-merge.sh`) give two cases. A worktree that `task-worktree.sh` did not create is retired with `git worktree remove <path>` (no `--force`) and `git branch -D <branch>`. Running `remove <tag>` on it stops at TASK-MISSING, because it has no `<change-branch>-<tag>` branch; finding-32 was this case in `task-worktree.sh`. Step 6d also does not name `discard` for a branch that `remove` rejects on commits. The step says it follows the fix line but gives only one of the fix line's three remedies. It should defer to the fix line in full, or name all three cases.
disposition: Fixed. Step 6d names all three cases, as the fix line states them, and the changed test requires each. To keep the skill within the ceiling, three sentences that repeat other text were cut: the precondition that the base branch receives one signed squash per change (stated in "Done when"), a standalone "Use `--strict`." under a command that passes it, and two words of the class C advice, which remains advisory.

### Round 9

**finding-52**: code — A script behaviour has no test. When `git merge` fails without a conflict, `task-worktree.sh merge` is meant to print "git merge of <branch> failed; nothing was removed." and exit 1 (`scripts/task-worktree.sh:268-269`). I deleted that `exit 1` on a copy under $TMPDIR, so the script falls through to `git worktree remove` and `git branch -d`, and `tests/task-worktree.bats` stayed fully green (0 not ok of 43). The path is reachable. I reproduced it in a scratch repository with signing off: a change worktree with a local edit to a file the task branch changes gives "Your local changes to the following files would be overwritten by merge". The script printed the line above and exited 1, with the task worktree and branch intact. That is correct, but no test covers it. AGENTS.md requires a bats test for every behaviour change to a script. Findings 33, 40, 45 and 50 were the same class.
disposition: Fixed. "task-worktree merge: a merge that fails without a conflict exits 1 and removes nothing" reproduces the reviewer's case with a real git rejection and fails with the reviewer's mutation applied. The same class is then swept for the whole change; see "Mutation sweep" below.

**finding-53**: code — The TASK-EXISTS remedy (`scripts/task-worktree.sh:135`) is "retire it with remove $tag or discard $tag, or choose another tag". It offers `discard` with no condition. Every other remedy that names `discard` does so only after `remove` rejects on commits and each commit is recorded as a finding. At `start`, the existing branch can hold unmerged, unreported work: a repeated tag after a missed cleanup, or a parallel task still in flight. Following the line deletes those commits with `-D`. For a leftover directory with no branch, the remedy loops: `remove t1` stops at TASK-MISSING, and `start t1` stops at TASK-EXISTS again. Only "choose another tag" works. Nothing pins the remedy text: the two TASK-EXISTS tests (`tests/task-worktree.bats:224`, `:236`) assert only the `fix TASK-EXISTS: ` prefix. I mutated the line to "run task-worktree.sh merge $tag, then start again." and all 43 tests passed. The round 4 ruling that no remedy for a task worktree names a merge is therefore not enforced for this rule.
disposition: Fixed. The remedy names "choose another tag" first; a leftover is retired with `remove <tag>`, and `discard <tag>` only after recording each commit `remove` rejects; a leftover directory with no branch is removed with `git worktree remove <path>`, or by hand after reading it. Both TASK-EXISTS tests pin the text and assert that no merging command appears.

**finding-54**: requirement — One of the round 8 cuts changed what the skill says. `skills/merge-change/SKILL.md:184-186` now reads "Class A may skip this step, B needs one reviewer, C a thorough review, and consider two independent reviewers for critical items." Before round 8 it read "C a thorough review; for class C, consider two independent reviewers" (on `main`: "For class C, consider two independent reviewers for critical items."). Cutting "for class C" moved the advice from class C to every class, so a class B agent now reads it as advice for its own reviews. No other text in the skill states that scope, so D6's test of whether an agent loses something it acts on is failed here. The record's round 8 disposition says the three cuts "repeat other text" and that the class C advice "remains advisory". That is true of its strength but not of its scope. The other two cuts are sound.
disposition: Fixed. The sentence reads "C a thorough review; for class C, consider two independent reviewers for critical items." Two words that repeat the instruction before them ("as well", after the checklist handed to the reviewer) were cut to stay within the ceiling. "merge-change: text the first rewrite lost is stated again" now requires the class C scope.

**finding-55**: record — Plan T7 (`docs/plans/2026-09-29-agent-first-skills-change-2.md:455-456`) still states "Gap: no test covers warnings under UNITS; the existing multi-unit test proves only that a run with no warnings prints nothing extra." Since `6565c07` (round 8, finding-50), "merge-preflight: a passing UNITS shows a unit's check-trace.sh warnings under that unit's header" (`tests/merge-preflight.bats:369`) covers it. The record removed the gap from its Gaps section; the plan still states it in the present tense. Findings 35 and 44 were the same class of stale plan text.
disposition: Fixed (`ed27be7`): T7 states that the gap existed when T7 was merged and that round 8 closed it.

### Mutation sweep

After round 9, one task (`b588506`) swept the class that findings 16, 17, 28,
33, 40, 45, 50 and 52 each found one line at a time. Mutants were generated
mechanically on a copy of the tree, outside quoted text, comments and awk
programs: a `gr_fail`, `gr_fix`, `gr_die` or `gr_refuse` call, an `exit` or a
`return` replaced by `:`; `a || b` made `a || true || b`; `&&` made `;`; a
condition negated; a `case` branch disabled. Every mutant passed `sh -n`. Each
mutant was run against the test files named in the table, not the full suite,
and counts as killed when at least one of them fails. A mutant not killed by
its own file can still be killed elsewhere: the `lib.sh` mutants of
`gr_nested_worktrees`, for one, also fail tests in `tests/finish-merge.bats`,
`tests/task-worktree.bats` and `tests/merge-preflight.bats`, which call it.

| Script | Lines in scope | Run against | Mutants | Killed | Not killed, then tested | Not killed, equivalent |
| --- | --- | --- | --- | --- | --- | --- |
| `task-worktree.sh` | all | `tests/task-worktree.bats` | 82 | 65 | 9 | 8 |
| `merge-preflight.sh` | all | `tests/merge-preflight.bats` | 58 | 45 | 9 | 4 |
| `finish-merge.sh` | changed by this change | `tests/finish-merge.bats` | 3 | 3 | 0 | 0 |
| `check-trace.sh` | changed by this change | `tests/check-trace.bats`, `tests/remedies.bats` | 36 | 31 | 0 | 5 |
| `check-ids.sh` | changed by this change | `tests/check-ids.bats`, `tests/remedies.bats` | 9 | 6 | 0 | 3 |
| `lib.sh` | changed by this change | `tests/lib.bats` | 4 | 0 | 3 | 1 |

Fourteen tests were added, in `tests/task-worktree.bats`,
`tests/merge-preflight.bats` and `tests/lib.bats`. Each passes on the scripts
and fails with the mutant it names. The equivalent mutants change nothing
observable:
- a `cd` to a directory just resolved, which cannot fail;
- a final `exit 0` after a command that already exits 0;
- two guards whose case a later guard already covers;
- the fallback branch of each remedy table, unreachable because every emitted
  rule has an entry;
- an empty-argument guard no caller reaches;
- a `continue` for porcelain lines that cannot match an absolute path.

The sweep measured the scripts at `b588506`. Lines changed after it are
outside its table: the round 10 and 11 fixes (the copy loop and
TASK-NOT-ON-BRANCH), where finding 62 found three of them untested, and the
later changes that the "Worktree state matrix" section lists.

No script line was changed, and the sweep found no defect. Mutations that
remove a flag were outside its kinds. The two known cases, `-c
commit.gpgsign=false` and `--force` (findings 16 and 28), already have tests.

### Round 10

**finding-56**: code — `task-worktree.sh start` decides whether a copy failed by searching its own progress output for a substring (`scripts/task-worktree.sh:182`, `:188-191`). The output lines contain the entry names. An ignored entry whose name contains `copy failed: ` makes `start` exit 1 and print "an ignored entry was not copied into it" when every entry was copied. I reproduced this in a scratch repository with signing off. The ignored files were `copy failed: x.log` and `ok.log`. Both copies are present in the new worktree, `start` exited 1, and a second `start t1` exits 1 with TASK-EXISTS. Every later `start` in that change worktree fails the same way. This is the same class of abnormal input as finding-39, where `start` could never exit 0 because of a name. A name that is skipped for a newline or \001 triggers it as well, because line 174 prints the name. A status kept apart from the printed names, such as a separate marker line or a counter, removes the defect. No test uses such a name.
disposition: Fixed. The copy loop reads a here-document in the main shell and sets a status variable; the progress lines are printed, never searched. "task-worktree start: an ignored entry named like a failure line is copied and start exits 0" reddened on the old script.

**finding-57**: code — `merge`, `remove` and `discard` find the task worktree by the task branch (`worktree_of_branch`, `scripts/task-worktree.sh:120-127`, `:206`), not by `$task_path`. When the worktree at `.worktrees/<change>-<tag>` is on a detached HEAD or on another branch, `registered` is empty. The script then skips the TASK-DIRTY and TASK-NESTED proofs (`:226-247`) and prints the false line "no worktree is registered for <branch>, so none was removed" (`:282`). I reproduced this with signing off: `start t1`, a commit in the task worktree, `git checkout --detach` there, an untracked file, and a worktree registered inside it. `merge t1` exited 0, merged the branch, deleted it with `-d`, and left the dirty task worktree registered with its nested worktree. `discard` deletes the branch with `-D` in the same state. This contradicts the header at `:39-40`, "change nothing until the task worktree is proved clean and has no worktree registered inside it", and the README and AGENTS-block rows. The leftover then makes the remedies loop: `remove <tag>` stops at TASK-MISSING, whose remedy "run start <tag> first" stops at TASK-EXISTS. The state is reachable: a subagent that checks out an old commit to watch a test fail, or one stopped mid-rebase, is left on a detached HEAD. No test covers a task worktree that is not on its task branch.
disposition: Fixed. A worktree registered at the task path but not on the task branch is rejected with `fix TASK-NOT-ON-BRANCH:`, before any proof or change; the remedy names the checkout of the task branch, then, under `merge`, returns the task to its subagent and names no merging command, and under `remove` and `discard` names the command again. The header states the rule. One test per command reproduces the reviewer's state and asserts that nothing changed.

**finding-58**: record — The "Mutation sweep" table does not state which tests each mutant was run against. That makes the lib.sh row read wrong: 4 mutants, 0 killed, 3 survived and then tested. I mutated the print branch of `gr_nested_worktrees` (`scripts/lib.sh:825`) in a copy under $TMPDIR. 17 tests in `tests/finish-merge.bats`, `tests/task-worktree.bats` and `tests/merge-preflight.bats` failed. "0 killed" can only be true against a subset of the suite, probably `tests/lib.bats` alone. The record should name the test set per script, or count kills against the full suite.
disposition: Fixed (`77c1ed0`): the table names the test files each script's mutants were run against, and the text states that a mutant surviving its own file can be killed elsewhere, with `gr_nested_worktrees` as the example.

### Round 11

**finding-59**: code — The TASK-NOT-ON-BRANCH remedy lets `remove` and `discard` drop commits without recording them. The remedy is at `scripts/task-worktree.sh:247-248`: "check out <task-branch> in it (git -C <path> checkout <task-branch>), then run remove <tag> again". If the worktree's detached HEAD has commits the task branch lacks, that checkout leaves them unreachable. `remove` then sees no commits on the branch (`:277-283`), so it passes TASK-HAS-COMMITS and exits 0. I reproduced this in a scratch repository with signing off: `start review`, a detached HEAD in the review worktree, a commit of `reviewer.txt` there. `remove review` exited 1 with TASK-NOT-ON-BRANCH. I followed the fix line: git printed "you are leaving 1 commit behind", and `remove review` exited 0 with the worktree removed and the branch deleted. Afterwards `git log --all` did not show the commit. This contradicts the header at `:25-27` and `:31-32`, step 6a of `skills/merge-change/SKILL.md` ("Record each as a finding … never merge them"), and `worktree-discipline`. Round 10 finding-57 reached this state through a detached HEAD, but the fix covered only the uncommitted and nested cases. The remedy should first have the operator list the commits on the detached HEAD that the task branch lacks and record them, or the script should reject when that range is non-empty. The tests in `assert_rejects_off_branch` detach with no commit, so they cannot see this.
disposition: Fixed. When the worktree at the task path is not on the task branch and its HEAD has commits the branch lacks, the script lists them, and the remedy states that they were never reported and that each is recorded as a finding before anything else; then, under `remove` and `discard`, the checkout and the command again, and under `merge`, the task goes back to its subagent, with no merging command. One test per command commits on the detached HEAD and reddened on the old remedy.

**finding-60**: code — `tests/remedies.bats:274-275`, "check-trace: an exit 2 after a collected violation still prints the violation", is annotated `# verifies: D7`. It tests `check-trace.sh` output, which is D8. Every other test in `tests/remedies.bats` verifies D8 or a PR item. The record repeats the error: the Red → green row tags it D7. That row also describes a red step against the EXIT-trap `cat`, a mechanism finding-38 removed. It is still the true history of when the test was red, but it reads as current.
disposition: Fixed. The annotation reads D8. The record row (`63c9e41`) is tagged D8 and states that the red step was in round 2, before round 6 removed the trap.

### Round 12

**finding-61**: code — A task worktree whose directory was deleted while git still lists it as a worktree (`git worktree list` marks it `prunable`) cannot be retired by any route the scripts print. `merge`, `remove` and `discard` reach `git -C "$registered" status` at `scripts/task-worktree.sh:272-273`, which fails, and they exit 2 with "git status failed in …, so it cannot be proved clean." and no fix line. `start` with the same tag prints TASK-EXISTS (`:140-142`), and its remedy says "retire it with remove t1", so the remedy points back to the command that failed. The TASK-EXISTS text for "a leftover directory with no branch" does not apply, because the branch still exists. At 6c, the NESTED-WORKTREE remedy (`scripts/merge-preflight.sh:219`, from `finish-merge.sh --check`, which lists the prunable path) also names `remove <tag>`. I reproduced this in a scratch repo with signing off: `start t1`, then `rm -rf .worktrees/ch-t1`, then `remove t1` exits 2 and `start t1` prints TASK-EXISTS. `git worktree remove <path>` exits 0 on the missing path, and `git worktree prune` would also clear it, but neither the scripts nor the skills name either one. Round 3 finding 13 was the same class: a state that no documented route retires. The script should detect the missing directory and print a fix line, or treat a prunable registration as "no worktree registered".
disposition: Fixed, and the class with it; see "Worktree state matrix" below. `remove` and `discard` retire a registration whose directory is missing with `git worktree remove` on that path, which exits 0 and drops only that registration; `remove` still rejects a branch with commits and `discard` lists them; `merge` rejects with `fix TASK-DIRECTORY-MISSING:` and returns the task to its subagent. TASK-EXISTS covers a registration with or without its directory. Each command has a test in that state, red before the fix (exit 2 at `git status failed`).

**finding-62**: code — The guards that round 11 added for TASK-NOT-ON-BRANCH (`scripts/task-worktree.sh:251-267`) have no test. These lines were written after the mutation sweep (`b588506`), so the sweep did not cover them. I ran three mutants on a copy under $TMPDIR against `tests/task-worktree.bats`, and all 58 tests passed for each: M1, `:254` `|| gr_die` changed to `|| true` — if `rev-list` fails, the script prints the no-commit remedy, and following it makes the detached commits unreachable, which is the finding-59 defect returning on a git failure; M2, `:260` `|| gr_die` changed to `|| true` — if `git log` fails, the remedy still refers to "the commits listed above", but none were listed; M3, deleted `:262-265`, the remedy specific to `merge` — under `merge` the generic line is then printed, which tells the dispatcher to check out the task branch before the task goes back to its subagent, and `assert_rejects_off_branch_with_commit merge` cannot tell the two lines apart. Findings 33, 40, 45 and 52 were the same class. AGENTS.md requires a bats test for every behaviour change to a script.
disposition: Fixed. A test with a failing `rev-list` kills M1, one with a failing `git log` kills M2, and the merge case now asserts that the line names no checkout, which kills M3. A second mutation sweep over all of `task-worktree.sh` followed; see "Worktree state matrix" below.

**finding-63**: record — The ruling in the plan, `docs/plans/2026-09-29-agent-first-skills-change-2.md:517-519`, states: "Every remedy for a task or review worktree, in every script, skill and reference file, names only `remove` or `discard`, never a merging command". The tree has correct remedies for a task worktree that name other commands: TASK-MISSING names `start`; TASK-NOT-ON-BRANCH names `git -C … checkout`; TASK-NESTED, TASK-EXISTS, NESTED-WORKTREE, `gr_nested_remedy` and `references/cleanup-rejections.md:13` name `git worktree remove` and `git branch -D` for a worktree that `task-worktree.sh` did not create, a case added deliberately in round 5, finding 32. Read literally, the sentence is false of correct work. Finding 36 was the same class. The sentence should read "never names a merging command", or list these as outside its scope.
disposition: Fixed (`49b664e`): the ruling states that no remedy names a merging command, that `discard` follows recording, and lists the non-merging commands remedies may name.

**finding-64**: record — The "Mutation sweep" section of the record uses words that AGENTS.md "Writing" replaces ("survives -> remains"): "A mutant that survives its own file", the table headers "Survived, then tested" and "Survived, equivalent", and "The equivalent survivors". These are the record's own prose, not quoted findings. The section also does not state that script lines changed in rounds 10 and 11 (the copy loop and TASK-NOT-ON-BRANCH) postdate the sweep, so the "Lines in scope: all" row for `task-worktree.sh` reads as if it covers the current script. Finding 62 shows that it does not.
disposition: Fixed (`5fa4bf9`): the section uses "not killed" and "equivalent mutants", and states that it measured the scripts at `b588506` and that later lines are outside its table.

### Worktree state matrix

After round 12, the maintainer chose to test every `task-worktree.sh` command
against every worktree state at once, instead of one state per round (findings
22, 39, 56, 57, 59 and 61 each found one). One task (`8f3829e`, `7d8a9bb`)
covered `start`, `merge`, `remove` and `discard` against fifteen states: a
clean task worktree with and without commits, an uncommitted change, an
untracked file, a nested worktree made by the script and one made by hand, a
detached HEAD with and without commits, another branch, a locked worktree, a
deleted directory still registered, a task branch registered outside the
change worktree, a missing branch with and without its directory, and a tag
already used. In each state a command either succeeds, or exits with a `fix`
line that retires the state without a merge and changes nothing.

The matrix task took `tests/task-worktree.bats` from 58 tests to 88: 30 added, with 31 new names, one of which replaced "task-worktree remove: a locked task worktree is not removed and remains registered". The follow-up tasks below brought it to 100. Four states were handled wrongly and are fixed,
each test red before its fix:
- a deleted directory, where every command exited 2 with no fix line;
- a locked worktree, where `merge` merged and then failed the removal with no
  fix line (now `fix TASK-LOCKED:`, rejected before the merge);
- a detached HEAD whose directory was deleted;
- a registered path with no task branch, where the remedies led from
  TASK-MISSING to TASK-EXISTS and back.

A second mechanical sweep, in the kinds above, covered every line of
`task-worktree.sh` at `8f3829e`, against `tests/task-worktree.bats`: 127
mutants, 114 killed, 3 not killed and then tested, 10 equivalent (the `cd` and
final `exit 0` cases of the first sweep, a blank-line branch with no effect,
and three guards a later guard already covers). No other script changed between `b588506`
and `8f3829e`. Lines changed after `8f3829e` are outside both sweeps: the
matrix follow-up tasks, the CHANGE-BUSY checks of rounds 13 to 16, and the
merge left uncommitted of round 18 (`03a7efe`) and the round 20 and 21 fixes (`b89ba1e`, `cb83e5b`), in `task-worktree.sh`; the TASK-NOT-REGISTERED check in `task-worktree.sh` and
the `gr_nested_worktrees` comments in `scripts/lib.sh` (`0b78f34`); the git-call status checks in `task-worktree.sh` and
`merge-preflight.sh` (`93a75f8`) and BASE-MERGED and the UNITS range in `merge-preflight.sh` (`cb83e5b`); and `gr_base_branch` with its callers in
`lib.sh`, `merge-preflight.sh`, `finish-merge.sh` and `check-review.sh`
(`b713592`). Each executable line among them was added with a test that was
red before it, listed in the "Red → green" table.

The task named the cases it left open, and three more tasks closed them before
round 13, each test red before its fix:
- `dbeb746`, `aa35918`: a deleted task directory with worktrees still
  registered inside it is TASK-NESTED; a removal git rejects after `merge` has
  merged gets `fix TASK-NOT-REMOVED:`.
- `86b0829`: the nested check is keyed on the registration at the task path,
  whatever its HEAD and whether or not its directory exists, and runs before
  any remedy that names a checkout or `git worktree remove`; TASK-NOT-REMOVED
  covers `remove` and `discard` too.
- `221a22c`: the last four exits that printed no fix line get one
  (TASK-NOT-CREATED, TASK-COPY-FAILED, TASK-MERGE-FAILED,
  TASK-BRANCH-NOT-DELETED).

An audit of every non-zero exit in `task-worktree.sh` at `221a22c` found each
one either prints a `fix` line through `gr_fix`, or exits 2 for usage or for
an environment failure such as a git command that cannot run. The one
exception is a missing `lib.sh`, which fails before any check, with an exit
code that depends on the shell.

### Round 13

**finding-65**: code — `merge`, `remove` and `discard` do not check the task directory when the task branch exists but no worktree is registered at the task path. The matrix has no such state: its two leftover-directory states both have no branch. `scripts/task-worktree.sh` checks `[ -e "$task_path" ]` only when `task_branch_exists=no` (`:282-290`). With the branch present, `registered` and `task_record` are both empty, so every proof is skipped (`:404`, `:431`, `:449`). `merge` then merges and deletes the branch, and `remove` would delete it too. Each prints "no worktree is registered for <branch>, so none was removed" (`:501`) and exits 0, and the directory stays. I reproduced this in a scratch repository with signing off: `start t1`, a commit in the task worktree, an untracked `uncommitted.txt`, `rm .worktrees/ch-t1/.git`, `git worktree prune`. `remove t1` exited 1 at TASK-HAS-COMMITS, which is correct. `merge t1` exited 0, merged the commit and deleted `ch-t1`, and left `.worktrees/ch-t1` with `uncommitted.txt` in it. The next `start t1` exits 1 with TASK-EXISTS. This contradicts the header at `:58-59` ("change nothing until the task worktree is proved … clean") and the record's matrix claim that each state either succeeds or exits with a fix line that retires it. The state is reachable only when someone removes the worktree's `.git` file or moves the directory, so the severity is low.
disposition: Fixed. A task directory that exists while nothing is registered at the task path and the task branch exists is rejected by `merge`, `remove` and `discard` with `fix TASK-NOT-REGISTERED:`: its contents were never checked; record anything worth keeping, delete it by hand after reading it, then run the command again, or, under `merge`, return the task to its subagent. Nothing changes. One test per command reproduces the reviewer's steps; `merge` and `discard` exited 0 on the old script, and `remove` printed no such line.

**finding-66**: code — The second TASK-NESTED form names the directory to run from, and no test checks it (`scripts/task-worktree.sh:275`, "from $gr_repo_root"). That form is printed when the task path is missing, unregistered or not on its branch. I changed it to "from $task_path", which is a directory that may not exist in this case, on a copy under $TMPDIR. All 100 tests in `tests/task-worktree.bats` passed (mutant M9). I ran 13 other mutants of the lines added after the second sweep (`dbeb746`, `aa35918`, `86b0829`, `221a22c`), and each was killed. The record's second sweep covers `8f3829e` only, so these lines had no sweep. Separately, the comment on `gr_nested_worktrees` (`scripts/lib.sh`, added by this change) is now inaccurate in two places: it names "task-worktree.sh merge, remove and discard", but since `86b0829` `start` calls it too; and it says "both sides come out of the same `git worktree list`", but task-worktree.sh passes `$task_path`, which is built from `gr_root`.
disposition: Fixed. The eight tests of that form assert "from <change worktree>, for each listed path" and that the task path is not named as the place to run from; the old assertion matched as a prefix of the task path, which is why the mutant was not killed. All eight fail with the reviewer's mutant. The `gr_nested_worktrees` comment names `start` and states which path each caller passes.

**finding-67**: record — The "Worktree state matrix" section says "Thirty-four tests were added." The matrix task's commits take `tests/task-worktree.bats` from 58 tests (`49b664e`) to 88 (`7d8a9bb`). That is 30 added; 31 test names are new, one of them replacing "task-worktree remove: a locked task worktree is not removed and remains registered". The later tasks bring it to 100. No count of 34 matches either range. The section's other claims hold.
disposition: Fixed (`9855875`): the section states 58 to 88, 30 added with 31 new names, and 100 after the follow-up tasks.

**finding-68**: record — The ruling in `docs/plans/2026-09-29-agent-first-skills-change-2.md:520-522`, fixed for finding 63, lists the non-merging commands a remedy may name: "`start`, a checkout of the task branch, and, for a worktree `task-worktree.sh` did not create, `git worktree remove` and `git branch -D`". The matrix tasks then added remedies outside that list: TASK-LOCKED names `git worktree unlock`; TASK-DIRECTORY-MISSING names `git worktree add`; TASK-COPY-FAILED names `cp -R`; TASK-BRANCH-NOT-DELETED names `git branch -d` and `-D` on the task branch; TASK-NOT-ON-BRANCH, TASK-MISSING and TASK-EXISTS name `git worktree remove $task_path` for a worktree the script did create; the second TASK-NESTED form names `git branch -D` for `.worktrees/<task-branch>-<tag>`; TASK-EXISTS says to delete a directory by hand. Every one of these merges nothing, so the work is correct. The enumerated list is false of it, and findings 36 and 63 were the same class.
disposition: Fixed (`9855875`): the ruling states its test, that a remedy may name any command that merges nothing, and gives the commands in the tree as examples rather than as a closed list.

### Round 14

**finding-69**: code — `task-worktree.sh merge` decides a merge conflicted by checking for unmerged entries in the whole index (`scripts/task-worktree.sh:486`, `[ -n "$(git ls-files -u)" ]`). It does not check that those entries came from this merge. When a conflict from an earlier dispatch is still unresolved in the change worktree, git rejects the new merge before it starts ("Merging is not possible because you have unmerged files … Exiting because of an unresolved conflict"). The script then prints TASK-CONFLICT anyway, and its remedy for a merge that never began reads: "resolve the conflicts …, conclude the merge with git -c commit.gpgsign=false commit, then run remove <tag>". I reproduced this in a scratch repository with signing off: `start t2` and `start t3`; t2 commits a change to `f.txt` that conflicts with the change branch; t3 commits a new file `g.txt`. `merge t2` conflicts, which is correct. Without resolving it, `merge t3` exits 1 with `fix TASK-CONFLICT: … then run remove t3.` I followed the line: I resolved and committed the t2 merge, then ran `remove t3`. It exited 1 with `fix TASK-HAS-COMMITS: ch-t3 has the commits listed above, which were never gated or reviewed; record each one as a finding, then run task-worktree.sh discard t3.` So t3's report was green, but the remedy chain records its commits as findings and deletes them with `-D`. The header claims "A merge conflict is left in progress in the change worktree" (`:68-70`), and the TASK-CONFLICT roster entry (`:116`) states "the merge of the task branch conflicted". Both are false here. No test covers a merge attempted while another conflict is unresolved. A cherry-pick or stash conflict left in the change worktree causes the same misreading.
disposition: Fixed. Before the merge, `merge` checks the change worktree for an operation in progress (a merge, cherry-pick or revert, or unmerged entries) and rejects with `fix CHANGE-BUSY:`, naming the operation and, for a merge, what is being merged; the remedy concludes or aborts it, then returns to the dispatcher's step, and names no merging command. TASK-CONFLICT is printed only when the conflict is this merge's (`MERGE_HEAD` is the task branch tip). A rebase in progress detaches HEAD, so it is detected earlier, for every command, and gets the same rule instead of a bare exit 2. Five tests cover the reviewer's case, a cherry-pick conflict, and a rebase stopped on a conflict under `merge`, `start` and `remove`; each was red on the old script.

### Round 15

**finding-70**: code — Four branches of the round 14 CHANGE-BUSY code have no test. The record states the change worktree is checked "for an operation in progress (a merge, cherry-pick or revert, or unmerged entries)". I mutated a copy under $TMPDIR and ran `tests/task-worktree.bats` against each mutant. All 108 tests passed every time: (A) the REVERT_HEAD condition (`scripts/task-worktree.sh:534`) changed to `false`; (B) the unmerged-entries-only condition (`:537`) changed to `false`, reachable after a `git stash pop` conflict, whose own text is never asserted; (C) the `rebase-apply` alternative (`:200`) deleted, so a `git rebase --apply` stopped in the change worktree falls through to the bare detached-HEAD exit 2; (D) the short-SHA fallback for a MERGE_HEAD no branch points at (`:528`) replaced by `:`. These lines postdate both mutation sweeps. A fifth mutant was also not killed: the MERGE_HEAD comparison at `:548` replaced by `true`. I judge it equivalent, because the CHANGE-BUSY check above it now rejects every earlier in-progress state. Findings 33, 40, 45, 52 and 62 were the same class.
disposition: Fixed. One test per branch, each failing with the reviewer's mutant: a revert conflict, unmerged entries from a stash pop (asserting its text), a `rebase --apply` stopped on a conflict, and a merge of a commit no branch names (asserting the short SHA). The `:548` comparison is equivalent, as the reviewer judged. A further task (`bcbe419`) made every git call in the block check its status: a failing call now exits 2 with the reason, instead of reading as nothing in progress. Ten tests use a stub git that fails one call each.

**finding-71**: code — `remove` and `discard` misread the state that `merge`'s own TASK-CONFLICT leaves. This is the class finding-69 fixed for `merge` only. The merge/cherry-pick/revert CHANGE-BUSY check is gated to `merge`, and the TASK-HAS-COMMITS text is printed whatever is in progress. I reproduced this in a scratch repository with signing off: `start t2`, a commit in t2 that conflicts with the change branch; `merge t2` exits 1 with `fix TASK-CONFLICT: … then run remove t2.`, which is correct; before concluding the merge, `remove t2` exits 1 with `fix TASK-HAS-COMMITS: … record each one as a finding, then run task-worktree.sh discard t2.` That is false: the commits are the green-reported task work, and MERGE_HEAD is their tip. `discard t2` then exits 0, removes the worktree and deletes `ch-t2` with `-D` while the merge of that branch is still in progress. If the dispatcher then aborts the merge, the work is gone from every branch. The severity is low: the TASK-CONFLICT line says to conclude the merge first.
disposition: Fixed. The CHANGE-BUSY check runs for every command, before any proof. For the merge of this task's own branch, the remedy concludes it and then names `remove`, or aborts it and returns to the dispatcher's step; it names neither `discard` nor a merging command. `start` runs the check too, so a task branch is never cut from a change branch in mid-merge. Tests for `remove` and `discard` reproduce the reviewer's sequence and assert that nothing changes.

**finding-72**: record — The "Red → green" table of the record stops at round 11 (finding 59, plus the finding-60 row edit). The tests added since then are not in it, although each disposition says they were red before the fix: the deleted-directory tests (finding 61); the failing `rev-list` and `git log` tests (finding 62); the 30 matrix tests and the follow-up tasks `dbeb746`, `aa35918`, `86b0829`, `221a22c`; the three TASK-NOT-REGISTERED tests (finding 65); the eight retargeted TASK-NESTED assertions (finding 66); the five CHANGE-BUSY tests (finding 69). Until round 11, each round's red → green attestations were added to the table. Step 6b lists the `red -> green:` attestations as part of the record, so the table now reads as complete when it is not.
disposition: Fixed (`dcbe10a`): the table has rows for rounds 12 to 14 and the matrix tasks, and this round's rows are added with it.

### Round 16

**finding-73**: code — One git call in the CHANGE-BUSY block of `scripts/task-worktree.sh` does not have its status checked. The comment at :234-236 states "Every git call here is read with its status taken", and the round 15 finding-70 disposition states that `bcbe419` "made every git call in the block check its status". Line 259, `"$(git rev-parse -q --verify "refs/heads/$task_branch" 2>/dev/null)"`, discards both its status and its stderr. When that call fails, the merge of this task's own branch is read as some other merge, and the generic CHANGE-BUSY remedy is printed. Under `discard`, that remedy is "abort it (git merge --abort), then run discard t2 again". Following it deletes the green-reported task work with `-D`, which is the outcome that the finding-71 fix and the header at :77-78 ("remove and discard never act on a task whose merge is in progress") exist to prevent. I reproduced this with a stub git that exits 128 only for `rev-parse -q --verify refs/heads/ch-t2`. No test covers this call.
disposition: Fixed (`6efbca1`). `git show-ref --verify --quiet` separates an absent task branch (exit 1) from a failure (any other status, exit 2), and the tip is then read with `git rev-parse --verify` and its status taken. The same task found that the read of the change branch with `git branch --show-current` read a failure as a detached HEAD, and fixed it. Three tests. Because findings 62, 70 and 73 were each one unchecked git call found by review, a further task (`93a75f8`) listed every git call in `task-worktree.sh` and `merge-preflight.sh` with how its status is taken, and fixed each call whose failure was read as a state: seven in `task-worktree.sh` (the primary-checkout check, the `show-ref` that decides the branch exists, `check-ignore`, the TASK-HAS-COMMITS listing, and the two reads after a merge) and five in `merge-preflight.sh` (the primary-checkout check, `branch --show-current`, the read of `origin/<base>`, and `merge-base --is-ancestor`, whose failure now exits 2 under BASE-MERGED instead of exit 1). Twelve tests use a stub git that fails one call each. TASK-CONFLICT now also requires a non-empty MERGE_HEAD, so two failed reads no longer compare equal. The audit found one more call of the same class outside the two scripts: `gr_base_branch` in `scripts/lib.sh` discarded the status of `git worktree list`, so a failure was read as a detached primary checkout. A task (`b713592`) made it return git's status, and each caller (`merge-preflight.sh`, `finish-merge.sh` at both sites, `check-review.sh`) now exits 2 and names the failure. Under `check-review.sh --branch` the failure had been a pass at exit 0. Six tests.

**finding-74**: record — The "Worktree state matrix" section states: "The other scripts have no line changed since `b588506`." `git diff b588506 HEAD -- scripts/` shows that `scripts/lib.sh` changed in `0b78f34`, the round 13 finding-66 fix: nine comment lines of `gr_nested_worktrees`. No executable line changed, so the sweep's coverage is unaffected. Read literally, the sentence is false of the tree.
disposition: Fixed (`1d26b61`): the sentence states that no executable line changed.

### Round 17

**finding-75**: requirement — `skills/merge-change/SKILL.md:18` still detects the base branch with `BASE=$(. .guardrails/scripts/lib.sh && gr_base_branch)` and does not take its status. The contract added at `scripts/lib.sh:771-778` states "A caller must take the status: an empty result with status 0 is detachment, and the same empty result from a git failure is not." The finding-73 disposition says "each caller" now takes it, and lists only the four script callers and `tests/evidence.sh`. When `git worktree list` fails, BASE is empty and step 1 runs `git merge "origin/"` or `git merge ""`; git rejects the merge, so the failure is caught, but the skill leaves it unnamed. The skill is also the only caller that does not check for an empty BASE.
disposition: Fixed (`3c0ac6b`): the line is `BASE=$(. .guardrails/scripts/lib.sh && gr_base_branch) && [ -n "$BASE" ]`, so a git failure or a detached primary checkout fails the precondition. The skill is 1,999 words.

**finding-76**: requirement — `b713592` fixed a defect that was already on `main`: under `check-review.sh --branch`, a failed `git worktree list` made the gate pass at exit 0, and the same fix covers `gr_base_branch` for `finish-merge.sh`; both scripts predate this change. No problem item was opened for it. The new tests in `tests/check-review.bats` and `tests/finish-merge.bats` are annotated `# verifies: D7`, which scripts three procedures and does not cover a gate defect inherited from `main`. Earlier `finish-merge` defects of the same kind were items (PR-n57ayn, PR-k77dzn), yet the "Problem ledger delta" states "Opens none."
disposition: Fixed (`3c0ac6b`): `PR-tz6gsp` in `docs/problems/2026-10-04-base-branch-git-failure.md`, opened and resolved by this change. The plan header resolves it, the ledger delta states it, and the five tests of `gr_base_branch` and of its callers in `check-review.sh` and `finish-merge.sh` verify it. The `merge-preflight.sh` test stays `D7`: that script is new in this change.

**finding-77**: record — The "Worktree state matrix" section states "The other scripts have no executable line changed since `b588506`; `scripts/lib.sh` changed in comments only (`0b78f34`)". `git diff --stat b588506 HEAD -- scripts/` contradicts this: executable lines changed in `merge-preflight.sh`, `finish-merge.sh` and `check-review.sh` (`93a75f8`, `b713592`), and in `gr_base_branch` (`b713592`). The "Mutation sweep" section names only the round 10 and 11 lines as outside its table. Finding 74 was the same class.
disposition: Fixed (`3c0ac6b`): both sections list the lines changed after each sweep, by commit, and state that each executable line among them was added with a test that was red before it.

**finding-78**: record — The plan is behind the tree. T4 lists the exit-2 cases "as built" without a git call that fails where its result is read, including BASE-MERGED's new exit 2; T3's `start` exit-2 list leaves out git-call failure; the plan never mentions CHANGE-BUSY; and the ruling lists the remedies outside its scope (`check-trace.sh` and `check-ids.sh` fix lines, BASE-MERGED, TASK-CONFLICT) but not CHANGE-BUSY, whose remedy concludes a merge in progress, the same class as TASK-CONFLICT. Findings 19, 35, 36, 44, 55 and 68 were the same class.
disposition: Fixed (`3c0ac6b`): T3 states the CHANGE-BUSY check and its remedy for every command and the git-failure exit; `start`'s list and the WORKTREES-NOT-IGNORED line state exit 2 on a git failure; T4 states the git-failure exits; the ruling names CHANGE-BUSY among the remedies outside its scope.

### Round 18

**finding-79**: code — `task-worktree.sh merge` reports TASK-MERGE-FAILED and states "nothing was merged or removed" when the merge of this task's own branch is left in progress. `scripts/task-worktree.sh:650` gives TASK-CONFLICT only when there are unmerged entries. A merge that git stops after a clean merge, with MERGE_HEAD equal to the task branch tip and no unmerged entries, falls through to TASK-MERGE-FAILED at `:658`. A `commit-msg` or `pre-merge-commit` hook that rejects the merge commit leaves this state. I reproduced it in a scratch repository with signing off: git printed "Not committing merge; use 'git commit' to complete the merge.", the script exited 1 with `fix TASK-MERGE-FAILED: … nothing was merged or removed …`, and MERGE_HEAD existed with the task change staged. Following the remedy, `merge t1` again, prints the correct CHANGE-BUSY line, so no work is lost; the severity is low. No test covers a merge that stops with MERGE_HEAD and no unmerged entries.
disposition: Fixed (`03a7efe`). When MERGE_HEAD is the task tip after a failed merge and there are no unmerged entries, `merge` prints CHANGE-BUSY with the remedy for this task's own merge, stating that it was not committed: conclude it after clearing the cause git names, then `remove`, or abort it and repeat the dispatcher's step. TASK-MERGE-FAILED is printed only when no merge of the task is in progress. Two tests, one per hook, each red before the fix; each follows the remedy to a completed `remove`. The plan's T3 text and the ruling's scope name the case.

**finding-80**: requirement — `skills/merge-change/references/cleanup-rejections.md:16` lists the exit-2 causes of `finish-merge.sh` as "Run from a linked worktree, on a detached HEAD, with no such branch, or naming the base branch itself", with the remedy "Run it from the primary checkout with the base branch checked out". Through `PR-tz6gsp` (`b713592`) this change added a new exit 2, "git worktree list failed, so the base branch cannot be read." (`scripts/finish-merge.sh:159`, `:245`). The row does not name it, and its remedy does not apply to it. The script's other git and awk failure exits (`:167`, `:301`, `:315`) are also missing from the row; those predate this change.
disposition: Fixed (`e118e24`): a row for a failed git or awk step (exit 2), which states that nothing was removed or deleted and that the remedy is to fix the cause git's error names and re-run the script.

**finding-81**: record — The `reproduced:` field covers only `PR-zmzav3` and `PR-sa5y4k`, although the change now resolves `PR-tz6gsp` and its tests were red before the fix. The "Red → green" rows for the `gr_base_branch` test and the five caller tests are still tagged `D7`, while their annotations read `# verifies: PR-tz6gsp`; only the `merge-preflight.sh` test remains `D7`.
disposition: Fixed (`e118e24`): `reproduced:` states `PR-tz6gsp`; the rows are tagged `PR-tz6gsp`, and the `merge-preflight.sh` test has its own `D7` row.

**finding-82**: record — `docs/problems/2026-10-04-base-branch-git-failure.md:3` and the plan header state that review round 17 found the defect. It was found and fixed by the git-call audit after round 16 (`b713592`), as the finding-73 disposition records; round 17 (finding 76) found that no problem item had been opened for it.
disposition: Fixed (`e118e24`): both state that the audit after round 16 found and fixed it, and that round 17 found no item had been opened.

**finding-83**: record — The "Worktree state matrix" section, fixed for finding 77, names `0b78f34` only for the `gr_nested_worktrees` comments in `scripts/lib.sh`. `0b78f34` also added executable lines to `scripts/task-worktree.sh`: the TASK-NOT-REGISTERED check, the round 13 finding-65 fix. Their tests are in the Red → green table, so the claim that each executable line has a test that was red before it still holds. Findings 74 and 77 were the same class.
disposition: Fixed (`e118e24`): the list names the TASK-NOT-REGISTERED check in `0b78f34`, and the round 18 lines of `03a7efe`.

### Round 19

**finding-84**: code — At merge time the pre-flight prints the wrong fix for a draft-named ledger file. `scripts/check-ids.sh:50` (`check_ids_remedy`, the DRAFT-FILE entry) prints "Leave it while the change is in flight (--allow-draft-files); merge-change step 3 renames it at merge." That line prints only when `--allow-draft-files` is absent, which is how `merge-preflight.sh` runs IDS at steps 4 and 6c, after step 3 has run. For this change's own draft, the operator is told to leave the file in place, and the pre-flight cannot take the flag, so IDS keeps failing. I reproduced this with the fixture of "merge-preflight: IDS fails on a draft-named ledger file". The check-traceability fix table that D7 item 2 replaced said "Nothing mid-change. At merge, run `merge-change` step 3." No test asserts the DRAFT-FILE fix text.
disposition: Fixed (`c1bd3cd`): the line reads "Mid-change, leave it: check-ids.sh --allow-draft-files passes it. At merge, run merge-change step 3 (finalize-docs.sh), which renames it, then run this check again." A `remedies.bats` test asserts the whole line, and the pre-flight test asserts its merge half; both were red on the old line.

**finding-85**: requirement — The exit-code paragraph of the `scripts/merge-preflight.sh` header lists when the script exits 2 and leaves out a detached primary checkout, which exits 2 ("the base branch cannot be determined") and is tested in `tests/merge-preflight.bats:544`. The T4 "as built" exit-2 list in the plan leaves it out as well. Low severity; the same kind of gap as finding 78.
disposition: Fixed (`c1bd3cd`): the header and T4 name it.

### Round 20

**finding-86**: code — The full suite fails at `01613b8`: `not ok 790 clanker: no file in scope contains the replaced vocabulary` (`tests/skills.bats:1268`). The round 19 fix `c1bd3cd` added two test comments that use "says", which AGENTS.md "Writing" replaces with "states" (`tests/merge-preflight.bats:232`, `tests/remedies.bats:175`). The round 19 gate measured `089f0e3`, before `c1bd3cd`, so no recorded gate had seen this.
disposition: Fixed (`a0c9186`): both comments use "states". The round 20 gate found the same failure.

**finding-87**: code, low severity — `scripts/task-worktree.sh` passes the task branch to git as a bare name, which a tag named `<change>-<tag>` makes ambiguous; git reads the tag. Reproduced with signing off: `merge` merged the tag ("Already up to date"), removed the task worktree and printed a false TASK-BRANCH-NOT-DELETED; `remove` skipped TASK-HAS-COMMITS and removed the worktree; `discard` listed no commit and deleted the branch with `-D` at exit 0, so an unrecorded commit was lost. No test covers an ambiguous name.
disposition: Fixed (`b89ba1e`): every revision argument that names the task or change branch is `refs/heads/<name>`, in `start`, the TASK-MISSING and TASK-NOT-ON-BRANCH listings, `remove`, `discard` and `merge`, which passes `-m` so the merge message is the one git writes for a branch name. `git branch -d`/`-D` takes a branch name and acted on the branch in a test with a same-named tag. Seven tests.

**finding-88**: code, low severity — A tag that is not a valid ref name (`t..x`, `x.lock`, `a~1`, `b:c`, `q?`) passes the usage checks and reaches `git worktree add`, which prints `fix TASK-NOT-CREATED: … run start t..x again`; following the line repeats the failure.
disposition: Fixed (`b89ba1e`): every command checks the tag with `git check-ref-format "refs/heads/task-<tag>"` and exits 2 with a usage message; exit 1 is an invalid name, any other status a git failure. `--branch` is not used, because it exits 128 for both. The header names the case. One test covers eleven such tags under all four commands, and one checks that `.t1` is still accepted.

**finding-89**: code, low severity — The remedies that conclude a merge name `git -c commit.gpgsign=false commit` with no message option. Run as written with no TTY and no `GIT_EDITOR`, git opens an editor and exits 1. The tests do not run the remedy as stated: each conclusion step adds `--no-edit`, and the shell the tests inherit exports `GIT_EDITOR=true`. So the finding-27 disposition ("runs the remedy as stated") was not exactly true.
disposition: Fixed (`b89ba1e`): TASK-CONFLICT, both CHANGE-BUSY lines for the task's own merge, and the CHANGE-BUSY line for another merge, a cherry-pick or a revert name `commit --no-edit`. Unmerged entries with no operation (a stash pop conflict) have no prepared message, where `--no-edit` aborts, so that line names `commit -m <message>`. Two tests run the TASK-CONFLICT and cherry-pick remedies exactly as printed, with no editor in the environment; five existing tests assert `--no-edit`.

### Round 21

The first round under the round 20 ruling. Its highest severity is low, so it
is the last review round; its low findings were fixed without a further round,
and the final gate measures the result.

**finding-90**: code, low — The CHANGE-BUSY remedy for a rebase in progress (`scripts/task-worktree.sh:253`) names `git -c commit.gpgsign=false rebase --continue`, which opens an editor after a conflict on the merge backend. Reproduced with signing off and no editor: git printed "error: Terminal is dumb, but EDITOR unset … could not commit staged changes." and exited 1, with the rebase still in progress. Round 20 finding 89 fixed the merge, cherry-pick and revert remedies but not this one. Low: it needs a rebase stopped in the change worktree, git's error names the cause, and nothing is lost.
disposition: Fixed (`cb83e5b`): the remedy names `git -c commit.gpgsign=false -c core.editor=true rebase --continue`; a test runs it as printed with no editor.

**finding-91**: code, low — BASE-MERGED in `scripts/merge-preflight.sh:160-183` passes the base to git as a bare name, and the UNITS impact range (`:204`, `"$base..HEAD"`) does the same. A tag named like the base branch is read in place of the branch. Reproduced: a tag `main` at the first commit, `main` advanced and not merged; `--local-base` printed "refname 'main' is ambiguous" and `BASE-MERGED ok`. Low: it needs a tag named like the base branch, though a gate passes that should fail.
disposition: Fixed (`cb83e5b`): both name `refs/heads/<base>` and `refs/remotes/origin/<base>`; messages show the short name. `skills/merge-change/references/multi-unit.md` names `refs/heads/$BASE..HEAD` for the same reason. Two tests.

**finding-92**: code, low — Under `start`, the CHANGE-BUSY remedy (`scripts/task-worktree.sh:339-341`, and `:252-253` for a rebase) tells the agent that runs `start` to conclude or abort the operation in the change worktree, including `git merge --abort`. Under `develop-change` a dispatched subagent runs `start`, and the operation is the dispatcher's (a base merge, or a TASK-CONFLICT merge being resolved), so an abort discards the dispatcher's partial resolution. Low: it needs a task dispatched while an operation is in progress, and no committed work is lost.
disposition: Fixed (`cb83e5b`): under `start`, the remedy states that the operation belongs to the dispatcher of the change worktree, that a dispatched subagent stops and reports the line without acting on it, and that the dispatcher concludes or aborts it before `start` is run again. The `merge`, `remove` and `discard` remedies are unchanged: the dispatcher runs those commands, and the operation is its own. Three tests.

**finding-93**: record — The `verdict:` line states that round 20 raised "four code findings, all of low severity", but finding 86 has no severity tag; findings 87 to 89 are low.
disposition: Fixed: the verdict line states a failing test (86) and three findings of low severity (87 to 89).

## Problem ledger delta

Resolves `PR-zmzav3` and `PR-sa5y4k`. Opens and resolves `PR-tz6gsp`
(`docs/problems/2026-10-04-base-branch-git-failure.md`).

## Gaps

- Nothing measures agent behaviour; the proposal states this limit.
- `check-traceability` is 2,490 words (`wc -w`) and stays exempt from the
  ceiling until change 3.
- `tests/check-ids.bats` contains literal draft tokens on many lines that
  `main` already reports under the synthesized config; none is in a hunk this
  change touched, and they predate it.
