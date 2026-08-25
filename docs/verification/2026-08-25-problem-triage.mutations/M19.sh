#!/bin/sh
# describes: lib.sh: gr_limit reads a present-but-empty limit as no limit
python3 - <<'PY'
old = '''        if grep -q "^$1:" "$GR_CONFIG" 2>/dev/null; then'''
new = '''        if false; then'''
p = 'scripts/lib.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
