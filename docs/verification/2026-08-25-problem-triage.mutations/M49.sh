#!/bin/sh
# describes: check-trace: the backlog noun is always plural
python3 - <<'PY'
old = '''    [ "$_open_n" -eq 1 ] && _noun="open problem report"'''
new = '''    :'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
