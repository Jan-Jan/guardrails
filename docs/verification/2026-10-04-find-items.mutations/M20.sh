#!/bin/sh
# describes: find-items.sh: an unknown subcommand is not rejected
_gr_before=$(cksum scripts/find-items.sh)
sed -i.bak 's|^    (\*) gr_die "$find_items_usage" ;;$|    (*) ;;|' scripts/find-items.sh
rm -f scripts/find-items.sh.bak

[ "$_gr_before" != "$(cksum scripts/find-items.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
