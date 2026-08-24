#!/bin/sh
# describes: check-review: an orphan disposition is dropped in silence
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('    else printf "O %d\\n", FNR\n', '')
open('scripts/check-review.sh','w').write(s)
PY
