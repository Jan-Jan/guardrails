# Verification — linux-suite (2026-10-11)

branch: worktree-linux-test-isolation
reviewer: an independent Claude subagent with fresh context, given the diff, the plan, the problem ledger, AGENTS.md and the review checklist only (merge-change step 6a), round 1 at `b0a1991`
verdict: all three claimed items resolved and every new test goes red when its fix is reverted; every finding was low or a record finding, so round 1 was the last review round, and each was fixed mechanically
reproduced: yes. PR-gw6wts and PR-cjvv8g were seen failing in full suite runs on `main` at `dd411a1` (gawk and mawk; busybox awk) and then reproduced by the tests named below. PR-8zcc72 was seen failing intermittently in the same runs; an instrumented copy of the suite captured its `git log` dying at exit 141 with no verdict letter, and `check-signing: a verdict git could not compute fails without --strict` reproduces that state deterministically

Change: the suite passes on Linux under gawk, mawk and busybox awk, and `check-signing.sh` fails a signed commit whose verdict git could not compute; resolves PR-gw6wts, PR-cjvv8g and PR-8zcc72. Branched from `main` at `1967dc8`; base merged from local `main` at `1967dc8`, per AGENTS.md non-negotiable 4.
Plan: `docs/plans/2026-10-11-linux-suite.md`.

## The gate

Measured on: `5643ff7` — `git rev-parse HEAD` — tree `90e4adbcf3ee3500232ec5167f059316c1aa04ae`, clean worktree, `main` at `1967dc8`. The ledger file was renamed before this round and step 1 pruned nothing, so this is the tree that merges, apart from this record.

| Gate | Result |
| --- | --- |
| `sh tests/run-tests.sh`, gawk 5.3.2 | 1..1283, 1283 ok, 0 not ok, 4 skipped, exit 0, 90 s |
| `sh tests/run-tests.sh`, mawk 1.3.4 first on `PATH` | 1..1283, 1283 ok, 0 not ok, 4 skipped, exit 0, 87 s |
| `sh tests/run-tests.sh`, BusyBox 1.37.0 awk first on `PATH` | 1..1283, 1283 ok, 0 not ok, 4 skipped, exit 0, 90 s |
| `check-ids.sh --allow-draft-files` (scratch config, change and `main`) | exit 1 on both, 69 lines each, byte-identical: the change adds no finding |
| `check-trace.sh` (scratch config, change and `main`) | exit 2 on both, `doc_srs is configured as 'docs/requirements', which does not exist`: no ledger is checked in either tree |
| Coverage | not configured |
| Working tree | clean |

The four skips in each run are the three real-BWK-awk contract tests and the real-BSD-date contract test: neither tool is on this machine. BWK awk is therefore covered only by the `tests/portability.bats` stub. The repository has no `.guardrails/config.yaml`, so `check-ids.sh` and `check-trace.sh` ran with a scratch config built from `templates/config.yaml`; `finalize-docs.sh` could not run and the draft ledger was renamed by hand; `merge-preflight.sh` was not run, as in `docs/verification/2026-10-08-supersession-reannotation.md`. No plan was left whole.

## Red → green

| Item | Test | Watched red |
| --- | --- | --- |
| PR-gw6wts | `check-signing: a test does not read the developer's global git config` | with `isolate_git_config` out of `setup()`: "verified against the planted global trust root" |
| PR-cjvv8g | `every case pattern in executable shell opens with a parenthesis` | under busybox awk with `gsub("\\047", …)`: first the live scan flagged `for shape in oneline …`, then, after the round 1 control, "the scan flags the compliant quoted spelling" |
| PR-8zcc72 | `check-signing: a verdict git could not compute fails without --strict` | `expected exit 1, got 0: WARN-UNVERIFIED …` |
| PR-8zcc72 | `check-signing: a verdict git could not compute with an unreadable trust root exits 2` | with the guard call out of the `(failed)` branch: `expected exit 2` |

Scope control, not attested: `check-signing: a verdict git could not compute fails under --strict`.

No test was inherited.

## What was wrong, and what was built

The suite run once per awk on Linux (Ubuntu, git 2.53.0, OpenSSH 10.2p1) failed in five distinct tests, all in test code or exposed by it; no script misbehaved under any awk.

`tests/check-signing.bats` isolated only some tests from the developer's git configuration, so a test that unset the fixture's `gpg.ssh.allowedSignersFile` read the maintainer's global one and failed on that machine (PR-gw6wts). `setup()` now isolates every test, and a test plants a global config in a HOME of its own so the leak reproduces anywhere.

The case-pattern lint in `tests/portability.bats` counted single quotes with `gsub("\\047", …)`. BusyBox awk does not decode an octal escape in a dynamic regex (0 matches in `a'b`, against 1 under gawk and mawk), so a quoted `case` read as code (PR-cjvv8g). The lint uses the regex literal `/\047/`, and a calibration control holds a quoted `case` followed by a loop.

When find-principals fails, git writes the signed payload to a second verifier call on stdin. A verifier that has already exited kills `git log --format=%G?` with SIGPIPE, and `check_commits` read the empty answer as a signature that did not verify and passed it without `--strict` (PR-8zcc72). A `git log` that fails on a signed commit is now `UNVERIFIED (git could not compute a verdict for this signature)` in both modes, as `B` is, after the same trust-root guard; an unsigned commit is reported `UNSIGNED` as before. The test stub for a broken verifier reads its payload, so the tests that use it measure `B`.

## Review

### Round 1

**finding-1**: code, low — `break_the_verifier` still exits without reading its stdin, so the race behind PR-8zcc72 remains in the tests that use it; they pass because `(failed)` also prints UNVERIFIED at exit 1, and on a run where the race fires they exercise `(failed)` instead of the `(B|X|Y|R)` branch they claim to verify.
disposition: the stub reads the payload on the check-novalidate and verify calls before it fails; `tests/check-signing.bats` passed 35 of 35 in three concurrent runs.

**finding-2**: code, low — the `(failed)` branch's unsigned arm has no test (a mutant of it left all 33 tests green), and there is no `--strict` case for the `(failed)` path.
disposition: a failed `git log` becomes `failed` only for a commit with a `gpgsig` header, so the unsigned arm is gone and an unsigned commit takes `*)` as on `main`; `check-signing: a verdict git could not compute fails under --strict` added.

**finding-3**: code, low — the `(failed)` branch drops `trust_root_env_guard`, contradicting the script header's exit 2 in every mode for an unreadable trust root.
disposition: the branch calls the guard; `check-signing: a verdict git could not compute with an unreadable trust root exits 2` reddens without it.

**finding-4**: code, low — the PR-cjvv8g guard depends on incidental text: no calibration control holds a quoted `case`.
disposition: a `good-quoted` control added; red under busybox awk with the old `gsub`, green with the fix.

**finding-5**: record — the plan said the PR-cjvv8g test fails only under busybox awk "which the gate runs", but `tests/run-tests.sh` runs whatever awk is first on `PATH`.
disposition: the plan says busybox awk was put first on `PATH` by this change's gate, and that nothing in `tests/run-tests.sh` does so.

**finding-6**: record — the plan's counts predate the HOME-planting test.
disposition: the plan states that each figure is as of the commit it names; the final counts are in this record.

## Guideline reviews

### docs/TEST_GUIDELINES.md

Governs: scripts/check-signing.sh tests/check-signing.bats tests/portability.bats

### Round 1

The review raised no finding; verdict "0 findings (0 high, 0 medium, 0 low); none above low", run after the deslop pass. Its note-1, that the PR-gw6wts and PR-cjvv8g tags fail only on one machine shape, was acted on: the HOME-planting test for PR-gw6wts, and the round 1 quoted-`case` control for PR-cjvv8g.

## Gaps

- BWK awk and BSD `date` were not run: this machine has neither, and their contract tests skipped. macOS is covered by the stubs alone.
- PR-cjvv8g's test reddens only under busybox awk. `tests/run-tests.sh` runs whatever awk is first on `PATH`, so a default gawk gate would not catch the old `gsub` returning.
- PR-8zcc72 and PR-gw6wts have abnormal-input tests under their own IDs; their normal cases are covered by existing tests under other IDs.
- The full suite was run serially per awk. The concurrency that exposed PR-8zcc72 was exercised on `tests/check-signing.bats` alone after the fix.
