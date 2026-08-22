#!/bin/sh
# describes: lib.sh: the annotation run credits a truncated reference again
python3 - <<'PY'
s = open('scripts/lib.sh').read()
old = """        if (nxt != "" && nxt !~ /'"${GR_ID_TAIL}"'/) {
            sub(/^[0-9A-Za-z]+/, "", rest)
            continue
        }
"""
assert old in s
open('scripts/lib.sh','w').write(s.replace(old, ""))
PY
