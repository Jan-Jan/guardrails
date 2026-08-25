#!/bin/sh
# describes: check-trace: an empty opened: value counts as a date
python3 - <<'PY'
old = '''                if (!opd_seen || opd == "")'''
new = '''                if (!opd_seen)'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
