#!/bin/sh
# describes: find-items.sh: refs matches the ID inside a longer token
_gr_before=$(cksum scripts/find-items.sh)
sed -i.bak 's|grep -n -w -I -E --untracked|grep -n -I -E --untracked|' scripts/find-items.sh
rm -f scripts/find-items.sh.bak

[ "$_gr_before" != "$(cksum scripts/find-items.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
