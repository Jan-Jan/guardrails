#!/bin/sh
# describes: check-trace: the problems: summary line is not printed
python3 - <<'PY'
# Anchor re-cut 2026-09-10 (PR-4fwfjp): the summary line gained an `accepted`
# field, so the original anchor matched nothing and the mutation could no
# longer apply. Re-cut rather than left stale, per bb7eee5 — these scripts are
# kept runnable across later changes, and a mutation that cannot apply proves
# nothing about the tests it was written to kill.
old = '''echo "problems: open $_open_n, accepted $_accepted_n, oldest $_oldest_txt; limits age ${age_limit:-none}, open ${open_limit:-none}"'''
new = ''':'''
p = 'scripts/check-trace.sh'
s = open(p).read()
assert s.count(old) == 1, "mutation did not apply: %d matches" % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
