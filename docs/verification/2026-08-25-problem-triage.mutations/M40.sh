#!/bin/sh
# describes: lib.sh: gr_digits accepts anything
python3 - <<'PY'
old = '''function gr_digits(s,   i, n) {
    n = length(s)
    if (n == 0) return 0'''
new = '''function gr_digits(s,   i, n) {
    return 1
    n = length(s)
    if (n == 0) return 0'''
p = 'scripts/lib.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
