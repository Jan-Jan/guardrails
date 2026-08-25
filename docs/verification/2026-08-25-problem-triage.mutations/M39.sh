#!/bin/sh
# describes: lib.sh: a zero month or a zero day is a valid calendar date
python3 - <<'PY'
old = '''    if (y < 1 || m < 1 || m > 12 || d < 1) return 0'''
new = '''    if (y < 1 || m > 12) return 0'''
p = 'scripts/lib.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
