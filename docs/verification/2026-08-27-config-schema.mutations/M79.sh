#!/bin/sh
# describes: lib: gr_prefixes leaves pathname expansion switched on behind it
python3 - <<'PY'
p = 'scripts/lib.sh'
old = '    [ "$_pfx_refl" -eq 1 ] || set +f\n'
new = ''
s = open(p).read()
assert s.count(old) == 1, 'mutation did not apply: %d matches' % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
