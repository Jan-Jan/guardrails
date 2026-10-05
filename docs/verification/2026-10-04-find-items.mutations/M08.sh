#!/bin/sh
# describes: find-items.sh: list does not remove a byte order mark
_gr_before=$(cksum scripts/find-items.sh)
sed -i.bak 's|FNR == 1 { list_flush(); sub(/^\\357\\273\\277/, "") }|FNR == 1 { list_flush() }|' scripts/find-items.sh
rm -f scripts/find-items.sh.bak

[ "$_gr_before" != "$(cksum scripts/find-items.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
