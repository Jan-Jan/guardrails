#!/bin/sh
# describes: check-trace: the no-usable-date count only counts a MISSING opened: (review N6)
python3 - <<'PY'
p = 'scripts/check-trace.sh'
s = open(p).read()
old = """_undatable_n=$(printf '%s\\n' "$_prs" | grep -c '^W -1 ' || true)"""
new = """_undatable_n=$(printf '%s\\n' "$_prs" | grep -c '^W -1 .*no opened' || true)"""
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
