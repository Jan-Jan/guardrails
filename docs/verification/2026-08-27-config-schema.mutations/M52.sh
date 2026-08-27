#!/bin/sh
# describes: lib: the diagnosis goes through echo, which de-escapes under dash
python3 - <<'PY'
p = 'scripts/lib.sh'
old = '    printf \'%s\\n\' "guardrails: $*" >&2'
new = '    echo "guardrails: $*" >&2'
s = open(p).read()
assert s.count(old) == 1, 'mutation did not apply: %d matches' % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
