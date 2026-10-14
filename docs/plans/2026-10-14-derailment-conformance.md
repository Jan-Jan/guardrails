# Derailment and the conformance loop Implementation Plan

**Goal:** `develop-change`'s derailment rule states when the conformance
review loop stops: only when a finding comes back after its fix was merged.
**Implements:** none (this repository has no SRS); delivers D1 below and
resolves PR-r6ypg9.
**Safety class:** not configured (this repository has no `.guardrails/config.yaml`).
**Verification:** `sh tests/run-tests.sh`

Context: tooth 1a of the self-hosting ratchet
(`docs/plans/2026-10-05-ratchet-gap-analysis.md`, §6), which brings the
problem backlog within its limits. PR-r6ypg9
(`docs/problems/2026-10-14-code-guidelines.md`) records that the derailment
rule, read literally, stops every change whose conformance reviews need a
second round.

## Decisions

**D1 — A conformance round counts toward derailment only through a recurring
finding.** The conformance reviews rerun until a round has nothing above low
(`develop-change`, "The conformance reviews"), so findings in a second round
are the loop working, not a stuck task. A finding a round reports again,
after the fix dispatched for it was merged, is a failed fix: the counterpart
of a task failing its red -> green cycle twice. It stops the loop and goes to
the user as the derailment rule states. New findings in a later round keep
the loop going, and no round count bounds it. Why: in `code-guidelines` the
CODE review had findings above low in rounds 1 and 2, all new, because the
round-1 fix covered only the cited lines; a round cap would have stopped a
loop that converged at round 3. Ruled 2026-10-14; a round cap, alone or
beside recurrence, was offered and declined.

The same finding is the same guideline clause reported at the same place.
The dispatcher decides it from the plan, where every finding and its
disposition is written as it arrives; the reviewer is fresh each round and
does not know the earlier rounds.

## Tasks

### T1 — The derailment rule names the recurring conformance finding

**Files touched:** skills/develop-change/SKILL.md,
skills/develop-change/references/rationale.md, tests/skills.bats,
docs/problems/2026-10-14-code-guidelines.md
**Parallel:** no (the only task)

Load the skill at `skills/develop-tdd/SKILL.md` in the change worktree (it is
not installed on this machine).

1. RED: add to `tests/skills.bats`, after the test
   "clanker: develop-change tells a stuck task to change approach", a test

   *(Code pruned at merge: 2 lines. Files touched: skills/develop-change/SKILL.md, skills/develop-change/references/rationale.md, tests/skills.bats, docs/problems/2026-10-14-code-guidelines.md.)*

   that reads `skills/develop-change/SKILL.md`, takes the
   `### Derailment: the one stop this skill adds` section with `section_of`
   (`tests/helpers.bash`), flattens it with `tr '\n' ' ' | tr -s ' '`, and
   asserts with `grep -qF`:
   - the third stop: `a conformance review reports a finding again after the fix dispatched for it was merged`;
   - that new findings do not count: `A conformance round with new findings is the loop working, not a repeat`.

   It also takes `### The conformance reviews` the same way and asserts
   `stops at the first finding that recurs (Derailment)`. Watch it fail on
   the missing text, not on a typo or a missing helper.
2. GREEN, in `skills/develop-change/SKILL.md`:
   - In "### Derailment: the one stop this skill adds", make the list three
     items: the red -> green item, the review item, and
     `a conformance review reports a finding again after the fix dispatched for it was merged.`
     Below the list add a paragraph:
     `A conformance round with new findings is the loop working, not a repeat:
     only a recurring finding counts, the same guideline clause at the same
     place. Compare against the findings already written in the plan; the
     reviewer is fresh each round and does not know them.`
   - In "### The conformance reviews", the sentence
     `Then run the reviews again; the first round with nothing above low is
     the last.` becomes
     `Then run the reviews again; the first round with nothing above low is
     the last. No round count bounds the loop; it stops at the first finding
     that recurs (Derailment).`
   - Keep the file under 2,000 words (`wc -w`; it is 1,350 before this task).
3. In `skills/develop-change/references/rationale.md`, `## Derailment`, add
   one paragraph: why a recurring finding and not a round count. A second
   round with new findings is what the loop is for; in `code-guidelines` the
   round-1 fix covered only the cited lines, round 2 found the same kind of
   problem elsewhere, and round 3 was the last. A finding that recurs after
   its fix shows the fixer cannot fix it as dispatched, which is the user's
   choice, as a task stuck at red -> green is.
4. In `docs/problems/2026-10-14-code-guidelines.md`, set PR-r6ypg9's
   `status: resolved` and append one line, flush left after the item's prose:
   `resolution: the derailment rule counts a conformance round only through a
   finding that recurs after its fix was merged (D1,
   docs/plans/2026-10-14-derailment-conformance.md); test "develop-change: a
   conformance finding that recurs after its fix stops the loop; a new one does
   not" in tests/skills.bats.` Match the resolution form other resolved items
   in `docs/problems/` use; read one first.
5. Run `tests/run-tests.sh tests/skills.bats` and `tests/run-tests.sh
   tests/develop-tdd.bats`; both green. Commit unsigned
   (`git -c commit.gpgsign=false commit`).

**T1 done** (556a976, merged e0b991c).

```
red -> green: develop-change: a conformance finding that recurs after its fix stops the loop; a new one does not — watched fail for the right reason before the implementation existed (failing at the grep for the third derailment stop; section_of resolved and ran)
```

## Conformance reviews

### Round 1 — CODE (docs/CODE_GUIDELINES.md)

**finding-1**: guideline, low — Names 4, "A concept has one name in every file, test and task of the change, and where the codebase already names it, that name" — tests/skills.bats:1162. The new test stores the flattened `### The conformance reviews` section in `loop`; the two existing tests that extract it (tests/skills.bats:1111, :1134) call it `section`.

**finding-2**: guideline, low — Comments 3, "A change comments at about the rate of the file it edits" — tests/skills.bats:1156-1164. Most tests in the file carry a why-comment after `verifies:`; the new one has none, and nothing says why it pins the "(Derailment)" cross-reference too.

note (reviewer): the SKILL.md line "last. No round count bounds the loop; it stops at the first finding that" was not reflowed to the file's wrap width.

verdict: 2 findings (0 high, 0 medium, 2 low); none above low.

### Round 1 — TEST (docs/TEST_GUIDELINES.md)

No findings.

note (reviewer): the new test asserts two of D1's three statements; "No round count bounds the loop" could be deleted, or a round cap added, and it would still pass. The floor ("fails when the behavior it `verifies:` breaks") sits in the file's unnumbered preamble, so this is a note, not a finding.

note (reviewer): Seams 1 names no seam for a test that reads skill prose (the gap code-guidelines' round-1 TEST review raised too).

verdict: 0 findings; none above low.

Both reviews have nothing above low, so round 1 is the last: the two low CODE findings and the reflow note are fixed (develop-refactor), and the floor note is fixed (develop-tdd); no further review is dispatched.

### Last-round fixes

- CODE finding-1: fixed — `loop` renamed `section` (3a45cd8, `tests/skills.bats`).
- CODE finding-2: fixed — a why-comment added to the new test (3a45cd8, `tests/skills.bats`).
- CODE reflow note: fixed — the paragraph reflowed, no word changed (3a45cd8, `skills/develop-change/SKILL.md`).
- TEST floor note: fixed — the test also asserts "No round count bounds the loop" (2fb90b7, `tests/skills.bats`).
- TEST seam note: no change — Seams 1's missing seam for skill-prose tests is the gap code-guidelines' round-1 TEST review already raised; it is not this change's.

```
red -> green: develop-change: a conformance finding that recurs after its fix stops the loop; a new one does not (no-round-count assertion) — the behavior already existed; watched fail at the new assertion with the sentence removed, pass with it restored
```

## Independent review (merge-change 6a), round 1

reviewer: independent subagent, fresh context (diff, plan, PR-r6ypg9, review checklist)
suite (reviewer's worktree, at 3e78687): 1..1401, 1401 ok, 0 not ok
verdict: approve; three findings, all low — the last review round.

**finding-1**: requirement, low — "Same place" (skills/develop-change/SKILL.md:94-96; D1) does not say what a place is. code-guidelines' round-1 and round-2 Simplicity 4 findings on the duplicated `section_of` extractor (docs/plans/2026-10-13-code-guidelines.md:914, :948) could be read as one finding recurring, which would stop the loop D1 says must continue.

**finding-2**: requirement, low — the third derailment stop counts a finding of any severity, while the loop's end rule ignores lows; a low that recurs in a round with nothing above low falls under both, and neither says which wins.

**finding-3**: code, low — the remedy "raise the effort level, or decompose the task differently" (SKILL.md:99-100) was written for a stuck task; for a recurring conformance finding the user's choices include accepting it or ruling against the clause.

**D2 — derived from D1 at finding-2: the recurrence stop counts only a finding above low.** A round with nothing above low has converged (`merge-change` 6a, `develop-change` "The conformance reviews"), so a low that recurs there is fixed or recorded as the last round's lows are, and does not derail. Why: D1's stop exists to bound a loop that does not converge, and that loop has. Taken by the dispatcher, 2026-10-14, as the reading D1's purpose fixes; put to the user at the hand-over.

All three are fixed in the last round (mechanical once D2 is stated): one dispatch, develop-tdd, tag fix-review1.

Last-round fixes (6b19879):

- finding-1: fixed — "A place is the file and lines the earlier finding cited; the same clause at another site is a new finding, not a recurrence." (`skills/develop-change/SKILL.md`)
- finding-2: fixed — D2 stated in the derailment section, its reason in `skills/develop-change/references/rationale.md`.
- finding-3: fixed — the remedy adds "accept the finding, or rule against the guideline clause" for a recurring conformance finding (`skills/develop-change/SKILL.md`).

```
red -> green: develop-change: a conformance finding that recurs after its fix stops the loop; a new one does not (D1, D2 assertions) — watched fail on the missing "A place is the file and lines" text before the skill edit
```
