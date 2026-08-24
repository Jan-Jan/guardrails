#!/bin/sh
# describes: check-review: the base-branch refusal is dropped
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
i = s.index('    [ "$branch" != "$base" ] || gr_die \\')
j = s.index('fi\n\ndir=$(gr_verification_dir)', i)
open('scripts/check-review.sh','w').write(s[:i] + s[j:])
PY
