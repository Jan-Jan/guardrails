#!/bin/sh
# describes: new-id.sh: COUNT is used unvalidated
python3 - <<'PY'
s = open('scripts/new-id.sh').read()
old = """case "$count" in
    ''|*[!0-9]*) gr_die "COUNT must be a positive integer: $count" ;;
esac
[ "$count" -ge 1 ] || gr_die "COUNT must be a positive integer: $count"
"""
assert old in s
open('scripts/new-id.sh','w').write(s.replace(old, ""))
PY
