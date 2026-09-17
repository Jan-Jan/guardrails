# Problem reports — a gate that cannot tell an assessment from a mention, and a rename that leaves its references behind

Both items arrived on 2026-09-08 in a report from a downstream guardrails
project, where they had been found, measured and fixed locally against the
vendored copy of `.guardrails/scripts/`. A vendored copy is replaced wholesale
at the next ratchet upgrade, so the report was written to bring the fixes
upstream. Both were recorded here before either was touched. Neither is a new
discovery for this repository: the first is stated as a caveat in the script's
own comments, the README and the check-traceability skill, and was measured as
review finding 17 of docs/verification/2026-08-19-item-placement.md; the second
is conceded in the header of finalize-docs.sh ("draft ledger FILES are a
different problem and remain"). A stated weakness is not a harmless one, which
is what the report's measurements show.

**PR-n274s7**: A derived REQ or LLR whose ID appears anywhere in the RMF files
passes `UNANALYZED-DERIVED`, so an item named only in a verification table, a
scope note or a passing parenthetical reads as assessed with the run at exit 0.
affects: scripts/check-trace.sh, the `UNANALYZED-DERIVED` gate (one free-text
`git grep` per derived ID over `$rmf_files`); templates/rmf.md, templates/srs.md,
templates/sad.md and templates/AGENTS-block.md, which state "assessed" for a gate
that enforces "mentioned"; skills/analyze-risks and skills/check-traceability,
which tell the author to name the ID and nothing more.
opened: 2026-09-08
status: resolved
Root cause: one free-text git grep per derived ID over the RMF files, satisfied
by any occurrence. Fixed by reading an `assesses:` annotation through the
one-definition rule, like mitigates:, as a hard cut announced in the ratchet
notes. Reproduced by `check-trace: a derived REQ named only in passing in the
RMF is unassessed` and `check-trace: a derived LLR named only in a
verification-table row is unassessed` (tests/check-trace.bats), watched failing
against the old gate.

**PR-58zsvf**: `finalize-docs.sh` renames a change's `DRAFT-<branch>-<slug>.md`
ledger files to their merge-dated names and leaves every reference to the old
name in the other ledgers pointing at a file that no longer exists, and no gate
reads a file reference, so the dangling links accumulate by construction.
affects: scripts/finalize-docs.sh, which knows both names of every file it
renames and rewrites nothing; scripts/check-trace.sh, whose `DANGLING-REF`
resolves item IDs only; skills/merge-change step 3, which commits the renames
as a complete finalize.
opened: 2026-09-08
status: resolved
Root cause: the rename loop was the whole script; the mapping it built was
discarded. Fixed twice over: finalize-docs.sh rewrites path and unambiguous
bare references across the ledger directories and the SOUP file, printing each,
and check-trace.sh's DANGLING-FILE resolves any draft reference left in that
scope. Reproduced by `finalize: a path reference to a renamed draft is
rewritten in another ledger` (tests/finalize-docs.bats) and `check-trace: a
ledger reference to a draft file that does not exist is DANGLING-FILE`
(tests/check-trace.bats), both watched failing first.
