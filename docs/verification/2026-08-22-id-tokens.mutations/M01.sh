#!/bin/sh
# describes: lib.sh: the token needs no digit — six characters of the alphabet
python3 - <<'PY'
import re
s = open('scripts/lib.sh').read()
i = s.index('GR_ID_TOKEN="\\\n'); j = s.index('\n\n', i)
s = s[:i] + 'GR_ID_TOKEN="${GR_ID_ANY}${GR_ID_ANY}${GR_ID_ANY}${GR_ID_ANY}${GR_ID_ANY}${GR_ID_ANY}"' + s[j:]
open('scripts/lib.sh','w').write(s)
PY
