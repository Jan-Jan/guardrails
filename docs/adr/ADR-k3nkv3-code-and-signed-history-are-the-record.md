**ADR-k3nkv3**: The code and the signed squash messages are the record of what was built and verified; the base branch keeps only terse documents that state intent or constraints.

Date: 2026-10-23
Status: accepted

## Context

Guardrails generated more record than code: in organisational-data-sovereignty
~1.2M words of Markdown against ~387k of code and tests, 70% of it history:
plans, verification records, problem narratives and design notes. That text
drifts from the code, and an agent reading it may take a superseded account
for the current one.

## Decision

- **Kept on the base branch:** glossary, guidelines, REQ/LLR, SDD, SOUP,
  HAZ/RC, ADRs, open problem reports. Each item is terse: one testable
  behavior, no rationale, history or implementation detail. An ADR holds its
  decision, context and consequences, and is rewritten, not amended.
- **Not kept:** plans (committed on the change branch, deleted before the
  gate), verification records and `.mutations/` scripts, resolved problem
  reports, and superseded or retired items. A deleted item leaves no
  annotation, so an item on the base branch is in force.
- **What a test cites:** A test verifies a REQ, LLR or ADR, never a problem
  report or a plan: an ID a test cites must outlive it. A test still naming a
  deleted item fails as a dangling reference; the change deletes it, or
  points it at the successor and lists it as
  `inherited: <test> — from <old ID>`. A regression test verifies the
  lowest-level item the defect broke: the LLR where one exists, else the REQ
  (or the RC's implementing REQ), added by the fixing change where none
  covered it.
- **The squash message is the record.** Its body states what and why, the
  items changed, the problems resolved and each review finding with its
  disposition. Its trailers are checked before hand-over and after signing:
  `Gate-tree:`, `Tests:` (in place of `Gate:`), `Mutation:` (anchor, mutant,
  killing test, one per mutant), `Resolves:`, `Base:`.
- **Comments state their reason** inline or cite an ADR, never a plan, record
  or problem report.
- **Terseness is reviewed, not counted:** the step 4 reviewer proposes a
  shorter wording for a changed item that carries more than its behavior.
- **`ratchet` upgrade** brings an existing project to this shape.

## Consequences

- IEC 62304 verification and problem-resolution records are the signed squash
  messages, listed by
  `git log --first-parent --format='%H %G? %s%n%b' <base>`; `%G?` reads `G`
  only where a signature verifier is configured. A rendering script waits for
  an audit that asks for a format.
- A reworded or replaced requirement leaves no trace on the base branch; the
  squash message that changed it does.
- No step prunes plans from the base branch: a plan never reaches it.
- ADR-3hsvvq states the checked trailers.
