#!/bin/sh
# describes: lib.sh: days_from_civil uses the wrong month shift
python3 - <<'PY'
old = '''    doy = int((153 * (m > 2 ? m - 3 : m + 9) + 2) / 5) + d - 1'''
new = '''    doy = int((153 * (m - 3) + 2) / 5) + d - 1'''
p = 'scripts/lib.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
