#!/bin/sh
# describes: check-trace: one day of clock tolerance is removed
python3 - <<'PY'
old = '''                    if (age == -1) age = 0
                    else if (age < 0) {'''
new = '''                    if (age < 0) {'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
