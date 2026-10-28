#!/bin/sh
# describes: check-trace: status: value is not checked against the closed set
python3 - <<'PY'
# The status test stops reporting and just returns, so a status outside the
# closed set (open, accepted) passes as one in it. `resolved` is
# RESOLVED-PROBLEM, tested ahead of this condition (ADR-k3nkv3).
old = '''                if (st != "open" && st != "accepted") {
                    printf "F 0 MALFORMED-STATUS %s (status: %s — expected open or accepted)\\n", cur, st
                    return
                }'''
new = '''                if (st != "open" && st != "accepted") return'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
