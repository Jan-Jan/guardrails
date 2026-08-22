#!/bin/sh
# describes: check-ids.sh: DRAFT-ID is suppressed by --allow-draft-files again
python3 - <<'PY'
s = open('scripts/check-ids.sh').read()
old = 'drafts=$(git grep -In --untracked -E "$draft_re" -- . "$GR_SCAN_EXCLUDE")'
new = 'if [ "$allow_draft_files" -eq 1 ]; then drafts=""; _st=0; else\ndrafts=$(git grep -In --untracked -E "$draft_re" -- . "$GR_SCAN_EXCLUDE")'
assert old in s
s = s.replace(old, new)
old2 = '''[ "$_st" -le 1 ] || gr_die "scanning for draft IDs failed (git grep exit $_st)"'''
assert old2 in s
s = s.replace(old2, old2 + '\nfi', 1)
open('scripts/check-ids.sh','w').write(s)
PY
