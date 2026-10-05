#!/bin/sh
# describes: find-items.sh: refs prints definition lines
_gr_before=$(cksum scripts/find-items.sh)
sed -i.bak 's| --and --not -e "$definition_re")| )|' scripts/find-items.sh
rm -f scripts/find-items.sh.bak

[ "$_gr_before" != "$(cksum scripts/find-items.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
