#!/bin/sh
# describes: lib: a key is accepted when EITHER reader finds something
python3 - <<'PY'
p = 'scripts/lib.sh'
old = '        if gr_contains "$GR_LIST_KEYS" "$_k"; then\n            [ -z "$(cfg_get "$_k")" ] || _wrong="${_wrong} $_k"'
new = '        if false; then\n            [ -z "$(cfg_get "$_k")" ] || _wrong="${_wrong} $_k"'
s = open(p).read()
assert s.count(old) == 1, 'mutation did not apply: %d matches' % s.count(old)
open(p, 'w').write(s.replace(old, new))
PY
