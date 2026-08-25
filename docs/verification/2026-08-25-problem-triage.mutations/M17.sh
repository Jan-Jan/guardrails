#!/bin/sh
# describes: check-trace: the backlog is counted per ledger file, not across the ledger
python3 - <<'PY'
old = '''_open_n=$(printf '%s\\n' "$_prs" | grep -c '^W ' || true)'''
new = '''_open_n=$(printf '%s\\n' "$_prs" | grep -c '^W .* PR-001 ' || true)'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
