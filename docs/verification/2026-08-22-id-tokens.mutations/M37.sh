#!/bin/sh
# describes: finalize-docs.sh: the config is not validated before the renames
# A mutation that stops matching is a silent no-op, and a no-op row reads as
# "no test detects this". Fail loudly instead — mutate.sh reports exit 3 as an
# unusable mutation. Independent review, N6.
_gr_before=$(cksum scripts/finalize-docs.sh)
sed -i.bak 's/^gr_check_config$/:/' scripts/finalize-docs.sh
rm -f scripts/finalize-docs.sh.bak

[ "$_gr_before" != "$(cksum scripts/finalize-docs.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
