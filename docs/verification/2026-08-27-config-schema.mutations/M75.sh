#!/bin/sh
# describes: lib: cfg_get strips the blanks a trailing comment needs to be seen
python3 - <<'PY'
p = 'scripts/lib.sh'
old = '            sub(/^[^:]*:/, "")\n            v = gr_clean($0)\n            sub(/^[ \\t]+/, "", v)\n            print v'
new = '            sub(/^[^:]*:[ \\t]*/, "")\n            v = gr_clean($0)\n            print v'
s = open(p).read()
assert s.count(old) == 1, 'mutation did not apply: %d matches' % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
