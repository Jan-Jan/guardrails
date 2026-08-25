#!/bin/sh
# describes: check-trace: the LAST status: in a block wins, not the first
python3 - <<'PY'
old = '''cur != "" && !st_seen  && gr_kw_here(line, "status:") { st_seen = 1;  st = gr_value(line, "status:") }'''
new = '''cur != "" && gr_kw_here(line, "status:") { st_seen = 1;  st = gr_value(line, "status:") }'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
