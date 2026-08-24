#!/bin/sh
# describes: check-review: a finding at end of file is never flushed
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('END { if (open_line) gr_flush() }\n', '')
open('scripts/check-review.sh','w').write(s)
PY
