#!/bin/sh
# describes: check-trace: the summary reports every limit as none, set or not
python3 - <<'PY'
old = '''echo "problems: open $_open_n, oldest $_oldest_txt; limits age ${age_limit:-none}, open ${open_limit:-none}"'''
new = '''echo "problems: open $_open_n, oldest $_oldest_txt; limits age none, open none"'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
