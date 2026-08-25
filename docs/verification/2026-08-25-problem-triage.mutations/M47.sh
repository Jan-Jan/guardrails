#!/bin/sh
# describes: check-trace: the limits are read at the point of use again
python3 - <<'PY'
old = '''age_limit=$(gr_limit problem_age_days) || exit 2
open_limit=$(gr_limit problem_open_max) || exit 2'''
new = '''age_limit=""
open_limit=""'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
