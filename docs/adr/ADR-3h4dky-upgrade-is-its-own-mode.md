**ADR-3h4dky**: A project that already has `.guardrails/scripts/` and wants newer ones is upgraded through `ratchet`'s own upgrade procedure, not through retrofit step 3; its completion check is that each failure the new scripts report is fixed and each new warning is listed in its squash message.

Date: 2026-10-06
Status: accepted

## Context

`ratchet` step 1 detects three modes: greenfield, retrofit and upgrade.
Retrofit step 3 inventories the codebase and writes a gap analysis to
`docs/plans/`; the upgrade procedure has neither. Without a Done when entry
of its own, an upgrade has no completion check.

The retrofit inventory and gap analysis answer one question: what in this
codebase is not yet under guardrails, and in what order should it be brought
under? A project that already has `.guardrails/scripts/` answered it at its
first ratchet. Its later teeth are listed in the squash message of the
change that ratchet made, and each tooth is a change of its own.

An upgrade asks a different question: what do the new scripts reject that the
old ones passed? `check-trace.sh` answers it after the copy, one finding per
line. `references/upgrade-notes.md` says, for each change in what the scripts
accept, why the old shape was never safe. A second inventory of the codebase
would not find these findings.

A failure the new scripts report cannot be listed and left open, because
`merge-change`'s gate needs `check-trace.sh` to pass, and a gate is never
loosened to let it through. A listing can apply only to new warnings:
findings that do not fail the run and that the old scripts did not print. A
warning the old scripts printed already, such as `UNRESOLVED-PR` for an open
problem item, is recorded in its ledger. The squash message listing the new
warnings that the upgrade change leaves does for an upgrade what it does for
a retrofit's later teeth: it records what is still open, and where.

Rejected alternatives:

- **Route an existing installation through retrofit step 3 again.** The
  inventory re-reads AGENTS.md, the docs, the tests and the CI that the
  first ratchet already put under the gates. Its gap analysis would list the
  same teeth again, and it still would not list the script findings.
- **Keep upgrade as a mode with no Done when entry.** Without a completion
  check, "the scripts are copied" can count as done, and the ratchet's Red
  flags already say that it is not.

## Decision

Mode detection has three outcomes. A project that has `.guardrails/scripts/`
and wants newer ones is an upgrade, and runs the upgrade procedure as a change
of its own. It does not run retrofit step 3, and it writes no gap analysis.

The upgrade is done when:

- the scripts, the four ledger READMEs, the squash message template and the
  AGENTS.md managed block all come from one guardrails version; and
- each failure the new scripts report is fixed in the upgrade change, and
  each new warning is listed in the upgrade change's squash message.

The retrofit inventory no longer lists the installed `.guardrails/` version:
a project that has one is an upgrade, so a retrofit never sees one.

## Consequences

- An upgrade does not re-check the parts of a project that the scripts do not
  read: AGENTS.md rules outside the managed block, CI, the signing of recent
  commits. If one of those has drifted since the first ratchet, the upgrade
  does not report it. Signing is checked by `finish-merge.sh` at every merge,
  and the managed block is replaced in the upgrade itself.
- A project that wants a full re-audit asks for one as a separate change. It
  is not part of an upgrade.
