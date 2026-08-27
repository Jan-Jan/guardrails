#!/bin/sh
# describes: lib: an empty list item is accepted for the path keys
python3 - <<'PY'
p = 'scripts/lib.sh'
old = '            cfg_list "$_k" | grep -q \'^$\' && _blank="${_blank} $_k"'
new = '            :'
s = open(p).read()
assert s.count(old) == 1, 'mutation did not apply: %d matches' % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
