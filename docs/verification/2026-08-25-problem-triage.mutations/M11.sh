#!/bin/sh
# describes: lib.sh: the leap-century rule is dropped — every 4th year is a leap year
python3 - <<'PY'
old = '''    else if (m == 2) dim = (y % 4 == 0 && (y % 100 != 0 || y % 400 == 0)) ? 29 : 28'''
new = '''    else if (m == 2) dim = (y % 4 == 0) ? 29 : 28'''
p = 'scripts/lib.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
