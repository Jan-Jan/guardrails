#!/bin/sh
# describes: check-ids.sh: the duplicate scan holds its own pathspec literal
python3 - <<'PY'
s = open('scripts/check-ids.sh').read()
tok = '"$GR_SCAN_EXCLUDE"'
idx = -1
for _ in range(3):
    idx = s.index(tok, idx + 1)
open('scripts/check-ids.sh','w').write(
    s[:idx] + "':(exclude).guardrails/scripts'" + s[idx+len(tok):])
PY
