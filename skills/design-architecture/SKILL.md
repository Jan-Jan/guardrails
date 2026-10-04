---
name: design-architecture
description: Create or evolve the IEC 62304 software architecture - SDD items traced to requirements, SOUP inventory, safety-class segregation, ADRs for real trade-offs. Use after requirements exist and before planning implementation of structural changes, or when a problem report's root cause turns out to be the design itself.
---

# Design Architecture

**Announce at start:** "Using the design-architecture skill."

## Preconditions

- You are in a worktree (`worktree-discipline`). Integrate through
  `merge-change`.
- The requirements this design serves exist in the SRS. If they do not, run
  `grill-requirements` first.
- Read `safety_class` and the ledger paths (`doc_sad`, the SOUP inventory
  `docs/architecture/soup.md`) from `.guardrails/config.yaml`.

## Steps

**Where items go.** Write new SDD and LLR items into this change's draft file,
`docs/architecture/DRAFT-<branch>-<slug>.md`. Edit an amendment to an existing
item in the dated file that defines it. Keep `soup.md` a single inventory
file.

1. **Read first:** the SRS (which REQs does this design serve?), the RMF
   (which controls constrain it?), `CONTEXT.md` (use the project's language),
   and the existing SAD.
2. **Decompose into software items.** Each item is one responsibility with a
   defined interface. Item grammar, checked by `check-trace.sh`:

   `**SDD-…**: <software item and its responsibility>. traces: REQ-…[, REQ-…]`

   Get a new item's ID from `.guardrails/scripts/new-id.sh SDD` (or `LLR`)
   as you write it. Every item traces to at least one requirement. Delete a
   design item that no requirement needs.
3. **Propose 2 or 3 architectures** for anything non-trivial, with their
   trade-offs, and lead with your recommendation. Present them in sections and
   confirm with the user before writing the final SAD.
4. **Scale to the class** from `safety_class`. A per-item override is allowed;
   record it in the item text.
   - **A:** architecture documentation is optional. Keep the SAD to a sketch.
   - **B:** architecture is required: items, interfaces and the REQ trace.
     LLRs are optional; write them for items complex enough to need them.
   - **C:** additionally, write **low-level requirements (LLRs)** under each
     SDD item, in place of free-form detailed-design prose:

     `**LLR-…**: <directly codeable behavior>. satisfies: REQ-…[, REQ-…]`

     Directly codeable means an engineer implements it without further
     interpretation: interfaces, algorithms, error and failure behavior,
     resource limits, each as its own testable LLR. Mark an LLR with no parent
     REQ `satisfies: derived` and send it to `analyze-risks`; the RMF must
     assess it. Tests verify LLRs, and `check-trace.sh` covers the REQs
     transitively.
5. **State segregation** between items of different classes: name the
   mechanism (process boundary, address space, hardware) and why it is
   adequate. A Class C item's failure modes must not propagate through it.

   In a multi-unit repository, declare a cross-unit dependency in the
   consumer's `depends_on:`. A dependency on a lower-class unit requires
   `segregated_from:` in the consumer's config, citing the control or ADR that
   states the mechanism. `check-units.sh` rejects an uncited entry
   (INCOMPLETE-SEGREGATION) and an uncovered class gap
   (MISCLASSED-DEPENDENCY).

   Before drawing a dependency edge, run the "Declaring a dependency"
   interview (`grill-requirements`). A dependency on the diagram without that
   assessment is an unassessed supplier.
6. **Record SOUP** in `soup.md`: every third-party component the software
   depends on, with its exact version, its role, the requirements it supports,
   and the known anomalies relevant to safety. Adding or upgrading SOUP is a
   design decision: check its failure modes against the RMF, and run
   `analyze-risks` for each new hazard.
7. **Write an ADR** in `docs/adr/` only for a decision that is hard to
   reverse, surprising without context, and a real trade-off: all three.
   Examples are technology lock-in, integration patterns, and a deliberate
   deviation from the obvious path.

## Red flags

| Thought | Reality |
|---|---|
| "This item is useful, the requirement can follow" | An item that traces to no REQ is deleted. Run `grill-requirements` if the need is real. |
| "One architecture is obvious, skip the alternatives" | For anything non-trivial, present 2 or 3 with trade-offs. |
| "The LLR has no parent, it is fine" | Mark it `satisfies: derived` and run `analyze-risks`. |
| "The dependency is a line on the diagram" | Run the "Declaring a dependency" interview first. |
| "Upgrading the library is a version bump" | It is a design decision. Check its failure modes against the RMF. |
| "Record this choice as an ADR" | Only when it is hard to reverse, surprising, and a real trade-off. |

## Done when

- Every touched SDD item traces to existing REQs, and `check-trace.sh`
  reports no UNTRACED-DESIGN or DANGLING-REF for them.
- The SOUP inventory matches the dependency manifests (`package.json`,
  `Cargo.toml`, `requirements.txt`): diff it against them.
- Hand off implementation planning to `plan-change`.
