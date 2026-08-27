#!/bin/sh
# describes: lib: a list key with no items is not collected as empty
python3 - <<'PY'
p = 'scripts/lib.sh'
old = '            [ -n "$(cfg_list "$_k")" ] || _empty="${_empty} $_k"'
new = '            :'
t = open(p).read()
assert t.count(old) == 1, 'mutation did not apply: %d matches' % t.count(old)
open(p, 'w').write(t.replace(old, new))
PY
