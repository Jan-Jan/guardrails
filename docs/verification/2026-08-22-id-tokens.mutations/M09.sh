#!/bin/sh
# describes: new-id.sh: the digit redraw is dropped
python3 - <<'PY'
s = open('scripts/new-id.sh').read()
old = """        case "$tok" in
            *["$digits"]*) ;;
            *) continue ;;   # ~1 draw in 6 is all letters; REQ-argued is why
        esac
"""
assert old in s
open('scripts/new-id.sh','w').write(s.replace(old, ""))
PY
