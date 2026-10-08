# Problem report — a testing gap found by change test-guidelines

Recorded by change `test-guidelines` (`docs/plans/2026-10-08-test-guidelines.md`).
`affects:` names files, because guardrails keeps no REQ/SDD/LLR ledger of its
own.

**PR-3kvpze**: A bats assertion written `! grep …` on any line but a test's last never fails the test, because bash's errexit ignores a command negated with `!`, so the negative assertions at `tests/skills.bats` lines 1055, 1400, 1412 and 1414 and `tests/finalize-docs.bats` line 215 (at `9dd6736`'s descendants on branch test-guidelines) check nothing.
affects: tests/skills.bats, tests/finalize-docs.bats.
opened: 2026-10-08
status: open

Found by the T6 dispatch of `test-guidelines`, which wrote its own negative
assertions as `if grep …; then false; fi`. A negation followed by
`|| { …; false; }` is not affected: the `||` list's last command fails. The
fix is a sweep of every `tests/*.bats` for a bare negation that is not a
test's last command, and a `tests/skills.bats` or portability check that
rejects one; it is outside this change.
