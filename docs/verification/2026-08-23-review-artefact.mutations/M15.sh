#!/bin/sh
# describes: check-review: a disposition outside any finding block counts
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('open_line && gr_kw_here(line, "disposition:") {',
              'gr_kw_here(line, "disposition:") {')
open('scripts/check-review.sh','w').write(s)
PY
