#!/bin/sh
# describes: check-trace: status: value is not checked against the closed set
python3 - <<'PY'
# Anchor re-cut 2026-09-10 (PR-4fwfjp): `accepted` became a third admissible
# status, so both the condition and the message this anchor quoted changed and
# it matched nothing. The mutation is unchanged in intent — the status test
# stops reporting and just returns, so a malformed status reads as resolved.
old = '''                if (st != "open" && st != "accepted" && st != "resolved") {
                    printf "F 0 MALFORMED-STATUS %s (status: %s — expected open, accepted or resolved)\\n", cur, st
                    return
                }'''
new = '''                if (st != "open" && st != "accepted" && st != "resolved") return'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
