# Problem report — three testing gaps found by change test-seams

Recorded by change `test-seams`. `affects:` names files.

**PR-dfndh4**: `tests/run-tests.bats` fakes GNU `parallel`, `getconf` and `sysctl` with output that `tests/run-tests.sh` parses, and no contract test checks those fakes against the real tools, against Doubles clause 3 of `docs/TEST_GUIDELINES.md`.
affects: tests/run-tests.bats (make_gnu_parallel_stub, and the make_stub uses that print output), tests/run-tests.sh.
opened: 2026-10-08
status: open

Found by classifying this repository's doubles. The change that found it
left existing tests unedited, so it records the gap instead of fixing it. `make_stub_bats` and the status-only `make_stub`
uses are not covered by this item.

**PR-qf5tkd**: Wall-clock `timeout` bounds in `tests/new-id.bats` turn a slow but correct run into a failure on a loaded host, as a full `tests/run-tests.sh` on tree a1e56eb that took about 2 h failed the give-up-message test (`timeout 30`) and the FIFO test (`timeout 20`, status 124).
affects: tests/new-id.bats (the timeout-bounded tests), tests/run-tests.sh.
opened: 2026-10-08
status: open

Investigated 2026-10-08 at load average 9-19 on 12 cores: three runs of
`sh tests/run-tests.sh tests/new-id.bats` passed 28 of 28 each (174 s, 166 s,
120 s). Run directly in a `make_fixture_repo` fixture, the `/dev/null` case took
10.4-14.7 s (bound 30 s) and the FIFO case 11.6-12.7 s (bound 20 s), against
10.0-12.9 s for a plain `/dev/urandom` mint: the cost is the script's fixed
start-up (about 570 forks in an `sh -x` trace, at about 18 ms per exec under
this load), not the entropy source. The FIFO case cannot block in open(): the
`[ ! -p ]` stat check (new-id.sh line 121) runs before the first
`< "$urandom"` (line 166), so its 124 was a slow run; the 2 h suite, 6-9 times
its usual 13-19 min, puts both cases past their bounds.
