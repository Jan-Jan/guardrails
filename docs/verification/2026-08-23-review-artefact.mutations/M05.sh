#!/bin/sh
# describes: check-review: a failed record listing is not propagated
# retired: check-review.sh was rewritten around the squash message; the record
# listing it guards is gone: the record is the squash message (ADR-k3nkv3),
# read from one file.
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('  review happened. Directory:") || exit 2', '  review happened. Directory:")')
open('scripts/check-review.sh','w').write(s)
PY
