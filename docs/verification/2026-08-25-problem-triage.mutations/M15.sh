#!/bin/sh
# describes: check-trace: the backlog limit fires AT the limit, not past it
python3 - <<'PY'
old = '''if [ -n "$open_limit" ] && [ "$_open_n" -gt "$open_limit" ]; then'''
new = '''if [ -n "$open_limit" ] && [ "$_open_n" -ge "$open_limit" ]; then'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
