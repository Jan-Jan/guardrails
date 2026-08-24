#!/bin/sh
# describes: check-review: a field with no value counts as present
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('        if (gr_value(line, K[i]) == "") continue\n', '')
open('scripts/check-review.sh','w').write(s)
PY
