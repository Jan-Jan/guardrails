#!/bin/sh
# describes: find-items.sh: list does not check that --status has a value
_gr_before=$(cksum scripts/find-items.sh)
sed -i.bak '/^                (--status)$/,/^                (\*) gr_die/s@^                    \[ $# -ge 2 \] || gr_die "$find_items_usage"$@                    :@' scripts/find-items.sh
rm -f scripts/find-items.sh.bak

[ "$_gr_before" != "$(cksum scripts/find-items.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
