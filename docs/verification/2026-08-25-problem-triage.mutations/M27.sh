#!/bin/sh
# describes: check-trace: BOTH today-guards removed — a nonsense date is accepted
python3 - <<'PY'
p = 'scripts/check-trace.sh'
s = open(p).read()
old_shell = '''    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
    *) gr_die "date +%Y-%m-%d produced '$today', which is not a date in YYYY-MM-DD form" ;;'''
old_awk = '''LC_ALL=C awk -v today="$today" "$GR_AWK_CIVIL"'BEGIN { exit(gr_date_ok(today) ? 0 : 1) }' \\
    || gr_die "date +%Y-%m-%d produced '$today', which is not a calendar date"'''
assert s.count(old_shell) == 1, "shell guard: %d matches" % s.count(old_shell)
assert s.count(old_awk) == 1, "awk guard: %d matches" % s.count(old_awk)
s = s.replace(old_shell, '    *) ;;').replace(old_awk, ':')
open(p, 'w').write(s)
PY
