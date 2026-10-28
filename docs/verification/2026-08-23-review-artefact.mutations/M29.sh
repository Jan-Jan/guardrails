#!/bin/sh
# describes: check-review: an orphan disposition is dropped in silence
# retired: check-review.sh was rewritten around the squash message; ORPHAN-
# DISPOSITION is gone: a disposition is on its finding line (ADR-k3nkv3).
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('    else printf "O %d\\n", FNR\n', '')
open('scripts/check-review.sh','w').write(s)
PY
