# Plan — the suite on Linux under gawk, mawk and busybox awk

Change branch: `worktree-linux-test-isolation`. Problem items:
`docs/problems/2026-10-11-linux-suite.md`.

**Goal:** `tests/run-tests.sh` passes on Linux under each of the three awks
installed here, and a signature git could not compute a verdict for fails.
**Implements:** PR-gw6wts, PR-cjvv8g, PR-8zcc72.
**Safety class:** unclassified (the toolkit has no `.guardrails/config.yaml`).
**Verification:** `sh tests/run-tests.sh`, once with each of gawk, mawk and
busybox awk first on `PATH`; `check-ids.sh` and `check-trace.sh` against a
scratch config built from `templates/config.yaml`.

Opened at the user's request of 2026-10-08 to test that every script works on
Linux. Three full suite runs on `main` at `dd411a1`, one per awk (gawk 5.3.2,
mawk 1.3.4, BusyBox 1.37.0), failed only in tests: five distinct tests, all
recorded before any investigation. BWK awk is not installed on this machine,
so its contract tests skipped and only the `tests/portability.bats` stub
covered it.

Each task is one problem item, fixed under TDD by the dispatcher, not a task
subagent. Each was a one-file test change or a one-branch script change,
diagnosed in the dispatcher's own context, as in earlier small plans.

## Task 1 — global git config leaks into a signing test (PR-gw6wts)

Files touched: `tests/check-signing.bats`.
`setup()` calls `isolate_git_config` for every test in the file.
red -> green: `check-signing: a test does not read the developer's global git
config` — plants a `~/.gitconfig` naming a trust root in a HOME of its own;
red with `isolate_git_config` taken out of `setup()` ("verified against the
planted global trust root"), green with it. Added after the guideline review's
note-1: `check-signing: the verifier's reason is reported once, under its
verdict`, the test that first showed the leak, fails without the fix only on a
machine configured like this one, so it keeps `verifies: PR-whkz8m` alone. It
was red here in all three suite runs and green after.

## Task 2 — busybox awk does not decode `\047` in a dynamic regex (PR-cjvv8g)

Files touched: `tests/portability.bats`.
The case-pattern scanner's `inquote()` matches a single quote with
`gsub(/\047/, …)`.
red -> green: `every case pattern in executable shell opens with a
parenthesis` — red under busybox awk (flagged `for shape in oneline …` at
`tests/portability.bats:513`), green under busybox awk, mawk and gawk after.

## Task 3 — a `git log` that dies passes as WARN-UNVERIFIED (PR-8zcc72)

Files touched: `scripts/check-signing.sh`, `tests/check-signing.bats`.
A failing `git log --format=%G?` sets the verdict to `failed`: a signed
commit is `UNVERIFIED` in both modes, followed by the verifier's reason, and
an unsigned commit stays `UNSIGNED`. Diagnosed from an instrumented copy of
the suite, run twice concurrently: 5 broken-verifier calls returned `B` at
exit 0, and one returned no letter at exit 141 (SIGPIPE), the run whose test
failed. The new test's stub kills its parent git with SIGPIPE on the first
call only, so the crash is deterministic and the `git verify-commit` that
collects the reason still runs.
red -> green: `check-signing: a verdict git could not compute fails without
--strict` — red (`expected exit 1, got 0: WARN-UNVERIFIED …`), green after;
`tests/check-signing.bats` then passed 32 of 32 serially and in three
parallel runs.
red -> green: `check-signing: a verdict git could not compute with an
unreadable trust root exits 2` — added at review round 1 (finding-3); red with
the `trust_root_env_guard` call taken out of the `(failed)` branch (`expected
exit 2`), green with it.
`check-signing: a verdict git could not compute fails under --strict` — added
at review round 1 (finding-2); a scope control on the strict path, red only
against `main`'s wording, not attested.

## Progress

- Tasks 1–3 done by the dispatcher on 2026-10-11.
- Deslop pass (2026-10-11, commit 6766c06): every test in
  `tests/check-signing.bats` now inherits `isolate_git_config` from
  `setup()`, so the explicit calls were removed and the helper moved above
  `setup()`; the killing stub became a heredoc. Left alone: the `(failed)`
  branch's own `gpgsig` check, since sharing `(*)`'s path would add
  `trust_root_env_guard` and an exit 2. 50 of 50 in the two files (4 skips).
  The plan's failed-test count was corrected to five.
- Guideline review against `docs/TEST_GUIDELINES.md` (2026-10-11): 0
  findings. note-1 (two `verifies:` tags fail only on one machine shape) is
  acted on for PR-gw6wts by the HOME-planting test. For PR-cjvv8g it was
  answered at review round 1 (finding-4, below). note-2 (the lint is not at a
  script's command line) and note-3 (red evidence for PR-8zcc72, recorded
  under Task 3) need no change.
- Review round 1 (2026-10-11, at `b0a1991`): all findings low or record, so
  it is the last round; each was fixed mechanically.
  - finding-1: `break_the_verifier`'s stub now reads the payload on the
    check-novalidate and verify calls, so the tests that use it measure `B`
    and not a dead git. `tests/check-signing.bats` passed 35 of 35 in three
    concurrent runs.
  - finding-2: a failed `git log` becomes `failed` only for a commit with a
    `gpgsig` header; an unsigned one falls to `*)` as on `main`, so the
    untested unsigned arm is gone. A `--strict` test was added.
  - finding-3: the `(failed)` branch calls `trust_root_env_guard`, keeping
    the header's exit 2 for an unreadable trust root; tested (Task 3).
  - finding-4: the case-pattern lint gained a `good-quoted` calibration
    control, a `case` after an unclosed single quote followed by a `for`
    loop. Red under busybox awk with `gsub("\\047", …)` restored ("the scan
    flags the compliant quoted spelling"), green with the fix, so the guard
    no longer depends on incidental text in the file.
  - finding-5: corrected. The default gate runs whatever `awk` is first on
    `PATH`, gawk here. PR-cjvv8g's test is red only under busybox awk, which
    this change's gate runs by putting it first on `PATH`; nothing in
    `tests/run-tests.sh` does so.
  - finding-6: final counts are in the verification record, not here; the
    figures above are each as of the commit they name.
