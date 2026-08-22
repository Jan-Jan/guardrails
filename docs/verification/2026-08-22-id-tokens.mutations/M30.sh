#!/bin/sh
# describes: check-trace.sh: the DANGLING-REF harvest keeps its own numeric body
python3 - <<'PY'
s = open('scripts/check-trace.sh').read()
old = '_refs=$(git grep -h --untracked -oE "(${P})-${GR_ID_BODY}(${GR_ID_TAIL}|\\$)" -- $scope)'
new = '_refs=$(git grep -h --untracked -oE "(${P})-[0-9]{3,}(${GR_ID_TAIL}|\\$)" -- $scope)'
assert old in s
open('scripts/check-trace.sh','w').write(s.replace(old, new))
PY
