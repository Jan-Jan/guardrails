#!/bin/sh
# describes: check-trace: the triage scan does not strip a trailing CR
python3 - <<'PY'
old = '''            { line = $0; sub(/\\r$/, "", line) }'''
new = '''            { line = $0 }'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
