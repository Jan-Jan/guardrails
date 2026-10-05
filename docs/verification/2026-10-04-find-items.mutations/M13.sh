#!/bin/sh
# describes: find-items.sh: show does not end a block at the end of its file
_gr_before=$(cksum scripts/find-items.sh)
sed -i.bak 's|FNR == 1 { printing = 0; blank_run = "";|FNR == 1 { blank_run = "";|' scripts/find-items.sh
rm -f scripts/find-items.sh.bak

[ "$_gr_before" != "$(cksum scripts/find-items.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
