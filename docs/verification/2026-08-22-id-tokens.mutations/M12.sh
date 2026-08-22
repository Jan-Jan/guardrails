#!/bin/sh
# describes: new-id.sh: any prefix is accepted, declared or not
python3 - <<'PY'
s = open('scripts/new-id.sh').read()
old = """gr_contains "$(gr_prefixes || exit 2)" "$prefix" \\
    || gr_die "$prefix is not declared in id_prefixes\""""
assert old in s
open('scripts/new-id.sh','w').write(s.replace(old, ":"))
PY
