#!/bin/sh
# describes: lib: the block-end test judges the raw line, so CRLF truncates every list
python3 - <<'PY'
p = 'scripts/lib.sh'
old = '        inlist && line ~ /^[^ \\t]/ { exit }'
new = '        inlist && $0 ~ /^[^ \\t]/ { exit }'
s = open(p).read()
assert s.count(old) == 1, 'mutation did not apply: %d matches' % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
