#!/bin/sh
# describes: finalize-docs.sh: --dry-run exits before printing the renames it planned
python3 - <<'PY'
s = open('scripts/finalize-docs.sh').read()
old = '[ -n "$renames" ] || exit 0\n'
new = '[ -n "$renames" ] || exit 0\n[ "$dry" -eq 1 ] && exit 0\n'
assert old in s
open('scripts/finalize-docs.sh','w').write(s.replace(old, new))
PY
