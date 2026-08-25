#!/bin/sh
# describes: check-trace: PROBLEM-BACKLOG never fires
python3 - <<'PY'
old = '''if [ -n "$open_limit" ] && [ "$_open_n" -gt "$open_limit" ]; then'''
new = '''if false; then'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
