#!/bin/sh
# describes: check-trace: an empty owner: value counts as an owner
python3 - <<'PY'
old = '''                who = (own_seen && own != "") ? own : "unrecorded"'''
new = '''                who = own_seen ? own : "unrecorded"'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
