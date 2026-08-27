#!/bin/sh
# describes: lib: the comment check uses a bracket expression that is not whitespace
python3 - <<'PY'
p = 'scripts/lib.sh'
old = '            cfg_list "$_k" | grep -q \'^#\' && _commented="${_commented} $_k"'
new = '            cfg_list "$_k" | grep -q \'^[ \\t]*#\' && _commented="${_commented} $_k"'
t = open(p).read()
assert t.count(old) == 1, 'mutation did not apply: %d matches' % t.count(old)
open(p, 'w').write(t.replace(old, new))
PY
