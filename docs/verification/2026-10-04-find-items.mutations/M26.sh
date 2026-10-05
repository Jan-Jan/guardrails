#!/bin/sh
# describes: find-items.sh: refs follows core.quotePath
_gr_before=$(cksum scripts/find-items.sh)
sed -i.bak 's|git -c core.quotePath=false -c grep.column=false|git -c grep.column=false|' scripts/find-items.sh
rm -f scripts/find-items.sh.bak

[ "$_gr_before" != "$(cksum scripts/find-items.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
