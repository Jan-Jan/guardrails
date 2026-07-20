# Per-Change Document Ledgers — Design

**Date:** 2026-07-20
**Status:** Validated with project owner

## Problem

With multiple developers, parallel worktrees appending to the same monolithic
documents (`srs.md`, `rmf.md`, `sad.md`, `problems/log.md`) conflict at merge
step 1. Same race as ID collisions, one level up.

## Solution

Per-change document files whose final names are minted at merge time — the
filename analogue of draft-ID finalization.

### Layout

```
docs/
├── requirements/   README.md + YYYY-MM-DD-<slug>.md per change (REQ items)
├── risk/           README.md + dated files (HAZ/RC items + derived assessments)
├── architecture/   README.md + dated files (SDD/LLR items) + soup.md
├── problems/       README.md + dated files (PR items)
```

- In a worktree, new items go into `DRAFT-<branch>-<slug>.md` in the right
  directory. `merge-change` renames it to `YYYY-MM-DD-<slug>.md` (merge
  date); same-day slug collisions get `-2`, `-3` suffixes. `ls` = ledger
  sorted by merge date.
- **Edits to existing items happen in the file that defines them.** The
  definition site never moves; `check-ids` duplicate detection is unchanged.
- `soup.md` stays a single file (inventory table, rarely touched).
- Each directory's `README.md` carries the item grammar (from templates);
  READMEs contain only `PREFIX-NNN` placeholders, never real IDs.

### Scripts

- `lib.sh` gains `gr_doc_files KEY`: resolves a `doc_*` config value to a
  file list — a file stays itself; a directory yields its `*.md` files
  (sorted). Every `check-trace.sh` scan of srs/rmf/sad/problems goes through
  it. **Back-compat:** existing single-file projects keep working; config
  may point at either form.
- `finalize-ids.sh` additionally renames `DRAFT-<branch>-<slug>.md` files in
  the doc directories via `git mv` (respects `--dry-run`, prints
  `old -> new`, suffixes on collision with an existing dated file).
- `check-ids.sh` gains `DRAFT-FILE`: any tracked file whose name starts with
  `DRAFT-` fails (no draft filenames on main), `--allow-drafts` tolerates.
- Template `config.yaml` doc keys become directories
  (`doc_srs: docs/requirements` etc.); `doc_soup` stays the file.

### Skills and templates

- `worktree-discipline`: mint the change's draft doc file(s); edit existing
  items in their defining file.
- `merge-change`: step 3 wording covers ID finalization AND draft-file
  renaming (same script run).
- `grill-requirements`, `analyze-risks`, `design-architecture`,
  `resolve-problem`: new items → the change's draft file in the respective
  directory; amendments → in place.
- `ratchet`: greenfield installs the directory layout with READMEs;
  retrofit offers migration (existing monolith stays valid — file-or-dir
  config — with the ledger recommended for multi-developer repos).
- Templates: srs/rmf/sad/problems templates become the directory READMEs
  (grammar reference only, no item sections).

### Tests

Fixture moves to directory layout (canonical path). New bats tests:
`gr_doc_files` file vs dir; trace rules across multiple dated files
(definitions in one file, references in another); DRAFT-FILE rule +
`--allow-drafts`; draft-file rename incl. `--dry-run` and same-day collision
suffix; single-file back-compat regression for check-trace.

## Out of scope

Splitting `soup.md`; migrating this repo's own docs (guardrails has no
config; its docs/plans and docs/verification already follow dated-file
naming).
