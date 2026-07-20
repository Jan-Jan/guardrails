# DO-178C Mechanics for Guardrails — Design

**Date:** 2026-07-20
**Status:** Validated with project owner
**Positioning:** Guardrails stays an IEC 62304 / ISO 14971 suite. It borrows
DO-178C's strongest mechanics; no aviation branding, no dual-standard regime.

## Adopted mechanics

Requirements side: HLR/LLR requirement levels; derived requirements fed back
to safety analysis; problem reports / change control; verification records
(results, not just test existence).

Verification side: coverage objectives scaled by safety class; independent
review (verifier ≠ author); verification of verification (folded into the
independent review); tool qualification note for the check scripts
(DO-330-lite).

Implementation approach: **evolve in place** — extend existing skills,
scripts, tests, templates. One worktree, one signed squash merge.

## 1. Grammar and config extensions

New ID prefixes, appended to `id_prefixes` (draft/finalize/duplicate handling
is automatic since the scripts iterate the config list):

- **LLR** — low-level requirements. Defined in the SAD under their SDD item
  (DO-178C: LLRs are design data):
  `**LLR-NNN**: <directly codeable behavior>. satisfies: REQ-NNN[, REQ-NNN]`
  Required at class C (replaces the vaguer "detailed design" prose), optional
  at class B for complex items, absent at A.
- **PR** — problem reports, in `docs/problems/log.md`:
  `**PR-NNN**: <symptom>. affects: <IDs>. status: open|resolved`

**Derived requirements:** a REQ or LLR with no parent in system requirements
is written `satisfies: derived` and MUST be assessed in the RMF (DO-178C
rule: derived requirements go to the safety assessment).

Config additions (flat schema, same awk parser):

```yaml
doc_problems: docs/problems/log.md
coverage_command:
  - make coverage
```

Coverage *targets* are guidance in the AGENTS block, judged by the verifier —
not parsed mechanically (report formats vary too much for POSIX sh):
A: none required · B: statement · C: statement + decision · MC/DC optional
beyond.

## 2. Script changes (TDD, new bats tests)

`check-trace.sh` gains four rules:

| Rule | Trigger |
|---|---|
| `UNSATISFIED-LLR LLR-…` | LLR block lacks `satisfies:` naming an existing REQ and is not `satisfies: derived` |
| `UNANALYZED-DERIVED <ID>` | REQ/LLR marked derived that never appears in the RMF |
| `MISSING-TEST LLR-…` | LLR with no `verifies:` reference in test_paths |
| `UNRESOLVED-PR PR-…` | **warning only, exit still 0** — open PRs listed at every merge, never force-closed |

The existing `MISSING-TEST REQ-…` rule becomes **transitive**: a REQ counts
as tested if a test `verifies:` it directly OR if a tested LLR `satisfies:`
it — otherwise annotating at the lowest level (develop-change's rule) would
false-positive every refined REQ. New test covers this.

Class scaling stays out of the scripts: rules only fire on items that exist.
The obligation to *write* LLRs at class C is skill guidance.

`finalize-ids.sh`, `check-ids.sh`: no code changes — new prefixes come from
config; add tests proving LLR/PR draft finalization and duplicate detection.
`check-signing.sh`: unchanged.

New tests: LLR satisfies/derived paths; derived-not-in-RMF failure; derived
LLR mentioned in RMF passes; LLR missing test; open-PR warning (exit 0);
resolved-PR silence; LLR/PR draft finalize.

## 3. Skill and template updates

- **grill-requirements** — REQs are explicitly high-level requirements. New
  rule: requirements that exist only because of design shape get marked
  `derived` (no fake parents) and are handed to `analyze-risks`.
- **design-architecture** — class C writes LLRs under each SDD item; class B
  optional for complex items. Each LLR directly codeable.
- **develop-change** — tests annotate the lowest requirement level present
  (`verifies: LLR-…` where LLRs exist, else the REQ). Robustness rule at
  class B/C: every REQ/LLR needs normal-case AND abnormal-input tests.
- **analyze-risks** — derived-requirements intake: assess hazard impact of
  each derived item, record in the RMF (what `UNANALYZED-DERIVED` checks).
- **New skill `resolve-problem`** — problem-report workflow: mint
  `PR-DRAFT-…` with symptom + `affects:`; reproduce as failing annotated
  test; fix via `develop-change`; flip `status: resolved` in the same change
  that merges the fix.
- **Templates** — `sad.md` header gains LLR grammar; new
  `templates/problems.md`; `rmf.md` header notes the derived-requirements
  assessment section; `AGENTS-block.md` adds coverage targets table,
  robustness rule, `resolve-problem` in the workflow map, and the new
  config keys.

## 4. The merge gate

- **verify-before-merge** — two new gate items: run `coverage_command` (if
  configured) and judge against the class target (shortfall = failure unless
  the user explicitly accepts a documented gap); check every Implements: ID
  has normal + robustness tests (class B/C).
- **merge-change** — two steps between re-verify (6) and signed squash (7):
  - **6a Independent review**: fresh subagent (or human) with only the diff,
    relevant SRS/RMF/SAD excerpts, and the plan — no implementation
    narrative. Checklist: code satisfies each claimed REQ/LLR; tests verify
    what they annotate (verification of verification); robustness cases
    present; unmarked derived behavior. Findings block. Rigor scales A/B/C.
  - **6b Verification record**: write `docs/verification/<date>-<branch>.md`
    with actual outputs (test totals, coverage summary, check results,
    reviewer verdict), committed before the squash; the commit's `Verified:`
    line references the record.
- **ratchet** — setup checklist gains the tool-qualification note: check
  scripts are verification tools; qualification basis = the guardrails bats
  suite at the recorded `guardrails_version`; script updates re-record
  version + evidence. Retrofit gap analysis learns the problems log and
  verification directory.

## Out of scope

Aviation document set (PSAC/SDP/SVP), DAL A–E naming, MC/DC enforcement,
mechanical coverage parsing, model-based/OO/formal-methods supplements
(DO-331/332/333).
