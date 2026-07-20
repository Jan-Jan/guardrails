---
name: design-architecture
description: Create or evolve the IEC 62304 software architecture - SDD items traced to requirements, SOUP inventory, safety-class segregation, ADRs for real trade-offs. Use after requirements exist and before planning implementation of structural changes.
---

# Design Architecture

**Announce at start:** "Using the design-architecture skill."

Work happens **in a worktree** (`worktree-discipline`); update
`docs/architecture/sad.md` and `docs/architecture/soup.md` (paths from
`.guardrails/config.yaml`); integrate via `merge-change`.

## Process

1. **Read first:** the SRS (which REQs does this design serve?), the RMF
   (which controls constrain it?), CONTEXT.md (use the project's language),
   and the existing SAD.
2. **Decompose into software items.** Each item is one responsibility with a
   defined interface. Item grammar (checked by `check-trace.sh`):

   `**SDD-…**: <software item and its responsibility>. traces: REQ-…[, REQ-…]`

   New items use **draft IDs**; every item must trace to ≥1 requirement — a
   design item no requirement needs is YAGNI, delete it.
3. **Propose 2–3 architectures** for anything non-trivial, with trade-offs;
   lead with your recommendation. Present in sections and validate with the
   user before writing the final SAD.
4. **Class scaling** (from `safety_class`, per-item overrides allowed —
   record them in the item text):
   - **A** — architecture documentation optional; keep the SAD to a sketch.
   - **B** — architecture required: items, interfaces, and the REQ trace.
   - **C** — additionally, detailed design per item: interfaces, algorithms,
     error/failure behavior, and resource limits in the item's subsection.
   - Segregation between items of different classes must be explicit: state
     the mechanism (process boundary, address space, hardware) and why it is
     adequate — a Class C item's failure modes must not reach through it.
5. **SOUP inventory:** every third-party component the software depends on
   goes in `soup.md` — exact version, role, the requirements it supports,
   known anomalies relevant to safety. Adding/upgrading SOUP is a design
   decision: check its failure modes against the RMF (new hazards → run
   `analyze-risks`).
6. **ADRs** in `docs/adr/` only for decisions that are hard to reverse AND
   surprising without context AND a real trade-off (technology lock-in,
   integration patterns, deliberate deviations from the obvious path).

## Done when

- Every touched SDD item traces to existing REQs; `check-trace.sh` reports no
  UNTRACED-DESIGN / DANGLING-REF for them.
- SOUP inventory reflects reality (`diff` it against the actual manifest —
  package.json, Cargo.toml, requirements.txt).
- Hand off: implementation planning → `plan-change`.
