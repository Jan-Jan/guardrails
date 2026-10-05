#!/bin/sh
# describes: find-items.sh: list does not remove a carriage return
_gr_before=$(cksum scripts/find-items.sh)
sed -i.bak '/^function list_flush() {$/,/^END { list_flush() }$/s|^{ line = $0; sub(/\\r$/, "", line) }$|{ line = $0 }|' scripts/find-items.sh
rm -f scripts/find-items.sh.bak

[ "$_gr_before" != "$(cksum scripts/find-items.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
