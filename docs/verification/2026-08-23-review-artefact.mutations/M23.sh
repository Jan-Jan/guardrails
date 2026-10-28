#!/bin/sh
# describes: check-review: the finding shape is a regex, not a byte test
# retired: check-review.sh was rewritten around the squash message; finding-
# shaped headers are gone: a finding is a numbered line of the message
# (ADR-k3nkv3).
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('    if (substr(s, 1, 9) != "**finding") return 0\n    t = substr(s, 10, 1)\n    return (t !~ /[0-9A-Za-z]/)',
              '    return (s ~ /^\\*\\*finding-[^*]*\\*\\*:/)')
open('scripts/check-review.sh','w').write(s)
PY
