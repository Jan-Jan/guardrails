#!/bin/sh
# describes: lib.sh: gr_verification_dir does not require the directory to exist
# retired: gr_verification_dir was removed from lib.sh with the
# doc_verification key: the record is the squash message (ADR-k3nkv3).
python3 - <<'PY'
s = open('scripts/lib.sh').read()
i = s.index('    [ -d "$_v" ] || gr_die \\')
j = s.index('    printf \'%s\\n\' "$_v"', i)
open('scripts/lib.sh','w').write(s[:i] + s[j:])
PY
