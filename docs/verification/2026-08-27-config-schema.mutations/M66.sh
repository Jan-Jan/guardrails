#!/bin/sh
# describes: lib: the carriage-return guard inspects the first line only
python3 - <<'PY'
p = 'scripts/lib.sh'
old = '        index($0, "\\r") > 0 && index($0, "\\r") < length($0) { print "cr"; exit }'
new = '        NR == 1 && index($0, "\\r") > 0 && index($0, "\\r") < length($0) { print "cr"; exit }'
s = open(p).read()
assert s.count(old) == 1, 'mutation did not apply: %d matches' % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
