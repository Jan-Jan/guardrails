#!/bin/sh
# describes: lib.sh: front matter opens on any leading --- again, header or rule (review N2)
python3 - <<'PY'
p = 'scripts/lib.sh'
s = open(p).read()
old = '''    if (n == 1) { GR_FM_MAYBE = (line ~ /^---[ \\t\\r]*$/); return }
    if (n == 2) {
        if (GR_FM_MAYBE && line !~ /^[ \\t\\r]*$/) GR_FM_IN = 1
        GR_FM_MAYBE = 0
        if (!GR_FM_IN) return
    }'''
new = '''    if (n == 1 && line ~ /^---[ \\t\\r]*$/) { GR_FM_IN = 1; return }'''
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
