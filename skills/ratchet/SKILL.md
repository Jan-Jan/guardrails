---
name: ratchet
description: Bootstrap or retrofit a project for IEC 62304 / ISO 14971 development under guardrails. Use when setting up a new regulated project, adopting guardrails in an existing codebase, updating guardrails scripts/config, or when the user runs /ratchet.
---

# Ratchet — bootstrap or tighten a project

**Announce at start:** "Using the ratchet skill to set up guardrails in this project."

A ratchet only turns one way. This skill installs the guardrails machinery and
— on existing projects — tightens enforcement one tooth at a time, never
loosening and never overwriting human work.

## Step 0: Locate the guardrails source

Templates and scripts come from the guardrails repo this skill belongs to
(the directory containing this SKILL.md, two levels up: `<guardrails>/templates/`
and `<guardrails>/scripts/`). Verify both directories exist before proceeding.

## Step 1: Detect mode

**Greenfield** = no commits beyond scaffolding AND no source files AND no
existing AGENTS.md/docs. Anything else is a **retrofit**.

```sh
git rev-list --count HEAD 2>/dev/null   # missing repo or tiny history → likely greenfield
ls src lib app AGENTS.md docs 2>/dev/null
```

## Step 2 (greenfield): Scaffold

1. `git init -b main` if not a repo; make an initial commit if there is none
   (a worktree needs a base).
2. Create a worktree for the scaffold work (use the `worktree-discipline`
   skill — ratchet practices what it preaches).
3. Copy in, from the guardrails repo:
   - `templates/config.yaml` → `.guardrails/config.yaml`
   - `scripts/*.sh` → `.guardrails/scripts/` (keep executable bits)
   - `templates/srs.md` → `docs/requirements/README.md`
   - `templates/rmf.md` → `docs/risk/README.md`
   - `templates/sad.md` → `docs/architecture/README.md`
   - `templates/soup.md` → `docs/architecture/soup.md`
   - `templates/problems.md` → `docs/problems/README.md`
   - `templates/CONTEXT.md` → `docs/CONTEXT.md`
   - `templates/CLAUDE.md` → `CLAUDE.md` (skip if one exists)
   - `templates/AGENTS-block.md` → becomes the body of a new `AGENTS.md`

   The requirements/risk/architecture/problems directories are **per-change
   ledgers**: each merged change contributes one dated file
   (`YYYY-MM-DD-<slug>.md`, merge date), created in the worktree as
   `DRAFT-<branch>-<slug>.md` and renamed by `merge-change`. The README in
   each directory carries the item grammar.
4. Create `docs/adr/`, `docs/plans/`, and `docs/verification/` directories.
   Ensure `.gitignore` excludes worktree directories and sed backups — add
   any of these that are missing:

   ```
   .worktrees/
   .claude/worktrees/
   *.bak
   ```
5. Run the **safety-class interview** (Step 4) and write the answer into
   `.guardrails/config.yaml` (`safety_class:`), replacing the `TBD` sentinel.
   Also set `verify_commands` to the project's real test command.
6. Commit in the worktree, then integrate with the `merge-change` skill
   (signed squash merge). The check scripts must pass on the result.

## Step 3 (retrofit): Gap analysis first, then tighten

Never overwrite. Sequence:

1. **Inventory** (read, don't write): existing AGENTS.md/CLAUDE.md content and
   any rules that conflict with guardrails (e.g. "commit to main directly");
   existing requirement/risk/architecture docs in any format; a bug tracker
   or problem log (feeds the `docs/problems/` ledger); verification evidence
   (test reports, coverage) worth archiving under `docs/verification/`;
   test layout and command; CI config; signing status of recent commits
   (`git log -20 --format='%h %G? %s'`); existing `.guardrails/` version if
   re-ratcheting.
2. **Write the gap analysis** to `docs/plans/<YYYY-MM-DD>-ratchet-gap-analysis.md`:
   what exists, what is missing, what conflicts, and a proposed adoption order.
3. **First tooth** (this change only): install `.guardrails/` (config +
   scripts), merge the managed block into AGENTS.md, add missing doc
   skeletons, and extend `.gitignore` to exclude worktree directories
   (`.worktrees/`, `.claude/worktrees/`) and `*.bak`. Do NOT migrate
   existing docs in this change.
   - AGENTS.md merging: if `<!-- guardrails:begin -->` exists, replace only
     the block between the markers (script updates re-use this). Otherwise
     append the whole block from `templates/AGENTS-block.md`, leaving existing
     content untouched. Flag any conflicting existing rules to the user rather
     than deleting them.
   - Set `strict_paths` to a SMALL list — only paths that are already clean
     or new. Existing untraced code is grandfathered.
4. **Later teeth** (separate worktree changes, listed in the gap analysis):
   migrate legacy requirement/risk docs into ID'd form via
   `grill-requirements` / `analyze-risks`; extend `strict_paths` as areas are
   brought under trace discipline; enable `--strict` signing checks once
   allowed_signers is set up. **Monolith → ledger migration:** doc config
   keys accept a file or a directory, so an existing single `srs.md` keeps
   working; for multi-developer repos recommend switching each `doc_*` key
   to a directory (move the monolith in as its first dated file, add the
   README) — new changes then land as dated per-change files and stop
   conflicting.
5. Integrate via `merge-change` like any other change.

## Step 4: Safety-class interview (IEC 62304 4.3)

Ask one question at a time; recommend an answer for each:

1. Can a failure of this software contribute to a hazardous situation at all?
   If no → **Class A**.
2. If yes: could the resulting harm, after external risk controls outside the
   software are considered, be serious injury or death? If yes → **Class C**;
   non-serious injury → **Class B**.
3. Record the rationale as an ADR in `docs/adr/` (this decision is hard to
   reverse, surprising without context, and a real trade-off).

If the user is unsure, walk through their intended use, foreseeable misuse,
and existing hardware safeguards before classifying. When in doubt between
two classes, the higher class governs until justified otherwise.

## Step 5: Human setup checklist

Print this AND save it to `docs/plans/<YYYY-MM-DD>-ratchet-setup.md`:

- [ ] Commit signing key: `git config gpg.format ssh`,
      `git config user.signingkey <key>`, `git config commit.gpgsign true`
      (GPG works too). Hardware keys require a physical touch per signature.
- [ ] Signature verification: create an allowed_signers file listing each
      committer (`<email> <key-type> <public-key>`), then
      `git config gpg.ssh.allowedSignersFile <path>`. Until this exists,
      `check-signing.sh` passes signed commits with WARN-UNVERIFIED; after,
      enable `--strict` in CI.
- [ ] Branch protection on main: no direct pushes, require signed commits.
- [ ] CI: run `verify_commands`, `check-ids.sh`, `check-trace.sh`, and
      `check-signing.sh --strict <base>..HEAD` on every merge.
- [ ] Decide the human review/approval policy for merges (who signs off),
      including who acts as the independent reviewer in `merge-change`
      step 6a when a human is preferred over a fresh agent.
- [ ] **Tool qualification (DO-330-lite):** the `.guardrails/scripts/` are
      verification tools — their failure could mask errors. Qualification
      basis: the guardrails bats suite at the `guardrails_version` recorded
      in config (this document records the version and the suite result at
      install time). When `/ratchet` updates the scripts, it re-records
      both. Do not modify the scripts in the target project; change them
      upstream where the tests live.
- [ ] **Guardrails supports your QMS but is not itself regulatory
      compliance.** Your quality manual, design controls, and human sign-offs
      govern; keep your notified-body/auditor requirements authoritative.

## Red flags

| Thought | Reality |
|---|---|
| "I'll just overwrite their AGENTS.md" | Retrofit never overwrites. Managed block only. |
| "Enable strict checks everywhere now" | That blocks all work on legacy code. Tighten one tooth. |
| "Skip the worktree for the scaffold" | Ratchet follows its own rules. Worktree + signed squash merge. |
| "safety_class can stay TBD" | Nothing else scales correctly until it's set. Interview now. |
