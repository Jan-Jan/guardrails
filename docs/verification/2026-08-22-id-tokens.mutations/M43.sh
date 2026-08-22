#!/bin/sh
# describes: check-ids.sh: the MALFORMED-ID scan drops its --and --not exclusion
python3 - <<'PY'
s = open('scripts/check-ids.sh').read()
old = ' --and --not -e "$def_re"'
assert old in s
open('scripts/check-ids.sh','w').write(s.replace(old, ''))
PY
