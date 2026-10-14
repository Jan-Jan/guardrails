#!/bin/sh
# describes: finalize-docs.sh: the same-day collision suffix never fires
# retired: scripts/finalize-docs.sh was deleted by ledger-names-at-creation
# (ADR-cy7ahd): nothing renames a ledger file at merge, so the behavior
# this mutation removed no longer exists, and its tests went with it.
python3 - <<'PY'
s = open('scripts/finalize-docs.sh').read()
old = """        while [ -e "$target" ] || printf '%s' "$renames" \\
                | awk -v t="$target" '$2 == t { found = 1 } END { exit !found }'; do"""
new = """        while false; do"""
assert old in s
open('scripts/finalize-docs.sh','w').write(s.replace(old, new))
PY
