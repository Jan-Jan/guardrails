---
name: design-architecture
description: Create or evolve the IEC 62304 software architecture - SDD items traced to requirements, SOUP inventory, safety-class segregation, ADRs for real trade-offs. Use after requirements exist and before planning implementation of structural changes.
---

# Design Architecture

**Announce at start:** "Using the design-architecture skill."

Work happens **in a worktree** (`worktree-discipline`); update
the architecture ledger (`doc_sad`) and `docs/architecture/soup.md` (paths
from `.guardrails/config.yaml`); integrate via `merge-change`. New SDD/LLR
items go into this change's draft file
(`docs/architecture/DRAFT-<branch>-<slug>.md`); amendments to existing items
are edited in the dated file that defines them. `soup.md` stays a single
inventory file.

## Process

1. **Read first:** the SRS (which REQs does this design serve?), the RMF
   (which controls constrain it?), CONTEXT.md (use the project's language),
   and the existing SAD.
2. **Decompose into software items.** Each item is one responsibility with a
   defined interface. Item grammar (checked by `check-trace.sh`):

   `**SDD-…**: <software item and its responsibility>. traces: REQ-…[, REQ-…]`

   A new item gets its ID from `.guardrails/scripts/new-id.sh SDD` (or `LLR`)
   as you write it. Every item must trace to ≥1 requirement — a design item
   no requirement needs is YAGNI, delete it.
3. **Propose 2–3 architectures** for anything non-trivial, with trade-offs;
   lead with your recommendation. Present in sections and validate with the
   user before writing the final SAD.
4. **Class scaling** (from `safety_class`, per-item overrides allowed —
   record them in the item text):
   - **A** — architecture documentation optional; keep the SAD to a sketch.
   - **B** — architecture required: items, interfaces, and the REQ trace.
     LLRs optional — write them for items complex enough to warrant them.
   - **C** — additionally, **low-level requirements (LLRs)** per item,
     replacing free-form detailed-design prose. Under each SDD item write:

     `**LLR-…**: <directly codeable behavior>. satisfies: REQ-…[, REQ-…]`

     Directly codeable means an engineer implements it without further
     interpretation: interfaces, algorithms, error/failure behavior,
     resource limits — each as its own testable LLR. An LLR that has no
     parent REQ is marked `satisfies: derived` and goes to `analyze-risks`
     (the RMF must assess it). Tests then verify LLRs, and REQs are covered
     transitively (`check-trace.sh` understands this).
   - Segregation between items of different classes must be explicit: state
     the mechanism (process boundary, address space, hardware) and why it is
     adequate — a Class C item's failure modes must not reach through it.
     In a multi-unit repository this statement has a home with teeth: a
     cross-unit dependency is declared in the consumer's `depends_on:`, and
     depending on a lower-class unit requires `segregated_from:` in the
     consumer's config, citing the control or ADR that carries the mechanism
     — `check-units.sh` convicts an uncited entry (INCOMPLETE-SEGREGATION)
     and an uncovered class gap (MISCLASSED-DEPENDENCY). And the edge itself
     is a decision: run the "Declaring a dependency" interview
     (`grill-requirements`) before drawing it — a dependency on the diagram
     without that assessment is an unassessed supplier.
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
