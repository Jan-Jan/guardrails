#!/bin/sh
# describes: find-items.sh: refs reads binary files
_gr_before=$(cksum scripts/find-items.sh)
sed -i.bak 's|grep -n -w -I -E --untracked|grep -n -w -E --untracked|' scripts/find-items.sh
rm -f scripts/find-items.sh.bak

[ "$_gr_before" != "$(cksum scripts/find-items.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
