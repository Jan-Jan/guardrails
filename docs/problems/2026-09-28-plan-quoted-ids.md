# Problem reports — a plan that quotes its own items defines them twice

One item, found while running `merge-change` step 4 on an unrelated ledger
amendment, and resolved in the same change once the user ruled on the question
it raised. It was not that change's doing and it is not a defect in any script:
it is a merged document using a form its own templates warn against, and the
gate reporting it correctly.

**PR-4hyuud**: `docs/plans/2026-09-17-mutation-evidence-implementation.md`
quotes two problem items in full, at column one, so `check-ids.sh` reads each as
a second definition and reports `DUPLICATE-ID` for two IDs that are each
defined exactly once in the ledger.
affects: docs/plans/2026-09-17-mutation-evidence-implementation.md, which
reproduces both items verbatim at column one inside a fenced block;
docs/problems/2026-09-17-mutation-evidence.md, the file that legitimately
defines them, which is reported alongside the plan and is not at fault;
docs/problems/README.md and templates/problems.md, whose grammar notes already
state the convention this breaks — illustrative forms go indented or inline in
backticks, because a definition form at column one is judged at any position,
in a fenced block too.
opened: 2026-09-28
status: resolved

Measured 2026-09-28 at `main` = `97add71`, with a synthesized config declaring
`PR` alone: `check-ids.sh` exits 1 with three `DUPLICATE-ID` lines, two of them
for real ledger IDs and the third a test fixture. Both real ones resolve to the
same shape — one definition in the problems ledger, one in the plan. Neither
file is touched by the change that found this, confirmed by an empty
`git diff main HEAD` over both paths, so the condition is on `main` and
predates it.

**No script is wrong here.** That a scan reads column one whatever the
surrounding markup declares is settled doctrine, written at the front of
`check-trace.sh`, in both ledger README files and in the assessment of the
first class B field report, which asked for fence-awareness and was declined for
this reason. The plan is the document that has to change, and the fix is the one
its own templates give: indent the quoted items, or cut them to the ID and a
sentence.

**Why it matters beyond tidiness.** `merge-change` step 4 requires zero
duplicates, so any change merged from a worktree that contains this plan meets
a red gate it did not cause and cannot fix without editing a merged plan. The
first author to hit it will reasonably assume their own change minted a
colliding ID — which is the one thing random IDs are supposed to make
impossible — and will look in the wrong place.

**The question this raised was ruled on**, on 2026-09-28, by the user: plans
are maintained documents, not sealed historical records, so a merged plan that
trips a gate is edited. That ruling is what made the fix in-scope for the
change that found the defect; it was deliberately not taken as a side effect.

Root cause: the plan reproduced two item definitions at column one to show what
would be written, and a definition form at column one is read as a definition
at any position, a fenced block included. That rule is settled doctrine and no
script is at fault — the templates and both ledger READMEs already give the
remedy. Fixed by indenting both quoted blocks by two spaces, content otherwise
byte-identical, so the plan still records exactly what it recorded before and
now defines nothing. The paragraph introducing them states why they are
indented, so the next author copying that plan's shape copies the safe one.
Verified by re-running `check-ids.sh`: three `DUPLICATE-ID` lines before, one
after.

**That remaining one is `PR-001`, it is not a defect, and it cannot be fixed.**
It is defined twice inside `tests/check-trace.bats`, in two heredoc fixtures
that write a ledger file for the parser to read. Both are at column one because
that is the property under test — a fixture indented to satisfy the duplicate
scan would stop testing that a column-one definition is recognised at all.

So a repository whose tests exercise a definition scanner cannot have a clean
in-tree duplicate scan: its test data must contain the form the scan looks for.
That is a structural reason guardrails is not ratcheted against itself, beyond
the absence of a config, and it means `merge-change` step 4 can never read
clean here however carefully the ledgers are written. An adopter is unaffected,
because an adopter's tests do not contain guardrails item definitions. Recorded
here rather than given its own item, because it is a property rather than a
problem and there is nothing to resolve.
