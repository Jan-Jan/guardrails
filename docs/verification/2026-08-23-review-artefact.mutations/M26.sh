#!/bin/sh
# describes: check-review: the trailing-CR strip is dropped
# retired: check-review.sh was rewritten around the squash message; the record
# file is gone; the message is written by the merge sequence, not an editor
# (ADR-k3nkv3).
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('{ line = $0; sub(/\\r$/, "", line) }', '{ line = $0 }')
open('scripts/check-review.sh','w').write(s)
PY
