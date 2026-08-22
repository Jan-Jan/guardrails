#!/bin/sh
# describes: check-trace.sh: the reference harvest swallows its status again (pre-review shape)
python3 - <<'PY'
s = open('scripts/check-trace.sh').read()
old = '''    _refs=$(git grep -h --untracked -oE "(${P})-${GR_ID_BODY}(${GR_ID_TAIL}|\\$)" -- $scope)
    _st=$?
    [ "$_st" -le 1 ] || gr_die "reference scan failed (git grep exit $_st)"
    referenced=$(printf '%s\\n' "$_refs" | sed "s/${GR_ID_TAIL}\\$//" | sort -u)'''
new = '''    referenced=$(git grep -h --untracked -oE "(${P})-${GR_ID_BODY}(${GR_ID_TAIL}|\\$)" \\
        -- $scope 2>/dev/null | sed "s/${GR_ID_TAIL}\\$//" | sort -u)'''
assert old in s
open('scripts/check-trace.sh','w').write(s.replace(old, new))
PY
