#!/bin/sh
# describes: lib.sh: gr_value does not trim the trailing whitespace off a value
python3 - <<'PY'
p = 'scripts/lib.sh'
s = open(p).read()
old = '''function gr_value(line, kw,   v) {
    v = substr(line, length(kw) + 1)
    sub(/^[ \\t]+/, "", v)
    sub(/[ \\t]+$/, "", v)
    return v
}'''
new = '''function gr_value(line, kw,   v) {
    v = substr(line, length(kw) + 1)
    sub(/^[ \\t]+/, "", v)
    return v
}'''
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
