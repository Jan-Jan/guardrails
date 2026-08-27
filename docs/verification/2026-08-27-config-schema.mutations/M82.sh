#!/bin/sh
# describes: lib: strict_paths naming nothing is accepted, so the source scan walks nothing
python3 - <<'PY'
p = 'scripts/lib.sh'
old = '    [ -n "$(cfg_list strict_paths)" ] || gr_die \\'
new = '    [ -n "1" ] || gr_die \\'
t = open(p).read()
assert t.count(old) == 1, 'mutation did not apply: %d matches' % t.count(old)
open(p, 'w').write(t.replace(old, new))
PY
