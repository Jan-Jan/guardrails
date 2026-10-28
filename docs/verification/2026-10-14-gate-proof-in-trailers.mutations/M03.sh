#!/bin/sh
# describes: finish-merge: guard 5 accepts a Gate-tree trailer that names another tree
# retired: guard 5's Gate-tree reading was removed from finish-merge.sh: the
# signed message must pass gr_message_check (ADR-f6ytg7), which reads the
# Gate-tree rule from the grammar ADR-3hsvvq states. The rule is covered by
# the finish-merge.bats guard-5 tests and lib.bats.
python3 - <<'PY'
target = 'scripts/finish-merge.sh'
old = '''[ "$gate_tree" = "$head_tree" ] || gr_refuse \\'''
new = '''[ -n "$head_tree" ] || gr_refuse \\'''
text = open(target).read()
assert text.count(old) == 1, 'mutation did not apply: %d matches' % text.count(old)
open(target, 'w').write(text.replace(old, new))
PY
