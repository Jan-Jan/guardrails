#!/bin/sh
# describes: new-id.sh: the tree collision scan is dropped
python3 - <<'PY'
s = open('scripts/new-id.sh').read()
old = """        git grep -q --untracked -F -e "$cand" -- . "$GR_SCAN_EXCLUDE"
        _st=$?
        [ "$_st" -le 1 ] || gr_die "scanning for an existing $cand failed (git grep exit $_st)"
        [ "$_st" -eq 0 ] && continue
"""
assert old in s
open('scripts/new-id.sh','w').write(s.replace(old, ""))
PY
