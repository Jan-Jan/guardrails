#!/bin/sh
# describes: check-ids.sh: MALFORMED-ID reports without failing the run
python3 - <<'PY'
# Anchor re-cut 2026-09-29 (D8 of docs/plans/2026-09-28-agent-first-skills.md):
# the stderr guidance line this anchor quoted became the `fix MALFORMED-ID:`
# remedy line, so the original anchor matched nothing. Re-cut per bb7eee5; the
# mutation is unchanged: the report is printed and the run does not fail.
s = open('scripts/check-ids.sh').read()
old = '''    fired_rules="$fired_rules MALFORMED-ID"
    fail=1
fi'''
new = '''    fired_rules="$fired_rules MALFORMED-ID"
fi'''
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open('scripts/check-ids.sh','w').write(s.replace(old, new))
PY
