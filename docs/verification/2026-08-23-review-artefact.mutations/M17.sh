#!/bin/sh
# describes: check-review: an unknown argument is ignored
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('        *) gr_die "unknown argument: $1" ;;', '        *) ;;')
open('scripts/check-review.sh','w').write(s)
PY
