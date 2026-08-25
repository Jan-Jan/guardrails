#!/bin/sh
# describes: check-trace: STALE-PROBLEM never fires
python3 - <<'PY'
old = '''                    if (agelim != "" && age > agelim + 0)
                        printf "F 0 STALE-PROBLEM %s (open %d days, limit %d)\\n", cur, age, agelim + 0'''
new = '''                    if (0)
                        printf "F 0 STALE-PROBLEM %s (open %d days, limit %d)\\n", cur, age, agelim + 0'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
