#!/bin/sh
# describes: check-ids.sh: MALFORMED-ID judges any prefix, not only the declared ones
python3 - <<'PY'
s = open('scripts/check-ids.sh').read()
old = '    -e "^\\\\*\\\\*(${P})-[^*]*\\\\*\\\\*:" --and --not -e "$def_re"'
new = '    -e "^\\\\*\\\\*[A-Za-z][A-Za-z0-9]*-[^*]*\\\\*\\\\*:" --and --not -e "$def_re"'
assert old in s
open('scripts/check-ids.sh','w').write(s.replace(old, new))
PY
