#!/bin/sh
# describes: check-review: every branch: line is a claim, not only the first
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('if (K[i] == "branch:" && !claimed) {\n            claimed = 1\n',
              'if (K[i] == "branch:") {\n')
open('scripts/check-review.sh','w').write(s)
PY
