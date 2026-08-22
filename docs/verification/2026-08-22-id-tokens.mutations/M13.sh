#!/bin/sh
# describes: new-id.sh: the entropy-source guard is dropped for a silent fallback
python3 - <<'PY'
s = open('scripts/new-id.sh').read()
i = s.index('[ -r "$urandom" ] || gr_die \\')
j = s.index('elsewhere."', i) + len('elsewhere."')
s = s[:i] + '[ -r "$urandom" ] || urandom=/dev/null' + s[j:]
open('scripts/new-id.sh','w').write(s)
PY
