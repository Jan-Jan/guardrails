#!/bin/sh
# describes: check-trace.sh: the derived-REQ parser keeps its own numeric body
python3 - <<'PY'
s = open('scripts/check-trace.sh').read()
old = 'BEGIN { defre = "^\\\\*\\\\*REQ-" body "\\\\*\\\\*:" }'
new = 'BEGIN { defre = "^\\\\*\\\\*REQ-[0-9][0-9][0-9]+\\\\*\\\\*:" }'
assert old in s, old
open('scripts/check-trace.sh','w').write(s.replace(old, new))
PY
