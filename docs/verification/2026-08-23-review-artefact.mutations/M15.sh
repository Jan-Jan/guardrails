#!/bin/sh
# describes: check-review: a disposition outside any finding block counts
# retired: this anchor is in no committed version of check-review.sh — f396c16,
# the commit it was written against, already reads
# `gr_kw_here(line, "disposition:") {` without a pattern-level open_line guard,
# so the mutation never applied and was counted without ever running.
#
# This is NOT an uncovered behaviour. The guard's substance is the in-body
# `if (open_line) disposed = 1` at check-review.sh:228, and it cannot change any
# verdict: `disposed` is written in exactly two places — cleared at line 215 where
# a block opens, set at line 228 — and read only at line 171 inside gr_flush,
# which is reachable only when open_line is non-zero. So a `disposition:` outside
# every block sets a flag that is provably cleared before it can be read. That is
# an equivalent mutant, and an equivalent mutant does not belong in a kill count.
#
# check-review.sh:163-168 and docs/verification/2026-08-24-review-artefact.md
# reach the same conclusion and cite a differential fuzz over 8000 generated
# records. That evidence is about the BEHAVIOUR, not about this script: this
# script's anchor matches no committed version of check-review.sh, so running it
# produces no mutant to fuzz. The invariant above is the reason to believe the
# conclusion; the fuzz figure is not this file's to claim. See PR-b7ua4s.
python3 - <<'PY'
s = open('scripts/check-review.sh').read()
s = s.replace('open_line && gr_kw_here(line, "disposition:") {',
              'gr_kw_here(line, "disposition:") {')
open('scripts/check-review.sh','w').write(s)
PY
