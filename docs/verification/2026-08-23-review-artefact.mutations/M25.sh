#!/bin/sh
# describes: check-review: the BOM strip is dropped
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('FNR == 1 { sub(/^\\357\\273\\277/, "") }\n', '')
open('scripts/check-review.sh','w').write(s)
PY
