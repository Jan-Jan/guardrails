#!/bin/sh
# describes: check-trace: an empty opened: value counts as a date
python3 - <<'PY'
# Anchor widened 2026-09-10 (PR-4fwfjp). Not because the quoted line changed —
# because the accepted branch added a second `if (!opd_seen || opd == "")`, more
# deeply indented, of which this 16-space anchor is a SUBSTRING. Two matches, so
# the assert fired. Duplication stales an anchor exactly as an edit does, and it
# is the case develop-change step 6's grep catches by finding two hits, not zero.
# The printf below belongs to the OPEN branch alone, which is this mutation's
# target, so the pair is unique (probed: 2 -> 1). The mutation is unchanged: the
# open branch stops treating an empty opened: as absent.
old = '''                if (!opd_seen || opd == "")
                    printf "F 0 INCOMPLETE-PROBLEM %s (open, no opened:)\\n", cur'''
new = '''                if (!opd_seen)
                    printf "F 0 INCOMPLETE-PROBLEM %s (open, no opened:)\\n", cur'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
