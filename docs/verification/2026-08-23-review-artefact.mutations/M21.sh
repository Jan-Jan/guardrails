#!/bin/sh
# describes: check-review: LC_ALL=C is dropped from the record scan
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('    LC_ALL=C awk -v kws=', '    awk -v kws=')
open('scripts/check-review.sh','w').write(s)
PY
