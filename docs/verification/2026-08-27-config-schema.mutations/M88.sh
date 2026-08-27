#!/bin/sh
# describes: lib: a scalar key given list items is not collected as wrong-form
python3 - <<'PY'
p = 'scripts/lib.sh'
old = '            [ -z "$(cfg_list "$_k")" ] || _wrong="${_wrong} $_k"'
new = '            :'
t = open(p).read()
assert t.count(old) == 1, 'mutation did not apply: %d matches' % t.count(old)
open(p, 'w').write(t.replace(old, new))
PY
