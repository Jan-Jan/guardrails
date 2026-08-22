#!/bin/sh
# describes: check-trace.sh: the annotation-run prefix filter keeps its own numeric body
python3 - <<'PY'
s = open('scripts/check-trace.sh').read()
old = '| grep -xE "${_pfx}-${GR_ID_BODY}" | sort -u'
new = '| grep -xE "${_pfx}-[0-9]{3,}" | sort -u'
assert old in s
open('scripts/check-trace.sh','w').write(s.replace(old, new))
PY
