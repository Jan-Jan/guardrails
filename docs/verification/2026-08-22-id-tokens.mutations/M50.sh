#!/bin/sh
# describes: new-id.sh: the draw reads until six usable bytes appear (unbounded, pre-review shape)
python3 - <<'PY'
s = open('scripts/new-id.sh').read()
old = '    dd bs=4096 count=1 < "$urandom" 2>/dev/null | LC_ALL=C tr -dc "$alphabet" | cut -c1-6'
new = '    LC_ALL=C tr -dc "$alphabet" < "$urandom" 2>/dev/null | dd bs=1 count=6 2>/dev/null'
assert old in s
open('scripts/new-id.sh','w').write(s.replace(old, new))
PY
