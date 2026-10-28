#!/bin/sh
# describes: check-review: --branch accepts a missing value
# retired: check-review.sh was rewritten around the squash message; --branch
# is gone: a message belongs to its worktree (ADR-k3nkv3).
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('            [ $# -gt 0 ] || gr_die "--branch needs a branch name"\n', '')
open('scripts/check-review.sh','w').write(s)
PY
