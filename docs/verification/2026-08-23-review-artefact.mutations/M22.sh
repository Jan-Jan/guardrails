#!/bin/sh
# describes: check-review: an awk failure on a record is not fatal
# retired: check-review.sh was rewritten around the squash message; the record
# scan is gone; an unreadable message is MISSING-RECORD from gr_message_check
# before the message scan runs.
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('        || gr_die "record scan failed on $1"\n', '        || true\n')
open('scripts/check-review.sh','w').write(s)
PY
