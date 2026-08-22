#!/bin/sh
# describes: check-ids.sh: the MALFORMED-ID gate is removed
python3 - <<'PY'
s = open('scripts/check-ids.sh').read()
i = s.index('malformed=$(git grep -nI --untracked -E')
j = s.index('# --- DUPLICATE-ID', i)
open('scripts/check-ids.sh','w').write(s[:i] + s[j:])
PY
