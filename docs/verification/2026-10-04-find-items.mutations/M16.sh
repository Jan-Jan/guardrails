#!/bin/sh
# describes: find-items.sh: the unit manifest is not read
_gr_before=$(cksum scripts/find-items.sh)
sed -i.bak '/^gr_unit_engage$/d' scripts/find-items.sh
rm -f scripts/find-items.sh.bak

[ "$_gr_before" != "$(cksum scripts/find-items.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
