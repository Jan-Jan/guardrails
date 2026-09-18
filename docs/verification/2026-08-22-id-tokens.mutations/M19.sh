#!/bin/sh
# describes: lib.sh: the MALFORMED-ID scan is not anchored to line start
# The pattern was spelled out in check-ids.sh when this was cut; it now lives in
# gr_def_re_loose, whose one consumer is still the MALFORMED-ID scan.
python3 - <<'PY'
s = open('scripts/lib.sh').read()
old = r'''    printf '%s' "${2-^}\\*\\*(${1})-[^*]*\\*\\*:"'''
new = r'''    printf '%s' "${2-}\\*\\*(${1})-[^*]*\\*\\*:"'''
assert s.count(old) == 1, s.count(old)
open('scripts/lib.sh','w').write(s.replace(old, new))
PY
