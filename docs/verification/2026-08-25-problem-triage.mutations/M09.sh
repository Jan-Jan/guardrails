#!/bin/sh
# describes: lib.sh: a date is accepted on shape alone, never validated as a calendar date
python3 - <<'PY'
old = '''    if (!gr_date_valid(y, m, d)) return 0'''
new = '''    if (0) return 0'''
p = 'scripts/lib.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
