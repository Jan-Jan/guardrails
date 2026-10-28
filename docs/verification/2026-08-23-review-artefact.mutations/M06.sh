#!/bin/sh
# describes: check-review: the branch is matched as a substring, not whole
# retired: check-review.sh was rewritten around the squash message; branch
# selection is gone: a message belongs to its worktree (ADR-k3nkv3).
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('    gr_contains "$_facts" "B $branch" || continue',
              '    case "$_facts" in *"$branch"*) ;; *) continue ;; esac')
open('scripts/check-review.sh','w').write(s)
PY
