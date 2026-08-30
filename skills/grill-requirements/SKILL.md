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

Update the requirements ledger (`doc_srs` in `.guardrails/config.yaml`)
inline — don't batch. **New items go into this change's draft file**,
`docs/requirements/DRAFT-<branch>-<slug>.md` (merge-change renames it to the
merge date). **Amendments to existing requirements are edited in the dated
file that defines them** — definitions never move. On single-file projects
(`doc_srs` points at a file), edit that file.

- **Probe for overlap before you write.** Dispatch a subagent (your harness's
  subagent mechanism — e.g. a `Task` tool, an `/agents` command) to search the
  requirements ledger for items that already cover this behavior. It returns
  IDs, one-line summaries and `file:line` — nothing else. The ledger itself
  must not enter this conversation's context. Overlap, ambiguity or
  contradiction goes to the user and is resolved with them before the new item
  is written.
- **Supersession is recorded, never silent.** A new requirement may supersede
  an old one — that is normal; performing it by deletion is not. The
  superseded item keeps its place in the file that defines it and gains
  `superseded-by: <new ID>`; the new item carries `supersedes: <old ID>`.
  Because the old item stays where it is, `check-trace.sh` still resolves
  every reference to it and the ledger still reads as a history.
- **The supersession annotations are annotations, not exemptions.** The
  superseded item keeps its definition, so it keeps demanding a test:
  `check-trace.sh`'s MISSING-TEST gate walks every defined item and knows
  nothing about `superseded-by:`. Satisfy both items with the one test that
  already exists — **the test that verified the superseded item gains the new
  ID alongside the old**: `verifies: <old ID>, <new ID>`. MISSING-TEST is then
  clean for both, the history survives, and no gate has to change.
- **Superseding is not retiring.** Supersede when the behavior still exists in
  some form — a rewording, a narrowing, a replacement — so one test can
  honestly verify both IDs. Behavior that is genuinely gone is a *retirement*,
  a different operation this skill does not cover today: with no
  `superseded-by:` exemption in `check-trace.sh`, a retired item still demands
  a test for behavior that no longer exists. Teaching the gate that exemption
  is a separate change with its own tests. Until it lands, put a retirement to
  the user as its own decision rather than dressing it as a supersession.
- REQ items are **high-level requirements**: system-observable behavior,
  written from outside the software. The "how", per software item, belongs
  to low-level requirements (LLRs) in the SAD (`design-architecture`).
- Item form: `**<ID>**: The software shall <single, testable behavior>.`
- A new item gets its ID from `.guardrails/scripts/new-id.sh REQ` as you
  write it (see `worktree-discipline`). Never invent one by hand.
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

## Probe the architecture

Before a requirement is settled, dispatch a subagent to read the architecture
ledger (`doc_sad`) and answer three questions. It returns the answers with
`file:line` citations — not the document.

1. **Does an existing software item already own this behavior?** Then this is
   an amendment to that item's LLRs, not a new item.
2. **Does the requirement as worded force a structure the SAD forbids?**
   Segregation boundaries are the usual casualty.
3. **Does satisfying it need a new software item, or new SOUP?**

On a contradiction, say so and hand off to `design-architecture`. **Never edit
the SAD from this skill** — the REQ/LLR split is what keeps design decisions
inside the skill that has the segregation and SOUP discipline. ADRs stay on
the three-part test above.

## Class awareness

Read `safety_class` from `.guardrails/config.yaml`. For Class B and C, push
harder on failure behavior: for every capability ask "what must happen when
this fails?" — those answers become requirements too. For Class C, also grill
the boundaries between software items (they feed `design-architecture`).

## Done when

- The user confirms shared understanding (ask explicitly).
- Every overlap, ambiguity or contradiction the probes surfaced is
  resolved with the user — superseded items annotated both ways and their
  test carrying both IDs, SAD contradictions handed to
  `design-architecture`. An unresolved overlap means the interview is not
  done.
- Every new/changed REQ is a draft-ID item in the SRS, testable as written.
- Glossary updated; ADRs recorded where warranted.
- Hand off: risks → `analyze-risks`; design → `design-architecture`;
  implementation planning → `plan-change`; integration → `merge-change`.
