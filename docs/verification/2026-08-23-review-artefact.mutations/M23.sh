#!/bin/sh
# describes: check-review: the finding shape is a regex, not a byte test
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('    if (substr(s, 1, 9) != "**finding") return 0\n    t = substr(s, 10, 1)\n    return (t !~ /[0-9A-Za-z]/)',
              '    return (s ~ /^\\*\\*finding-[^*]*\\*\\*:/)')
open('scripts/check-review.sh','w').write(s)
PY
