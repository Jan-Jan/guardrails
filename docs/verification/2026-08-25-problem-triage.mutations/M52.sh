#!/bin/sh
# describes: lib.sh: front matter never opens at all, so a real header is read as ledger prose
python3 - <<'PY'
p = 'scripts/lib.sh'
s = open(p).read()
old = '        if (GR_FM_MAYBE && line !~ /^[ \\t\\r]*$/) GR_FM_IN = 1'
new = '        if (0) GR_FM_IN = 1'
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
