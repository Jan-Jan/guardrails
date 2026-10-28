#!/bin/sh
# describes: check-review: --branch may name the base branch
# retired: check-review.sh was rewritten around the squash message; --branch
# is gone: a message belongs to its worktree (ADR-k3nkv3).
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
i = s.index('    [ -z "$base" ] || [ "$branch" != "$base" ] || gr_die \\')
j = s.index('else\n    branch=$(git branch --show-current', i)
open('scripts/check-review.sh','w').write(s[:i] + '    :\n' + s[j:])
PY
