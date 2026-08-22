#!/bin/sh
# describes: new-id.sh: a third argument is ignored rather than refused
# A mutation that stops matching is a silent no-op, and a no-op row reads as
# "no test detects this". Fail loudly instead — mutate.sh reports exit 3 as an
# unusable mutation. Independent review, N6.
_gr_before=$(cksum scripts/new-id.sh)
sed -i '/^\[ \$# -le 2 \] || gr_die "unknown argument: \$3"$/d' scripts/new-id.sh

[ "$_gr_before" != "$(cksum scripts/new-id.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
