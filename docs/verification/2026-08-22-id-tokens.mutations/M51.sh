#!/bin/sh
# describes: new-id.sh: the give-up message names one cause for both (pre-review shape)
python3 - <<'PY'
s = open('scripts/new-id.sh').read()
i = s.index('    if [ -z "$id" ] && [ "$drew" -eq 0 ]; then')
j = s.index('    fi\n', i) + len('    fi\n')
open('scripts/new-id.sh','w').write(s[:i] + s[j:])
PY
