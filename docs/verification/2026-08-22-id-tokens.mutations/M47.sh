#!/bin/sh
# describes: check-ids.sh: the duplicate scan swallows its status again (pre-review shape)
python3 - <<'PY'
s = open('scripts/check-ids.sh').read()
old = '''_defs=$(git grep -h --untracked -oE "$def_re" -- . "$GR_SCAN_EXCLUDE")
_st=$?
[ "$_st" -le 1 ] || gr_die "duplicate scan failed (git grep exit $_st)"
dups=$(printf '%s\\n' "$_defs" | sed 's/[*:]//g' | sort | uniq -d)'''
new = '''dups=$(git grep -h --untracked -oE "$def_re" -- . "$GR_SCAN_EXCLUDE" 2>/dev/null \\
    | sed 's/[*:]//g' | sort | uniq -d)'''
assert old in s
open('scripts/check-ids.sh','w').write(s.replace(old, new))
PY
