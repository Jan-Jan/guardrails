# Problem report — limits of the bare-negation scan

Recorded by change `bare-negations` (`docs/plans/2026-10-13-bare-negations.md`),
from its third review round, whose findings were all low. `affects:` names
files, because guardrails keeps no REQ/SDD/LLR ledger of its own.

**PR-z7jq9k**: The bare-negation scan in `tests/portability.bats` reads shell one line at a time, so it silently passes some negations that errexit ignores, and rejects some compliant shapes.
affects: tests/portability.bats, AGENTS.md.
opened: 2026-10-13
status: open

Silently passed, each confirmed under `/bin/bash -e` 3.2.57:
- a `!` after a case-arm pattern, `(a) ! grep -q x f ;;`;
- a one-line subshell that runs a command after the negation,
  `( ! grep -q x f; echo hi )`;
- `time ! grep -q x f`;
- a line that ends in an escaped backslash, which is read as a continuation,
  so the next line's bare negation is hidden.

Rejected although compliant:
- `[[ -f a && ! -f b ]]`, where the `!` belongs to the test expression;
- `! grep -q x f ||` with `false` on the next line;
- a one-line helper `refute() { ! grep -q "$1" "$2"; }`, whose caller's
  errexit applies.

None of these shapes is in the tree. A parser of shell, or `bash -n` with a
trace, would remove the class; a further line rule removes one shape at a time.
