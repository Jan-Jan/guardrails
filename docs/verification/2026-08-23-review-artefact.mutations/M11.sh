#!/bin/sh
# describes: check-review: a finding at end of file is never flushed
# retired: check-review.sh was rewritten around the squash message; finding
# blocks are gone: a finding is a numbered line of the message (ADR-k3nkv3).
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('END { if (open_line) gr_flush() }\n', '')
open('scripts/check-review.sh','w').write(s)
PY
