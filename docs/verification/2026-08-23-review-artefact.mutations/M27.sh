#!/bin/sh
# describes: check-review: every branch: line is a claim, not only the first
# retired: check-review.sh was rewritten around the squash message; branch
# selection is gone: a message belongs to its worktree (ADR-k3nkv3).
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('if (K[i] == "branch:" && !claimed) {\n            claimed = 1\n',
              'if (K[i] == "branch:") {\n')
open('scripts/check-review.sh','w').write(s)
PY
