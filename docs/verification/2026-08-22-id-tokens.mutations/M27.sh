#!/bin/sh
# describes: check-trace.sh: the LLR block parser keeps its own numeric body
python3 - <<'PY'
s = open('scripts/check-trace.sh').read()
old = 'BEGIN { defre = "^\\\\*\\\\*LLR-" body "\\\\*\\\\*:" }'
new = 'BEGIN { defre = "^\\\\*\\\\*LLR-[0-9][0-9][0-9]+\\\\*\\\\*:" }'
assert old in s, old
open('scripts/check-trace.sh','w').write(s.replace(old, new))
PY
