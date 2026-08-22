#!/bin/sh
# describes: check-ids.sh: the DRAFT-ID failure no longer names new-id.sh
# A mutation that stops matching is a silent no-op, and a no-op row reads as
# "no test detects this". Fail loudly instead — mutate.sh reports exit 3 as an
# unusable mutation. Independent review, N6.
_gr_before=$(cksum scripts/check-ids.sh)
sed -i 's|when it is written. Run .guardrails/scripts/new-id.sh <PREFIX> and replace|when it is written. Replace|' scripts/check-ids.sh

[ "$_gr_before" != "$(cksum scripts/check-ids.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
