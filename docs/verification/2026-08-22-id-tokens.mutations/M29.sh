#!/bin/sh
# describes: check-trace.sh: the derived-REQ parser keeps its own numeric body
python3 - <<'PY'
s = open('scripts/check-trace.sh').read()
old = 'BEGIN { gr_block_init("REQ", body) }'
new = 'BEGIN { gr_block_init("REQ", "[0-9][0-9][0-9]+") }'
assert s.count(old) == 1, s.count(old)
open('scripts/check-trace.sh','w').write(s.replace(old, new))
PY
