#!/bin/sh
# describes: check-review: a finding-shaped line that opens no block is passed over
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
i = s.index('!gr_block_opens(line) && gr_finding_shaped(line) {')
j = s.index('}\n', s.index('printf "M %d', i))
open('scripts/check-review.sh','w').write(s[:i] + s[j+2:])
PY
