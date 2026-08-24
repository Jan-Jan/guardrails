#!/bin/sh
# describes: check-review: --branch accepts a missing value
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('            [ $# -gt 0 ] || gr_die "--branch needs a branch name"\n', '')
open('scripts/check-review.sh','w').write(s)
PY
