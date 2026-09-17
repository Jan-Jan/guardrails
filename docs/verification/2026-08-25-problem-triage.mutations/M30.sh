#!/bin/sh
# describes: lib.sh: gr_value does not trim the trailing whitespace off a value
python3 - <<'PY'
p = 'scripts/lib.sh'
s = open(p).read()
# Re-cut 2026-09-16: gr_value went through gr_kw_lead for one change and was
# reverted to column one when review rejected the widened readers, so the
# verbatim anchor moved twice and is back at the form it had before. The
# mutation itself never changed — drop the trailing trim — and still kills the
# tests it killed before.
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
