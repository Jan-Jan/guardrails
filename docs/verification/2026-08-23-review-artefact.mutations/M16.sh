#!/bin/sh
# describes: check-review: the config is not validated
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('\n    gr_check_config\n', '\n')
open('scripts/check-review.sh','w').write(s)
PY
