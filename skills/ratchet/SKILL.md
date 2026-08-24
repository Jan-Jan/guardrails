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

1. `git init` if not a repo (any default branch name works — the scripts
   detect the base branch rather than assuming `main`); make an initial
   commit if there is none (a worktree needs a base).
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
4. Create `docs/adr/`, `docs/plans/`, and `docs/verification/` directories, and
   copy `templates/verification.md` → `.guardrails/templates/verification.md`.
   `docs/verification/` is where `merge-change` step 6b writes one record per
   change and step 6c checks it; `doc_verification` in the config overrides the
   location and defaults to it. The default is safe only because an absent
   directory is exit 2 — so if you keep records elsewhere, set the key.

   **The template goes into `.guardrails/`, never into `docs/verification/`.**
   Every `*.md` directly in that directory is read as a record, and the
   template carries the field names at column one because that is the shape it
   teaches. Filed among the records it would be one — a document declaring a
   `branch:`, a `reviewer:` and a `**finding-1**:` that nobody wrote about any
   change. Leave the records directory holding records.
   Ensure `.gitignore` excludes worktree directories and sed backups — add
   any of these that are missing:

   ```
   .worktrees/
   .claude/worktrees/
   *.bak
   ```
5. **Make every configured path exist in the commit**, and every ledger
   directory hold at least one `*.md`. `check-trace.sh` exits 2 otherwise —
   that is what stops a typo'd path from silently disabling a gate. Git does
   not track empty directories, so anything that exists only on your disk is
   missing for everyone who clones the repo, and CI fails at exit 2. Two
   different remedies, and they are not interchangeable:

   - `strict_paths` / `test_paths` entries need to **match at least one file
     that is present in the working tree**, so a `.gitkeep` in an as-yet-empty
     `src/` or `tests/` is enough. Each entry is a **git pathspec** handed to
     `git grep` verbatim — a plain path, or a pattern like `*_test.sh` that git
     matches recursively. The shell never expands it, so the pattern means the
     same thing wherever it is run from.
   - `doc_*` values are plain paths, not patterns: a file, or a directory whose
     `*.md` files sit directly in it (subdirectories are not read).
   - `doc_*` directories need an actual `*.md` — a `.gitkeep` does **not**
     satisfy them. Step 3 above already copies a README template into each of
     the four ledger directories, which is what makes them valid; keep it.

   Do **not** reach for the other apparent option — leaving the key out of the
   config until the directory has content. For any key a declared prefix
   requires that is now exit 2, not a silent pass; and for the rest, a missing
   key still reads as "this project does not use that". Point the key at a
   real path. The one remaining way to switch a gate off is to drop its prefix
   from `id_prefixes`, which is honest but wholesale — record why if you do.
6. Run the **safety-class interview** (Step 4) and write the answer into
   `.guardrails/config.yaml` (`safety_class:`), replacing the `TBD` sentinel.
   Also set `verify_commands` to the project's real test command.
7. Commit in the worktree, then integrate with the `merge-change` skill
   (signed squash merge). The check scripts must pass on the result.

> **Upgrading the scripts in an existing project.** The config and layout
> rules above are enforced from this version on, and several shapes the older
> scripts accepted in silence are now exit 2. Before swapping in new
> `scripts/`, run `check-trace.sh` once and work through whatever it reports:
>
> | Exit-2 cause | Why it was never safe |
> |---|---|
> | A ledger directory with no `*.md`, or a configured path that was never committed | The gates reading it did nothing and the run still passed |
> | A configured directory that is empty | It exists, but matches no file, so the gate reading it scanned nothing |
> | An unrecognised key (`doc_rmff:`) | Nothing read it, so the gate it configured never ran |
> | A key that is not `identifier:` at column one (`strict-paths:`, ` strict_paths:`, `strict_paths :`) | The config reader never saw it, so its value read as absent |
> | A list item at column zero (`- src` unindented) | `cfg_list` never read those entries either |
> | A list item orphaned from its key by a column-one comment or a `---` above it | Ambiguous: it either vanished with its list or was adopted by the block above, so `- src` under a commented-out `strict_paths:` could become a test path. **Commenting a list key out means commenting its items out too.** |
> | A config saved with a UTF-8 BOM | The BOM made the first key unreadable, i.e. silently absent |
> | `id_prefixes` naming none of REQ/HAZ/RC/SDD/LLR/PR | No traceability gate of its own would run for any prefix. Extra prefixes alongside the six stay valid and stay covered by DANGLING-REF, DUPLICATE-ID and MALFORMED-ID — do **not** remove them |
> | A declared `id_prefixes` entry whose document is unconfigured — `REQ`/`RC` without `doc_srs`, `HAZ`/`RC` without `doc_rmf`, `SDD`/`LLR` without `doc_sad`, `PR` without `doc_problems`, or `REQ`/`LLR` with an empty `test_paths` | Without it the gate for that prefix was skipped and the run still passed. `RC` needs both: `UNIMPLEMENTED-CONTROL` reads `doc_srs`, where the *requirements* live, and `MISPLACED-ITEM` reads `doc_rmf`, the only document a control may be defined in |
> | An `id_prefixes` entry that is not a bare identifier | It is interpolated into every scan pattern; an invalid pattern matches nothing, which looks like a clean tree |
>
> Some changes are **exit 1**, not exit 2, and so are easy to miss.
>
> An item defined outside the document configured for its prefix now reports
> `MISPLACED-ITEM`. It used to be counted in `checked:` while the gate that
> would convict it never parsed its block — `**SDD-001**:` in
> `docs/design.md`, with no `traces:` line at all, passed. (Other gates did
> still see it: a misplaced item has always drawn `MISSING-TEST`,
> `UNMITIGATED-HAZARD` or `DANGLING-REF` where those applied. What it escaped
> was the gate keyed on its own document.)
> Move the definition into the configured document; adding the stray file to
> `strict_paths` does **not** fix it, because that widens reference scanning
> rather than the document a gate opens. A `doc_*` directory resolves to its
> `*.md` files one level deep, so a `.md` in a subdirectory of one reports —
> and so does a `.txt` sitting directly in it; a `doc_*` configured as a
> single file resolves to that file whatever its extension. Where the ID is
> illustrative text rather than a real item — an example in a plan, changelog
> or README at column one — the remedy is the reverse: indent it, or keep it
> inline. Do not leave it at the start of a line, whatever body you give it:
> `MALFORMED-ID` reports a definition form there whose ID is not valid.
> Measured on a project already keeping its items in the configured ledgers,
> this gate reports nothing at all.
>
> `strict_paths` and `test_paths` entries are now handed to `git grep` as
> pathspecs instead of being expanded by the shell first. Git's `*` crosses
> `/` where a shell glob does not, so an entry like `src/*.c` now reaches into
> subdirectories that were previously out of scope, and files there can raise
> failures for the first time. This is the entry meaning what it says; narrow
> it if the wider scope is not what you wanted.
>
> An SDD
> block now ends at the next definition line or markdown heading, the rule
> low-level requirements already followed — so a `**Bold:**` aside or a fenced
> block between an `**SDD-nnn**:` header and its `traces:` line now reports
> `UNTRACED-DESIGN`. Move the annotation onto the header line or directly
> beneath it.
>
> And annotations are now read as lists, with only the IDs immediately
> following the keyword counting.
> `verifies: LLR-001 and REQ-002` credits `LLR-001` alone, where the older
> scripts credited both. A project using prose-joined ID lists will see new
> `MISSING-TEST` / `UNMITIGATED-HAZARD` failures. Rewrite them as
> `verifies: LLR-001, REQ-002`.
>
> **Item IDs are now random tokens.** From this version on an item gets its
> ID when it is written — `.guardrails/scripts/new-id.sh REQ` prints
> `REQ-a3k9z2` — instead of a sequential number assigned at merge. Existing
> sequential IDs keep working, permanently and without conversion: every
> pattern in the toolkit accepts both forms, and nothing renumbers an SRS.
> Four things change at the upgrade:
>
> * **Delete `.guardrails/scripts/finalize-ids.sh`.** It is replaced by
>   `finalize-docs.sh`, which renames the change's draft ledger FILE and does
>   nothing to IDs. Copying in the new `scripts/` leaves the old file behind;
>   remove it, or `merge-change` step 3 will find a script that still tries to
>   mint. Update any CI line that calls it.
> * **Finish or discard drafts in flight before upgrading.** A
>   `REQ-DRAFT-<branch>-<n>` token is now a hard failure in `check-ids.sh`
>   under every flag, because nothing will ever turn it into a real ID. Run
>   the old `finalize-ids.sh` one last time, or replace each token by hand
>   with an ID from `new-id.sh`.
> * **`check-ids.sh --allow-drafts` and `--base` are refused, not ignored.**
>   The first is now `--allow-draft-files`, and it covers draft-named ledger
>   files only. The second named a gate that no longer exists: IDs are
>   allocated against nothing, so two branches cannot mint the same one, and
>   the in-tree duplicate scan sees everything once `merge-change` step 1 has
>   merged the base branch in. `UNANCHORED-DEF` and `SKIPPED-DUPLICATE-BASE`
>   are gone with it.
> * **`MALFORMED-ID` is new, and is exit 1.** It reports a line opening with a
>   definition form whose body is not a valid ID — including a legacy
>   `**REQ-01**:`, too short to have ever matched `[0-9]{3,}`. Such an item
>   was invisible to every gate under the old scripts too; this is the first
>   version that says so. Give it a real ID.
>
> **The review artefact is now checked.** `check-review.sh` is new. It reads
> the verification record for the change under merge and reports
> `MISSING-RECORD` when there is none, `INCOMPLETE-RECORD` when it omits
> `reviewer:`, `verdict:` or `reproduced:`, and `UNDISPOSED-FINDING` when a
> `**finding-N**:` block carries no `disposition:`. Three things to know at
> the upgrade:
>
> * **Records already written are left alone.** Only the record for the branch
>   under merge is read, so a ledger of sixty-nine legacy records does not go
>   red on the day you upgrade. The schema applies from the next change on,
>   and the migration cost is one record at a time.
> * **`reproduced:` is required and its value is never judged.** `reproduced:
>   no — the root cause was measured directly, the end-to-end failure never
>   reproduced` is a passing record. The field exists so the absence of
>   evidence is a visible omission, not an optional act of honesty.
> * **It is not a CI gate on the base branch.** There is no change under
>   review there, so it exits 2. Run it at `merge-change` step 6c from the
>   worktree, or in pull-request CI as `check-review.sh --branch <head>`.
>
> Every one of these is a pre-existing gap the older scripts passed over, not
> a new requirement invented by the upgrade. Fix the config or the layout;
> **there is no compatibility flag, deliberately.** Almost every shape above
> was a gate that did not run, so an opt-out would be a supported way to keep
> a false green. The exception is an unrecognised key — a project-local
> annotation was harmless before and is now rejected. That is accepted
> deliberately: a typo and an extension are indistinguishable from here, and
> guessing wrong on a typo is what this change exists to stop.
>
> The fastest way through the list is to run `check-trace.sh` once and work
> from the top: config errors are reported before any gate runs, so each fix
> reveals the next.

## Step 3 (retrofit): Gap analysis first, then tighten

Never overwrite. Sequence:

1. **Inventory** (read, don't write): existing AGENTS.md/CLAUDE.md content and
   any rules that conflict with guardrails (e.g. "commit to the base branch
   directly");
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
- [ ] Branch protection on the base branch: no direct pushes, require signed
      commits.
- [ ] CI: run `verify_commands`, `check-ids.sh`, `check-trace.sh`, and
      `check-signing.sh --strict <base>..HEAD` on every merge. **Not
      `check-review.sh`** — it asks about the change under merge, so on the
      base branch it exits 2 rather than reporting a pass over no question.
      It runs from the change worktree at `merge-change` step 6c. To gate it
      in CI on a pull request, name the branch: `check-review.sh --branch
      <head-branch>`.
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
