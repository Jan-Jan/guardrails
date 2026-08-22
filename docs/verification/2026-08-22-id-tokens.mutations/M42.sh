#!/bin/sh
# describes: check-ids.sh: MALFORMED-ID harvests the forms and relocates each by literal search (the two-pass report)
python3 - <<'PY'
s = open('scripts/check-ids.sh').read()
i = s.index('malformed=$(git grep -nI --untracked -E')
j = s.index('# --- DUPLICATE-ID', i)
new = r'''shaped=$(git grep -hoI --untracked -E "^\\*\\*(${P})-[^*]*\\*\\*:" \
    -- . "$GR_SCAN_EXCLUDE")
_st=$?
[ "$_st" -le 1 ] || gr_die "MALFORMED-ID scan failed (git grep exit $_st)"
if [ -n "$shaped" ]; then
    malformed=$(printf '%s\n' "$shaped" | grep -vE "$def_re" | sort -u)
    if [ -n "$malformed" ]; then
        printf '%s\n' "$malformed" | while IFS= read -r t; do
            [ -n "$t" ] || continue
            git grep -InI --untracked -F -e "$t" -- . "$GR_SCAN_EXCLUDE" 2>/dev/null \
                | sed 's/^/MALFORMED-ID /'
        done
        fail=1
    fi
fi

'''
open('scripts/check-ids.sh','w').write(s[:i] + new + s[j:])
PY
