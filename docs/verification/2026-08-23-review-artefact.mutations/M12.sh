#!/bin/sh
# describes: check-review: a finding is not flushed when the next block opens
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('    if (open_line) gr_flush()\n', '')
open('scripts/check-review.sh','w').write(s)
PY
