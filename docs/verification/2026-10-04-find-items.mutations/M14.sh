#!/bin/sh
# describes: find-items.sh: the ledger file list is split on blanks as well as newlines
_gr_before=$(cksum scripts/find-items.sh)
sed -i.bak "s|^IFS='\$|unused_ifs='|" scripts/find-items.sh
rm -f scripts/find-items.sh.bak

[ "$_gr_before" != "$(cksum scripts/find-items.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
