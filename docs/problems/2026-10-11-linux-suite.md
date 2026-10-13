# Problem reports — the suite run on Linux under gawk, mawk and busybox awk

Recorded by change `worktree-linux-test-isolation`, which ran
`tests/run-tests.sh` once per awk on Linux (Ubuntu, git 2.53.0,
OpenSSH 10.2p1, gawk 5.3.2, mawk 1.3.4, BusyBox 1.37.0). Two of the failures
were in tests; the third was a test that exposed a defect in
`scripts/check-signing.sh`. `affects:` names files, because guardrails keeps
no REQ/SDD/LLR ledger of its own.

**PR-gw6wts**: `check-signing: the verifier's reason is reported once, under its verdict` fails on a machine whose global git config sets `gpg.ssh.allowedSignersFile`, because the test unsets only the repository's value and git falls back to the global one.
affects: tests/check-signing.bats.
opened: 2026-10-11
status: resolved
Root cause: only some tests in `tests/check-signing.bats` called `isolate_git_config`, so a test that unset a fixture setting read the developer's global value in its place; `setup()` now isolates every test in the file. Reproduced on every machine by `check-signing: a test does not read the developer's global git config`, which plants a global config in a HOME of its own.

**PR-cjvv8g**: Under busybox awk, `every case pattern in executable shell opens with a parenthesis` reports the words of a `for` loop in `tests/portability.bats` as case patterns, because the scanner's `inquote()` counts single quotes with `gsub("\\047", …)` and busybox awk does not decode an octal escape in a dynamic regex.
affects: tests/portability.bats.
opened: 2026-10-11
status: resolved
Root cause: measured, `gsub("\\047", "", c)` on `a'b` returns 0 under BusyBox 1.37.0 awk and 1 under gawk and mawk, while the regex literal `gsub(/\047/, "", c)` returns 1 under all three; the scanner now uses the literal. Reproduced by that test under busybox awk, red before and green after, and green under gawk and mawk.

**PR-8zcc72**: The broken-verifier tests in `tests/check-signing.bats` fail intermittently in a full parallel suite run, with the stubbed verifier's failure reported as `WARN-UNVERIFIED` at exit 0 instead of `UNVERIFIED` at exit 1.
affects: tests/check-signing.bats, scripts/check-signing.sh.
opened: 2026-10-11
status: resolved
Root cause: when find-principals fails, git writes the signed payload to a second verifier call on stdin, and a verifier that has already exited kills `git log --format=%G?` with SIGPIPE (captured at exit 141 with no letter, in an instrumented full-suite run); `check_commits` read the empty answer as a signature that did not verify and, without --strict, passed it. A `git log` that fails on a signed commit now gives `UNVERIFIED (git could not compute a verdict for this signature)` in both modes, as `B` does, after the same trust-root guard; and the test stub reads the payload before it fails, so its tests measure `B`. Reproduced deterministically by `check-signing: a verdict git could not compute fails without --strict`, whose stub kills git on its first call.
