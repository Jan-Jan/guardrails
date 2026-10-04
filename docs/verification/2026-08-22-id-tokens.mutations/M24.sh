#!/bin/sh
# describes: check-ids.sh: the DRAFT-ID failure no longer names new-id.sh
# A mutation that stops matching is a silent no-op, and a no-op row reads as
# "no test detects this". Fail loudly instead — mutate.sh reports exit 3 as an
# unusable mutation. Independent review, N6.
# Anchor re-cut 2026-09-29 (D8 of docs/plans/2026-09-28-agent-first-skills.md):
# the DRAFT-ID guidance moved from a stderr paragraph to the `fix DRAFT-ID:`
# remedy line, so the original anchor matched nothing. Re-cut per bb7eee5; the
# mutation is unchanged: the guidance stops naming new-id.sh.
_gr_before=$(cksum scripts/check-ids.sh)
sed -i.bak 's|Run .guardrails/scripts/new-id.sh <PREFIX> and replace each draft token|Replace each draft token|' scripts/check-ids.sh
rm -f scripts/check-ids.sh.bak

[ "$_gr_before" != "$(cksum scripts/check-ids.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
