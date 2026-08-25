#!/bin/sh
# describes: check-trace: an undatable open item is dropped from the roll-call
python3 - <<'PY'
p = 'scripts/check-trace.sh'
s = open(p).read()
old = '''                if (age < 0)
                    printf "W -1 UNRESOLVED-PR %s (open, age unrecorded, owner %s)\\n", cur, who
                else {'''
new = '''                if (age < 0) {
                    # dropped
                }
                else {'''
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
