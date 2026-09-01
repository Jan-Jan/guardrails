#!/bin/sh
# describes: lib.sh: the alphabet keeps the ambiguous characters 0 o 1 l i
# A mutation that stops matching is a silent no-op, and a no-op row reads as
# "no test detects this". Fail loudly instead — mutate.sh reports exit 3 as an
# unusable mutation. Independent review, N6.
_gr_before=$(cksum scripts/lib.sh)
sed -i.bak "s/^GR_ID_LETTER=.*/GR_ID_LETTER='[abcdefghijklmnopqrstuvwxyz]'/" scripts/lib.sh
sed -i.bak "s/^GR_ID_DIGIT=.*/GR_ID_DIGIT='[0123456789]'/" scripts/lib.sh
sed -i.bak "s/^GR_ID_ANY=.*/GR_ID_ANY='[abcdefghijklmnopqrstuvwxyz0123456789]'/" scripts/lib.sh
rm -f scripts/lib.sh.bak

[ "$_gr_before" != "$(cksum scripts/lib.sh)" ] || { echo "mutation changed nothing" >&2; exit 3; }
