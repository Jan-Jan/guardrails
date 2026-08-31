# Problem reports — the owner: field on problem items

`affects:` names files rather than item IDs for the reason
`docs/problems/2026-08-27-macos-awk.md` gives: guardrails keeps no
REQ/SDD/LLR ledger of its own yet. When the ledgers arrive, these lines get
the IDs.

**PR-dudg35**: The problem-item grammar requires an `owner:` field whose
information is redundant (git blame already answers who wrote an item) and
whose premise is wrong — problems are not personally owned, anyone may
resolve them — so the field adds a failure mode (`INCOMPLETE-PROBLEM` for a
missing name nobody needs) without adding triage value.
affects: scripts/check-trace.sh (INCOMPLETE-PROBLEM, UNRESOLVED-PR,
check_orphans), scripts/lib.sh (keyword registry), templates/problems.md,
docs/problems/README.md, skills/resolve-problem/SKILL.md,
skills/check-traceability/SKILL.md, tests/check-trace.bats.
opened: 2026-08-30
status: resolved
The field was designed in 2026-08-24-problem-triage as triage metadata, but
authorship is already answered by `git blame` on the ledger line and problems
are not personally owned — anyone may resolve them. The grammar now requires
`opened:` and `status:` only; a leftover `owner:` line is inert prose.
Reproduced by `tests/check-trace.bats: an open item needs no owner:`, red
before the fix.
