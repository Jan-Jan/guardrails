#!/bin/sh
# describes: check-trace: the front-matter BOM strip is dropped
python3 - <<'PY'
s = open('scripts/check-trace.sh').read()
s = s.replace('            FNR == 1 { sub(/^\\357\\273\\277/, "") }\n', '')
open('scripts/check-trace.sh','w').write(s)
PY
