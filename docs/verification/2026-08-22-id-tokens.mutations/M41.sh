#!/bin/sh
# describes: finalize-docs.sh: the same-day collision suffix never fires
python3 - <<'PY'
s = open('scripts/finalize-docs.sh').read()
old = """        while [ -e "$target" ] || printf '%s' "$renames" \\
                | awk -v t="$target" '$2 == t { found = 1 } END { exit !found }'; do"""
new = """        while false; do"""
assert old in s
open('scripts/finalize-docs.sh','w').write(s.replace(old, new))
PY
