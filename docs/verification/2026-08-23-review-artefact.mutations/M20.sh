#!/bin/sh
# describes: check-review: findings are never counted in the denominator
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
old = '$1 == "FINDING" { count++ }'
assert s.count(old) == 1, 'mutation did not apply: %d matches' % s.count(old)
s = s.replace(old, '$1 == "FINDING" { }')
open('scripts/check-review.sh','w').write(s)
PY
