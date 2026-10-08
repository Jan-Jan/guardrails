**ADR-8ft3hb**: A test attaches only to an interface that a REQ or LLR describes; a deeper interface gets a direct test only after it earns an LLR.

Date: 2026-10-08
Status: accepted

## Context

A suite that tests every function fixes the implementation in place: a
refactor that keeps every behavior still breaks the tests pinned to the
functions it moved. `develop-change` already requires every test to declare
`verifies: <IDs>`, and its class C rule already puts tests at each SDD item's
interface, but nothing stated where a test may attach in classes A and B, or
when an internal deserves tests of its own.

## Decision

A test calls only an interface that a REQ or LLR describes. A private helper
is covered through the interface above it. Where a project has no LLRs, the
seam is the REQ level, the public interface. A user journey is a REQ only
when it states an outcome none of its steps' REQs state.

A deeper interface earns an LLR, through `design-architecture`, when one of
its cases cannot be triggered from the REQ interface without faking code the
project owns, when its cases multiply past enumeration from that interface, or
when it is maths, parsing, encoding or a numerical transform with a contract
of its own. A case reachable from the REQ interface is tested there, even
where a deeper seam would be easier.

Decisions D1 to D3 of `docs/plans/2026-10-07-test-seams.md`.

## Cost

Adding a test seam means writing an LLR, which is design work. That friction
is the point: it is the price of freezing an interface, paid once, in the
open. Mutation testing, not line coverage, is the evidence that tests at the
seam reach the internals below it; a surviving mutant calls for a test at the
seam or for deleting dead code, never for a test below the seam.

Amended by ADR-me39p4 (2026-10-08): this rule is the shipped default of
`templates/TEST_GUIDELINES.md`, which a project may change in its own
`docs/TEST_GUIDELINES.md`; it is not part of the compliance floor.
