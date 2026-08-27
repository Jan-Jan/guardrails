#!/bin/sh
# describes: lib: a key set to nothing is accepted, whichever key it is
python3 - <<'PY'
p = 'scripts/lib.sh'
old = '    [ -z "$_empty" ] || gr_die \\'
new = '    [ -n "$_empty" ] || gr_die \\'
s = open(p).read()
assert s.count(old) == 1, 'mutation did not apply: %d matches' % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
