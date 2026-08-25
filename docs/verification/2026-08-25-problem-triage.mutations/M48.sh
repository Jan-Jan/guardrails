#!/bin/sh
# describes: check-trace: the no-usable-date count is dropped from the summary
python3 - <<'PY'
p = 'scripts/check-trace.sh'
s = open(p).read()
old = '[ "$_undatable_n" -gt 0 ] && _oldest_txt="$_oldest_txt ($_undatable_n with no usable date)"'
new = ':'
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
