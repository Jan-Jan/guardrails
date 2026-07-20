---
name: grill-requirements
description: Relentless one-question-at-a-time interview to define or refine software requirements (REQ items) for an IEC 62304 project, maintaining the glossary and ADRs as decisions crystallize. Use before designing or implementing any new capability, or when requirements are vague.
---

# Grill Requirements

**Announce at start:** "Using the grill-requirements skill to pin down requirements."

Interview the user relentlessly about the capability until you reach shared
understanding, writing requirements down as they crystallize. Requirements
work is a change like any other: do it **in a worktree**
(`worktree-discipline`) and integrate via `merge-change`.

## Interview rules

- **One question per message.** Multiple questions at once are bewildering.
- **Recommend an answer** with every question, with your reasoning.
- **Facts vs decisions:** if the answer is discoverable in the environment
  (code, docs, git history), look it up instead of asking. Decisions belong
  to the user — put each one to them and wait.
- Walk each branch of the decision tree; resolve dependencies between
  decisions one at a time.
- Stress-test with concrete scenarios: invent edge cases that force precise
  boundaries ("The pump loses power mid-bolus — what must the software
  guarantee on restart?").
- Do not start writing implementation code during the interview.

## Write requirements as they crystallize

Update `docs/requirements/srs.md` (path from `.guardrails/config.yaml`)
inline — don't batch:

- REQ items are **high-level requirements**: system-observable behavior,
  written from outside the software. The "how", per software item, belongs
  to low-level requirements (LLRs) in the SAD (`design-architecture`).
- Item form: `**<ID>**: The software shall <single, testable behavior>.`
- New items get **draft IDs**: `REQ-DRAFT-<branch>-<n>` (see
  `worktree-discipline`). Never hand-pick final numbers.
- **Derived requirements:** when a requirement exists only because of how
  the design turned out (no parent in system/user needs), do not invent a
  fake parent — mark it `satisfies: derived` and hand it to `analyze-risks`
  for assessment (the RMF must mention it; `check-trace.sh` enforces this
  as UNANALYZED-DERIVED).
- One behavior per requirement, phrased so a test can verify it. "Fast",
  "user-friendly", "robust" are not requirements — grill until they become
  numbers or observable behavior.
- A requirement that realizes a risk control ends with
  `(implements: RC-…)`. If the discussion surfaces a new hazard or control,
  switch to the `analyze-risks` skill, then come back.

## Maintain the glossary inline

`docs/CONTEXT.md` is the project glossary — definitions only, no
implementation detail.

- When the user uses a term that conflicts with the glossary, call it out
  immediately: "CONTEXT.md defines 'dose' as X, you seem to mean Y — which?"
- When language is fuzzy or overloaded, propose one canonical term, record
  the rejected synonyms under `_Avoid_`.
- Update CONTEXT.md the moment a term is resolved.

## Offer ADRs sparingly

Offer to record an ADR in `docs/adr/` only when all three hold:
1. **Hard to reverse.**
2. **Surprising without context.**
3. **The result of a real trade-off.**

Format: `docs/adr/NNNN-slug.md`, sequential numbering, 1–3 sentences
(context, decision, why). That's enough; skip ceremony.

## Class awareness

Read `safety_class` from `.guardrails/config.yaml`. For Class B and C, push
harder on failure behavior: for every capability ask "what must happen when
this fails?" — those answers become requirements too. For Class C, also grill
the boundaries between software items (they feed `design-architecture`).

## Done when

- The user confirms shared understanding (ask explicitly).
- Every new/changed REQ is a draft-ID item in the SRS, testable as written.
- Glossary updated; ADRs recorded where warranted.
- Hand off: risks → `analyze-risks`; design → `design-architecture`;
  implementation planning → `plan-change`; integration → `merge-change`.
