#!/bin/sh
# describes: find-items.sh: the last status line wins, not the first
_gr_before=$(cksum scripts/find-items.sh)
sed -i.bak 's|cur != "" && !has_status && gr_kw_here(line, "status:")|cur != "" \&\& gr_kw_here(line, "status:")|' scripts/find-items.sh
rm -f scripts/find-items.sh.bak

[ "$_gr_before" != "$(cksum scripts/find-items.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
