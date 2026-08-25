#!/bin/sh
# describes: check-trace: the LAST opened: in a block wins, not the first
python3 - <<'PY'
old = '''cur != "" && !opd_seen && gr_kw_here(line, "opened:") { opd_seen = 1; opd = gr_value(line, "opened:") }'''
new = '''cur != "" && gr_kw_here(line, "opened:") { opd_seen = 1; opd = gr_value(line, "opened:") }'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
