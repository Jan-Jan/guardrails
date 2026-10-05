#!/bin/sh
# describes: find-items.sh: list does not end an item at the end of its file
_gr_before=$(cksum scripts/find-items.sh)
sed -i.bak 's|FNR == 1 { list_flush(); sub(|FNR == 1 { sub(|' scripts/find-items.sh
rm -f scripts/find-items.sh.bak

[ "$_gr_before" != "$(cksum scripts/find-items.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
