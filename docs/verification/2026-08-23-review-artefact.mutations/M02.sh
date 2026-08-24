#!/bin/sh
# describes: lib.sh: gr_verification_dir does not require the directory to exist
python3 - <<'PY'
s = open('scripts/lib.sh').read()
i = s.index('    [ -d "$_v" ] || gr_die \\')
j = s.index('    printf \'%s\\n\' "$_v"', i)
open('scripts/lib.sh','w').write(s[:i] + s[j:])
PY
