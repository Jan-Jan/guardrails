#!/bin/sh
# describes: lib: an item that is itself a comment is accepted and run
python3 - <<'PY'
p = 'scripts/lib.sh'
old = '            cfg_list "$_k" | grep -q \'^#\' && _commented="${_commented} $_k"'
new = '            :'
t = open(p).read()
assert t.count(old) == 1, 'mutation did not apply: %d matches' % t.count(old)
open(p, 'w').write(t.replace(old, new))
PY
