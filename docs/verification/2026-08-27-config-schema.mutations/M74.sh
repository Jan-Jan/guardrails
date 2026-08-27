#!/bin/sh
# describes: lib: the duplicate check runs after the emptiness check again
python3 - <<'PY'
p = 'scripts/lib.sh'
old = '    _dup=$(printf \'%s\\n\' "$_keys" | sort | uniq -d | tr \'\\n\' \' \')\n    [ -z "$_dup" ] || gr_die \\\n"config key(s) set more than once in $GR_CONFIG: ${_dup}\n  Every reader here takes the FIRST one and stops, while YAML takes the last,\n  so one of the two is read by nobody. Keep one."\n\n'
new = ''
s = open(p).read()
assert s.count(old) == 1, 'mutation did not apply: %d matches' % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
