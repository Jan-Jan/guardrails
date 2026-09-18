#!/bin/sh
# describes: lib: coverage_command is not a list key, so its scalar form is accepted
python3 - <<'PY'
p = 'scripts/lib.sh'
old = "verify_commands\ncoverage_command\ndepends_on"
new = "verify_commands\ndepends_on"
t = open(p).read()
assert t.count(old) == 1, 'mutation did not apply: %d matches' % t.count(old)
open(p, 'w').write(t.replace(old, new))
PY
