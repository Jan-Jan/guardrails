# Problems found by implements-one-reader

**PR-8um9a9**: A REQ definition line inside a ledger file's front matter
opens a block for the out-of-force scan, so a `retired:` beside it in the
front matter exempts the item from MISSING-TEST.
affects: scripts/check-trace.sh, whose `oof_scan` does not skip front matter
while the ORPHAN-ANNOTATION backstop does, so the `retired:` line is neither
reported nor refused.
opened: 2026-10-08
status: open
Found 2026-10-08 by the fix for review round 1 of implements-one-reader,
probing the front-matter claim in `oof_scan`'s comment: front matter holding
`**REQ-002**: …` and `retired: 2026-01-01 — gone`, REQ-002 defined again
below with no test, gives `check-trace.sh` exit 0 (`check-ids.sh` reports the
duplicate). `credit_scan` skips front matter by `GR_AWK_FRONT_MATTER` as of
this change; `oof_scan` needs the same rule. Not fixed here, to keep this
change to the two keywords it resolves.
