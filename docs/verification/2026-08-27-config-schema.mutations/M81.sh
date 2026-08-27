#!/bin/sh
# describes: check-signing: cd fails open outside a repository, as it did before
python3 - <<'PY'
p = 'scripts/check-signing.sh'
old = '# NOT `cd "$(gr_root)" || exit 2`: gr_root\'s gr_die exits only the command\n# substitution, and under dash `cd ""` returns 0 and stays put — so outside a\n# git repository the script carried on in the caller\'s directory with a\n# relative config path. The status has to be taken from the substitution.\ngr_repo_root=$(gr_root) || exit 2\ncd "$gr_repo_root" || exit 2\n'
new = 'cd "$(gr_root)" || exit 2\n'
s = open(p).read()
assert s.count(old) == 1, 'mutation did not apply: %d matches' % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
