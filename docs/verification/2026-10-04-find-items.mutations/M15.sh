#!/bin/sh
# describes: find-items.sh: pathname expansion applies to the ledger file list
_gr_before=$(cksum scripts/find-items.sh)
sed -i.bak '/^set -f$/d' scripts/find-items.sh
rm -f scripts/find-items.sh.bak

[ "$_gr_before" != "$(cksum scripts/find-items.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
