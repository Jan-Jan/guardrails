# Guardrails Skill Suite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the guardrails distributable skill suite (10 skills, 4 POSIX-shell check/finalize scripts with bats tests, templates, installer) per `docs/plans/2026-07-20-guardrails-design.md`.

**Architecture:** A skills repo like superpowers: `skills/<name>/SKILL.md` for process guidance, `scripts/` as the source of truth for mechanical checks that `/ratchet` copies into target projects, `templates/` for scaffolded files, `tests/` with bats covering every script behavior against throwaway fixture git repos.

**Tech Stack:** POSIX sh + git + grep/awk/sed (`sed -i.bak` for portability), bats-core (vendored on demand by `tests/run-tests.sh`), markdown skills.

## Global Constraints

- Scripts must be POSIX sh (`#!/bin/sh`), no bash-isms, no runtime deps beyond git/grep/awk/sed.
- All IDs use prefixes from config; default set `REQ HAZ RC SDD`.
- Final ID grammar: `<PREFIX>-<NNN>` (zero-padded, 3+ digits). Definition site: line starting `**<ID>**:`.
- Draft ID grammar: `<PREFIX>-DRAFT-<slug>-<n>`, slug `[A-Za-z0-9][A-Za-z0-9-]*`, n integer.
- Trace annotations: tests say `verifies: REQ-001, RC-002`; RC items say `mitigates: HAZ-001`; REQ items say `implements: RC-001`; SDD items say `traces: REQ-001`.
- Config lives at `.guardrails/config.yaml`, flat schema only: `key: value` scalars and two-space `- item` lists. Parsed with awk (`cfg_get`, `cfg_list`) — never require yq.
- Skills are standard SKILL.md (frontmatter: `name`, `description`), self-contained (no superpowers references).
- Every commit in the worktree: `git -c commit.gpgsign=false commit` (squash merge is signed at the end).

## Interface contracts (used by every task)

`.guardrails/config.yaml` canonical schema:

```yaml
guardrails_version: 0.1.0
safety_class: B
id_prefixes: REQ HAZ RC SDD
doc_srs: docs/requirements/srs.md
doc_rmf: docs/risk/rmf.md
doc_sad: docs/architecture/sad.md
doc_soup: docs/architecture/soup.md
strict_paths:
  - src
test_paths:
  - tests
verify_commands:
  - make test
```

Script CLIs (all exit 0 = pass, 1 = violations found, 2 = usage/environment error; all print violations one per line to stdout as `<RULE> <ID-or-commit> <detail>`):

- `check-ids.sh [--allow-drafts] [--base REF]` — fail on draft IDs anywhere in tracked files (unless `--allow-drafts`); fail on duplicate definitions of a final ID in the tree; with `--base`, also fail on definitions that already exist on REF.
- `finalize-ids.sh [--dry-run] [--base REF]` (default base `main`) — mint next sequential final IDs per prefix from the max across REF and the working tree, in definition order (path, then line); rewrite every occurrence in tracked files (longest draft token first); print `DRAFT -> FINAL` mapping; idempotent.
- `check-trace.sh` — enforce: every REQ has a `verifies:` reference in test_paths; every HAZ has an RC `mitigates:` it; every RC has a REQ `implements:` it; every SDD `traces:` ≥1 existing REQ; no dangling ID references in doc files, strict_paths, or test_paths.
- `check-signing.sh [--strict] [REV_RANGE]` (default range `HEAD^!`) — per commit, `%G?` of `G`/`U` passes; `E` (signature present, unverifiable) warns and passes, or fails with `--strict`; `N`/`B` fails.

---

### Task 1: Repo scaffolding

**Files:**
- Create: `.gitignore`, `AGENTS.md`
- Modify: `README.md` (placeholder only; full README in Task 10)

- [x] **Step 1:** `.gitignore` with: `.claude/worktrees/`, `tests/.bats-core/`, `*.bak`.
- [x] **Step 2:** `AGENTS.md` — rules for developing guardrails itself: all changes via worktree; signed squash merge to main; scripts changes require bats coverage; run `tests/run-tests.sh` before merge; POSIX sh constraint; skills follow `skills/<name>/SKILL.md` layout.
- [x] **Step 3:** Commit `chore: scaffolding (.gitignore, AGENTS.md)`.

### Task 2: Test harness + `scripts/lib.sh`

**Files:**
- Create: `tests/run-tests.sh`, `tests/helpers.bash`, `tests/lib.bats`, `scripts/lib.sh`

**Interfaces produced:** `gr_die`, `gr_root`, `cfg_get KEY`, `cfg_list KEY`, `gr_prefix_re` (e.g. `REQ|HAZ|RC|SDD`), `GR_CONFIG` env override.

- [x] **Step 1:** `tests/run-tests.sh` — clones bats-core (tag v1.11.0, depth 1) into `tests/.bats-core` if absent and not on PATH; runs `bats tests/*.bats "$@"`.
- [x] **Step 2:** `tests/helpers.bash`:

```bash
make_fixture_repo() {   # creates $REPO with git init, config.yaml, doc skeleton, scripts copied
  REPO="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$REPO" && cd "$REPO"
  git init -q -b main
  git config user.name test && git config user.email test@example.com
  git config commit.gpgsign false
  mkdir -p .guardrails/scripts docs/requirements docs/risk docs/architecture src tests
  cp "$BATS_TEST_DIRNAME"/../scripts/*.sh .guardrails/scripts/
  write_config          # canonical schema from Interface contracts
  git add -A && git commit -qm fixture
}
```

- [x] **Step 3:** `tests/lib.bats` — failing tests: `cfg_get safety_class` → `B`; `cfg_get doc_srs` → path; `cfg_list strict_paths` → `src`; `cfg_list verify_commands` → `make test`; `gr_prefix_re` → `REQ|HAZ|RC|SDD`; `cfg_get missing` → empty, exit 0.
- [x] **Step 4:** Run `tests/run-tests.sh` → FAIL (lib.sh absent). Implement `scripts/lib.sh` per contract. Run → PASS.
- [x] **Step 5:** Commit `feat: config-parsing lib + bats harness`.

### Task 3: `check-ids.sh`

**Files:** Create: `scripts/check-ids.sh`, `tests/check-ids.bats`

- [x] **Step 1:** Failing tests: clean fixture passes; adding `**REQ-DRAFT-foo-1**: x` to srs fails with `DRAFT-ID`; `--allow-drafts` passes it; duplicate `**REQ-001**:` definitions in two files fails with `DUPLICATE-ID`; `--base main` catches a definition re-used from main (branch defines `**REQ-001**:` when main already has it).
- [x] **Step 2:** Run → FAIL. Implement: `git grep -InE` for draft regex over tracked files; definition scan `^\*\*(<P>)-[0-9]{3,}\*\*:` collected with `git grep -hoE`, `sort | uniq -d`; base comparison via `git grep` on `REF` and `comm -12`.
- [x] **Step 3:** Run → PASS. Commit `feat: check-ids script`.

### Task 4: `finalize-ids.sh`

**Files:** Create: `scripts/finalize-ids.sh`, `tests/finalize-ids.bats`

- [x] **Step 1:** Failing tests:
  - fixture with `**REQ-001**` on main; worktree branch adds `**REQ-DRAFT-b-1**:` in srs + reference `verifies: REQ-DRAFT-b-1` in `tests/test_x.sh` → run: srs now has `**REQ-002**:`, test says `verifies: REQ-002`, stdout contains `REQ-DRAFT-b-1 -> REQ-002`.
  - `--dry-run` prints mapping, changes nothing (`git diff --quiet`).
  - two drafts `-1` and `-12` (token-prefix overlap) both rewritten correctly.
  - multiple prefixes finalized independently (REQ high-water 1, HAZ high-water 0 → HAZ-001).
  - idempotent: second run exits 0, prints nothing, no diff.
- [x] **Step 2:** Run → FAIL. Implement: definition-ordered scan (`git grep -n` sorted by path/line); high-water = max over base-ref grep and tree grep of `<P>-[0-9]+` definitions; mapping applied with `sed -i.bak` + `rm *.bak`, longest draft token first.
- [x] **Step 3:** Run → PASS. Commit `feat: finalize-ids script`.

### Task 5: `check-trace.sh`

**Files:** Create: `scripts/check-trace.sh`, `tests/check-trace.bats`

- [x] **Step 1:** Failing tests around a "good" fixture (REQ-001 implements RC-001; RC-001 mitigates HAZ-001; SDD-001 traces REQ-001; `tests/test_a.sh` has `# verifies: REQ-001`):
  - good fixture → exit 0, empty output.
  - remove test annotation → `MISSING-TEST REQ-001`.
  - HAZ-002 with no RC → `UNMITIGATED-HAZARD HAZ-002`.
  - RC-002 with no implementing REQ → `UNIMPLEMENTED-CONTROL RC-002`.
  - SDD-002 with no `traces:` → `UNTRACED-DESIGN SDD-002`.
  - reference to undefined `REQ-999` in src → `DANGLING-REF REQ-999`.
- [x] **Step 2:** Run → FAIL. Implement with git grep over doc files + strict/test paths; sets compared with `comm`/awk.
- [x] **Step 3:** Run → PASS. Commit `feat: check-trace script`.

### Task 6: `check-signing.sh`

**Files:** Create: `scripts/check-signing.sh`, `tests/check-signing.bats`

- [x] **Step 1:** Failing tests:
  - unsigned HEAD → `UNSIGNED <sha>`, exit 1.
  - fixture generates throwaway ed25519 SSH key, configures `gpg.format=ssh`, `user.signingkey`, `gpg.ssh.allowedSignersFile`; signed commit → exit 0.
  - signed commit with allowedSignersFile removed → passes with `WARN-UNVERIFIED` line; `--strict` → exit 1.
  - range form checks every commit in `main..branch`.
- [x] **Step 2:** Run → FAIL. Implement via `git log --format='%H %G?' <range>` + case on status. Run → PASS.
- [x] **Step 3:** Commit `feat: check-signing script`.

### Task 7: Templates

**Files:** Create: `templates/config.yaml`, `templates/AGENTS-block.md`, `templates/CLAUDE.md`, `templates/CONTEXT.md`, `templates/srs.md`, `templates/rmf.md`, `templates/sad.md`, `templates/soup.md`

- [x] **Step 1:** `config.yaml` = canonical schema above with `safety_class: TBD` sentinel `/ratchet` must replace.
- [x] **Step 2:** `AGENTS-block.md` — the managed block, delimited by `<!-- guardrails:begin -->` / `<!-- guardrails:end -->`, containing the three non-negotiables (worktrees mandatory, signed squash merge via merge-change sequence, draft-ID + traceability discipline), the skill flow map, and the check-script contract. `CLAUDE.md` = two lines pointing at AGENTS.md.
- [x] **Step 3:** Doc skeletons: each starts with an HTML comment explaining item grammar (`**REQ-001**: ...` etc.) + section headings; `rmf.md` includes a 3×3 severity/probability acceptability matrix table with TBD cells; `soup.md` a table (name, version, role, requirements, risk considerations).
- [x] **Step 4:** Commit `feat: target-project templates`.

### Task 8: The ten skills

**Files:** Create `skills/<name>/SKILL.md` for: `ratchet`, `grill-requirements`, `analyze-risks`, `design-architecture`, `plan-change`, `worktree-discipline`, `develop-change`, `check-traceability`, `verify-before-merge`, `merge-change`.

Each skill: frontmatter (`name`, `description` with trigger conditions), "Announce at start" line, numbered process, red-flags table where useful, cross-links to the other skills by `/name`. Content per design doc §"The skill suite"; key specifics:

- [x] `ratchet` — greenfield vs retrofit detection (`git log` empty + no source files = greenfield); greenfield writes templates + interviews for safety class (with IEC 62304 4.3 decision questions); retrofit runs gap inventory → `docs/plans/<date>-ratchet-gap-analysis.md` → managed-block merge into existing AGENTS.md → proposes `strict_paths` ramp-up; both end with human checklist saved to `docs/plans/<date>-ratchet-setup.md` (signing key, allowed_signers, branch protection, CI wiring, QMS disclaimer). Scaffold committed via worktree + signed squash merge.
- [x] `grill-requirements` — one question at a time, recommended answer per question, facts looked up not asked; REQ items minted as drafts in worktrees; glossary (`docs/CONTEXT.md`) updated inline the moment a term resolves; ADR only when hard-to-reverse + surprising + real trade-off.
- [x] `analyze-risks` — interview walks hazard → hazardous situation → harm (severity/probability) → evaluation vs matrix → RC minting (each RC `mitigates:` its HAZ, then handed to grill-requirements to become `implements:` REQs); records residual-risk statement.
- [x] `design-architecture` — SDD items with `traces:`; SOUP inventory update; class-scaling table (A: architecture optional / B: architecture required / C: + detailed design per item).
- [x] `plan-change` — plan template requiring per-task trace IDs and test deliverables; saved to `docs/plans/`.
- [x] `worktree-discipline` — worktree per change (native tool first, `git worktree add .worktrees/<branch>` fallback), draft-ID minting rules, never commit to main directly, unsigned commits OK inside worktree only.
- [x] `develop-change` — RED/GREEN/REFACTOR with `verifies:` annotations mandatory in every new test; no implementation before failing test.
- [x] `check-traceability` — how to run/interpret each `<RULE>` output line, and fix guidance per rule.
- [x] `verify-before-merge` — evidence-before-claims gate: run every `verify_commands` + all three check scripts, paste actual output, no "should pass".
- [x] `merge-change` — the 8-step sequence from the design doc verbatim (merge main in → verify → finalize → check-ids → check-trace → re-verify → signed squash with structured message → check-signing; halt-and-fix on any failure; never unsigned fallback).
- [x] Commit `feat: guardrails skill suite (10 skills)`.

### Task 9: `install.sh`

**Files:** Create: `install.sh`

- [x] **Step 1:** POSIX sh; symlinks each `skills/<name>` into `~/.claude/skills/` (or `$CLAUDE_SKILLS_DIR`); `--copy` flag as fallback; refuses to clobber non-symlink existing dirs; prints what it did.
- [x] **Step 2:** Smoke-test into a temp dir via `CLAUDE_SKILLS_DIR`. Commit `feat: installer`.

### Task 10: README

**Files:** Modify: `README.md`

- [x] **Step 1:** What guardrails is (and the QMS disclaimer), install instructions, the workflow diagram (mermaid: ratchet → grill-requirements/analyze-risks/design-architecture → plan-change → worktree-discipline → develop-change → check-traceability → verify-before-merge → merge-change), the ID/trace grammar reference table, script reference, credits to obra/superpowers and mattpocock/skills (MIT attribution).
- [x] **Step 2:** Commit `docs: README`.

### Task 11: Verification + signed squash merge

- [x] **Step 1:** Run `tests/run-tests.sh` — all bats tests pass (paste output).
- [x] **Step 2:** `shellcheck -s sh scripts/*.sh install.sh` if shellcheck available (advisory).
- [x] **Step 3:** Follow merge-change sequence on this worktree itself: merge main in, re-run tests, signed squash merge to main (**requires user's security-key touch**), verify signature.

## Self-Review

- Spec coverage: every design-doc section maps to a task (design §skills → T8, §layout/config → T7, §merge → T6/T8/T11, §repo → T1/T2/T9/T10, ID strategy → T3/T4). Deferred items are explicitly out of scope in the design.
- Placeholder scan: skill-content specifics are enumerated per skill in T8; script behavior fully specified by contracts + test cases in T2–T6.
- Type consistency: rule names (`DRAFT-ID`, `DUPLICATE-ID`, `MISSING-TEST`, `UNMITIGATED-HAZARD`, `UNIMPLEMENTED-CONTROL`, `UNTRACED-DESIGN`, `DANGLING-REF`, `UNSIGNED`, `WARN-UNVERIFIED`) and config keys (`doc_srs`…, `strict_paths`, `test_paths`, `verify_commands`) are single-sourced in Interface contracts.
