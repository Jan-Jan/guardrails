#!/bin/sh
# describes: check-review: the checked: denominator is not printed
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('echo "checked: records $_n, for $branch $_matched, findings $_findings; $_prov"\n', '')
open('scripts/check-review.sh','w').write(s)
PY
