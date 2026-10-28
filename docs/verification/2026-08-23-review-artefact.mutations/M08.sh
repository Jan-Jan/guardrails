#!/bin/sh
# describes: check-review: a field is matched anywhere on the line, not at column one
# retired: check-review.sh was rewritten around the squash message; the field
# rule moved to gr_message_check in lib.sh; tests/lib.bats "gr_message_check
# does not count a review field indented or in the trailer paragraph" covers
# it.
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('        if (!gr_kw_here(line, K[i])) continue',
              '        if (index(line, K[i]) == 0) continue')
open('scripts/check-review.sh','w').write(s)
PY
