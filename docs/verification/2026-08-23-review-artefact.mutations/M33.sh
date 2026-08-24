#!/bin/sh
# describes: check-review: the finding shape is a regex AND LC_ALL=C is dropped
# The pair is the defect review round 1 found: either alone is survivable, and
# only together do they make a latin-1 finding label fail OPEN at exit 0.
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('    if (substr(s, 1, 9) != "**finding") return 0\n    t = substr(s, 10, 1)\n    return (t !~ /[0-9A-Za-z]/)',
              '    return (s ~ /^\\*\\*finding-[^*]*\\*\\*:/)')
s = s.replace('    LC_ALL=C awk -v kws=', '    awk -v kws=')
open('scripts/check-review.sh','w').write(s)
PY
