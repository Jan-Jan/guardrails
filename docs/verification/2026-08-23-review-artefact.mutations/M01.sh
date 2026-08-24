#!/bin/sh
# describes: lib.sh: gr_verification_dir has no default
python3 - <<'PY'
s = open('scripts/lib.sh').read()
s = s.replace('    [ -n "$_v" ] || _v=docs/verification\n', '')
open('scripts/lib.sh','w').write(s)
PY
