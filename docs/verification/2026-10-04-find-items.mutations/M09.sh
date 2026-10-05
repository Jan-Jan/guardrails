#!/bin/sh
# describes: find-items.sh: show does not remove a byte order mark
_gr_before=$(cksum scripts/find-items.sh)
sed -i.bak 's|FNR == 1 { printing = 0; blank_run = ""; sub(/^\\357\\273\\277/, "") }|FNR == 1 { printing = 0; blank_run = "" }|' scripts/find-items.sh
rm -f scripts/find-items.sh.bak

[ "$_gr_before" != "$(cksum scripts/find-items.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
