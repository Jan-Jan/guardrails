#!/bin/sh
# describes: find-items.sh: show and refs accept a second argument
_gr_before=$(cksum scripts/find-items.sh)
sed -i.bak '/^        \[ $# -eq 1 \] || gr_die "$find_items_usage"$/d' scripts/find-items.sh
rm -f scripts/find-items.sh.bak

[ "$_gr_before" != "$(cksum scripts/find-items.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
