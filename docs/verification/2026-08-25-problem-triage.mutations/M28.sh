#!/bin/sh
# describes: lib.sh: gr_date_ok does not check the length of the value
python3 - <<'PY'
old = '''    if (length(s) != 10) return 0'''
new = '''    if (0) return 0'''
p = 'scripts/lib.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
