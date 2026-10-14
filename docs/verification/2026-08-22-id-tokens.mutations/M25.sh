#!/bin/sh
# describes: check-ids.sh: the DRAFT-FILE gate is removed
# Re-cut by ledger-names-at-creation: the anchor was the --allow-draft-files
# guard, which that change removed.
python3 - <<'PY'
s = open('scripts/check-ids.sh').read()
assert s.count('# --- DRAFT-FILE:') == 1
i = s.index('# --- DRAFT-FILE:')
j = s.index('# --- MALFORMED-ID', i)
open('scripts/check-ids.sh','w').write(s[:i] + s[j:])
PY
