#!/bin/sh
# describes: find-items.sh: show exits 0 when nothing is found
_gr_before=$(cksum scripts/find-items.sh)
sed -i.bak 's|END { exit (found_count > 0 ? 0 : 1) }|END { exit 0 }|' scripts/find-items.sh
rm -f scripts/find-items.sh.bak

[ "$_gr_before" != "$(cksum scripts/find-items.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
