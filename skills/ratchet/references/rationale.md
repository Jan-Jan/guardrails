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

## Upgrade is its own mode

A project that already has `.guardrails/scripts/` is not re-inventoried.
Retrofit step 3 asks what in a codebase is not yet under guardrails; the first
ratchet answered that, and its gap analysis lists the later teeth. An upgrade
asks what the new scripts reject that the old ones passed, and `check-trace.sh`
answers that after the copy. A second inventory would not find those findings.
The plan that lists the new warnings the upgrade leaves does for an upgrade what
the gap analysis does for a retrofit. A failure is fixed, never listed: the
upgrade merges through `merge-change`, whose gate needs `check-trace.sh` to
pass. The decision is `ADR-3h4dky` in the guardrails repository
(`docs/adr/ADR-3h4dky-upgrade-is-its-own-mode.md`).

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

The suite runs in the clone because the target project records
the outcome (version, commit, pass or fail), not the tooling. A recorded gap
(`suite not run at install time: <reason>`) is preferred to installing a
dependency nobody asked for.

A pipe sets `$?` to the status of its last command, so
`tests/run-tests.sh | tee ratchet.log` records `tee`'s status.

## The guardrails checkout is cloned before anything is read from it

The suite takes about twenty minutes and its tests read the files of the tree
they live in. When a commit was made in the checkout during an adopter's run,
the log mixed the two commits' tests, and the commit recorded as qualified was
the one the run started on (PR-y8ff5p). The scaffold, retrofit and upgrade
copies read the same tree and can mix commits the same way. A clone holds one commit and
nothing edits it, so every copy and the suite read the same code, and
`git -C <guardrails> rev-parse HEAD` names it. Uncommitted edits in the
checkout are not in the clone, by design: what is not committed has no commit
to record.

The clone goes in a temporary directory outside the target project, such as one
made by `mktemp -d`, and is removed when the ratchet is done. Step 5 runs the
suite in the clone, never in the target project; a clone
inside the project's tree would run it there, and one left behind is an
untracked copy of guardrails in the project.

The suite's log goes beside the clone, at `<tmp>/ratchet.log`, never inside
it. The runner fingerprints every file git does not ignore, before and after
the run. A `ratchet.log` redirected inside the clone is created by the shell
before the runner starts, untracked and not ignored, so the first fingerprint
reports `the working tree differs from commit <sha>`, the log grows while bats
runs, the second reports `the working tree changed during the run`, and the
run exits 1 however often it is repeated. The log is the evidence for the result the
setup document records, so it is kept when the clone is removed.

Step 5 records one qualifying run per update: a run whose log names the
recorded commit. A run that names no commit qualifies nothing, so it is run
again, and only the qualifying run's result is recorded.

`tests/run-tests.sh` says on standard error what it tested, before bats
runs, with one of these lines:

* `run-tests: testing commit <sha>`: the working tree is that commit's;
* `run-tests: the working tree differs from commit <sha>; this run tests no commit`;
* `run-tests: no git repository found; the commit tested is unknown`: the
  directory holding `tests/` is not the top of a git repository of its own,
  or git is absent;
* `run-tests: HEAD names no commit; the commit tested is unknown`: a
  repository with no commit yet;
* `run-tests: the commit tested is unknown`: git failed while indexing the
  working tree or reading the commit's tree object, or mktemp could not
  make the temporary directory, and a line of its own precedes this one: the
  git failure line below, or mktemp's message.

After bats runs, it fingerprints the working tree again, and says one more
line when the fingerprint differs or cannot be taken:

* `run-tests: the working tree changed during the run; this result describes no commit`,
  and the run fails even if every test passed.

A git command that fails prints `run-tests: git <args> failed: <message>`.
One entry covers every such command: `<args>` is `read-tree HEAD`, `add -A`
or `write-tree` from `tests/fingerprint-tree.sh` indexing the working tree,
before or after the run, or `rev-parse <sha>^{tree}` from `tests/run-tests.sh`
reading the commit's tree object, before the run only. Before the run the commit-unknown
line follows it, and after the run the working-tree-changed line does.

Only `run-tests: testing commit <sha>` qualifies a commit. The runner downloads bats-core when there
is neither a system bats nor a `tests/.bats-core/`. A fresh clone has no
`tests/.bats-core/`, which is gitignored; copy the checkout's into the clone
to skip the download.

An export (`git archive | tar -x`) also holds one commit, but it has no
`.git`, and `tests/mutate.sh` runs `git ls-files` on the repository it lives
in, so `tests/mutations.bats` cannot pass in one.

A symlinked skill resolves to `skills/ratchet/` inside the checkout, so the
repository two levels above it is the checkout. A copy made by
`install.sh --copy` lives in the skills directory, and two levels above it is
that directory's parent, such as `~/.claude` (PR-783b29). So the copy records
the checkout's path in `.guardrails-source`, and step 0 reads it first.

## The exit status goes in `rc`

zsh reserves `status` as a read-only mirror of `$?`: `status=$?` fails with
`read-only variable: status`, which aborts a non-interactive zsh and, in an
interactive one, leaves the failed assignment's 1 where the suite's status
should be (PR-ww36qr). `rc` is special in no common shell. A pipe into `tee`
is no way around it: a pipe's `$?` is the status of its last command, tee's.

## `check-review.sh` is not a CI gate on the base branch

It asks about the change under merge. On the base branch there is none, so it
exits 2 rather than reporting a pass over no question.
