#!/bin/sh
# describes: check-trace: an item with no status: is not reported
python3 - <<'PY'
old = '''                if (!st_seen) {
                    printf "F 0 INCOMPLETE-PROBLEM %s (no status: line in its block)\\n", cur
                    return
                }'''
new = '''                if (!st_seen) return'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
