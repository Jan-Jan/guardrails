#!/bin/sh
# describes: lib: gr_verification_dir defaults instead of refusing an empty value
python3 - <<'PY'
p = 'scripts/lib.sh'
old = '    if [ -z "$_v" ] && grep -q \'^doc_verification:\' "$GR_CONFIG" 2>/dev/null; then'
new = '    if false; then'
s = open(p).read()
assert s.count(old) == 1, 'mutation did not apply: %d matches' % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
