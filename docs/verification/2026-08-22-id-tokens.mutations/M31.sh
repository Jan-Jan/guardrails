#!/bin/sh
# describes: check-trace.sh: the problem-report parser keeps its own numeric body
python3 - <<'PY'
s = open('scripts/check-trace.sh').read()
old = 'BEGIN { defre = "^\\\\*\\\\*PR-" body "\\\\*\\\\*:" }'
new = 'BEGIN { defre = "^\\\\*\\\\*PR-[0-9][0-9][0-9]+\\\\*\\\\*:" }'
assert old in s, old
open('scripts/check-trace.sh','w').write(s.replace(old, new))
PY
