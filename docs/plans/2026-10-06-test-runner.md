# Phase 1: the test runner runs what it is given, in parallel where it can

**Roadmap:** `docs/plans/2026-10-06-salvage-churn-and-parallel.md`, phase 1
(D6, D7, D8, D13).
**Resolves:** PR-r83mmd (D6), PR-hrx4vf (D7, D8), PR-2nxadp (T5).
**Opens:** PR-sc5qy5, PR-555dk4 (D13), recorded without a fix.

## Tasks

| Task | Files touched | Depends on |
|---|---|---|
| T1 — a `.bats` argument replaces the glob | `tests/run-tests.sh`, `tests/run-tests.bats` (new) | — |
| T2 — measure the suite serially and with `--jobs` | none (a report) | — |
| T3 — `--jobs <CPUs>` by default where `parallel` is installed | `tests/run-tests.sh`, `tests/run-tests.bats` | T1, and T2's counts matching |
| T4 — the setup checklist installs GNU `parallel` | `skills/ratchet/references/setup-checklist.md`, `tests/skills.bats` | — |
| T5 — a nested bats run resolves `bin/bats` | `tests/helpers.bash`, `tests/evidence.bats`, `tests/portability.bats` | T2 |

T1, T2 and T4 run in parallel: their file sets do not intersect. The dispatcher
sets PR-r83mmd and PR-hrx4vf to `resolved` in the change's problem draft after
the tasks merge, so no task edits that file.

### T1 — a `.bats` argument replaces the glob

Step 1. Write `tests/run-tests.bats`. It runs the real `tests/run-tests.sh`
with a stub `bats` first on `PATH` that prints each argument on its own line,
so the test reads exactly what the runner would have run. `PATH` is the stub
directory plus a tools directory of symlinks to the commands the runner needs
(`dirname`, and `getconf` only where a test wants the host's CPU count), so
the host's own `bats` and `parallel` are not found. `/usr/bin:/bin` would not
keep them out: Debian's `parallel` package installs `/usr/bin/parallel`.

*(Code pruned at merge: 48 lines.)*

Step 2. Run it and watch the first and second tests fail for the right
reason: the output carries the whole glob after the named file. The third and
fourth pass against the old runner by design: they pin the behavior the fix
must keep, so a fix that drops the glob for any argument goes red.

*(Code pruned at merge: 1 line.)*

Step 3. Replace the last line of `tests/run-tests.sh`:

*(Code pruned at merge: 14 lines.)*

Step 4. Run `tests/run-tests.bats` and `tests/portability.bats`; both pass.
Commit.

### T2 — measure the suite serially and with `--jobs`

A subagent in task worktree `.worktrees/test-runner-measure` runs the
vendored bats over `tests/*.bats` once serially and twice with `--jobs 12`,
one run after another, and reports each run's plan count, `ok` and `not ok`
counts, failing test names, exit code and elapsed seconds. It commits nothing.
The counts decide T3: identical results let T3 proceed; a test that fails only
under `--jobs` becomes a problem item, and T3 is not done.

T2 measured three such tests (PR-2nxadp). T5 fixed them, and the condition
was measured again before the default merged: the gate ran the suite serially
and with `--jobs 12` on one tree, with identical per-test results. The
verification record gives the counts and the tree.

### T3 — `--jobs <CPUs>` by default where `parallel` is installed

Written after T2 reports, against T1's runner. The behavior:

- `RUN_TESTS_JOBS=1` runs serially; `RUN_TESTS_JOBS=<n>`, for a positive
  integer `n`, passes `--jobs n`; any other value exits 2 with a message.
- Unset, and GNU `parallel` on `PATH`: `--jobs <CPU count>`, the count from
  `getconf _NPROCESSORS_ONLN`, falling back to `sysctl -n hw.ncpu`, then to 1.
  A count of 1 passes no `--jobs`.
- A caller's own `--jobs` or `-j` is passed through untouched, and no second
  one is added.
- `parallel` absent: serial, as today.

Each bullet gets a test in `tests/run-tests.bats` (`verifies: PR-hrx4vf`), with
a stub `parallel` on `PATH` where one is wanted.

### T4 — the setup checklist installs GNU `parallel`

Step 1. Add a test to `tests/skills.bats`:

*(Code pruned at merge: 7 lines.)*

Watch it fail.

Step 2. In `skills/ratchet/references/setup-checklist.md`, insert before the
tool qualification item:

*(Code pruned at merge: 4 lines.)*

Step 3. The test passes. Commit.

### T5 — a nested bats run resolves `bin/bats` (PR-2nxadp)

Added after T2 measured three tests failing only under `--jobs`. bats puts its
internal libexec directory on `PATH` (`tests/.bats-core/libexec/bats-core/bats:117`),
so a nested `command -v bats` finds the internal entry point, which needs the
`bats_readlinkf` function that `bin/bats` exports; GNU `parallel` starts each
file without it. `outside_bats` in `tests/helpers.bash` runs a command with that
entry removed from `PATH`, and the two places that resolve a nested bats
(`tests/evidence.bats` setup and the portability capture test) use it. The
three tests are the red -> green evidence: red under `--jobs 4` with the fix
reverted, green with it.

## Review round 1

The listings under T1 and the behavior under T3 are the text as dispatched.
Review round 1 (findings 1 to 6, in the verification record) reworked them:
every test now runs through one `run_runner` helper whose `PATH` holds only
stubs and the tools the runner needs, with `RUN_TESTS_JOBS` unset unless the
test sets it; `parallel` counts as present only when `parallel --version`
names GNU parallel; a `.bats` argument names a file only when the file exists;
`RUN_TESTS_JOBS` longer than four digits exits 2; `--jobs=N` is no longer
recognised, because bats 1.11 rejects it; and `outside_bats` has a direct test
annotated PR-2nxadp. The diff is authoritative.
