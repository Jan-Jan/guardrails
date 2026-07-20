# Software Architecture

<!--
Item grammar (enforced by .guardrails/scripts/check-trace.sh):

  **SDD-NNN**: <software item and its responsibility>. traces: REQ-NNN[, REQ-NNN]

Low-level requirements (design data — the directly codeable refinement of
the high-level REQs), written under the software item they belong to:

  **LLR-NNN**: <directly codeable behavior>. satisfies: REQ-NNN[, REQ-NNN]
  **LLR-NNN**: <behavior with no parent requirement>. satisfies: derived

- Every design item must trace to at least one requirement.
- Every LLR satisfies a REQ or is marked derived; derived LLRs must be
  assessed in the risk management file.
- Tests verify LLRs where they exist; the parent REQ is covered
  transitively.
- Class C items require LLRs (interfaces, algorithms, error behavior,
  resource limits — one testable LLR each); class B optional per item.
- If an item's safety class differs from the project default, state it in the
  item text (IEC 62304 allows per-item classification).
- Mint new items as drafts in worktrees (see SRS header).
-->

## Overview

<!-- System decomposition, key interfaces, and the segregation rationale
     between items of different safety classes (if any). -->

## Software items

## Interfaces
