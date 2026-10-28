**ADR-3hsvvq**: The squash message is drafted in the change worktree's git directory, in a grammar of review fields, dispositioned findings and checked trailers.

Date: 2026-10-25
Status: accepted

## Context

ADR-k3nkv3 makes the squash message the record, checked before hand-over and
after signing. A script checks only a grammar it is given, and the draft must
survive every rerun of the merge sequence without entering the gated tree.

## Decision

- **Where:** `git rev-parse --git-path guardrails-squash.msg` in the change
  worktree. Each worktree has its own.
- **Guidance:** `#` lines are dropped by the checker and by the hand-over's
  `git commit --cleanup=strip`. The checker reads a CRLF message as LF.
- **Review fields:** `reviewer:`, `verdict:`, `reproduced:`, non-empty, at
  column one in the body. A field or trailer value still holding a template
  `<placeholder>` is missing.
- **Findings:** column-one `Findings:`, spelled exactly so, to the next
  blank line; each `<N>. [<disposition>] <tag>[ <severity>] — <finding>`,
  continued on indented lines that do not open with `<N>. `, each number
  once. Findings are the only body
  lines that open with `<N>. `: one outside the section, or a `Findings`
  header spelled otherwise, is malformed. Tag `code`, `requirement` or
  `guideline` with severity `high`, `medium` or `low`, or `record` with
  none. The disposition, up to the first `] `, is `fixed: <cite>, …`,
  `open: <cite>` or `no change: <reason>`. Under `--cite` each cite is a
  tracked or untracked, not ignored, file, a declared test or a defined ID;
  a `record` finding may cite `message`.
- **Trailers**, read by `git interpret-trailers --parse`: one non-empty
  `Base:`; one `Gate-tree:`; `Tests:` and `Coverage:`: exactly one per
  `verify_commands` / `coverage_command` entry, over the units of the
  change's impact set under a manifest (`check-units.sh --impact`); at
  least one `Tests:`, each ending `<passed>/<total>` with passed equal to
  total; each
  `Mutation:` as `<path>:<line> <mutant> — killed by "<test name>"`, its
  path and test resolved under `--cite`. A repository without a
  configuration owes one `Tests:` and no `Coverage:`. `Resolves:`, over
  any number of trailers, its IDs split on commas, semicolons and
  blanks, names
  exactly the PR items the change deletes. `Opens:` is not checked.
- **Deletions** (`gr_deleted_items`), over the base branch`...HEAD` before
  the hand-over and `HEAD^..HEAD` after signing: a deleted item is one
  whose definition line the diff removes from its ledgers and adds back
  nowhere in them, so a move between ledger files or a rewording under the
  same ID deletes nothing. A PR item's ledgers are the configured
  `doc_problems`; a REQ, LLR, SDD, HAZ or RC item's the configured
  `doc_srs`, `doc_sad` and `doc_rmf`; under a manifest each unit's. A
  ledger is the files check-trace reads: a directory's top-level `*.md`
  files, a file itself. A definition outside them is not read, and with
  none configured nothing is owed. Only these six prefixes are owed:
  `Items:` the five gated kinds, REQ, LLR, SDD, HAZ and RC, and
  `Problems:` and `Resolves:` PR. An item of another prefix a project
  declares is not owed, wherever it is defined. Each deleted PR is named in `Resolves:` and appears as a word
  under `Problems:`; each other deleted item appears as a word under
  `Items:`. A word is a run of letters, digits, `-` and `_`. The
  `Items:` and `Problems:` sections each run from their column-one header,
  the text after its colon included, to the first blank line after their
  content, so blank lines between the header and its list do not end
  them, or to the next column-one section header (`Items:`, `Problems:`, `Red-green:`, `Gaps:`,
  `Qualification:`, `Findings:` or a review field). Their prose is
  otherwise not checked.
- **The checker:** `check-review.sh [--message FILE] [--cite]` and
  `finish-merge.sh` guard 5 run one checker,
  `gr_message_check FILE TREE TESTS COVERAGE DELETED`, which prints one finding per
  line and returns 0, 1 with findings, or 2 when it cannot parse; every
  argument is required, `DELETED` empty where nothing is deleted. Codes:
  `MISSING-RECORD`, `INCOMPLETE-RECORD`, `UNDISPOSED-FINDING`,
  `MALFORMED-FINDING`, `BASE`, `GATE-TREE`, `TESTS`, `FAILED-TESTS`,
  `COVERAGE`, `MALFORMED-MUTATION`, `RESOLVES`, `PROBLEMS`, `ITEMS`;
  under `--cite` also
  `UNRESOLVABLE-DISPOSITION`, `UNRESOLVABLE-MUTATION`.
- `check-review.sh` runs only on a change branch: it exits 2 outside a
  repository, on a detached HEAD or primary checkout, on the base branch, on
  an unknown argument, and on a missing or invalid configuration.

## Consequences

- The draft never enters the gate's tree or `git status`, and goes with the
  worktree after the commit has taken it.
- A fix dispatched after step 5 returns its red -> green lines in its
  report; the dispatcher writes them into the change worktree's message.
- A change that resolves a problem report deletes it (ADR-k3nkv3), and
  its message cannot omit it from `Resolves:` or `Problems:`, or name in
  `Resolves:` one it keeps. A change that deletes any other item cannot
  omit it from `Items:`, the only record left of it.
- No mutant is required: no guidelines file here names a mutation command.
