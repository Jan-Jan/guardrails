#!/bin/sh
# describes: check-trace: the LAST owner: in a block wins, not the first
python3 - <<'PY'
old = '''cur != "" && !own_seen && gr_kw_here(line, "owner:")  { own_seen = 1; own = gr_value(line, "owner:") }'''
new = '''cur != "" && gr_kw_here(line, "owner:")  { own_seen = 1; own = gr_value(line, "owner:") }'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
