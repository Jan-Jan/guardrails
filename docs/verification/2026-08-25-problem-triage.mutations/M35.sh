#!/bin/sh
# describes: check-trace: the oldest-age maximum starts at 0, so an age of 0 never registers
python3 - <<'PY'
p = 'scripts/check-trace.sh'
s = open(p).read()
old = "awk 'BEGIN { m = -1 } $1 == \"W\" && $2 + 0 > m { m = $2 + 0 } END { print m }'"
new = "awk '$1 == \"W\" && $2 + 0 > m { m = $2 + 0; seen = 1 } END { print (seen ? m : -1) }'"
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
