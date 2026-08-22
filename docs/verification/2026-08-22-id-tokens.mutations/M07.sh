#!/bin/sh
# describes: lib.sh: gr_def_re spells the pre-change numeric body itself
python3 - <<'PY'
s = open('scripts/lib.sh').read()
old = '''    printf '%s' "${2-^}\\\\*\\\\*(${1})-${GR_ID_BODY}\\\\*\\\\*:"'''
new = '''    printf '%s' "${2-^}\\\\*\\\\*(${1})-[0-9]{3,}\\\\*\\\\*:"'''
assert old in s
open('scripts/lib.sh','w').write(s.replace(old, new))
PY
