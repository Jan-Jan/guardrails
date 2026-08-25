#!/bin/sh
# describes: check-trace: the calendar guard on today is removed (shape check remains)
python3 - <<'PY'
old = '''LC_ALL=C awk -v today="$today" "$GR_AWK_CIVIL"'BEGIN { exit(gr_date_ok(today) ? 0 : 1) }' \\
    || gr_die "date +%Y-%m-%d produced '$today', which is not a calendar date"'''
new = ''':'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
