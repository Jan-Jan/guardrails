# Verification — test-runner (2026-10-07)

branch: test-runner
reviewer: independent Claude subagents with fresh context, given the diff, the plans, the claimed items and the review checklist only (merge-change step 6a); round 1 at `b16c147`, round 2 at `5d9e05b`
verdict: converged at round 2 — round 1 requested changes (two medium code findings); round 2 raised three low code findings and two record findings, nothing above low, so it was the last round; every finding is fixed
reproduced: yes — PR-r83mmd by a stub `bats` that received the whole glob after a named file; PR-2nxadp by two `--jobs 12` suite runs on one tree that both failed the same three tests a serial run passed; PR-hrx4vf by a serial run of 1907 s with the runner passing no `--jobs`

Change: `tests/run-tests.sh` runs only the `.bats` files or directories it is given, and runs the suite with one bats job per CPU where GNU `parallel` is installed; a nested bats run in the suite resolves `bin/bats`; the ratchet setup checklist installs `parallel`; and the roadmap for the rest of the churn and parallel-session proposals is committed. Branched from `main` at `821e783`; base merged from local `main` at `821e783`, per AGENTS.md non-negotiable 5.
Plan: `docs/plans/2026-10-06-test-runner.md`, phase 1 of `docs/plans/2026-10-06-salvage-churn-and-parallel.md`.

## The gate

Measured on: `4fa522d` — `git rev-parse HEAD` — tree `40cfbad874cbeb8ec529a2a34a06eb1cceccbebb`, clean worktree, `main` at `821e783` at the start and end of the run. Step 3 had renamed the problem draft before this gate, so this is the tree that merges, apart from this record.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh` (default, `--jobs 12`) | 1..1101, 1101 ok, 0 not ok, exit 0, 650 s |
| `RUN_TESTS_JOBS=1 sh tests/run-tests.sh` (serial) | 1..1101, 1101 ok, 0 not ok, exit 0; per-test results byte-identical to the parallel run. Its wall time (4863 s) is not a measurement: the host was suspended during it (`sleep 240` took 468 s) |
| `check-ids.sh --allow-draft-files` (scratch copies, base and change) | exit 1 on both, as on `main`; sorted output diff empty |
| `check-trace.sh` (scratch copies) | exit 1 on both, as on `main`; this change's IDs entering the roll-call: PR-r83mmd, PR-hrx4vf, PR-2nxadp (resolved), PR-sc5qy5 and PR-555dk4 (open, `UNRESOLVED-PR`); no other line differs |
| Coverage | not configured |
| Working tree | clean |

D7's condition, measured after T5 fixed the tests that failed only under `--jobs`: on `1e5adf5` (tree `c33f1eb15de3d9afce91562fbed25cb9f94fe493`) the serial run passed 1096/1096 in 1765 s and the `--jobs 12` run 1096/1096 in 701 s, with identical per-test results; the run above repeats the comparison on the final tree. A parallel run therefore takes about 11 to 12 minutes on this 12-CPU host, against about 29 to 32 serially.

The repository has no `.guardrails/config.yaml`, so `check-ids.sh` and `check-trace.sh` ran on scratch copies built from `main` and from the change with `templates/config.yaml`, and `merge-preflight.sh` was not run; the base and change outputs are compared, as in `docs/verification/2026-10-03-accept-2scmvn.md`.

`tests/evidence.sh main` on the same tree: suite 1101 tests (main: 1074); 27 new or renamed; 1 goes red against `main`'s scripts (`ratchet: the setup checklist installs GNU parallel for the qualification suite`); 26 cannot go red, which are every test in `tests/run-tests.bats`. `evidence.sh` swaps in `main`'s `scripts/` only, and neither `tests/run-tests.sh` nor `tests/helpers.bash` is under `scripts/`; their red runs are the dispatch reports' below.

## Red → green

| Item | Test | Watched red |
| --- | --- | --- |
| PR-r83mmd | `run-tests: a named .bats file runs alone, without the whole suite`; `run-tests: two named files run, and nothing else` | the stub received the named files and then all of `tests/*.bats` |
| PR-r83mmd | `run-tests: an option value ending in .bats that names no file keeps the glob` | the stub received only `--filter foo.bats`, the glob dropped (review finding-6) |
| PR-r83mmd | `run-tests: a named directory runs alone, without the whole suite` | the stub received the directory and then every file (finding-9) |
| PR-r83mmd | `run-tests: with no argument, every file in tests/ runs`; `run-tests: an option alone still runs every file` | green from the start, by design: they pin the behavior the fix keeps |
| PR-hrx4vf | `RUN_TESTS_JOBS=3` passes `--jobs 3`; `=0`, non-numeric, negative and trailing-junk values exit 2; empty counts as unset; unset with GNU `parallel` passes the CPU count; the `sysctl` fallback; `--jobs` before the caller's arguments; an explicit count without `parallel` | no `--jobs` was passed, or the run exited 0 where 2 was expected |
| PR-hrx4vf | `run-tests: a parallel that is not GNU parallel counts as absent, and the run is serial` | `--jobs 4` passed for a moreutils stub (finding-2) |
| PR-hrx4vf | `run-tests: a non-numeric CPU count counts as 1 and passes no --jobs` | red with the non-numeric arm deleted (finding-4) |
| PR-hrx4vf | `run-tests: a RUN_TESTS_JOBS longer than 4 digits exits 2 and names the bound and value` | exit 0 and a serial run (finding-5), then the old message (finding-10) |
| PR-hrx4vf | `run-tests: a caller's own -j N passes through, and no second one is added` | red with the caller-flag arm cut to `(--jobs)` once the test set `runner_jobs=3` (finding-8) |
| PR-hrx4vf | `RUN_TESTS_JOBS=1`; a CPU count of 1; no `getconf` or `sysctl`; the caller's `--jobs N`; unset without `parallel` | green from the start: they pin behavior that already held |
| PR-hrx4vf | `ratchet: the setup checklist installs GNU parallel for the qualification suite` | failed with "no GNU parallel item"; the one test `evidence.sh` measured red |
| PR-2nxadp | `outside_bats: the command runs without bats's libexec directory on PATH` | red serially with `outside_bats` made a passthrough (finding-3) |
| PR-2nxadp | `evidence: a test name with a backslash escape is matched to the name bats reports`; `evidence: a new test whose escaped name passes on the base is listed as unable to go red`; `the capture reaches a real bats run's output` | under `--jobs 4` with the fix reverted: `not ok`, the nested run printing `bats_readlinkf: command not found`; `ok` with it. They carry the IDs they were written for (PR-9aaart, PR-2scmvn) |

## What was wrong, and what was built

`tests/run-tests.sh` appended its arguments to `"$dir"/*.bats`, so naming one
file ran it twice and the whole suite once (PR-r83mmd). An argument that names
an existing `.bats` file or directory now replaces the glob.

The suite ran serially (PR-hrx4vf). Measured on one tree, a serial run took
1907 s and two `--jobs 12` runs 776 s and 659 s, but the parallel runs failed
three tests (PR-2nxadp). bats puts its internal libexec directory on `PATH`
(`tests/.bats-core/libexec/bats-core/bats:117`), so a nested `command -v bats`
found the internal entry point, which needs the `bats_readlinkf` function that
`bin/bats` exports; GNU `parallel` starts each file without it. `outside_bats`
in `tests/helpers.bash` resolves a nested bats with that entry removed. With
that fixed, `tests/run-tests.sh` passes `--jobs <CPU count>` where GNU
`parallel` is installed, `RUN_TESTS_JOBS` overrides it, and an invalid value
exits 2. The ratchet setup checklist installs `parallel`.

The change also carries the roadmap and opens PR-sc5qy5 and PR-555dk4, the two
findings the roadmap keeps as items rather than phases.

## Review

Round 2's findings are numbered on from round 1's.

### Round 1

Reviewed at `b16c147`, base `main` `821e783`. Reviewer's own suite run, in parallel: 1..1096, 1096 ok, 0 not ok, exit 0, about 34 minutes wall time with the reviewer's probes running alongside. Verdict: changes requested — two medium code findings (finding-1, finding-2); the rest are low or record.

**finding-1**: code, medium — The `tests/run-tests.bats` tests are reachable by the host's own `parallel` and by the caller's `RUN_TESTS_JOBS`. Tests 1, 2 and 4 (`tests/run-tests.bats:20`, `:27`, `:41`) call `env PATH=...` without `-u RUN_TESTS_JOBS`; `RUN_TESTS_JOBS=4 tests/.bats-core/bin/bats tests/run-tests.bats` fails tests 1, 2 and 4 with `--jobs 4` in the output (reproduced). Every helper puts `/usr/bin:/bin` on `PATH`, and `apt install parallel`, which this change's own checklist tells Debian users to run (`setup-checklist.md:34`), installs `/usr/bin/parallel`; on any multi-CPU Debian host tests 1, 2, 4 and 19 then fail (not reproduced; follows from the code). The plan's T1 Step 1 claim that `/usr/bin:/bin` keeps the host's `bats` and `parallel` out is false on Debian.
disposition: every test in `tests/run-tests.bats` runs through `run_runner`, whose `PATH` holds only the stub directory and a tools directory of the commands the runner needs, under `env -u RUN_TESTS_JOBS`; the plan's T1 sentence is corrected. `RUN_TESTS_JOBS=4 tests/.bats-core/bin/bats tests/run-tests.bats` passes 25/25 (fix commit `8ee908b`).

**finding-2**: code, medium — `tests/run-tests.sh:61` detects `parallel` with `command -v parallel`, but D7 and T3 say GNU `parallel`. moreutils ships a non-GNU `parallel`; on a host with only that, the default run passes `--jobs` and bats runs nothing, and `bats-exec-suite:96` aborts only when the binary is absent. Reproduced with a stub that rejects options: `1..2`, `parallel: invalid option`, `# bats warning: Executed 0 instead of expected 2 tests`, rc=1. Fails closed, but the message does not name the cause.
disposition: `gnu_parallel_installed` in `tests/run-tests.sh` counts `parallel` only when `parallel --version` names GNU parallel; test `run-tests: a parallel that is not GNU parallel counts as absent, and the run is serial` was red (`--jobs 4` passed) before the fix.

**finding-3**: requirement, low — No test carries `verifies: PR-2nxadp`, which `skills/resolve-problem/SKILL.md:82-83` requires of the reproduction. The red -> green tests are annotated PR-9aaart (`tests/evidence.bats:61`, `:69`) and PR-2scmvn (`tests/portability.bats:473`), and go red only under `--jobs`: with `outside_bats` replaced by a passthrough, a serial run stays 15/15 green, so on a host without `parallel` nothing guards the helper.
disposition: test `outside_bats: the command runs without bats's libexec directory on PATH` (`verifies: PR-2nxadp`), red serially with `outside_bats` made a passthrough.

**finding-4**: code, low — The fallback to 1 on a non-numeric CPU count (`tests/run-tests.sh:71-73`) has no test; deleting the `*[!0-9]*` arm survives `tests/run-tests.bats`.
disposition: test `run-tests: a non-numeric CPU count counts as 1 and passes no --jobs`, red with the `*[!0-9]*` arm deleted.

**finding-5**: code, low — `RUN_TESTS_JOBS=99999999999999999999` prints `[: integer expression expected` twice (`tests/run-tests.sh:43`, `:78`), then runs serially and exits 0, against the comment at `tests/run-tests.sh:31-33` that a bad value must not fall back to a serial run.
disposition: a `RUN_TESTS_JOBS` longer than four digits exits 2 before any numeric test; its test was red (status 0, serial run) before the fix. finding-10 corrected the message.

**finding-6**: code, low — Two behaviors with no claim behind them: an option value ending in `.bats` (`--filter foo.bats`) counts as a named file and drops the glob (`tests/run-tests.sh:25-29`); and `--jobs=N` is recognised as the caller's job count (`tests/run-tests.sh:53`, pinned at `tests/run-tests.bats:203-209`), a spelling bats 1.11 rejects (`tests/.bats-core/libexec/bats-core/bats:216`).
disposition: (a) a `.bats` argument counts as a file only when `[ -f ]` holds; test `run-tests: an option value ending in .bats that names no file keeps the glob` was red before the fix. (b) the `--jobs=*` arm and its test are removed.

**finding-7**: record — D7 conditions the parallel default on the serial and `--jobs` counts matching; T2 measured a mismatch, and nothing in the tree records a re-measurement after T5. The reviewer's run is that evidence and the record should state it with its tree, and the wall time (about 34 minutes, against the plan's "about 12" and PR-2nxadp's serial 1907 s), on which D10's five-minute threshold depends.
disposition: the gate table below gives the serial and `--jobs` runs on one tree after T5, with identical per-test results, and their wall times; the plan's T2 and the roadmap's D7 now say the condition was re-measured (finding-12).

### Round 2

Reviewed at `5d9e05b`, base `main` `821e783`. Reviewer's own suite run, in parallel (`--jobs 12`): 1..1100, 1100 ok, 0 not ok, exit 0. Sixteen hand mutations of `tests/run-tests.sh`, fifteen killed; `outside_bats` made a no-op turned four tests red under `--jobs 4` and the direct test red serially. Verdict: converged — findings 1 to 3 are code, all low; 4 and 5 are record; with nothing above low, this is the last review round.

**finding-8**: code, low — Nothing tests that a caller's `-j N` suppresses the runner's own `--jobs`: making `tests/run-tests.sh:65` read `(--jobs)` alone turns no test red. The test at `tests/run-tests.bats:262-269` leaves `RUN_TESTS_JOBS` unset and has no `getconf` on `PATH`, so the runner's count is 1 and it would add no `--jobs` either way.
disposition: the `-j N` test now sets `runner_jobs=3`, so the runner would add `--jobs` without the caller-flag arm; red with the case cut to `(--jobs)` alone (fix commit `b79add3`).

**finding-9**: code, low — A directory argument still runs the suite twice, the same defect as PR-r83mmd by another route: `tests/run-tests.sh:27-34` recognises only `*.bats` files, so `sh tests/run-tests.sh tests/`, which bats accepts natively, gets the glob appended; `bats --count tests/` through the runner printed 2200 against the suite's 1100. No test covers a directory argument.
disposition: an argument naming an existing directory counts as named; test `run-tests: a named directory runs alone, without the whole suite` (`verifies: PR-r83mmd`) was red, the stub seeing the directory and then every file.

**finding-10**: code, low — `tests/run-tests.sh:47-52` rejects any value of five or more characters with "must be a positive integer, not '10000'", though 10000 is one, and the comment's "More than four digits can overflow the shell's integer test" overstates it: on macOS sh `[ 99999 -lt 1 ]` works, and overflow begins at 19 digits. `00004` is also rejected. The cap is a sanity bound and the message should say so.
disposition: the cap has its own message, `RUN_TESTS_JOBS must be at most 9999, not '<value>'`, and its comment calls it a sanity bound; the test checks the boundary value `10000` and was red against the old wording.

**finding-11**: record — PR-r83mmd's resolution line (`docs/problems/2026-10-07-test-runner-salvage.md:12`) says "an argument ending in `.bats` now replaces it"; since round 1 that holds only when the argument names an existing file (`tests/run-tests.sh:29-31`), and the line omits the test `run-tests: an option value ending in .bats that names no file keeps the glob`.
disposition: PR-r83mmd's resolution line now says an existing `.bats` file or directory replaces the glob, and names the option-value test (`cbb1823`).

**finding-12**: record — Roadmap D7 says a test that fails only under `--jobs` "becomes a problem item and the default stays serial", and plan T2 says "T3 is not done". Three tests did (PR-2nxadp); T5 fixed them and T3 shipped the default, but neither document says D7's condition was met again after T5, or records the re-measured `--jobs` counts D7 requires. This round's 1100/1100 under `--jobs 12` is such a measurement, and the record should cite one.
disposition: the plan's T2 and the roadmap's D7 state that the condition was measured again after T5; the counts are in the gate table below (`cbb1823`).

## Gaps

- No test of `tests/run-tests.sh` or `outside_bats` can be shown red by `tests/evidence.sh`, which swaps `scripts/` only; their red runs rest on the dispatch reports.
- Parallel runs were measured on one macOS host with 12 CPUs and GNU `parallel` 20260822. No Linux host, and no host with a system bats on `PATH`, was measured; the Debian `/usr/bin/parallel` case of finding-1 was reasoned, not reproduced.
- A bats option whose value is an existing directory, such as `--output <dir>`, counts as a named directory, so the glob is dropped and bats runs no files; the run fails rather than passing, but the message does not name the cause. A joined `-j5` is not recognised as the caller's job count.
- `merge-preflight.sh` does not run in this repository, which has no `.guardrails/config.yaml`. `check-review.sh --branch test-runner` ran on a scratch copy of the commit that added this record: exit 0, 12 findings for `test-runner`.
