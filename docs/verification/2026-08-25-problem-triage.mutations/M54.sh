#!/bin/sh
# describes: lib.sh: gr_limit does not check comparability at all (review N5/finding 3)
python3 - <<'PY'
p = 'scripts/lib.sh'
s = open(p).read()
old = '    [ "$_lv" -ge 0 ] 2>/dev/null || gr_die \\'
new = '    [ 0 -ge 1 ] 2>/dev/null || gr_die \\'
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
