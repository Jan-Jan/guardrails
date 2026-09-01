#!/bin/sh
# describes: lib.sh: GR_ID_BODY drops the legacy sequential form
# A mutation that stops matching is a silent no-op, and a no-op row reads as
# "no test detects this". Fail loudly instead — mutate.sh reports exit 3 as an
# unusable mutation. Independent review, N6.
_gr_before=$(cksum scripts/lib.sh)
sed -i.bak 's|^GR_ID_BODY=.*|GR_ID_BODY="(${GR_ID_TOKEN})"|' scripts/lib.sh
rm -f scripts/lib.sh.bak

[ "$_gr_before" != "$(cksum scripts/lib.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
