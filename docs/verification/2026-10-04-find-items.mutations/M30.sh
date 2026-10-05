#!/bin/sh
# describes: find-items.sh: a leading ./ in a ledger path is not removed
_gr_before=$(cksum scripts/find-items.sh)
sed -i.bak '\#^    while (sub(/^\\.\\//, "")) {}$#d' scripts/find-items.sh
rm -f scripts/find-items.sh.bak

[ "$_gr_before" != "$(cksum scripts/find-items.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
