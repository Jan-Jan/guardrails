**ADR-cy7ahd**: A change names each ledger file it creates `docs/<area>/<YYYY-MM-DD>-<slug>.md`, dated the day it creates it, and nothing renames it; `finalize-docs.sh` and the finalize step of `merge-change` are removed.

Date: 2026-10-13
Status: accepted

## Context

Until this decision a change wrote each new ledger file as
`docs/<area>/DRAFT-<branch>-<slug>.md`, and `merge-change` step 3 ran
`finalize-docs.sh`, which renamed it to `<finalize-date>-<slug>.md` and
rewrote references to it across the ledger directories and the SOUP file.

- The rename finalizes no ID: `new-id.sh` mints each ID when the item is
  written.
- The script's own header says the filename "is a handle for finding the
  file, not a record of when it merged".
- The rename is a late commit, made after the step 2 gate, that rewrites
  shared ledger files.
- Its `-2` collision check sees only the local disk, so two changes that
  pick the same slug on different machines or in different worktrees are
  not told.
- It renames every draft-named file in the ledger directories, whoever wrote
  it. `PR-umtm9b` records the result: a draft ledger file left behind by
  another change is silently adopted into the merging change, its diff and
  its record.

Plans already follow the convention this decision adopts:
`docs/plans/YYYY-MM-DD-<topic>.md`, named once and never renamed.

## Decision

D1–D5 of `docs/plans/2026-10-13-ledger-names-at-creation.md`:

- A change creates each ledger file as `docs/<area>/<YYYY-MM-DD>-<slug>.md`,
  dated the day it creates the file, and nothing renames it. Every skill,
  template and README that says where new items go says so.
- `finalize-docs.sh` is deleted, with its tests. It is not kept as a
  migration tool.
- `check-ids.sh` keeps `DRAFT-FILE`, as a legacy-name error under every flag.
  Its remedy is the rename by hand: `git mv` the file to its dated name, then
  fix each reference `check-trace.sh` reports. `--allow-draft-files` is
  rejected as an unknown argument, exit 2: a flag accepted in silence is a
  check the caller believes they ran.
- `check-trace.sh` keeps `DANGLING-FILE`, with its scan and scope, for the
  references such a move leaves behind in this tree or another worktree. Only
  its words change: write the name the file has now.
- `merge-change` step 3 is now the tree check that was step 6, run when the
  step 2 summary arrives. Steps 4, 5, 6a–6d, 7 and 8 keep their numbers.

Ruled by the maintainer on 2026-10-13.

## Consequences

- Two changes that create a file under the same name meet as a git add/add
  conflict at `merge-change` step 1, on whatever machine either was written.
  The merging change moves its own version to a new slug, keeps the base's,
  and writes the new name wherever it cites it. This replaces the `-2`
  suffix.
- The date in a filename is the day the file was created, so `ls` reads a
  ledger directory in creation order. The day a change merged is in git.
- No reference is rewritten at merge, because nothing renames.
- Nothing renames another change's file, so the adoption `PR-umtm9b` records
  cannot happen.
- A target project renames each draft ledger file in flight by hand, once,
  with one `git mv` per file; `DRAFT-FILE` names each file and
  `DANGLING-FILE` each stale reference.
- `PR-8ucezf` stays open: `DRAFT-FILE` still reads the whole tree, and names
  no change. Scoping it to the files the branch adds would give `check-ids.sh`
  a base-branch dependency it has never had.

## Alternatives considered

- **Keep `finalize-docs.sh` as a migration tool** (D2). Kept, it would still
  perform the rename this decision removes, and its collision check would
  still read only the local disk. A draft in flight migrates with one `git mv`
  per file, and the two gates name every step of it.
- **Remove `DRAFT-FILE`** (D3). A change written under an old installed
  skill would then merge a draft-named file into the base for good,
  contradicting the dated names the READMEs promise. The repair costs one
  `git mv`, and CI greps, the remedy tables and `merge-change` step 5 cite
  the token, so it is not renamed either.
- **Renumber the whole `merge-change` sequence** (D5). Removing step 3 and
  closing the gap would touch about 30 files and 40 lines that cite steps
  6a–8, AGENTS.md among them, and every record and habit that names
  "step 6c" or "step 7". The tree check moves into the empty step 3 instead,
  where it loses nothing: steps 4 and 5 only read, and every fix reruns from
  step 1.
