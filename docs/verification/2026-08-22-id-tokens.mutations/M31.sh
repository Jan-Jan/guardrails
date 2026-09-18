#!/bin/sh
# describes: check-trace.sh: the problem-report parser keeps its own numeric body
python3 - <<'PY'
s = open('scripts/check-trace.sh').read()
old = 'gr_block_init("PR", body)'
new = 'gr_block_init("PR", "[0-9][0-9][0-9]+")'
assert s.count(old) == 1, s.count(old)
open('scripts/check-trace.sh','w').write(s.replace(old, new))
PY
