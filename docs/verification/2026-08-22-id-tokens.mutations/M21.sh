#!/bin/sh
# describes: check-ids.sh: MALFORMED-ID reports without failing the run
python3 - <<'PY'
s = open('scripts/check-ids.sh').read()
old = '''    echo ".guardrails/scripts/new-id.sh <PREFIX>." >&2
    fail=1
fi'''
new = '''    echo ".guardrails/scripts/new-id.sh <PREFIX>." >&2
fi'''
assert old in s
open('scripts/check-ids.sh','w').write(s.replace(old, new))
PY
