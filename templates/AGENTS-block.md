<!-- guardrails:begin — managed by /ratchet; do not edit inside this block -->
# Guardrails: regulated development rules

This project is developed under IEC 62304 (software lifecycle) and ISO 14971
(risk management) discipline, enforced by the guardrails skill suite and the
check scripts in `.guardrails/scripts/`. Configuration: `.guardrails/config.yaml`.

## Non-negotiables

1. **All work happens in a git worktree** — documentation and code alike.
   Never commit directly to the main branch. Use the `worktree-discipline`
   skill before touching anything.
2. **Integration is a signed squash merge** performed by the `merge-change`
   skill. Main receives exactly one signed commit per change. Intermediate
   worktree commits may be unsigned; the squash commit must be signed and is
   verified with `check-signing.sh` before the worktree is cleaned up. There
   is no unsigned fallback.
3. **Traceability is mechanical.** New requirement/hazard/control/design/
   problem items are minted as draft IDs (`<PREFIX>-DRAFT-<branch>-<n>`)
   inside the worktree and finalized to sequential IDs only at merge time by
   `finalize-ids.sh`. Every new test declares what it verifies
   (`verifies: <IDs>` — annotate the lowest level present: LLR where one
   exists, else REQ/RC; the parent REQ is covered transitively).
   `check-trace.sh` and `check-ids.sh` must pass before any merge.

## Verification rigor (by safety class, from config)

| | Coverage target | Robustness tests | LLRs | Independent review |
|---|---|---|---|---|
| **A** | none required | recommended | no | optional |
| **B** | statement | required (normal + abnormal per REQ/LLR) | per-item where complex | one reviewer |
| **C** | statement + decision | required | required per SDD item | thorough |

MC/DC beyond the class C target is optional extra credit. Requirements with
no parent in system needs are marked `satisfies: derived` and must be
assessed in the risk management file (UNANALYZED-DERIVED otherwise). Every
bug becomes a problem report (`resolve-problem` skill) in the log at
`doc_problems` (config); open PRs are listed at each merge and never
silently forgotten. The coverage gate runs the config's `coverage_command`
when one is configured — projects without one document why in their setup
notes.

## Workflow map

| I want to… | Use skill |
|---|---|
| Bootstrap/tighten project setup | `ratchet` |
| Define or refine requirements | `grill-requirements` |
| Analyze hazards and risk controls | `analyze-risks` |
| Design architecture / record SOUP | `design-architecture` |
| Plan an implementation | `plan-change` |
| Start any change | `worktree-discipline` |
| Implement (TDD) | `develop-change` |
| Handle a bug / anomaly | `resolve-problem` |
| Check traceability | `check-traceability` |
| Confirm work is done | `verify-before-merge` |
| Integrate to main | `merge-change` |

## Check scripts (run from repo root)

- `.guardrails/scripts/check-ids.sh [--allow-drafts] [--base REF]` — draft/duplicate IDs
- `.guardrails/scripts/check-trace.sh` — traceability gates
- `.guardrails/scripts/check-signing.sh [--strict] [RANGE]` — signature verification
- `.guardrails/scripts/finalize-ids.sh [--dry-run] [--base REF]` — mint final IDs

Exit code 0 = pass, 1 = violations (fix them, never bypass), 2 = setup error.

*Guardrails supports the quality management system; it is not itself
regulatory compliance. The quality manual and human sign-offs govern.*
<!-- guardrails:end -->
