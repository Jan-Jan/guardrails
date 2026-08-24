#!/bin/sh
# describes: check-review: the trailing-CR strip is dropped
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('{ line = $0; sub(/\\r$/, "", line) }', '{ line = $0 }')
open('scripts/check-review.sh','w').write(s)
PY
