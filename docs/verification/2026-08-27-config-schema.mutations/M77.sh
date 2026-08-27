#!/bin/sh
# describes: lib: the empty-item verdict is collected but never reported
python3 - <<'PY'
p = 'scripts/lib.sh'
old = '    [ -z "$_blank" ] || gr_die \\'
new = '    [ -n "$_blank" ] || gr_die \\'
s = open(p).read()
assert s.count(old) == 1, 'mutation did not apply: %d matches' % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
