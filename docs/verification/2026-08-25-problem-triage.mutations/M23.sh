#!/bin/sh
# describes: check-trace: the orphan backstop no longer covers owner:
# retired: the owner: field was dropped at 860dce4; check-trace.sh contains no
# owner handling to revert
python3 - <<'PY'
old = '''    check_orphans 'owner:' PR $problems_files'''
new = '''    :'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
