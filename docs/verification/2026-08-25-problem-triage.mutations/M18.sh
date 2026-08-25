#!/bin/sh
# describes: lib.sh: gr_limit accepts a value that is not a whole number
python3 - <<'PY'
old = '''        *[!0-9]*) gr_die \\'''
new = '''        __never__) gr_die \\'''
p = 'scripts/lib.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
