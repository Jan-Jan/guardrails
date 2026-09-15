#!/bin/sh
# describes: check-trace: the triage scan does not strip a trailing CR
python3 - <<'PY'
# Anchor widened 2026-09-10 (PR-zt5c2v). Not because the quoted line changed —
# because the supersession scan added a SECOND awk block containing it
# verbatim, so `s.count(old)` became 2 and the assert fired. Duplication stales
# an anchor exactly as an edit does, which is the case develop-change step 6's
# grep is meant to catch: the grep finds two hits, not zero.
#
# `gr_prflush()` is the triage scan's own flush and appears in no other block,
# so the three-line context is unique (probed: 2 -> 1). The mutation itself is
# unchanged — the triage scan stops stripping a trailing CR.
old = '''            { line = $0; sub(/\\r$/, "", line) }
            gr_block_closes(line) {
                gr_prflush()'''
new = '''            { line = $0 }
            gr_block_closes(line) {
                gr_prflush()'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
