#!/bin/sh
# describes: check-ids.sh: the MALFORMED-ID failure drops its guidance lines
python3 - <<'PY'
s = open('scripts/check-ids.sh').read()
old = '''    echo "guardrails: the lines above open with a definition form whose ID is not" >&2
    echo "valid, so no gate can see the item they announce. Give each one an ID from" >&2
    echo ".guardrails/scripts/new-id.sh <PREFIX>." >&2
'''
assert old in s
open('scripts/check-ids.sh','w').write(s.replace(old, ""))
PY
