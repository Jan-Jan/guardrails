**ADR-me39p4**: Skills state the compliance floor; each project states its preferences in one standalone guidelines file per kind, which overrides the shipped default whole.

Date: 2026-10-08
Status: accepted

## Context

Skills mixed two kinds of rule: what a standard or a gate needs (the floor)
and what makes a good default (where a test attaches, which doubles it may
use). Adopters could change neither without editing a skill, and an upgrade
would overwrite the edit. Projects differ on the second kind for good reasons:
a pure domain unit and an adapter unit beside it want different test rules.

## Decision

A rule is floor when a standard or a gate needs it, and it stays in the
skills. Every other rule is a preference, shipped as a default in
`templates/<KIND>_GUIDELINES.md` and tailored per project in
`docs/<KIND>_GUIDELINES.md`, or per unit in `<unit>/docs/<KIND>_GUIDELINES.md`.
A project or unit file replaces the file above it entirely: files are never
layered, and none refers to another. Each subagent reads exactly one file,
chosen by `guidelines-file.sh`. A guideline that contradicts the floor is a
finding against the guideline.

The test-doubles rule of ADR-4xh6cf and the seam rule of ADR-8ft3hb are, under
this decision, the shipped defaults of `TEST_GUIDELINES.md`, not floor.

Decisions D2, D3 and D6 of `docs/plans/2026-10-08-test-guidelines.md`.

## Cost

A unit file repeats everything it keeps from the project file, and a project
file everything it keeps from the default; a later improvement to the default
reaches a project only when it adopts it through `tailor-guidelines`. A
project that edits a clause owns its reason and examples.
