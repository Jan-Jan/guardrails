# DO-178C Mechanics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the eight adopted DO-178C mechanics to guardrails per `docs/plans/2026-07-20-do178c-mechanics-design.md`.

**Architecture:** Evolve in place: extend `check-trace.sh` (four new rules + transitive REQ coverage), add LLR/PR prefixes via config, update seven skills, add one skill (`resolve-problem`), extend templates and README. Scripts stay POSIX sh; all script behavior TDD'd in bats.

**Tech Stack:** unchanged (POSIX sh, bats, markdown skills).

## Global Constraints

- Same as v1 plan (POSIX sh, `sed -i.bak`, config flat schema, worktree commits unsigned).
- New grammar: LLR defined in SAD blocks `**LLR-NNN**: text. satisfies: REQ-NNN[, …]` or `satisfies: derived`; PR defined in `docs/problems/log.md` blocks `**PR-NNN**: symptom. affects: <IDs>. status: open|resolved`.
- New config keys: `doc_problems: docs/problems/log.md`, `coverage_command:` (list, optional). `id_prefixes: REQ HAZ RC SDD LLR PR`.
- New check-trace rules: `UNSATISFIED-LLR`, `UNANALYZED-DERIVED`, `MISSING-TEST` (extended to LLR), `UNRESOLVED-PR` (warning, exit 0). `MISSING-TEST REQ` becomes transitive via tested LLRs' `satisfies:`.

### Task 1: Config plumbing (helpers, template, lib test)

- [ ] Update `tests/helpers.bash` `write_config`: `id_prefixes: REQ HAZ RC SDD LLR PR`, add `doc_problems: docs/problems/log.md`; create `docs/problems/` dir in fixture.
- [ ] Update `tests/lib.bats` prefix-alternation expectation to `REQ|HAZ|RC|SDD|LLR|PR`; run suite — all green (config-driven, no script code change).
- [ ] Update `templates/config.yaml`: new prefixes, `doc_problems`, commented `coverage_command` block.
- [ ] Commit `feat: LLR/PR prefixes and problems-log config`.

### Task 2: Draft handling for new prefixes (tests only)

- [ ] `tests/finalize-ids.bats`: add test — `**LLR-DRAFT-b-1**:` in sad + `**PR-DRAFT-b-1**:` in problems log finalize to `LLR-001`/`PR-001` independently.
- [ ] `tests/check-ids.bats`: add test — `LLR-DRAFT-…` token fails without `--allow-drafts`.
- [ ] Run: both must pass with zero script changes (prefixes come from config). If not, fix scripts.
- [ ] Commit `test: draft/finalize coverage for LLR and PR prefixes`.

### Task 3: check-trace — LLR rules + transitive REQ coverage

- [ ] RED tests in `tests/check-trace.bats` (extend good fixture: sad gains `**LLR-001**: Clamp dose to max. satisfies: REQ-001`, test file annotates `verifies: LLR-001` **instead of** REQ-001):
  - good fixture (REQ covered only transitively via LLR) → exit 0, empty.
  - LLR without `satisfies:` → `UNSATISFIED-LLR LLR-002`.
  - LLR with `satisfies: derived` + RMF mention → clean.
  - LLR with no `verifies:` anywhere → `MISSING-TEST LLR-002`.
  - REQ with neither direct test nor tested-satisfying-LLR → `MISSING-TEST REQ-002`.
- [ ] GREEN: implement in `check-trace.sh` — awk block parse of sad emitting `LLR id, satisfies-list, derived-flag`; MISSING-TEST loop for LLR; REQ coverage set = direct `verifies:` REQs ∪ satisfies-lists of tested LLRs; UNSATISFIED-LLR when block lacks both REQ-pattern and `derived` after `satisfies:`.
- [ ] Run suite green. Commit `feat: LLR traceability rules with transitive REQ coverage`.

### Task 4: check-trace — UNANALYZED-DERIVED

- [ ] RED: derived LLR (`satisfies: derived`) NOT mentioned in rmf → `UNANALYZED-DERIVED LLR-…`; derived REQ (block contains `satisfies: derived` in srs) not in rmf → same; mentioned in rmf → clean.
- [ ] GREEN: collect derived REQ/LLR ids (grep blocks), for each `git grep -q "<id>" -- "$rmf"` else violation.
- [ ] Commit `feat: derived requirements must be assessed in RMF`.

### Task 5: check-trace — UNRESOLVED-PR warning

- [ ] RED: problems log with `**PR-001**: X. affects: REQ-001. status: open` → output contains `UNRESOLVED-PR PR-001`, **exit 0**; `status: resolved` → silent; open PR + a real violation elsewhere → exit 1 and both lines present.
- [ ] GREEN: awk over `$doc_problems` blocks; print warning lines; do not touch `fail`.
- [ ] Commit `feat: open problem reports surface as merge warnings`.

### Task 6: Skill updates (7 skills)

- [ ] `grill-requirements`: REQs = high-level requirements; derived rule (`satisfies: derived`, hand to analyze-risks; never invent fake parents).
- [ ] `design-architecture`: class C writes LLRs per SDD item (grammar + directly-codeable bar); class B optional; derived LLRs flagged to analyze-risks.
- [ ] `develop-change`: annotate lowest level present; robustness rule (normal + abnormal tests per REQ/LLR at class B/C).
- [ ] `analyze-risks`: derived-requirements intake section (assess, record in RMF).
- [ ] `verify-before-merge`: coverage gate (run `coverage_command` if configured; judge vs class target A none / B statement / C statement+decision; documented-gap escape needs explicit user acceptance); robustness completeness item.
- [ ] `merge-change`: step 6a independent review (fresh subagent/human; diff + doc excerpts + plan only; checklist incl. verification-of-verification; blocking; rigor by class), step 6b verification record `docs/verification/<date>-<branch>.md` committed pre-squash; `Verified:` line references the record.
- [ ] `check-traceability`: add the four new rules + fixes to the rules table.
- [ ] `ratchet`: tool-qualification note in setup checklist; retrofit inventory learns problems log + verification dir; template copies include problems.md.
- [ ] Commit `feat: DO-178C mechanics in skills`.

### Task 7: resolve-problem skill + templates

- [ ] New `skills/resolve-problem/SKILL.md`: PR-DRAFT minting, reproduce-as-failing-test (annotated), fix via develop-change, `status: resolved` flipped in the same merged change, hazard check via analyze-risks when the bug reveals one.
- [ ] New `templates/problems.md` (grammar header + empty log). `templates/sad.md` header gains LLR grammar; `templates/rmf.md` gains "Derived requirements assessment" section; `templates/AGENTS-block.md` gains coverage table, robustness rule, resolve-problem row, new config keys.
- [ ] Commit `feat: resolve-problem skill and template updates`.

### Task 8: README + verification + merge

- [ ] README: grammar table gains LLR/PR rows + derived note; workflow diagram gains resolve-problem; check-trace row mentions new rules; skills count 11.
- [ ] Full suite green (paste output); `git status` clean.
- [ ] **Independent review of this change** (per the new merge-change 6a): fresh subagent, diff + spec, findings resolved.
- [ ] Verification record `docs/verification/2026-07-20-do178c-mechanics.md`.
- [ ] merge-change sequence: merge main in, re-verify, signed squash (key touch), check-signing, ExitWorktree remove.

## Self-Review

- All 8 adopted mechanics map to tasks (HLR/LLR→3, derived→4, PRs→5+7, verification records→6+8, coverage→6, independence→6+8, verif-of-verif→6, tool qual→6).
- Rule names/config keys single-sourced in Global Constraints; transitive REQ rule explicit in Task 3.
- No placeholders; test cases fully enumerated in Tasks 2–5.
