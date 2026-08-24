#!/bin/sh
# describes: lib.sh: an empty doc_verification value falls back to the default
python3 - <<'PY'
s = open('scripts/lib.sh').read()
i = s.index('    if [ -z "$_v" ] && grep -q ')
j = s.index('    [ -n "$_v" ] || _v=docs/verification', i)
open('scripts/lib.sh','w').write(s[:i] + s[j:])
PY
