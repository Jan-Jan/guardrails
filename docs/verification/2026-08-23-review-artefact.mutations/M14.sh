#!/bin/sh
# describes: check-review: reproduced: is not required
# retired: check-review.sh was rewritten around the squash message; the field
# list moved to gr_message_check in lib.sh; tests/lib.bats "gr_message_check
# reports each missing or empty review field" covers it.
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace("GR_RECORD_FIELDS='reviewer:\nverdict:\nreproduced:'",
              "GR_RECORD_FIELDS='reviewer:\nverdict:'")
open('scripts/check-review.sh','w').write(s)
PY
