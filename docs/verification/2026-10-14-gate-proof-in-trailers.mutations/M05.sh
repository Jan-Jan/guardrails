#!/bin/sh
# describes: finish-merge: guard 5 reads the trailer with log.showSignature in force
python3 - <<'PY'
target = 'scripts/finish-merge.sh'
old = '''gate_tree=$(git log -1 --no-show-signature --format='%(trailers:key=Gate-tree,valueonly,unfold)' HEAD) || gr_die \\'''
new = '''gate_tree=$(git log -1 --format='%(trailers:key=Gate-tree,valueonly,unfold)' HEAD) || gr_die \\'''
text = open(target).read()
assert text.count(old) == 1, 'mutation did not apply: %d matches' % text.count(old)
open(target, 'w').write(text.replace(old, new))
PY
