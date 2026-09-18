#!/bin/sh
# describes: check-trace.sh: the SDD block parser keeps its own numeric body
python3 - <<'PY'
s = open('scripts/check-trace.sh').read()
old = 'BEGIN { gr_block_init("SDD", body) }'
new = 'BEGIN { gr_block_init("SDD", "[0-9][0-9][0-9]+") }'
assert s.count(old) == 1, s.count(old)
open('scripts/check-trace.sh','w').write(s.replace(old, new))
PY
