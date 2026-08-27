#!/bin/sh
# describes: lib: the config is scanned without first checking it can be read
python3 - <<'PY'
p = 'scripts/lib.sh'
old = '    [ -r "$GR_CONFIG" ] || gr_die \\\n"cannot read $GR_CONFIG — it exists but this user cannot open it."'
new = '    :'
s = open(p).read()
assert s.count(old) == 1, 'mutation did not apply: %d matches' % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
