#!/bin/sh
# describes: lib.sh: gr_verification_dir has no default
# retired: gr_verification_dir was removed from lib.sh with the
# doc_verification key: the record is the squash message (ADR-k3nkv3).
python3 - <<'PY'
s = open('scripts/lib.sh').read()
s = s.replace('    [ -n "$_v" ] || _v=docs/verification\n', '')
open('scripts/lib.sh','w').write(s)
PY
