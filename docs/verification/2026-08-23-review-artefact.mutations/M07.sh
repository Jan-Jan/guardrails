#!/bin/sh
# describes: check-review: a field with no value counts as present
# retired: check-review.sh was rewritten around the squash message; the field
# rule moved to gr_message_check in lib.sh; tests/lib.bats "gr_message_check
# reports each missing or empty review field" covers it.
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('        if (gr_value(line, K[i]) == "") continue\n', '')
open('scripts/check-review.sh','w').write(s)
PY
