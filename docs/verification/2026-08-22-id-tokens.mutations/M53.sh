#!/bin/sh
# describes: finalize-docs.sh: --dry-run exits before printing the renames it planned
# retired: scripts/finalize-docs.sh was deleted by ledger-names-at-creation
# (ADR-cy7ahd): nothing renames a ledger file at merge, so the behavior
# this mutation removed no longer exists, and its tests went with it.
python3 - <<'PY'
s = open('scripts/finalize-docs.sh').read()
old = '[ -n "$renames" ] || exit 0\n'
new = '[ -n "$renames" ] || exit 0\n[ "$dry" -eq 1 ] && exit 0\n'
assert old in s
open('scripts/finalize-docs.sh','w').write(s.replace(old, new))
PY
