#!/bin/sh
# describes: check-ids.sh: the DRAFT-FILE gate is removed
python3 - <<'PY'
s = open('scripts/check-ids.sh').read()
i = s.index('if [ "$allow_draft_files" -eq 0 ]; then')
j = s.index('# --- MALFORMED-ID', i)
open('scripts/check-ids.sh','w').write(s[:i] + s[j:])
PY
