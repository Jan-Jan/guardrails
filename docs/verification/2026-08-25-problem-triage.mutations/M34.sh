#!/bin/sh
# describes: check-trace: only the SHELL today-guard is removed (the calendar guard remains)
python3 - <<'PY'
p = 'scripts/check-trace.sh'
s = open(p).read()
old = '''    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
    *) gr_die "date +%Y-%m-%d produced '$today', which is not a date in YYYY-MM-DD form" ;;'''
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, '    *) ;;'))
PY
