#!/bin/sh
# describes: check-signing: the verdict letter is read with log.showSignature in force
python3 - <<'PY'
target = 'scripts/check-signing.sh'
old = '''        if ! gstat=$(git log -1 --no-show-signature --format='%G?' "$c" 2>/dev/null) &&'''
new = '''        if ! gstat=$(git log -1 --format='%G?' "$c" 2>/dev/null) &&'''
text = open(target).read()
assert text.count(old) == 1, 'mutation did not apply: %d matches' % text.count(old)
open(target, 'w').write(text.replace(old, new))
PY
