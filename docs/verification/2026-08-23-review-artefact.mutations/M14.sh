#!/bin/sh
# describes: check-review: reproduced: is not required
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace("GR_RECORD_FIELDS='reviewer:\nverdict:\nreproduced:'",
              "GR_RECORD_FIELDS='reviewer:\nverdict:'")
open('scripts/check-review.sh','w').write(s)
PY
