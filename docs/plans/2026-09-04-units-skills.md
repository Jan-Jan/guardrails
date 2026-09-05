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

```bash
@test "ratchet-asks-one-system-or-many: mode detection includes the units question" {
    # verifies: D9 (docs/plans/2026-08-26-monorepo-support.md)
    # Without this question a twelve-package repository gets a root config and
    # every gate silently reads one unit's facts as the whole tree's.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'one system in many packages, or many systems' "$skill"
    grep -q 'a single-unit project gets no manifest' "$skill"
}

@test "ratchet-units-interview-writes-facts-not-rules: the D9 line is drawn in the skill" {
    # verifies: D9
    # The interview writes units:, not_a_unit:, depends_on:, segregated_from:,
    # safety_class — and must SAY it does not ask about the rules, or the next
    # editor adds the enforcement knob D9 rejects by name.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'declares the facts; the rules are not configurable' "$skill"
    grep -q 'not_a_unit:' "$skill"
    grep -q 'segregated_from:' "$skill"
    grep -q 'whether the class floor applies' "$skill"
}

@test "ratchet-manifest-repo-has-no-root-config: scaffold branches on the manifest" {
    # verifies: D2/D9; exclusivity implemented in gr_check_units (0a35669)
    # Copying templates/config.yaml to the root of a manifest repository is
    # exit 2 at the next gate — the scaffold step must say which file goes
    # where in each mode, or ratchet scaffolds a refused shape.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'templates/units.yaml' "$skill"
    grep -q 'no root .guardrails/config.yaml' "$skill"
    grep -q '<unit>/.guardrails/config.yaml' "$skill"
}

@test "ratchet-tooth-one-is-manifest-and-disclaimers: adoption order is stated" {
    # verifies: D9 (tooth ordering, confirmed 2026-08-31)
    # Without the ordering, adoption on a large repo reads as all-or-nothing
    # and the honest first tooth (manifest + disclaimers, no edges) is missed.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'a tooth ordering, not a package' "$skill"
    grep -q 'empty `depends_on:` is a freestanding guardrails project' "$skill"
}

@test "ratchet-per-unit-class-interview: step 4 repeats per unit" {
    # verifies: D5/D9 — the per-unit class is the input to the class floor,
    # and the interview most likely to be skipped.
    skill="$BATS_TEST_DIRNAME/../skills/ratchet/SKILL.md"
    grep -q 'repeat this interview per unit' "$skill"
    grep -q "that unit's config" "$skill"
}
```

**Implementation:** three edits to `skills/ratchet/SKILL.md`.

**(a)** In `## Step 1: Detect mode`, after the greenfield/retrofit paragraph
and its code block, append:

```markdown
Then, for any repository that is not obviously one program, ask (one
question, recommend an answer): **one system in many packages, or many
systems in one repository?** Packages that version, release and take risk
together are one system — a single-unit project gets no manifest and the
rest of this skill reads exactly as before. Separately compliant systems
sharing a repository get the units interview (step 1b) before any file is
copied, because the answer decides where every config lives.
```

**(b)** Insert a new section between Step 1 and Step 2:

```markdown
## Step 1b: The units interview (multi-unit repositories only)

D9 (docs/plans/2026-08-26-monorepo-support.md): `/ratchet` declares the
facts; the rules are not configurable. Ask one question at a time, recommend
an answer, and write each fact where it lives:

| Ask | Write to |
|---|---|
| What are the units? (each a relative directory) | `units:` in `.guardrails/units.yaml` |
| What is outside compliance, and why? | `not_a_unit:` in the manifest; the why as a `#` comment beside the entry |
| What is each unit's safety class? | `safety_class:` in that unit's config — the step 4 interview, repeated per unit |
| What does each unit depend on? | `depends_on:` in the consumer unit's config — each edge triggers the dependency assessment (`grill-requirements`, "Declaring a dependency") |
| Is any dependency segregated, and under which control? | `segregated_from:` in the consumer unit's config, citing the control or ADR — `check-units.sh` convicts an uncited entry as INCOMPLETE-SEGREGATION |

It does **not** ask whether the class floor applies, whether a unit may see
another's internals, or which units run at merge — those are D4, D5 and D6,
and every configurable version of them is a gate that did not run while
nothing in the output said so.

Adoption is a tooth ordering, not a package. Tooth one — mandatory — is the
manifest, the per-unit configs and the disclaimers: a unit with an empty
`depends_on:` is a freestanding guardrails project that happens to share a
repository, and a manifest naming one unit with everything else disclaimed
is a valid, passing first tooth on a repository of twelve packages. Declare
edges (`depends_on:`, exports, expectations) later, when the coupling bites;
until an edge exists those gates have nothing to read, so "not yet adopted"
is visible in the manifest instead of being a switched-off gate.

After writing, run `.guardrails/scripts/check-units.sh` — it validates the
manifest and every unit's config in one pass, and its findings
(UNCLAIMED-PATH above all) are the worklist for the disclaimers question.
```

**(c)** In `## Step 2 (greenfield): Scaffold`, item 3 currently opens with
`Copy in, from the guardrails repo:` and lists
`templates/config.yaml → .guardrails/config.yaml` first. Replace that first
list line and add the mode branch, so item 3 begins:

```markdown
3. Copy in, from the guardrails repo — the destination depends on step 1b:
   - single unit: `templates/config.yaml` → `.guardrails/config.yaml`
   - multi-unit: `templates/units.yaml` → `.guardrails/units.yaml`, filled in
     from the interview, and `templates/config.yaml` →
     `<unit>/.guardrails/config.yaml` for **each** unit (adjust each copy's
     `doc_*` paths and `verify_commands` to that unit). There is
     **no root .guardrails/config.yaml** in a manifest repository — two
     authorities over one tree is exit 2 at every gate. Scripts stay at the
     root: `.guardrails/scripts/` serves every unit. The doc skeletons below
     are copied **per unit** (into `<unit>/docs/...`); `docs/verification/`,
     `docs/plans/`, `docs/adr/` and the interface glossary `docs/CONTEXT.md`
     stay at the repository root.
```

(keep the remaining copy list intact for the single-unit reading, and in
Step 3 (retrofit) item 3 "First tooth", append one sentence: `On a
multi-unit repository the first tooth installs the manifest and per-unit
configs from step 1b instead of a root config.`)

**(d)** In `## Step 4: Safety-class interview (IEC 62304 4.3)`, after the
"When in doubt between two classes" paragraph, append:

```markdown
In a multi-unit repository, repeat this interview per unit and record each
class in that unit's config — the per-unit class is the input to the class
floor (D5), and this is the interview most likely to be skipped.
```

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

```bash
@test "merge-consumes-impact-mechanically: the skill names the mode and forbids hand-picking" {
    # verifies: D6/D12; --impact semantics quoted from scripts/check-units.sh
    # The composed-chain obligations test the chain THROUGH this mode; a
    # hand-judged unit list is the false green the mode exists to prevent.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    grep -q 'check-units.sh --impact' "$skill"
    grep -q 'never hand-pick the unit list' "$skill"
    grep -q 'maps a change under the root `.guardrails/` to every unit' "$skill"
}

@test "merge-runs-impact-set-gates: per-unit runs are spelled out" {
    # verifies: D6 — gates and verify_commands of every unit in the impact
    # set, plus the repository-level check-units.sh run.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    grep -q 'GR_CONFIG=<unit>/.guardrails/config.yaml' "$skill"
    grep -q 'every unit in the impact set' "$skill"
    grep -q 'check-units.sh` with no flag' "$skill"
}

@test "merge-finalizes-touched-units-only: the finalize loop is scoped" {
    # verifies: architecture item 6 — finalize-docs.sh is unit-scoped; drafts
    # sit in touched units by the paths-inside-the-unit rule, so dependents
    # have nothing to rename.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    grep -q 'once per touched unit' "$skill"
}

@test "merge-record-names-units: the verification record carries the impact set" {
    # verifies: D6 — one record per change; the record names the units.
    skill="$BATS_TEST_DIRNAME/../skills/merge-change/SKILL.md"
    grep -q 'units touched, and the impact set' "$skill"
}
```

**Implementation:** one new section inserted into `skills/merge-change/SKILL.md`
immediately before `## The sequence`, plus two one-line riders.

**(a)** New section:

````markdown
## Multi-unit repositories

When `.guardrails/units.yaml` exists, the sequence below runs **per unit
over the impact set**, and the impact set is computed, not judged:

```sh
.guardrails/scripts/check-units.sh --impact "$BASE..HEAD"
```

One `<unit>\t<touched|dependent>` line per unit — consume it mechanically,
never hand-pick the unit list. The mode exits 2 on a changed path claimed by
no unit (fix default mode's UNCLAIMED-PATH first; a partial impact set would
read as complete), and maps a change under the root `.guardrails/` to every
unit. Then, wherever the sequence says to run the gates or the suite:

- run `check-units.sh` with no flag once — the repository-level gates;
- run `check-trace.sh`, `check-ids.sh` and that unit's `verify_commands`
  with `GR_CONFIG=<unit>/.guardrails/config.yaml`, for **every unit in the
  impact set** (dependents included — that is what the set is for);
- run `finalize-docs.sh` (step 3) once per touched unit, `GR_CONFIG`
  pointing at each — a dependent has no drafts to rename;
- `check-review.sh` is repository-level and runs exactly once, unchanged.

The record at 6b names the units touched, and the impact set beside its
`branch:` line, so the evidence says which units' gates the verdict covers.
One branch, one squash, one record — D6 — however many units ran.
````

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

```bash
@test "grill-dependency-assessment-interview: the provider's artefacts are consulted by name" {
    # verifies: D10 — adopted as skill guidance, rejected as mechanism; the
    # consultation list is the decision's own: exports, RMF, ADRs, open
    # problem reports, SOUP.
    skill="$BATS_TEST_DIRNAME/../skills/grill-requirements/SKILL.md"
    grep -q 'check-units.sh --exports' "$skill"
    grep -q 'does its risk analysis consider this use' "$skill"
    grep -q 'open problem reports' "$skill"
    grep -q 'transitively its SOUP' "$skill"
}

@test "grill-gap-becomes-expectation: expects: grammar with the met condition" {
    # verifies: D10/D11 — the gap is a requirement; met = provider's exported
    # REQ carrying satisfies:.
    skill="$BATS_TEST_DIRNAME/../skills/grill-requirements/SKILL.md"
    grep -q 'expects: <unit>' "$skill"
    grep -q 'UNMET-EXPECTATION' "$skill"
    grep -q 'exported REQ carrying `satisfies:' "$skill"
}

@test "grill-glossary-escalates-interface-terms: unit default, root escalation, conflict rule" {
    # verifies: D13 — a skill rule for the interviews, not a check.
    skill="$BATS_TEST_DIRNAME/../skills/grill-requirements/SKILL.md"
    grep -q 'the root glossary owns interface terms' "$skill"
    grep -q 'the moment it appears in an exported REQ or an `expects:` item' "$skill"
    grep -q 'Two units disagreeing internally is not a conflict' "$skill"
}
```

**Implementation:** two edits to `skills/grill-requirements/SKILL.md`.

**(a)** New section after `## Write requirements as they crystallize`:

```markdown
## Declaring a dependency (multi-unit repositories)

`depends_on:` is a decision, not a config line. Before an edge lands in the
consumer's config, walk the provider's artefacts with the user, one question
at a time (D10):

- its export surface — `.guardrails/scripts/check-units.sh --exports
  <provider>` lists every exported REQ with its defining file: is the
  behavior you need on it?
- its RMF — does its risk analysis consider this use, or does your use case
  sit outside every analyzed situation?
- its ADRs — a recorded decision may foreclose your requirement;
- its open problem reports — the known anomalies of a supplied component;
- transitively its SOUP — your dependency's dependencies are yours.

A gap found here is a requirement, so it gets requirement machinery: write a
consumer REQ carrying `expects: <unit>` on its own line (the unit must be a
declared dependency). The expectation is **met** when the provider defines an
exported REQ carrying `satisfies:` naming your REQ; until then the consumer's
run reports UNMET-EXPECTATION and the provider's run lists the open
expectations standing against it — the prompt lands on the team that owes
the work. Never model the gap as a problem report in the provider's ledger:
a need is not an anomaly.
```

**(b)** Extend `## Maintain the glossary inline` — replace its opening line
`` `docs/CONTEXT.md` is the project glossary — definitions only, no
implementation detail. `` with:

```markdown
`docs/CONTEXT.md` is the project glossary — definitions only, no
implementation detail. In a multi-unit repository, write to the unit's own
`docs/CONTEXT.md` by default; the root glossary owns interface terms.
Escalate a term to the root glossary the moment it appears in an exported
REQ or an `expects:` item. A term defined in a unit glossary AND at root
with different meanings is challenged, exactly like any other conflict.
Two units disagreeing internally is not a conflict at all — "dose" in an
infusion unit and in a reporting unit are different concepts, legitimately.
```

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

```bash
@test "design-depends-on-is-a-decision: the design skill routes the edge through the assessment" {
    # verifies: D10 — the consultation belongs to grill-requirements AND
    # design-architecture; a dependency drawn on the diagram without the
    # interview is an unassessed supplier.
    skill="$BATS_TEST_DIRNAME/../skills/design-architecture/SKILL.md"
    grep -q 'Declaring a dependency' "$skill"
    grep -q 'an unassessed supplier' "$skill"
}

@test "design-segregation-cites-a-control: segregated_from: names its mechanism" {
    # verifies: D5 + architecture — check-units.sh convicts an uncited entry
    # (INCOMPLETE-SEGREGATION) and an uncovered class gap
    # (MISCLASSED-DEPENDENCY); the skill must say where the citation lives.
    skill="$BATS_TEST_DIRNAME/../skills/design-architecture/SKILL.md"
    grep -q 'segregated_from:' "$skill"
    grep -q 'INCOMPLETE-SEGREGATION' "$skill"
    grep -q 'MISCLASSED-DEPENDENCY' "$skill"
}
```

**Implementation:** extend point 4's segregation bullet in
`skills/design-architecture/SKILL.md`. The bullet currently ends
`— a Class C item's failure modes must not reach through it.` Append to it:

```markdown
     In a multi-unit repository this statement has a home with teeth: a
     cross-unit dependency is declared in the consumer's `depends_on:`, and
     depending on a lower-class unit requires `segregated_from:` in the
     consumer's config, citing the control or ADR that carries the mechanism
     — `check-units.sh` convicts an uncited entry (INCOMPLETE-SEGREGATION)
     and an uncovered class gap (MISCLASSED-DEPENDENCY). And the edge itself
     is a decision: run the "Declaring a dependency" interview
     (`grill-requirements`) before drawing it — a dependency on the diagram
     without that assessment is an unassessed supplier.
```

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
