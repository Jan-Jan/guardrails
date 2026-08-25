#!/bin/sh
# describes: lib.sh: gr_limit guesses a digit width instead of asking the shell (review N5)
python3 - <<'PY'
p = 'scripts/lib.sh'
s = open(p).read()
old = '    [ "$_lv" -ge 0 ] 2>/dev/null || gr_die \\'
new = '    [ "${#_lv}" -le 9 ] || gr_die \\'
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
