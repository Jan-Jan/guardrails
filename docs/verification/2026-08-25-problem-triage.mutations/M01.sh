#!/bin/sh
# describes: check-trace: status: read anywhere on the line again (the original defect)
python3 - <<'PY'
old = '''cur != "" && !st_seen  && gr_kw_here(line, "status:") { st_seen = 1;  st = gr_value(line, "status:") }'''
new = '''cur != "" && !st_seen  && line ~ /status:/ { st_seen = 1;  st = gr_value(substr(line, index(line, "status:")), "status:") }'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
