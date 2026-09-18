#!/bin/sh
# describes: lib.sh: MALFORMED-ID judges any prefix, not only the declared ones
# The pattern was spelled out in check-ids.sh when this was cut; it now lives in
# gr_def_re_loose, whose one consumer is still the MALFORMED-ID scan.
python3 - <<'PY'
s = open('scripts/lib.sh').read()
old = r'''    printf '%s' "${2-^}\\*\\*(${1})-[^*]*\\*\\*:"'''
new = r'''    printf '%s' "${2-^}\\*\\*([A-Za-z][A-Za-z0-9]*)-[^*]*\\*\\*:"'''
assert s.count(old) == 1, s.count(old)
open('scripts/lib.sh','w').write(s.replace(old, new))
PY
