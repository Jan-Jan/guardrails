# Problem report — `ratchet` names upgrade as a mode no decision created

Found by review round 2 of `agent-first-skill-shape`, which rewrote
`skills/ratchet/SKILL.md` into the tested skill shape; the round booked it as
an open item rather than a fix in that change. `affects:` names files, because
guardrails keeps no REQ/SDD/LLR ledger of its own.

**PR-s8dcmp**: `ratchet` mode detection names upgrade as a third mode with its own procedure, which no decision created, so an upgrade skips the inventory and gap analysis that retrofit step 3 performs.
affects: skills/ratchet/SKILL.md, step 1 (mode detection), the section "Upgrading the scripts in an existing project", and Done when.
opened: 2026-10-04
status: open
On `main`, a project that already has `.guardrails/` is re-ratcheted through
retrofit step 3, which inventories the project and writes a gap analysis to
`docs/plans/`. The rewritten skill detects an existing `.guardrails/scripts/`
as a separate upgrade mode and runs its own procedure, which copies the
scripts and the files that document their grammar and contains no inventory
and no gap analysis. Done when still requires a gap analysis for a retrofit,
so the upgrade path has no stated completion check for the step it omits.
Either a decision records upgrade as its own mode, with a Done when entry for
it, or the skill routes an existing installation through retrofit step 3
again.
