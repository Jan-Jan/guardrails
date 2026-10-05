#!/bin/sh
# describes: find-items.sh: a git grep failure in refs exits 0
_gr_before=$(cksum scripts/find-items.sh)
sed -i.bak 's|(\*) gr_die "git grep exited $refs_status searching for $item_id" ;;|(*) exit 0 ;;|' scripts/find-items.sh
rm -f scripts/find-items.sh.bak

[ "$_gr_before" != "$(cksum scripts/find-items.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
