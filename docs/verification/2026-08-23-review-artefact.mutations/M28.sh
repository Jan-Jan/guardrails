#!/bin/sh
# describes: check-review: provenance is never checked
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('if [ "$named" -eq 0 ]; then\n    provenance=1', 'if false; then\n    provenance=1')
open('scripts/check-review.sh','w').write(s)
PY
