#!/bin/sh
# describes: check-review: provenance is never checked
# retired: check-review.sh was rewritten around the squash message; provenance
# is gone: the message lives in its worktree git directory (ADR-k3nkv3).
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('if [ "$named" -eq 0 ]; then\n    provenance=1', 'if false; then\n    provenance=1')
open('scripts/check-review.sh','w').write(s)
PY
