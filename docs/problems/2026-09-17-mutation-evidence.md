# Problem reports — mutation evidence, and a test idiom that asserts nothing

`affects:` names files.

Found while resolving a defect in the mutation corpus, by a task doing
something else; wider than that change, and left open deliberately, as its
note states.

**PR-2c2k3p**: `check-trace.sh`'s derived-REQ collector is pinned to the shared ID
body by nothing any test observes, so if it were narrowed to numeric IDs only,
`UNANALYZED-DERIVED` would stop firing for every derived REQ with a token ID
and the gate would exit 0 having reported nothing.
affects: scripts/check-trace.sh (the derived-REQ block at the `gr_block_init("REQ",
body)` call) and tests/check-trace.bats, which exercises derived REQs only with
numeric IDs.
opened: 2026-09-17
status: open
Found by mutation, which is what mutation testing is for. A mutation that
replaces the collector's shared `body` argument with the literal
`[0-9][0-9][0-9]+` applies correctly and is then killed by **zero** tests.

Measured at `bd8cdf6` in a real git worktree, `1..651` with 0 `not ok`. That is
the 719-test suite less three files: the mutation-corpus test file, since deleted,
which could not take part — inside a mutated tree the other 183 anchors stopped
matching, so it failed for reasons unrelated to the mutation under test — and `tests/check-signing.bats` and
`tests/finish-merge.bats`, which exercise gpg and worktree removal and reach no
part of `check-trace.sh`'s derived-REQ collector. The figure is 0 of 651 actually
run, and the three omitted files are named rather than folded into a rounder
number.

Measured **after** the base advanced to `650f090`, which rewrites 82 lines of
`check-trace.sh` — the script the mutation changes — and adds 120 tests to
`tests/check-trace.bats`. The first measurement predated that commit and was
re-run rather than copied forward, because those 120 tests could have killed it
and that would have made this item wrong.

It is not an equivalent mutant. The derived-REQ fixtures in
`tests/check-trace.bats` all use numeric IDs — `REQ-001` and `REQ-002`, twelve
occurrences, no token among them — while token IDs are the only form
`new-id.sh` has minted since `c672c9f`. Change one fixture ID and the mutation
dies at once. Measured on `check-trace: derived REQ not assessed in RMF fails`
with its `REQ-002` rewritten to `REQ-a3k9z2` and nothing else altered:

| tree | verdict |
| --- | --- |
| token-ID fixture, no mutation | `ok` — UNANALYZED-DERIVED fires |
| token-ID fixture, mutation applied | `not ok` — it does not fire |

The LLR side of the same gate **is** covered for tokens, by `check-trace: a
token derived LLR absent from the RMF fails` and its neighbour. Only the REQ arm
is uncovered, so this is an asymmetry in the fixtures rather than an oversight
about tokens in general.

Left open: the repair is a token-ID derived-REQ test, which is a test-coverage
change with its own red → green, and a mutation no test detects is reported
rather than repaired by the change that found it.
