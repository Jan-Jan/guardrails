#!/bin/sh
# describes: find-items.sh: show does not remove a carriage return
_gr_before=$(cksum scripts/find-items.sh)
sed -i.bak '/^show_status=0$/,$s|^{ line = $0; sub(/\\r$/, "", line) }$|{ line = $0 }|' scripts/find-items.sh
rm -f scripts/find-items.sh.bak

[ "$_gr_before" != "$(cksum scripts/find-items.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
