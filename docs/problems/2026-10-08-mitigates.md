# Problems found by implements-one-reader

**PR-z7w5bf**: A hazard reads as mitigated when a `mitigates:` line names it
outside every RC block, so UNMITIGATED-HAZARD passes on a hazard no risk
control mitigates.
affects: scripts/check-trace.sh, whose UNMITIGATED-HAZARD gate credits
`ids_matching 'mitigates:' HAZ` over the RMF line-wise, from anywhere on any
line, attributed to no item; its orphan-scan comment names `mitigates:` among
the keywords that "cannot be orphaned".
opened: 2026-10-08
status: resolved
Resolved 2026-10-08 by implements-one-reader: `mitigates:` credits only from inside an RC block (`credit_scan` in check-trace.sh) and ORPHAN-ANNOTATION covers it — tests "a mitigates: in RMF prose with no RC mitigates nothing" and "a column-one mitigates: under a heading after the last RC mitigates nothing and is reported" in tests/check-trace.bats.
Measured 2026-10-08 on BWK awk at dd411a1: a single-unit fixture whose RMF
defines HAZ-002, no RC naming it, and the prose line `A control that
mitigates: HAZ-002 must say so.` under a `## Notes` heading exits 0 with no
report. Found while measuring PR-44ww7q, which is the same defect for
`implements:`.

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
