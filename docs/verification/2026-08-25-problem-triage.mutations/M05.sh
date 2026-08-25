#!/bin/sh
# describes: check-trace: owner: is not required on an open item
python3 - <<'PY'
old = '''                if (who == "unrecorded")
                    printf "F 0 INCOMPLETE-PROBLEM %s (open, no owner:)\\n", cur'''
new = '''                if (0)
                    printf "F 0 INCOMPLETE-PROBLEM %s (open, no owner:)\\n", cur'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
