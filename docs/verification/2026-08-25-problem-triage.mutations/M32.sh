#!/bin/sh
# describes: check-trace: owner: is read anywhere on the line, not at column one
python3 - <<'PY'
old = '''cur != "" && !own_seen && gr_kw_here(line, "owner:")  { own_seen = 1; own = gr_value(line, "owner:") }'''
new = '''cur != "" && !own_seen && line ~ /owner:/ { own_seen = 1; own = gr_value(substr(line, index(line, "owner:")), "owner:") }'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
