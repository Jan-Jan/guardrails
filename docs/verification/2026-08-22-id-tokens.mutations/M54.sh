#!/bin/sh
# describes: check-ids.sh: the MALFORMED-ID failure drops its guidance lines
python3 - <<'PY'
# Anchor re-cut 2026-09-29 (D8 of docs/plans/2026-09-28-agent-first-skills.md):
# the three stderr guidance lines became the `fix MALFORMED-ID:` remedy entry,
# so the original anchor matched nothing. Re-cut per bb7eee5; the mutation is
# unchanged: the guidance is dropped.
s = open('scripts/check-ids.sh').read()
old = '''        (MALFORMED-ID) echo 'Give each item an ID from .guardrails/scripts/new-id.sh <PREFIX>; never widen a pattern to accept the token that is there.' ;;
'''
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open('scripts/check-ids.sh','w').write(s.replace(old, ""))
PY
