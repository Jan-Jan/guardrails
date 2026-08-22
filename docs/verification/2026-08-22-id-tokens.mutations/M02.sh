#!/bin/sh
# describes: lib.sh: the token union loses its last branch (digit in position six)
python3 - <<'PY'
s = open('scripts/lib.sh').read()
old = '|\\\n${GR_ID_LETTER}${GR_ID_LETTER}${GR_ID_LETTER}${GR_ID_LETTER}${GR_ID_LETTER}${GR_ID_DIGIT}"'
assert old in s
open('scripts/lib.sh','w').write(s.replace(old, '"'))
PY
