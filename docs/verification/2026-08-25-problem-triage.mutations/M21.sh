#!/bin/sh
# describes: check-trace: the problems: summary line is not printed
python3 - <<'PY'
old = '''echo "problems: open $_open_n, oldest $_oldest_txt; limits age ${age_limit:-none}, open ${open_limit:-none}"'''
new = ''':'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
