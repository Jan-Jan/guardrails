#!/bin/sh
# describes: check-review: findings are never counted in the denominator
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('    print "N"\n', '')
open('scripts/check-review.sh','w').write(s)
PY
