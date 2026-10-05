#!/bin/sh
# describes: find-items.sh: refs does not check the shape of its argument
_gr_before=$(cksum scripts/find-items.sh)
sed -i.bak 's#^        check_item_id "$item_id"$#        [ "$subcommand" = refs ] || check_item_id "$item_id"#' scripts/find-items.sh
rm -f scripts/find-items.sh.bak

[ "$_gr_before" != "$(cksum scripts/find-items.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
