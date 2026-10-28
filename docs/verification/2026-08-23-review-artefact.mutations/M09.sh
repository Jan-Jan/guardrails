#!/bin/sh
# describes: check-review: front matter is not skipped
# retired: check-review.sh was rewritten around the squash message; the
# message has no front matter (ADR-k3nkv3).
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('gr_fm_skip(FNR) { next }\n', '')
open('scripts/check-review.sh','w').write(s)
PY
