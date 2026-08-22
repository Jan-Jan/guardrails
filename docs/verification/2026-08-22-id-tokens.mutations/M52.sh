#!/bin/sh
# describes: lib.sh: a mistyped ID leaves its stray characters, ending the annotation run
python3 - <<'PY'
s = open('scripts/lib.sh').read()
old = """            sub(/^[0-9A-Za-z]+/, "", rest)
"""
assert old in s
open('scripts/lib.sh','w').write(s.replace(old, ""))
PY
