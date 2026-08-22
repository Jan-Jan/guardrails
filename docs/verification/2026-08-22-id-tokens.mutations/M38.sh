#!/bin/sh
# describes: finalize-docs.sh: doc_* values are not validated before the renames
python3 - <<'PY'
s = open('scripts/finalize-docs.sh').read()
old = """for _key in doc_srs doc_rmf doc_sad doc_soup doc_problems; do
    gr_doc_files "$_key" >/dev/null || exit 2
done
"""
assert old in s
open('scripts/finalize-docs.sh','w').write(s.replace(old, ""))
PY
