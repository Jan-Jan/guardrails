#!/bin/sh
# describes: check-trace.sh: the DANGLING-REF harvest drops its trailing boundary
python3 - <<'PY'
s = open('scripts/check-trace.sh').read()
old = '''    _refs=$(git grep -h --untracked -oE "(${P})-${GR_ID_BODY}(${GR_ID_TAIL}|\\$)" -- $scope)
    _st=$?
    [ "$_st" -le 1 ] || gr_die "reference scan failed (git grep exit $_st)"
    referenced=$(printf '%s\\n' "$_refs" | sed "s/${GR_ID_TAIL}\\$//" | sort -u)'''
new = '''    _refs=$(git grep -h --untracked -oE "(${P})-${GR_ID_BODY}" -- $scope)
    _st=$?
    [ "$_st" -le 1 ] || gr_die "reference scan failed (git grep exit $_st)"
    referenced=$(printf '%s\\n' "$_refs" | sort -u)'''
assert old in s
open('scripts/check-trace.sh','w').write(s.replace(old, new))
PY
