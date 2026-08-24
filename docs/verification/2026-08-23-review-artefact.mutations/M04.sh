#!/bin/sh
# describes: check-review: a detached HEAD is accepted
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
i = s.index('    [ -n "$branch" ] || gr_die \\')
j = s.index('    [ -n "$base" ] || gr_die \\', i)
open('scripts/check-review.sh','w').write(s[:i] + s[j:])
PY
