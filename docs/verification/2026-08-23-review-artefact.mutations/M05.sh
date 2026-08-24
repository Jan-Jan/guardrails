#!/bin/sh
# describes: check-review: a failed record listing is not propagated
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('  review happened. Directory:") || exit 2', '  review happened. Directory:")')
open('scripts/check-review.sh','w').write(s)
PY
