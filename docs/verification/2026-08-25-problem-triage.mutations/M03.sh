#!/bin/sh
# describes: check-trace: status: value is not checked against the closed set
python3 - <<'PY'
old = '''                if (st != "open" && st != "resolved") {
                    printf "F 0 MALFORMED-STATUS %s (status: %s — expected open or resolved)\\n", cur, st
                    return
                }'''
new = '''                if (st != "open" && st != "resolved") return'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
