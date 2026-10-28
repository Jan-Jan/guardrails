#!/bin/sh
# describes: check-review: the finding line is reported as NR, not FNR
# retired: check-review.sh was rewritten around the squash message; finding
# blocks are gone: a finding is a numbered line of the message (ADR-k3nkv3).
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('        open_line = FNR; open_id = gr_block_id(line); disposed = 0',
              '        open_line = NR; open_id = gr_block_id(line); disposed = 0')
open('scripts/check-review.sh','w').write(s)
PY
