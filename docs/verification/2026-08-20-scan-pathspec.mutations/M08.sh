#!/bin/sh
# describes: lib.sh: GR_SCAN_EXCLUDE narrowed so the tooling is no longer excluded
# A mutation that stops matching is a silent no-op, and a no-op row reads as
# "no test detects this". Fail loudly instead — mutate.sh reports exit 3 as an
# unusable mutation. Independent review, N6; the guard is also what carries a
# failure of sed itself, now that `rm -f` runs after it and would otherwise
# report success. Independent review of the BSD-sed change, finding 1.
_gr_before=$(cksum scripts/lib.sh)
sed -i.bak "s|GR_SCAN_EXCLUDE=':(exclude).guardrails/scripts'|GR_SCAN_EXCLUDE=':(exclude).guardrails/scripts/nothing'|" scripts/lib.sh
rm -f scripts/lib.sh.bak

[ "$_gr_before" != "$(cksum scripts/lib.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
