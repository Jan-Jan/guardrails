#!/bin/sh
# describes: check-review: a field is matched anywhere on the line, not at column one
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('        if (!gr_kw_here(line, K[i])) continue',
              '        if (index(line, K[i]) == 0) continue')
open('scripts/check-review.sh','w').write(s)
PY
