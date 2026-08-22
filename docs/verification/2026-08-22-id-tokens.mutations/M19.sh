#!/bin/sh
# describes: check-ids.sh: the MALFORMED-ID scan is not anchored to line start
python3 - <<'PY'
s = open('scripts/check-ids.sh').read()
old = '    -e "^\\\\*\\\\*(${P})-[^*]*\\\\*\\\\*:" --and --not -e "$def_re"'
new = '    -e "\\\\*\\\\*(${P})-[^*]*\\\\*\\\\*:" --and --not -e "$def_re"'
assert old in s
open('scripts/check-ids.sh','w').write(s.replace(old, new))
PY
