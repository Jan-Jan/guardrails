#!/bin/sh
# describes: check-trace: an awk failure in the triage scan is not detected
python3 - <<'PY'
p = 'scripts/check-trace.sh'
s = open(p).read()
old = """        ' "$f" || gr_die "problem-report scan failed on $f\""""
new = """        ' "$f" 2>/dev/null || true"""
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
