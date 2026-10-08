# Units Skill Updates Implementation Plan

**Goal:** The skills catch up with the unit machinery merged at 0a35669 —
`/ratchet` interviews and writes the manifest and per-unit configs (D9),
`merge-change` consumes the impact set mechanically (D6/D12), and
`grill-requirements`/`design-architecture` carry the dependency-assessment
interview (D10) and the glossary escalation (D13).

**Implements:** none — the repository is not yet self-hosted (no minted REQ
IDs; docs/plans/2026-08-22-ratchet-gap-analysis.md). The binding contract is
the **14 named test obligations** below, same convention as
docs/plans/2026-09-04-units-implementation.md: each obligation name appears in
exactly one `@test` title in `tests/skills.bats`, audited mechanically (see
"Obligation audit").

**Safety class:** n/a (the toolkit itself; qualified by its own suite).

**Verification:** `sh tests/run-tests.sh` — baseline 588 tests green at
0a35669 (fresh worktree run, exit 0). Every merge gate reads this suite.

**Sources of truth (read, do not restate from memory):**
- D6, D9, D10, D12, D13 in `docs/plans/2026-08-26-monorepo-support.md`
- items 5–6 and "Findings vocabulary" in `docs/plans/2026-09-03-units-architecture.md`
- the header comment of `scripts/check-units.sh` (flag semantics are quoted
  below and were verified against the script at 0a35669)

## Implementation decisions

1. **All tasks serial.** Every task adds tests to `tests/skills.bats`, so no
   two tasks have disjoint file sets. T1 → T2 → T3 → T4, each in its own task
   worktree, merged by the dispatcher before the next dispatch.
2. **Test idiom matches the file.** `tests/skills.bats` is content lints:
   bare `grep -q '<load-bearing phrase>' "$skill"` lines, a comment block
   saying why the phrase is load-bearing, `# verifies:` citing the decision
   (these tests have no PR item; cite `D9 (docs/plans/2026-08-26-monorepo-support.md)`
   etc.). No `[[ ]]` anywhere — grep is a plain command, errexit binds it on
   bash 3.2, and it is the file's existing idiom.
3. **Pinned phrases are contractual.** Each test greps phrases that the task's
   prose edit introduces verbatim. The plan lists both; an executor who
   rewords the prose must reword the pin in the same commit or the test lies.
4. **Red first, even for prose.** Write the task's tests, run
   `bats tests/skills.bats`, watch the new tests fail because the phrases are
   absent, then edit the skill, then watch them pass and run the whole suite.
5. **Facts the prose must not drift from** (verified against the scripts at
   0a35669): `--impact RANGE` prints `<unit>\t<touched|dependent>` one per
   line, exits 2 on a changed path claimed by nobody (remedy: default mode's
   `UNCLAIMED-PATH`), and maps a change under the root `.guardrails/` to
   EVERY unit; a unit's run is `GR_CONFIG=<unit>/.guardrails/config.yaml`;
   with a manifest present there is no root `.guardrails/config.yaml` (two
   authorities refused, exit 2); `check-review.sh` is repo-level and
   unchanged; `finalize-docs.sh` is unit-scoped via `gr_unit_engage`.
6. **`analyze-risks` is deliberately untouched.** D13 names it, but it has no
   glossary section to extend; the glossary rules live in
   `grill-requirements`, which `analyze-risks` already round-trips with.
   Recorded here so the omission reads as a decision, not a gap.
7. **`install.sh` untouched.** It syncs `skills/` wholesale; content changes
   ride along.

## Obligation audit

After T4, from the change worktree, this loop must print nothing:

```sh
for o in \
  ratchet-asks-one-system-or-many \
  ratchet-units-interview-writes-facts-not-rules \
  ratchet-manifest-repo-has-no-root-config \
  ratchet-tooth-one-is-manifest-and-disclaimers \
  ratchet-per-unit-class-interview \
  merge-consumes-impact-mechanically \
  merge-runs-impact-set-gates \
  merge-finalizes-touched-units-only \
  merge-record-names-units \
  grill-dependency-assessment-interview \
  grill-gap-becomes-expectation \
  grill-glossary-escalates-interface-terms \
  design-depends-on-is-a-decision \
  design-segregation-cites-a-control \
; do grep -q "@test \"$o" tests/skills.bats || echo "MISSING: $o"; done
```

---

### T1 — ratchet: the units interview writes the facts

**Files touched:** `skills/ratchet/SKILL.md`, `tests/skills.bats`
**Parallel:** no (first)

**Tests (write first, watch fail):** append to `tests/skills.bats`:

*(Code pruned at merge: 48 lines. Files touched: `skills/ratchet/SKILL.md`, `tests/skills.bats`.)*

**Implementation:** three edits to `skills/ratchet/SKILL.md`.

**(a)** In `## Step 1: Detect mode`, after the greenfield/retrofit paragraph
and its code block, append:

*(Code pruned at merge: 7 lines. Files touched: `skills/ratchet/SKILL.md`, `tests/skills.bats`.)*

**(b)** Insert a new section between Step 1 and Step 2:

*(Code pruned at merge: 31 lines. Files touched: `skills/ratchet/SKILL.md`, `tests/skills.bats`.)*

**(c)** In `## Step 2 (greenfield): Scaffold`, item 3 currently opens with
`Copy in, from the guardrails repo:` and lists
`templates/config.yaml → .guardrails/config.yaml` first. Replace that first
list line and add the mode branch, so item 3 begins:

*(Code pruned at merge: 12 lines. Files touched: `skills/ratchet/SKILL.md`, `tests/skills.bats`.)*

(keep the remaining copy list intact for the single-unit reading, and in
Step 3 (retrofit) item 3 "First tooth", append one sentence: `On a
multi-unit repository the first tooth installs the manifest and per-unit
configs from step 1b instead of a root config.`)

**(d)** In `## Step 4: Safety-class interview (IEC 62304 4.3)`, after the
"When in doubt between two classes" paragraph, append:

*(Code pruned at merge: 3 lines. Files touched: `skills/ratchet/SKILL.md`, `tests/skills.bats`.)*

**Commands:** `bats tests/skills.bats` red on the 5 new tests → edit → green
→ `sh tests/run-tests.sh` all green.

**DONE — dispatch report (T1, branch units-skills-t1, merged):**

```
red -> green: ratchet-asks-one-system-or-many — watched fail for the right reason (pinned phrase absent from SKILL.md) before the prose existed
red -> green: ratchet-units-interview-writes-facts-not-rules — watched fail for the right reason before the prose existed
red -> green: ratchet-manifest-repo-has-no-root-config — watched fail for the right reason before the prose existed
red -> green: ratchet-tooth-one-is-manifest-and-disclaimers — watched fail for the right reason before the prose existed
red -> green: ratchet-per-unit-class-interview — watched fail for the right reason before the prose existed
result: 593 passed, 0 failed (full suite, exit 0; baseline 588 + 5 new)
surprises: plan listing defect — three pinned phrases were wrapped mid-phrase in the plan's prose blocks, so line-based grep could never match; rewrapped (identical words, pins verbatim on one line) under red-first discipline. Executors of T2–T4: keep every pinned phrase on ONE line in the skill prose.
```

---

### T2 — merge-change: the impact set is consumed, not judged

**Files touched:** `skills/merge-change/SKILL.md`, `tests/skills.bats`
**Parallel:** no (serial, after T1)

**Tests (write first, watch fail):**

*(Code pruned at merge: 32 lines. Files touched: `skills/merge-change/SKILL.md`, `tests/skills.bats`.)*

**Implementation:** one new section inserted into `skills/merge-change/SKILL.md`
immediately before `## The sequence`, plus two one-line riders.

**(a)** New section:

*(Code pruned at merge: 26 lines. Files touched: `skills/merge-change/SKILL.md`, `tests/skills.bats`.)*

**(b)** Riders: in step 2's text, after "runs every `verify_commands` entry
in the worktree", append `(per unit over the impact set in a multi-unit
repository — see "Multi-unit repositories")`; in step 6b's field list
paragraph, append the sentence `In a multi-unit repository the record also
names the units touched, and the impact set.`
Note: the pinned phrase `units touched, and the impact set` must appear in
BOTH (a) and (b) verbatim — write (b) exactly as given.

**Commands:** as T1.

**DONE — dispatch report (T2, branch units-skills-t2, merged):**

```
red -> green: merge-consumes-impact-mechanically — watched fail for the right reason (pinned phrase absent from SKILL.md) before the prose existed
red -> green: merge-runs-impact-set-gates — watched fail for the right reason before the prose existed
red -> green: merge-finalizes-touched-units-only — watched fail for the right reason before the prose existed
red -> green: merge-record-names-units — watched fail for the right reason before the prose existed
result: 597 passed, 0 failed (full suite, exit 0; 593 after T1 + 4 new)
surprises: same wrap defect as T1 on two pins, rewrapped one-line in the skill; vendored bats runner is per-worktree (gitignored) — task worktrees call it by absolute path.
```

---

### T3 — grill-requirements: dependency assessment and glossary escalation

**Files touched:** `skills/grill-requirements/SKILL.md`, `tests/skills.bats`
**Parallel:** no (serial, after T2)

**Tests (write first, watch fail):**

*(Code pruned at merge: 27 lines. Files touched: `skills/grill-requirements/SKILL.md`, `tests/skills.bats`.)*

**Implementation:** two edits to `skills/grill-requirements/SKILL.md`.

**(a)** New section after `## Write requirements as they crystallize`:

*(Code pruned at merge: 23 lines. Files touched: `skills/grill-requirements/SKILL.md`, `tests/skills.bats`.)*

**(b)** Extend `## Maintain the glossary inline` — replace its opening line
`` `docs/CONTEXT.md` is the project glossary — definitions only, no
implementation detail. `` with:

*(Code pruned at merge: 8 lines. Files touched: `skills/grill-requirements/SKILL.md`, `tests/skills.bats`.)*

**Commands:** as T1.

**DONE — dispatch report (T3, branch units-skills-t3, merged):**

```
red -> green: grill-dependency-assessment-interview — watched fail for the right reason (pinned phrase absent from SKILL.md) before the prose existed
red -> green: grill-gap-becomes-expectation — watched fail for the right reason before the prose existed
red -> green: grill-glossary-escalates-interface-terms — watched fail for the right reason before the prose existed
result: 600 passed, 0 failed (full suite, exit 0; 597 after T2 + 3 new)
surprises: same wrap defect on two pins, rewrapped one-line in the skill, words identical.
```

---

### T4 — design-architecture: edges and segregation are design decisions

**Files touched:** `skills/design-architecture/SKILL.md`, `tests/skills.bats`
**Parallel:** no (serial, after T3)

**Tests (write first, watch fail):**

*(Code pruned at merge: 18 lines. Files touched: `skills/design-architecture/SKILL.md`, `tests/skills.bats`.)*

**Implementation:** extend point 4's segregation bullet in
`skills/design-architecture/SKILL.md`. The bullet currently ends
`— a Class C item's failure modes must not reach through it.` Append to it:

*(Code pruned at merge: 9 lines. Files touched: `skills/design-architecture/SKILL.md`, `tests/skills.bats`.)*

**Commands:** as T1.

**DONE — dispatch report (T4, branch units-skills-t4, merged):**

```
red -> green: design-depends-on-is-a-decision — watched fail for the right reason before the prose existed (grep 'Declaring a dependency' failed; phrase absent)
red -> green: design-segregation-cites-a-control — watched fail for the right reason before the prose existed (grep 'segregated_from:' failed; phrase absent)
result: 602 passed, 0 failed (full suite, exit 0; tests/skills.bats alone: 40 passed)
surprises: none — the 14-name obligation audit printed nothing from the task worktree.
```

---

## Review fix round (post-6a)

**DONE — dispatch report (fix1, branch units-skills-fix1, merged):** four
findings from the independent review (verdict approve-with-findings), all
fixed:

```
finding-1 (MINOR): merge-record-names-units pin matched two sites; added rider-unique pin 'the record also names the units touched'. Sabotage: rider deleted -> test red on the new grep, restored -> green.
finding-2 (MINOR): grill prose "lists the open expectations" overstated the script's count-only advisory; reworded to "reports how many open expectations stand against it". No pin touched.
finding-3 (IMPORTANT): expects: grammar omitted the required opened: annotation. Red-first: pins 'opened: YYYY-MM-DD' + 'INCOMPLETE-EXPECTATION' added, watched red, then the grammar sentence ("Carry opened: YYYY-MM-DD in the same item block, on its own line...") -> green. Shape verified against check-trace.sh (column-one, block-attributed).
finding-4 (MINOR): toothless pin replaced with 'record each class in that unit's config' (step-4-unique after a whitespace reflow). Red-first against the line-spanning original; targeted sabotage reddened, restored, green.
result: 602 passed, 0 failed (full suite, exit 0)
```

## Task graph

T1 → T2 → T3 → T4, strictly serial (shared `tests/skills.bats`). Each task in
its own worktree `.worktrees/units-skills-t<N>` off `units-skills`; the
dispatcher merges each before dispatching the next.

## Self-review

1. All 14 obligations map to exactly one task each; the audit loop covers all 14.
2. Every pinned phrase in every test appears verbatim in the prose the same
   task writes (decision 3) — checked pin-by-pin while drafting.
3. Names used across tasks are consistent: `check-units.sh --impact`,
   `GR_CONFIG=<unit>/.guardrails/config.yaml`, `expects: <unit>` match the
   scripts at 0a35669.
4. Files touched are declared per task; no parallelism claimed anywhere.
