# Problem report — the test runner, and two findings the roadmap keeps as items

Recorded by phase 1 of the roadmap in
`docs/plans/2026-10-06-salvage-churn-and-parallel.md` (D6, D13). `affects:`
names files, because guardrails keeps no REQ/SDD/LLR ledger of its own.

**PR-r83mmd**: `sh tests/run-tests.sh tests/<file>.bats` runs the whole suite and then the named file a second time, because the script appends its arguments to the `tests/*.bats` glob instead of replacing it.
affects: tests/run-tests.sh, and every plan or dispatch prompt that runs one test file through it.
opened: 2026-10-06
status: resolved
Resolved: the runner appended its arguments to the glob; an argument that names an existing `.bats` file or directory now replaces it (`tests/run-tests.sh`; tests in `tests/run-tests.bats`, among them `run-tests: a named .bats file runs alone, without the whole suite`, `run-tests: two named files run, and nothing else` and `run-tests: an option value ending in .bats that names no file keeps the glob`).

Measured on 2026-09-18 as 430 tests reported for a 234-test file. Sessions
have worked around it by calling `tests/.bats-core/bin/bats` directly.

**PR-sc5qy5**: No gate distinguishes a sentence about an unmerged branch from a sentence about the tree under merge, so a document can state another worktree's state as a fact about this one and every check passes.
affects: scripts/check-trace.sh, and every document under `strict_paths` that names a branch.
opened: 2026-10-06
status: open

Seen in every review round of the discarded churn proposal (2026-09-18),
including after reviewers were told to hunt for it. A candidate check: a
backtick-quoted token that matches a local branch not merged into the base
branch, excluding the branch under merge and the base itself, is reported as a
warning with its file and line. A deleted branch falls silent on its own. It
catches a named branch only; a claim wrong by omission stays with the
reviewer.

**PR-555dk4**: `analyze-risks` gives no guidance on how to design a risk control so that a test can show it works, so each change derives control design afresh.
affects: skills/analyze-risks/SKILL.md, and the risk controls written under it.
opened: 2026-10-06
status: open

The discarded churn proposal (D4) proposed a `design-controls` section stating
four laws of control design and the rule that each control ships with the
mutation that defeats its predecessor. Only one of the four laws was ever
written down, argued for one case in the mutation-evidence plan. Its other two
parts, a kill line per test in the dispatch report and a `killed:` column in
the verification record, would mostly restate the mutation evidence `main`
already keeps (`tests/mutate.sh`, the `docs/verification/*.mutations/`
scripts, the `red -> green:` lines).

**PR-hrx4vf**: `tests/run-tests.sh` runs the suite serially even where GNU `parallel` is installed and bats 1.11 could run it with `--jobs`, so every gate, every reviewer's own run and every install-time qualification run pays the full serial time.
affects: tests/run-tests.sh, skills/ratchet/references/setup-checklist.md.
opened: 2026-10-06
status: resolved
Resolved: `tests/run-tests.sh` passes `--jobs <CPU count>` where GNU `parallel` is installed, with `RUN_TESTS_JOBS` to override (tests in `tests/run-tests.bats`), and the ratchet setup checklist installs `parallel` (`ratchet: the setup checklist installs GNU parallel for the qualification suite`).

A serial run was measured by an earlier session at about 25 minutes. Whether
the suite is safe to run in parallel has never been measured; PR-2scmvn's
intermittent temporary-file failures are the known risk.

**PR-2nxadp**: Under `bats --jobs 12` three tests that start a bats run of their own fail on every run and pass serially: `evidence: a test name with a backslash escape is matched to the name bats reports`, `evidence: a new test whose escaped name passes on the base is listed as unable to go red` and `the capture reaches a real bats run's output`.
affects: tests/evidence.bats, tests/portability.bats, tests/evidence.sh, and PR-hrx4vf, whose parallel default waits on this item.
opened: 2026-10-06
status: resolved
Resolved: bats puts its internal libexec on `PATH`, whose entry point needs a function `parallel` does not carry; `outside_bats` in `tests/helpers.bash` resolves a nested bats without that entry. The three tests named above are the red -> green evidence.

Measured 2026-10-06 on one tree: a serial run passed 1074 of 1074 in 1907 s;
two `--jobs 12` runs each passed 1071, failing the same three, in 776 s and
659 s. The inner run reports `bats_readlinkf: command not found` and looks for
`bats-exec-test` in the test's own directory, which points at the outer
parallel run's environment reaching the nested bats.
