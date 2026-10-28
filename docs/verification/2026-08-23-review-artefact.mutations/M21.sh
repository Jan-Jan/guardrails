#!/bin/sh
# describes: check-review: LC_ALL=C is dropped from the record scan
# retired: check-review.sh was rewritten around the squash message; the record
# scan is gone; a finding line has no multibyte header to misread
# (ADR-k3nkv3).
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('    LC_ALL=C awk -v kws=', '    awk -v kws=')
open('scripts/check-review.sh','w').write(s)
PY
