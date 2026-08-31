<!-- guardrails:begin — managed by /ratchet; do not edit inside this block -->
# Guardrails: regulated development rules

This project is developed under IEC 62304 (software lifecycle) and ISO 14971
(risk management) discipline, enforced by the guardrails skill suite and the
check scripts in `.guardrails/scripts/`. Configuration: `.guardrails/config.yaml`.

## Non-negotiables

1. **All work happens in a git worktree** — documentation and code alike.
   Never commit directly to the base branch (the branch the primary,
   non-worktree checkout has checked out). Use the `worktree-discipline`
   skill before touching anything.
2. **Integration is a signed squash merge** performed by the `merge-change`
   skill. The base branch receives exactly one signed commit per change.
   Intermediate worktree commits may be unsigned; the squash commit must be
   signed and is verified with `check-signing.sh` before the worktree is
   cleaned up. There is no unsigned fallback.
3. **Traceability is mechanical.** A new requirement/hazard/control/design/
   problem item gets its ID the moment it is written: run
   `.guardrails/scripts/new-id.sh <PREFIX>` and paste what it prints. The ID
   is a random six-character token — `a3k9z2`, say — allocated against nothing,
   so two worktrees and two GitHub PRs never contend for one and nothing is
   renumbered at merge. Never invent an ID by hand. Document FILES are still
   finalized at merge: new items go into `docs/<area>/DRAFT-<branch>-<slug>.md`,
   renamed to `<merge-date>-<slug>.md` by `finalize-docs.sh`; existing items
   are edited in the dated file that defines them. Every new test declares
   what it verifies
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
`doc_problems` (config), carrying an `opened:` date while it
is open; open PRs are listed at each merge with their age, and past
the config's `problem_age_days` or `problem_open_max` the list stops being a
warning and fails the merge. The coverage gate runs the config's `coverage_command`
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
| Integrate to the base branch | `merge-change` |

## Check scripts (run from repo root)

- `.guardrails/scripts/new-id.sh PREFIX [COUNT]` — mint item IDs
- `.guardrails/scripts/check-ids.sh [--allow-draft-files]` — draft, duplicate and
  malformed IDs
- `.guardrails/scripts/check-trace.sh` — traceability gates
- `.guardrails/scripts/check-review.sh [--branch NAME]` — the change under merge
  has a verification record, written by this change, naming a reviewer, a
  verdict, what was reproduced, and a disposition per finding. Run from the
  change worktree (merge-change step 6c); on the base branch it exits 2, never 0
- `.guardrails/scripts/check-signing.sh [--strict] [RANGE]` — signature verification
- `.guardrails/scripts/finalize-docs.sh [--dry-run]` — rename draft ledger files

Exit code 0 = pass, 1 = violations (fix them, never bypass), 2 = setup error.

*Guardrails supports the quality management system; it is not itself
regulatory compliance. The quality manual and human sign-offs govern.*
<!-- guardrails:end -->
