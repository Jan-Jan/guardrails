#!/bin/sh
# describes: finish-merge: guard 5 accepts a message with more than one Gate-tree trailer
python3 - <<'PY'
target = 'scripts/finish-merge.sh'
old = '''    (*"$gr_nl"*) gr_refuse \\'''
new = '''    (*"$gr_nl-unmatched"*) gr_refuse \\'''
text = open(target).read()
assert text.count(old) == 1, 'mutation did not apply: %d matches' % text.count(old)
open(target, 'w').write(text.replace(old, new))
PY
