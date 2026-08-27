#!/bin/sh
# describes: lib: a duplicated config key is accepted and the second one ignored
python3 - <<'PY'
p = 'scripts/lib.sh'
old = '    _dup=$(printf \'%s\\n\' "$_keys" | sort | uniq -d | tr \'\\n\' \' \')'
new = '    _dup='
s = open(p).read()
assert s.count(old) == 1, 'mutation did not apply: %d matches' % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
