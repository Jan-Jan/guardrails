# Why ratchet's rules are what they are

Read this when a rule in `ratchet` seems wrong for your case, or before
proposing to change one.

## The units interview asks for facts only

The interview writes `units:`, `not_a_unit:`, `safety_class:`, `depends_on:`
and `segregated_from:`. It does not ask whether the class floor applies,
whether a unit may see another's internals, or which units run at merge: those
are D4, D5 and D6 of `docs/plans/2026-08-26-monorepo-support.md`. Every
configurable version of them is a gate that does not run while nothing in the
output reports it.

## Adoption is ordered

A manifest naming one unit, with everything else disclaimed, is a valid and
passing first tooth on a repository of twelve packages. Edges (`depends_on:`,
exports, expectations) are declared later, when the coupling exists. Until an
edge exists those gates have nothing to read, so "not yet adopted" is visible
in the manifest instead of being a gate switched off. Without the ordering,
adoption on a large repository reads as all-or-nothing.

## The verification template is not in `docs/verification/`

Every `*.md` directly in that directory is read as a record. The template
contains the field names at column one, because that is the shape it teaches,
so filed among the records it is one: a document declaring a `branch:`, a
`reviewer:` and a `**finding-1**:` that nobody wrote about any change.

The `doc_verification` default is safe only because an absent directory is
exit 2. A project that keeps records elsewhere sets the key.

## Both worktree entries are gitignored

`.claude/worktrees/` covers change worktrees a harness creates. `.worktrees/`
covers the manual fallback and every task worktree nested inside a change
worktree (`worktree-discipline` step 1). A missing `.worktrees/` entry does not
stop a subagent creating its task worktree; the untracked directory then fails
`verify-before-merge`'s clean `git status` check.

## Every configured path exists in the commit

`check-trace.sh` exits 2 on a configured path that does not exist, so a
mistyped path cannot disable a gate in silence. Git does not track empty
directories: a directory that exists only on one disk is missing for every
clone, and CI exits 2.

Leaving a key out until its directory has content is not an alternative. For a
key a declared prefix requires, that is exit 2; for the rest, a missing key
reads as "this project does not use that". The one remaining way to switch a
gate off is to drop its prefix from `id_prefixes`, which removes every gate for
that prefix.

## Signing is a gate on the ratchet

Every merge ends with `finish-merge.sh`, which runs `check-signing.sh --strict`
before it removes the worktree and deletes the branch. Strictness begins at the
first merge, not in CI. A project that defers signing completes each merge and
is then denied the cleanup, and accumulates worktrees with no visible cause.

`check-signing.sh --setup` makes a real signed commit in a throwaway
repository and confirms it reads `%G?` = `G`, because configuration being
present proves nothing about whether the key can sign or the signature
verifies.

`gpg.format` is not on its list. Unset is not unconfigured: git documents the
default as `openpgp`. Requiring it reported a non-problem, and because a
reported gap returns before the proof, it suppressed the half of `--setup`
that measures anything.

## Tool qualification records a commit

A version string does not identify code: upstream can advance mid-change and
still read the same number, and the reviewer then has to establish by hand
which code the suite result was measured on. `guardrails_commit` makes the
basis checkable.

The suite runs in the guardrails repository because the target project records
the outcome (version, commit, pass or fail), not the tooling. A recorded gap
(`suite not run at install time: <reason>`) is preferred to installing a
dependency nobody asked for.

A pipe sets `$?` to the status of its last command, so
`tests/run-tests.sh | tee ratchet.log` records `tee`'s status.

## `check-review.sh` is not a CI gate on the base branch

It asks about the change under merge. On the base branch there is none, so it
exits 2 rather than reporting a pass over no question.
