#!/bin/sh
# describes: find-items.sh: list ignores an unknown argument
_gr_before=$(cksum scripts/find-items.sh)
sed -i.bak 's|(\*) gr_die "unknown argument: $1" ;;|(*) ;;|' scripts/find-items.sh
rm -f scripts/find-items.sh.bak

[ "$_gr_before" != "$(cksum scripts/find-items.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
