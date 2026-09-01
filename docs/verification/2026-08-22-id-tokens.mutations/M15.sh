#!/bin/sh
# describes: new-id.sh: the config is not validated before an ID is handed out
# A mutation that stops matching is a silent no-op, and a no-op row reads as
# "no test detects this". Fail loudly instead — mutate.sh reports exit 3 as an
# unusable mutation. Independent review, N6.
_gr_before=$(cksum scripts/new-id.sh)
sed -i.bak 's/^gr_check_config$/:/' scripts/new-id.sh
rm -f scripts/new-id.sh.bak

[ "$_gr_before" != "$(cksum scripts/new-id.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
