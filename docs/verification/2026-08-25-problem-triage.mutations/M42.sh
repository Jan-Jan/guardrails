#!/bin/sh
# describes: check-trace: opened: is read anywhere on the line, not at column one
python3 - <<'PY'
old = '''cur != "" && !opd_seen && gr_kw_here(line, "opened:") { opd_seen = 1; opd = gr_value(line, "opened:") }'''
new = '''cur != "" && !opd_seen && index(line, "opened:") > 0 { opd_seen = 1; opd = gr_value(substr(line, index(line, "opened:")), "opened:") }'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
