---
name: grill-requirements
description: Relentless one-question-at-a-time interview to define or refine software requirements (REQ items) for an IEC 62304 project, maintaining the glossary and ADRs as decisions crystallize. Use before designing or implementing any new capability, or when requirements are vague.
---

# Grill Requirements

**Announce at start:** "Using the grill-requirements skill to define requirements."

## Preconditions

- You are in a change worktree (`worktree-discipline`). Requirements work is a
  change like any other, and `merge-change` integrates it.
- Read `doc_srs`, `doc_sad` and `safety_class` from `.guardrails/config.yaml`.
- Where `.guardrails/units.yaml` exists, the unit rules under "Declaring a
  dependency" and "The glossary" apply.

## Steps

Interview the user about the capability until you reach shared understanding.
Write each requirement down as soon as it is settled.

### The interview

- Ask one question per message.
- Recommend an answer with every question, and give your reasoning.
- Look up a fact the environment answers (code, docs, git history) instead of
  asking it. Put each decision to the user and wait for the answer.
- Walk each branch of the decision tree. Resolve dependencies between
  decisions one at a time.
- Stress-test answers with concrete scenarios: invent edge cases that force a
  precise boundary.
- Class B and C: for every capability, ask "what must happen when this
  fails?" Each answer is a requirement too.
- Class C: also question the boundaries between software items. The answers
  are inputs to `design-architecture`.
- Write no implementation code during the interview.

### Probe before you write

Run both probes before a requirement is settled. Each is a subagent dispatch
(a `Task` or `Agent` tool, an `/agent` command, whatever your harness offers).
The ledgers must not enter this conversation's context.

- **Overlap.** The subagent finds the items that already cover the behavior
  with `.guardrails/scripts/find-items.sh list --kind REQ`, then
  `find-items.sh show ID` for each candidate, and does not read ledger files
  whole. It returns IDs, one-line summaries and `file:line`, nothing else. Put every overlap, ambiguity or contradiction to
  the user and resolve it with them before you write the new item.
- **Architecture.** The subagent finds the items in `doc_sad` with
  `.guardrails/scripts/find-items.sh list --kind SDD --kind LLR`, reads each
  candidate with `find-items.sh show ID`, and answers three questions, with
  `file:line` citations and not the document:
  1. Does an existing software item already own this behavior? Then the
     change amends that item's LLRs and adds no new item.
  2. Does the requirement as worded force a structure the SAD forbids?
     Segregation boundaries are the most common conflict.
  3. Does satisfying it need a new software item, or new SOUP?

  On a contradiction, state it and hand off to `design-architecture`. Never
  edit the SAD from this skill.

### Write requirements as they are settled

Update the requirements ledger (`doc_srs`) one item at a time. Do not batch.

- Write new items in this change's draft file,
  `docs/requirements/DRAFT-<branch>-<slug>.md`. `merge-change` renames it to a
  dated name when it finalizes the draft.
- Edit an amendment to an existing requirement in the dated file that defines
  it. Definitions never move. Where `doc_srs` points at a single file, edit
  that file. An amendment that supersedes or retires an item follows
  "Supersession" below.
- Item form: `**<ID>**: The software shall <single, testable behavior>.`
- Get each new item's ID from `.guardrails/scripts/new-id.sh REQ` as you write
  it (`worktree-discipline`). Never write an ID by hand.
- A REQ item is a high-level requirement: system-observable behavior, written
  from outside the software. The "how", per software item, belongs to the
  low-level requirements (LLRs) in the SAD (`design-architecture`).
- One behavior per requirement, phrased so a test can verify it. "Fast",
  "user-friendly" and "robust" are not requirements: question the user until
  each becomes a number or an observable behavior.
- **Derived requirements:** a requirement that exists only because of how the
  design turned out has no parent in system or user needs. Do not invent a
  parent. Mark it `satisfies: derived` and send it to `analyze-risks`: an
  `assesses:` line in the RMF must name it, and `check-trace.sh` reports
  UNANALYZED-DERIVED otherwise.
- A requirement that realizes a risk control ends with `(implements: RC-…)`.
  When the discussion surfaces a new hazard or control, switch to
  `analyze-risks`, then return.

### Supersession

Read `references/supersession.md` before you record a supersession or put a
retirement to the user.

- Record a supersession. Never perform it by deletion. The superseded item
  stays in the file that defines it and gains `superseded-by: <new ID>`; the
  new item contains `supersedes: <old ID>`.
- The superseded item still requires a test. Add the new ID to the test that
  verified the superseded item: `verifies: <old ID>, <new ID>`.
- Supersede only when the behavior still exists in some form: a rewording, a
  narrowing, a replacement. Behavior that is gone is a retirement, which this
  skill does not cover: `check-trace.sh` has no `superseded-by:` exemption.
  Until a change that adds that exemption is merged, put a retirement to the
  user as its own decision, and do not record it as a supersession.

### Declaring a dependency (multi-unit repositories)

`depends_on:` is a decision, not a config line. Before an edge is added to the
consumer's config, walk the provider's artefacts with the user, one question
at a time:

- its export surface: `.guardrails/scripts/check-units.sh --exports <provider>`
  lists every exported REQ with its defining file. Is the behavior you need on
  it?
- its RMF: does its risk analysis consider this use, or is your use case
  outside every analyzed situation?
- its ADRs: a recorded decision may foreclose your requirement.
- its open problem reports: the known anomalies of a supplied component.
- transitively its SOUP: your dependency's dependencies are yours.

Write a gap found here as a consumer REQ with `expects: <unit>` on its own
line. The unit must be a declared dependency. Put `opened: YYYY-MM-DD` on its
own line in the same item block; without a usable date, the consumer's own
gate reports INCOMPLETE-EXPECTATION. The expectation is met when the provider
defines an exported REQ with `satisfies:` naming your REQ. Until then the
consumer's run reports UNMET-EXPECTATION, and the provider's run reports the
count of open expectations against it. Never record the gap as a problem
report in the provider's ledger: a need is not an anomaly.

### The glossary

`docs/CONTEXT.md` is the project glossary: definitions only, no
implementation detail.

- When the user uses a term that conflicts with the glossary, state the
  conflict at once: "CONTEXT.md defines 'dose' as X, you seem to mean Y —
  which?"
- When a term is fuzzy or overloaded, propose one canonical term and record
  the rejected synonyms under `_Avoid_`.
- Update CONTEXT.md as soon as a term is resolved.
- Multi-unit: write to the unit's own `docs/CONTEXT.md` by default;
  the root glossary owns interface terms. Escalate a term to the root
  glossary the moment it appears in an exported REQ or an `expects:` item:
  add it there, and keep it in the unit glossary.
  Challenge a term that a unit glossary and the root glossary define with
  different meanings, like any other conflict.
  Two units disagreeing internally is not a conflict.

### ADRs

Offer to record an ADR in `docs/adr/` only for a decision that is all three:

1. hard to reverse;
2. surprising without context;
3. the result of a real trade-off.

Mint the ID with `.guardrails/scripts/new-id.sh ADR`. Write one decision
per file, `docs/adr/ADR-<token>-<slug>.md`, opening with the item line
`**ADR-<token>**: <the decision in one sentence>`, then one to three sentences
(context, decision, why). Cite an ADR by its ID. `new-id.sh` exits 2 until
`ADR` is in `id_prefixes`; add it there first. In an existing project, read
"`ADR` is a declared prefix" in `ratchet`'s `references/upgrade-notes.md`
before adding it: it states which findings the existing ADRs produce.

Multi-unit: a decision that a unit cites by ID is in that unit's
`docs/adr/`, which `check-trace.sh` reads for the unit. A decision that spans
units is in the root `docs/adr/`. A unit's documents cite a root ADR by path,
because `check-trace.sh` scoped to the unit does not read the root. A
`segregated_from:` entry may cite it by ID, `(ADR-<token>)`, because
`check-units.sh` resolves it.

## Red flags

| Thought | Reality |
|---|---|
| "I'll ask the three open questions in one message" | One question per message. |
| "The user will want X, I'll write it down" | A decision is the user's. Put it to them and wait. |
| "I'll read the ledger myself to check for overlap" | Dispatch the probe. The ledger stays out of this context. |
| "The old requirement is wrong, I'll delete it" | Supersede it: both annotations, both IDs on the one test. |
| "The SAD needs a small fix, I'll edit it here" | Hand off to `design-architecture`. |
| "The parent need is obvious, I'll name one" | No parent: `satisfies: derived`, then `analyze-risks`. |

## Done when

- The user confirms shared understanding. Ask explicitly.
- Every overlap, ambiguity or contradiction the probes found is resolved with
  the user: superseded items annotated both ways and their test annotated with
  both IDs, SAD contradictions handed to `design-architecture`. An unresolved
  overlap means the interview is not done.
- Every new or changed REQ is in the SRS with an ID from `new-id.sh`, testable
  as written.
- The glossary is updated, and ADRs are recorded where the three-part test is
  met.
- Hand off: risks to `analyze-risks`; design to `design-architecture`;
  implementation planning to `plan-change`; integration to `merge-change`.

## References

- `references/supersession.md` — read when a new item supersedes or retires an
  existing one, or before proposing to change the supersession rules.
- `references/rationale.md` — read when a rule here seems wrong for your case,
  or before proposing to change one.
