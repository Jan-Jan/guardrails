#!/bin/sh
# describes: check-trace: resolved items are counted toward the backlog too
# retired: a resolved problem report is deleted (ADR-k3nkv3); status: resolved
# is RESOLVED-PROBLEM, so no resolved item reaches the roll-call or the backlog.
python3 - <<'PY'
old = '''                if (st == "resolved") return'''
new = '''                if (st == "resolved") { printf "W 0 UNRESOLVED-PR %s (resolved)\\n", cur; return }'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
