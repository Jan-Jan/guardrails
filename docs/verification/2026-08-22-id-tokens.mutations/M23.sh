#!/bin/sh
# describes: check-ids.sh: the retired --allow-drafts and --base flags are accepted and ignored
python3 - <<'PY'
s = open('scripts/check-ids.sh').read()
old = "        --allow-draft-files) allow_draft_files=1 ;;"
new = "        --allow-draft-files) allow_draft_files=1 ;;\n        --allow-drafts) allow_draft_files=1 ;;\n        --base) shift ;;"
assert old in s
open('scripts/check-ids.sh','w').write(s.replace(old, new))
PY
