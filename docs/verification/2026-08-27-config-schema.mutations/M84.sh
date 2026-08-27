#!/bin/sh
# describes: lib: the commented-item verdict is collected but never reported
python3 - <<'PY'
p = 'scripts/lib.sh'
old = '    [ -z "$_commented" ] || gr_die \\'
new = '    [ -n "$_commented" ] || gr_die \\'
t = open(p).read()
assert t.count(old) == 1, 'mutation did not apply: %d matches' % t.count(old)
open(p, 'w').write(t.replace(old, new))
PY
