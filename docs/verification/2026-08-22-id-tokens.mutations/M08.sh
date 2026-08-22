#!/bin/sh
# describes: lib.sh: the annotation-run rule keeps its pre-change numeric body
python3 - <<'PY'
s = open('scripts/lib.sh').read()
old = """    while (match(rest, /^[ \\t,]*[A-Za-z]+-'"${GR_ID_BODY}"'/)) {"""
new = """    while (match(rest, /^[ \\t,]*[A-Za-z]+-[0-9][0-9][0-9]+/)) {"""
assert old in s
open('scripts/lib.sh','w').write(s.replace(old, new))
PY
