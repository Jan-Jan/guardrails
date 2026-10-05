#!/bin/sh
# describes: find-items.sh: the ledger file list is no longer deduplicated
_gr_before=$(cksum scripts/find-items.sh)
sed -i.bak 's|if (!file_count\[\$0\]++) print|print|' scripts/find-items.sh
rm -f scripts/find-items.sh.bak

[ "$_gr_before" != "$(cksum scripts/find-items.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
