#!/bin/sh
# describes: finish-merge: guard 5 accepts a Gate-tree trailer that names another tree
python3 - <<'PY'
target = 'scripts/finish-merge.sh'
old = '''[ "$gate_tree" = "$head_tree" ] || gr_refuse \\'''
new = '''[ -n "$head_tree" ] || gr_refuse \\'''
text = open(target).read()
assert text.count(old) == 1, 'mutation did not apply: %d matches' % text.count(old)
open(target, 'w').write(text.replace(old, new))
PY
