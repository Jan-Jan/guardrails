#!/bin/sh
# describes: check-ids.sh: the retired --allow-drafts and --base flags are accepted and ignored
# Re-cut by ledger-names-at-creation: the anchor was the --allow-draft-files
# case arm, which that change removed.
python3 - <<'PY'
s = open('scripts/check-ids.sh').read()
old = '        (*) gr_die "unknown argument: $1" ;;'
new = '        (--allow-drafts) ;;\n        (--base) shift ;;\n' + old
assert s.count(old) == 1
open('scripts/check-ids.sh','w').write(s.replace(old, new))
PY
