#!/bin/sh
# describes: find-items.sh: repeated slashes in a ledger path are not collapsed
_gr_before=$(cksum scripts/find-items.sh)
sed -i.bak '\#^    gsub(/\\/\\/+/, "/")$#d' scripts/find-items.sh
rm -f scripts/find-items.sh.bak

[ "$_gr_before" != "$(cksum scripts/find-items.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
