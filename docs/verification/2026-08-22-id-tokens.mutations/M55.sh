#!/bin/sh
# describes: new-id.sh: a FIFO entropy source is read rather than refused
python3 - <<'PY'
s = open('scripts/new-id.sh').read()
i = s.index('[ ! -p "$urandom" ] || gr_die \\')
j = s.index('[ -r "$urandom" ] || gr_die \\', i)
open('scripts/new-id.sh','w').write(s[:i] + s[j:])
PY
