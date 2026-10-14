# Problem report — a clock flake found by change ledger-names-at-creation

Recorded by change `ledger-names-at-creation`
(`docs/plans/2026-10-13-ledger-names-at-creation.md`). `affects:` names files,
because guardrails keeps no REQ/SDD/LLR ledger of its own.

**PR-pc6byk**: A `tests/check-trace.bats` test that asserts an exact age fails when its run crosses local midnight, because the fixture's date comes from `days_ago` and `check-trace.sh` reads `date` again: "trailing whitespace on a field is not part of its value" reported `open 5 days` for an item written four days back.
affects: tests/helpers.bash, tests/check-trace.bats.
opened: 2026-10-13
status: resolved

Resolved: the fixture and the script read the clock separately. `pin_today` in
`tests/helpers.bash` puts a `date` stub on PATH and `days_ago` counts from the
same pinned day; `tests/check-trace.bats` pins in `setup()`, and
"check-trace: an age is counted from the pinned day on both sides" reproduces
the split. With GNU date, `days_ago` anchors the pinned day at noon and writes
the time before the day (`-d "12:00 <day> N days ago"`). Noon, because a day
can have no local midnight: America/Santiago springs forward at 00:00 on
2026-09-06, and GNU date rejects that day read bare. Time first, because GNU
date reads a signed number straight after a time as that time's zone offset,
so a negative count (a future day) came back as the day before.
`tests/portability.bats` "days_ago counts back from a pinned day whose local
midnight does not exist" asks every GNU and BSD date the machine has for
counts 1, -1 and -2.
