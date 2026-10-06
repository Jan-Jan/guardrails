**ADR-3h4dky**: A project that already has `.guardrails/scripts/` and wants newer ones is upgraded through `ratchet`'s own upgrade procedure, not through retrofit step 3; its completion check is that each failure the new scripts report is fixed and each new warning is listed in a plan.

Date: 2026-10-06
Status: accepted

## Context

`agent-first-skill-shape` rewrote `skills/ratchet/SKILL.md` into the tested
skill shape. The rewrite made upgrade a third mode in step 1, beside
greenfield and retrofit. The text under "Upgrading the scripts in an existing
project" was older, a blockquote inside step 2; the rewrite made it that
mode's procedure. No decision created the mode. Before the rewrite, a project
with `.guardrails/` was re-ratcheted through retrofit step 3, whose inventory
listed "the `.guardrails/` version if re-ratcheting" and whose step 3.2 wrote
a gap analysis to `docs/plans/`. The upgrade procedure has no inventory and no
gap analysis, and the Done when section that the rewrite added stated no
completion check for it. Review round 2 of that change recorded this as
`PR-s8dcmp`.

The maintainer ruled on 2026-10-04 that upgrade stays its own mode, and that
the decision is recorded with a Done when entry for it: every new violation
fixed or listed in a plan. Review round 1 of the change that records this
decision found that a failure listed in a plan cannot merge, because
`merge-change`'s gate needs `check-trace.sh` to pass. The listing therefore
applies to new warnings: findings that do not fail the run and that the old
scripts did not print. A warning the old scripts printed already, such as
`UNRESOLVED-PR` for an open problem item, is recorded in its ledger.

## Decision

Mode detection has three outcomes. A project that has `.guardrails/scripts/`
and wants newer ones is an upgrade, and runs the upgrade procedure as a change
of its own. It does not run retrofit step 3, and it writes no gap analysis.

The upgrade is done when:

- the scripts, the four ledger READMEs, the verification template and the
  AGENTS.md managed block all come from one guardrails version; and
- each failure the new scripts report is fixed in the upgrade change, and
  each new warning is listed in a plan in `docs/plans/`.

The retrofit inventory no longer lists the installed `.guardrails/` version:
a project that has one is an upgrade, so a retrofit never sees one.

## Why

The retrofit inventory and gap analysis answer one question: what in this
codebase is not yet under guardrails, and in what order should it be brought
under? A project that already has `.guardrails/scripts/` answered it at its
first ratchet. Its later teeth are listed in the gap analysis that ratchet
wrote, and each tooth is a change of its own.

An upgrade asks a different question: what do the new scripts reject that the
old ones passed? `check-trace.sh` answers it after the copy, one finding per
line. `references/upgrade-notes.md` says, for each change in what the scripts
accept, why the old shape was never safe. A second inventory of the codebase
would not find these findings. A plan listing the new warnings that the upgrade
change leaves does what the gap analysis does for a retrofit: it records what is
still open, and where. A failure is not listed: the upgrade change does not pass
its merge gate while one remains, and a gate is never loosened to let it
through.

## Alternatives

- **Route an existing installation through retrofit step 3 again.** Rejected.
  The inventory re-reads AGENTS.md, the docs, the tests and the CI that the
  first ratchet already put under the gates. Its gap analysis would list the
  same teeth again, and it still would not list the script findings.
- **Keep upgrade as a mode with no Done when entry.** Rejected: it is the
  defect `PR-s8dcmp` reports. Without a completion check, "the scripts are
  copied" can count as done, and the ratchet's Red flags already say that it
  is not.

## Cost

An upgrade does not re-check the parts of a project that the scripts do not
read: AGENTS.md rules outside the managed block, CI, the signing of recent
commits. If one of those has drifted since the first ratchet, the upgrade
does not report it. That is accepted. Signing is checked by
`finish-merge.sh` at every merge, and the managed block is replaced in the
upgrade itself. A project that wants a full re-audit asks for one as a
separate change. It is not part of an upgrade.
