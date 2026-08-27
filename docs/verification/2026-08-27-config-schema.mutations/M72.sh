#!/bin/sh
# describes: lib: strict_paths is not a list key, so its scalar form is accepted
python3 - <<'PY'
p = 'scripts/lib.sh'
old = "GR_LIST_KEYS='strict_paths\ntest_paths"
new = "GR_LIST_KEYS='test_paths"
s = open(p).read()
assert s.count(old) == 1, 'mutation did not apply: %d matches' % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
