#!/bin/sh
# describes: find-items.sh: trailing blank lines of a block are printed
_gr_before=$(cksum scripts/find-items.sh)
sed -i.bak '/^printing && line ~/d' scripts/find-items.sh
rm -f scripts/find-items.sh.bak

[ "$_gr_before" != "$(cksum scripts/find-items.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
