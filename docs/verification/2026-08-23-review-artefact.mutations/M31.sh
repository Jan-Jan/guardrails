#!/bin/sh
# describes: lib.sh: an empty doc_verification value falls back to the default
# retired: the doc_verification key is withdrawn and gr_verification_dir
# removed: the record is the squash message (ADR-k3nkv3); tests/lib.bats
# "doc_verification is withdrawn" covers the withdrawal.
python3 - <<'PY'
s = open('scripts/lib.sh').read()
i = s.index('    if [ -z "$_v" ] && grep -q ')
j = s.index('    [ -n "$_v" ] || _v=docs/verification', i)
open('scripts/lib.sh','w').write(s[:i] + s[j:])
PY
