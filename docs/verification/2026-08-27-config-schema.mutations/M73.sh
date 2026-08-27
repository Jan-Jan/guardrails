#!/bin/sh
# describes: lib: id_prefixes is split with pathname expansion on
python3 - <<'PY'
p = 'scripts/lib.sh'
old = '    case $- in *f*) _pfx_refl=1 ;; *) _pfx_refl=0 ;; esac\n    set -f\n'
new = '    _pfx_refl=1\n'
s = open(p).read()
assert s.count(old) == 1, 'mutation did not apply: %d matches' % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
