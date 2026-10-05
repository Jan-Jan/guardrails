#!/bin/sh
# describes: find-items.sh: a newline in an argument is not rejected
_gr_before=$(cksum scripts/find-items.sh)
sed -i.bak 's|gr_die "an argument contains a newline"|:|' scripts/find-items.sh
rm -f scripts/find-items.sh.bak

[ "$_gr_before" != "$(cksum scripts/find-items.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
