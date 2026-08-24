#!/bin/sh
# describes: check-review: front matter is not skipped
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('gr_fm_skip(FNR) { next }\n', '')
open('scripts/check-review.sh','w').write(s)
PY
