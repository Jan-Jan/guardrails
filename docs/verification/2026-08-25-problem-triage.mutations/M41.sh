#!/bin/sh
# describes: lib.sh: days_from_civil drops the century term
python3 - <<'PY'
old = '''    doe = yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy'''
new = '''    doe = yoe * 365 + int(yoe / 4) + doy'''
p = 'scripts/lib.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
