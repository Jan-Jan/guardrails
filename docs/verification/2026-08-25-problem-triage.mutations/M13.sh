#!/bin/sh
# describes: check-trace: the age limit fires AT the limit, not past it
python3 - <<'PY'
old = '''                    if (agelim != "" && age > agelim + 0)'''
new = '''                    if (agelim != "" && age >= agelim + 0)'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
