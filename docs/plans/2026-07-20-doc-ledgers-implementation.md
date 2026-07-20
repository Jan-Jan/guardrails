# Doc Ledgers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Per-change dated document files with merge-time renaming, per `docs/plans/2026-07-20-doc-ledgers-design.md`.

**Architecture:** `gr_doc_files` resolver in lib.sh (file-or-dir), check-trace scans through it, finalize-ids renames DRAFT files, check-ids gains DRAFT-FILE. Fixture switches to directory layout; back-compat test keeps single-file mode honest.

**Tech Stack:** unchanged.

## Global Constraints

- Draft doc filename grammar: `DRAFT-<branch-slug>-<slug>.md` (slug kebab-case). Final: `YYYY-MM-DD-<slug>.md`, collision suffix `-2`, `-3`, ….
- Config doc keys may be file OR directory. Fixture canonical: `doc_srs: docs/requirements`, `doc_rmf: docs/risk`, `doc_sad: docs/architecture`, `doc_problems: docs/problems`, `doc_soup: docs/architecture/soup.md`.
- `gr_doc_files KEY` prints one path per line; missing path prints nothing.
- New rule name: `DRAFT-FILE <path>` in check-ids.

### Task L1: `gr_doc_files` + fixture directory layout

- [ ] RED (`tests/lib.bats`): `gr_doc_files doc_srs` on dir fixture lists the dated files; on a file value (`doc_soup`) prints just it; missing key/path → empty, exit 0.
- [ ] Update `tests/helpers.bash`: config doc keys point at directories; fixture seeds `docs/requirements/0000-00-00-seed.md` style files where tests previously wrote srs.md (adjust all bats fixtures accordingly — check-trace/check-ids/finalize tests write their items into dated files).
- [ ] GREEN: implement `gr_doc_files` in `scripts/lib.sh`.
- [ ] Adapt `check-trace.sh` to scan file lists (`gr_doc_files doc_srs` etc.): `implements:` scan over srs files, `mitigates:`/derived-mention over rmf files, LLR/SDD awk loops over sad files, PR awk over problems files, DANGLING scope collects all lists. Suite green (this is refactor + fixture move; all 47 existing behaviors preserved).
- [ ] Back-compat regression: one bats test builds a single-file-config fixture (old layout) and asserts check-trace still passes/fails correctly on a representative rule.
- [ ] Commit `feat: doc paths accept file or directory (gr_doc_files)`.

### Task L2: cross-file trace behaviors

- [ ] RED: REQ defined in `docs/requirements/2026-01-01-a.md`, implements-line in `docs/requirements/2026-02-02-b.md`, RC in a dated risk file → UNIMPLEMENTED-CONTROL clean across files; LLR in one sad file satisfying REQ in another requirements file → transitive coverage works; derived assessment in any rmf-dir file counts.
- [ ] GREEN expected without code change (lists already concatenated); fix if not.
- [ ] Commit `test: trace rules across dated ledger files`.

### Task L3: DRAFT-FILE rule in check-ids

- [ ] RED: tracked `docs/requirements/DRAFT-b-dose.md` → `DRAFT-FILE docs/requirements/DRAFT-b-dose.md`, exit 1; `--allow-drafts` → exit 0.
- [ ] GREEN: `git ls-files --cached --others --exclude-standard | grep '/DRAFT-[^/]*$\|^DRAFT-'` style scan (POSIX grep), gated by `--allow-drafts`.
- [ ] Commit `feat: check-ids flags draft-named files`.

### Task L4: finalize-ids renames draft doc files

- [ ] RED: fixture with `docs/requirements/DRAFT-b-dose-limits.md` (containing a draft REQ) → after run: file is `docs/requirements/<today>-dose-limits.md` (git mv'd, `git status` shows rename), stdout has `DRAFT-b-dose-limits.md -> <today>-dose-limits.md`, IDs inside finalized too; `--dry-run` renames nothing; collision: pre-existing `<today>-dose-limits.md` → new file becomes `<today>-dose-limits-2.md`.
- [ ] GREEN: after ID rewrite loop, scan doc dirs (from `gr_doc_files` parents; only directories) for `DRAFT-*.md`, strip `DRAFT-<branch>` prefix by taking the slug = filename minus `DRAFT-` minus the leading `<branch-slug>-` segment... **Simplification (locked):** slug = everything after `DRAFT-` with the branch prefix removed only when it matches the current branch name (`git branch --show-current`, sanitized); otherwise the whole `DRAFT-`-stripped name is the slug. Target `$(date +%Y-%m-%d)-<slug>.md`; while target exists, bump suffix. `git mv` (fall back to mv+add if unstaged).
- [ ] Commit `feat: finalize-ids renames draft doc files at merge`.

### Task L5: templates → READMEs, config, skills

- [ ] Rename template roles: `templates/srs.md` → grammar-only README content (title "Requirements ledger", grammar comment, note "one dated file per change; edit items where they are defined"); same for rmf/sad/problems templates. `templates/config.yaml` doc keys become directories.
- [ ] Skills: `worktree-discipline` (mint `DRAFT-<branch>-<slug>.md`, edit-in-place rule), `merge-change` (step 3 mentions file renaming + `git add` of renames), `grill-requirements` / `analyze-risks` / `design-architecture` / `resolve-problem` (new items → the change's draft file in their directory; amendments in place), `ratchet` (installs directories + READMEs; retrofit migration note; gap analysis mentions monolith→ledger option).
- [ ] Commit `feat: ledger layout in templates and skills`.

### Task L6: README, verify, review, record, merge

- [ ] README: layout snippet + draft-file convention row in grammar table.
- [ ] Full suite green; `git status` clean.
- [ ] Independent review (fresh subagent, diff + spec); fix findings.
- [ ] Verification record `docs/verification/2026-07-20-doc-ledgers.md`.
- [ ] merge-change: merge main, re-verify, signed squash (key touch), check-signing, ExitWorktree remove.

## Self-Review

- Design sections all map: layout→L1/L5, rename→L4, DRAFT-FILE→L3, back-compat→L1, cross-file→L2, skills/templates→L5.
- Rule/behavior names locked in Global Constraints; slug derivation ambiguity resolved in L4.
