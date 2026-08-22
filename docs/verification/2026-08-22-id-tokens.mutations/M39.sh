#!/bin/sh
# describes: finalize-docs.sh: a ledger name containing whitespace is accepted
python3 - <<'PY'
s = open('scripts/finalize-docs.sh').read()
old = """        case "$f" in
            *" "* | *"\t"*)
                gr_die "draft ledger file name contains whitespace: $f" ;;
        esac
"""
assert old in s, repr(s[s.index('case "$f" in'):][:200])
open('scripts/finalize-docs.sh','w').write(s.replace(old, ""))
PY
