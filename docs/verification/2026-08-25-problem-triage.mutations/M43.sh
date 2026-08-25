#!/bin/sh
# describes: check-trace: the BOM strip is removed from the TRIAGE scan only
python3 - <<'PY'
p = 'scripts/check-trace.sh'
s = open(p).read()
old = '''            FNR == 1 { sub(/^\\357\\273\\277/, "") }
            # NO front-matter skip here'''
new = '''            FNR == 1 { }
            # NO front-matter skip here'''
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
