#!/bin/sh
# describes: new-id.sh: the alphabet and digit set are hand-typed, not derived from lib.sh
python3 - <<'PY'
s = open('scripts/new-id.sh').read()
old = """alphabet=$(printf '%s' "$GR_ID_ANY" | tr -d '[]')
digits=$(printf '%s' "$GR_ID_DIGIT" | tr -d '[]')"""
new = """alphabet='abcdefghjkmnpqrstuvwxyz23456789'
digits='23456789'"""
assert old in s
open('scripts/new-id.sh','w').write(s.replace(old, new))
PY
