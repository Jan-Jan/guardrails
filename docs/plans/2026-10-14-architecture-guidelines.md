# Architecture guidelines: structural preferences beside the compliance floor

**Goal:** Architecture preferences live in one project file,
`ARCHITECTURE_GUIDELINES.md`, and a constraint a tool can decide is an LLR
with a test.
**Implements:** none (this repository has no SRS); delivers the decisions
below.
**Safety class:** not configured (this repository has no `.guardrails/config.yaml`).
**Verification:** `sh tests/run-tests.sh`

Context: change 4 in the series `test-guidelines` started
(`docs/plans/2026-10-08-test-guidelines.md`, "Follow-ups outside this
change"), after `code-guidelines` (`docs/plans/2026-10-13-code-guidelines.md`).
That series listed this change as "`ARCHITECTURE_GUIDELINES.md` with per-unit
constraints in `units.yaml`"; D1 replaces the second half.

## Decisions

**D1 — A constraint a tool can decide is an LLR with a test, not a config
key.** A mechanical structural constraint ("pump-core performs no I/O", "the
domain never imports infrastructure") is an LLR on the SDD item it binds,
verified by an architecture test the project writes with its own stack's
tool (an import linter, ArchUnit, dependency-cruiser and the like), annotated
`verifies: LLR-…`. No config key in `units.yaml` or a unit's config, and no
new script: the guardrails scripts are POSIX sh and language-agnostic and
cannot parse imports, and the trace gate already fails an LLR with no test.
`ARCHITECTURE_GUIDELINES.md` states the rule as a clause, so a reviewer who
meets such a constraint written as prose reports it. Why: a rule a script can
decide is weaker as a reviewer's judgment, and the project's own tool decides
it in the project's language. Cost: a class A or B project with no LLRs
writes one for each constraint it wants enforced. Ruled 2026-10-14.

**D2 — `design-architecture` writes to the file; `develop-change` reviews
against it.** `design-architecture` reads the file that
`guidelines-file.sh ARCHITECTURE` prints for the paths the design touches,
and proposes and writes SDD and LLR items that follow it. A proposal that
departs from a clause says which clause it departs from, and the user
decides. `develop-change` runs a third conformance review,
`guidelines-file.sh ARCHITECTURE` over the whole change diff, with the
`TEST` and `CODE` reviews, all at once. The same convergence rule applies:
the first round with nothing above low is the last. `guidelines-file.sh`
learns the kind `ARCHITECTURE`. Why: one review point, with the machinery
the other two kinds already use. Cost: one more reviewer dispatch per
change, every round. Ruled 2026-10-14.

**D3 — A refactor fixes an architecture finding where it can; otherwise the
finding goes to a redesign.** `develop-refactor` fixes an `ARCHITECTURE`
finding the code can meet with no behavior change, such as moving a call
behind an adapter or splitting a module. For those findings it loads the
architecture file instead of the code file. A finding that needs an SDD or
LLR item changed, or a different structure, comes back as not fixed:
`develop-refactor` does not edit design items. The dispatcher runs
`design-architecture` for it, and the choice between that skill's
alternatives is the user's, so that is a stop. `develop-change` lists it
beside the other deliberate stops. Why: a subagent that changes design items
would choose a structure without the user seeing the alternatives. Ruled
2026-10-14.

**D4 — The default ships five sections.** `templates/ARCHITECTURE_GUIDELINES.md`
holds numbered clauses, each with its rule, its boundary, a reason and
language-neutral examples, as the other two templates do:

- **Domain:** a public interface uses the glossary's terms; a new public term
  enters `docs/CONTEXT.md` in the same change; a term means one thing within
  a unit.
- **Core and edges:** rules live in a core that performs no I/O; I/O lives
  in adapters at the edge; dependencies point inward; one adapter per
  third-party dependency.
- **Boundaries:** an item is entered only through its interface; an error
  crosses a boundary as the interface's own error; one responsibility per
  item.
- **Constraints:** D1 as a clause.
- **Existing code:** the rules bind the structure a change writes, as the
  test template's "Existing suites" does.

"One responsibility per item" moves out of `design-architecture` step 2,
which keeps "a defined interface", so the rule has one home. Each section is
a default that a project keeps, changes or drops with `tailor-guidelines`,
and `/ratchet` invokes it for `ARCHITECTURE` as for `TEST` and `CODE`.
Ruled 2026-10-14.

**D5 — This repository tailors its own file in this change.**
`docs/ARCHITECTURE_GUIDELINES.md` is seeded from the new template and walked
clause by clause with the user under `tailor-guidelines`, as the change's
last task. The change's own conformance review then runs against the
tailored file. Why: the default's Domain and Core-and-edges clauses fit a
POSIX sh toolkit poorly. The toolkit has no glossary, and its scripts exist
to do I/O. Ruled 2026-10-14.

**D6 — The architecture floor joins the one floor list.** The floor list in
`review-conformance`, `tailor-guidelines` and `develop-refactor` gains five
items, each one something `design-architecture` or a gate already requires:

- every SDD item traces to a REQ;
- class C items have LLRs;
- a mechanism is stated for segregation between items of different classes;
- every third-party component is in `soup.md`;
- a cross-unit dependency is declared in `depends_on:`, with
  `segregated_from:` where the classes differ.

The list stays one list in all three skills, except that
`develop-refactor`'s floor, one sentence, omits "every new test was watched
red" and the double-call clause, as it did before this change: a refactor
writes no new test. (This exception was written into D6 on 2026-10-14 by
the dispatching agent, as the disposition of ARCHITECTURE round-2 finding-3,
to state what the tree already did; it was not put to the user.) Why: no skill has
to choose a list by kind, and a reviewer of another kind reads five lines
that do not apply to it, at no cost. Ruled 2026-10-14.

**D7 — What carries over unchanged.** These need no new ruling:

- A unit's `<unit>/docs/ARCHITECTURE_GUIDELINES.md` replaces the root file
  whole (test-guidelines D3).
- No guidelines file refers to another (test-guidelines D6).
- `/ratchet` copies `templates/*_GUIDELINES.md` already, so the scaffold
  and upgrade copy lines need no edit.
- The record's `## Guideline reviews` gains the `ARCHITECTURE` entries
  (test-guidelines D9).
- A task subagent still reads only the `TEST` file (code-guidelines D1).
  The architecture file reaches the code through `design-architecture` and
  the review.

**D8 — The boundary's test fake is the second implementation.** The
default `Core and edges 2` and the code default's "no interface without a
second caller" would give a project that keeps both contradictory findings.
`Core and edges 2` states that the test fake at the boundary counts as the
interface's second implementation, and that in a language with duck or
structural typing the interface is the parameter the core takes, with no
declared type. The code template is unchanged. Why: the test default already
puts fakes at the boundary, so the second implementation exists, and the
code template stays free of architecture. Ruled 2026-10-14.

## Tasks

Every test this change writes or edits carries
`# verifies: D<n> (docs/plans/2026-10-14-architecture-guidelines.md)`, naming
the decisions above it tests. A test that already verified an earlier plan's
decision keeps that annotation beside the new one. Each new or edited test is
watched red before the text or code it checks exists, and the task's
`red -> green:` line records it. Text tests pin operative clauses only,
matched with `grep -qF`, or `grep -qxF` for a line that must survive whole;
a sentence that may wrap is matched on the section flattened with
`tr '\n' ' ' | tr -s ' '`. Each task runs only its own test files, with
`sh tests/run-tests.sh tests/<file>.bats`, and reports the counts. The full
suite is the merge gate, not a task step.

Write a negative assertion as `if grep …; then echo …; false; fi` or
`! grep … || { echo …; false; }` (AGENTS.md, Rules). No guidelines file may
contain a skill directory name, `ADR-`, `docs/plans/`, `references/`,
`SKILL.md` or `AGENTS.md`.

### Inventory

What changes, by decision, found by `git grep` at `6a9d6eb`:

- **D1, D4:**
  - `templates/ARCHITECTURE_GUIDELINES.md` (new).
  - `skills/design-architecture/SKILL.md` step 2: "Each item is one
    responsibility with a defined interface" loses its first half.
- **D2:**
  - `scripts/guidelines-file.sh:35`: `KNOWN_KINDS='TEST CODE'`.
  - `tests/guidelines-file.bats:72-76`: uses `ARCHITECTURE` as its unknown
    kind.
  - `skills/develop-change/SKILL.md:121-133`: the conformance reviews, TEST
    and CODE only.
  - `skills/develop-change/SKILL.md:188`: Done when, "for `TEST` and for
    `CODE`".
  - `skills/design-architecture/SKILL.md`: step 1 "Read first" and step 3
    "Propose 2 or 3".
  - `skills/merge-change/references/review-checklist.md:76-79`.
  - `templates/verification.md:105`.
  - `README.md:45`: the tailor-guidelines node.
  - Mutation anchors: `grep -rn 'KNOWN_KINDS' docs/verification/*.mutations/`
    prints nothing.
- **D3:**
  - `skills/develop-refactor/SKILL.md`: description, Preconditions, step 4
    and Red flags.
  - `skills/develop-change/SKILL.md:147-150`: the fix dispatch.
  - `skills/develop-change/SKILL.md:110-112`: "Two other stops".
- **D5:** `docs/ARCHITECTURE_GUIDELINES.md` (new).
- **D6:** the floor lists in `skills/review-conformance/SKILL.md:46-53`,
  `skills/tailor-guidelines/SKILL.md` step 5, and
  `skills/develop-refactor/SKILL.md` step 4.
- **D7, tailoring:**
  - `skills/tailor-guidelines/SKILL.md`: description, Preconditions, step 3
    and the "generic examples" red flag.
  - `skills/ratchet/SKILL.md:128`.
  - `skills/ratchet/references/upgrade-notes.md`: a new section.
  - `skills/review-conformance/SKILL.md:3`: the description.
- **Tests that pin the old wording and change with it:**
  - `tests/develop-refactor.bats:12-18`.
  - `tests/tailor-guidelines.bats:55-60` and `:99-106`.
  - `tests/guidelines-file.bats:72-76`.
- **Test helpers:** `tests/code-guidelines.bats` defines `clause_list` and
  `names_no_guardrails_document_or_skill`, and the new
  `tests/architecture-guidelines.bats` needs both. T1 moves them to
  `tests/helpers.bash`, so they have one copy.
- **Word budgets:**
  - `ratchet` is at 1,972; T5 adds 2 words.
  - `develop-change` is at 1,484.
  - `design-architecture` is at 846.
  - The other edited skills are under 1,100.

Waves:
1. T1, T2, T3, T4 and T5 at once, since their file sets are disjoint.
2. T6, once a slot frees.
3. T7, after T1. It is the dispatcher's own task, an interview with the
   user under `tailor-guidelines`.

Merge order is T1 before T2: `tests/code-guidelines.bats` "every kind
guidelines-file.sh knows has a shipped template" fails on T2 without T1.

### T1 — the shipped architecture guidelines template

**Files touched:** `templates/ARCHITECTURE_GUIDELINES.md`,
`tests/architecture-guidelines.bats`, `tests/helpers.bash`,
`tests/code-guidelines.bats`
**Parallel:** yes
**Decisions:** D1, D4, D7

First, move `clause_list` and `names_no_guardrails_document_or_skill` from
`tests/code-guidelines.bats` to `tests/helpers.bash`. Move them word for
word, with their comments. `tests/code-guidelines.bats` must stay green;
run it to confirm.

Then write `tests/architecture-guidelines.bats`. Head it with a comment
naming the file under test and this plan, followed by `load helpers` and
`template="$BATS_TEST_DIRNAME/../templates/ARCHITECTURE_GUIDELINES.md"`.
Every test carries
`# verifies: D4 (docs/plans/2026-10-14-architecture-guidelines.md)`; the
Constraints clause test adds D1, and the stand-alone test adds
`D6 (docs/plans/2026-10-08-test-guidelines.md)`.

- **"architecture guidelines: the template's clauses, by heading and
  number":** `clause_list "$template"` equals exactly these lines:

  ```
  ## Domain | 1. **A public interface speaks the glossary.**
  ## Domain | 2. **A new public term enters the glossary in the same change.**
  ## Domain | 3. **One term, one meaning, within a unit.**
  ## Core and edges | 1. **Rules live in a core that performs no I/O.**
  ## Core and edges | 2. **I/O lives in adapters at the edge.**
  ## Core and edges | 3. **Dependencies point inward.**
  ## Core and edges | 4. **One adapter per third-party dependency.**
  ## Boundaries | 1. **An item is entered only through its interface.**
  ## Boundaries | 2. **An error crosses a boundary as the interface's own error.**
  ## Boundaries | 3. **One responsibility per item.**
  ## Constraints | 1. **A rule a tool can decide is an LLR with a test.**
  ## Existing code | 1. **These rules bind the structure a change writes.**
  ```

  Fail with "no templates/ARCHITECTURE_GUIDELINES.md" when the file is
  absent.
- **"architecture guidelines: the template has the five headings, in
  order":** `grep -E '^##? '` prints `# Architecture guidelines`, then
  `## Domain`, `## Core and edges`, `## Boundaries`, `## Constraints` and
  `## Existing code`.
- **"architecture guidelines: every clause states a reason and an
  example":** the awk from `tests/code-guidelines.bats`'s test of the same
  name, run over `$template`.
- **"architecture guidelines: the boundaries D4 names are stated":** on the
  flattened template, `grep -qF` for each of:
  - `never a synonym it lists under \`_Avoid_\``
  - `Names inside an item are not bound by this clause.`
  - `Two units may define a word differently.`
  - `reads and writes no file, network, database, device, environment variable, clock or random source`
  - `The core imports no adapter, framework or infrastructure module`
  - `outside the language's standard library`
  - `keeps the error it received as the cause`
  - `A rule that needs judgment stays a clause in this file.`
  - `No change restructures a codebase wholesale for compliance.`
- **"architecture guidelines: a rule a tool can decide is an LLR with a
  test":** D1, D4. The Constraints section, flattened, contains
  `is written as an LLR on the software item it binds` and
  `annotated with that LLR`.
- **"architecture guidelines: the preface states the one-file rule and the
  floor rule":** as the code-guidelines test of the same name, but on the
  preface flattened, since this preface wraps `is a finding against the` /
  `clause`: `and no other guidelines file`,
  `is a finding against the clause`, and at most 6 non-heading, non-blank
  lines (the preface is 5).
- **"architecture guidelines: the template stands alone, naming no
  guardrails document or skill":** `names_no_guardrails_document_or_skill
  "$template"`.
- **"architecture guidelines: the template is at most 1,300 words".**

Watch each one red, then write `templates/ARCHITECTURE_GUIDELINES.md` with
exactly this content (1,090 words):

```markdown
# Architecture guidelines

This file states the project's architecture preferences. An agent reads this
file and no other guidelines file. The compliance floor the skills state wins
any conflict, and a clause that contradicts it is a finding against the
clause. A project that changes a clause rewrites its reason and examples with
it.

## Domain

1. **A public interface speaks the glossary.** The names in a unit's or a
   software item's public interface are the terms `docs/CONTEXT.md` defines,
   never a synonym it lists under `_Avoid_`: exported functions and types,
   endpoints, events and messages, configuration keys, and the words the user
   reads. Names inside an item are not bound by this clause. Why: the
   glossary is where the project agreed what a word means, and an interface
   is where another unit, another team or the user reads it. Example: where
   the glossary defines "dose" and lists "amount" under `_Avoid_`,
   `schedule_dose(patient, dose)`, not `schedule_amount(patient, amount)`.

2. **A new public term enters the glossary in the same change.** A term a
   change adds to a public interface that `docs/CONTEXT.md` does not define
   is defined there by that change. Why: a term used before it is defined
   gets a meaning from its first caller, and the second caller may guess a
   different one. Example: a change that adds a `Titration` event adds the
   definition of "titration" to the glossary beside it.

3. **One term, one meaning, within a unit.** Inside one unit a term means one
   thing. Where two parts of the domain need the same word for different
   things, they are separate units or software items, each with its own
   definition. Two units may define a word differently. Why: a word with two
   meanings in one place is read with the wrong one, and the error passes
   every type check. Example: "order" as a purchase order in billing and as a
   prescriber's order in dosing lives in two units, not as one `Order` type
   with a `kind` field.

## Core and edges

1. **Rules live in a core that performs no I/O.** Decisions, calculations,
   validation and state transitions are in code that reads and writes no
   file, network, database, device, environment variable, clock or random
   source. The core takes what it needs as arguments and returns its result.
   Why: core code is tested with plain values and no test double, and its
   behavior cannot depend on the machine it runs on. Example:
   `next_dose_time(last_dose, schedule, now)` takes `now` as an argument
   instead of reading the clock.

2. **I/O lives in adapters at the edge.** Each access to a file, network,
   database, device, clock or random source is in an adapter the project
   owns, and the core reaches it through an interface the core defines.
   Why: the edge is thin and the decisions are in the core, so most of the
   code is tested without I/O, and a change of storage or transport changes
   one adapter. Example: the core defines a `DoseLog` interface with
   `append(entry)`; a `SqliteDoseLog` adapter implements it.

3. **Dependencies point inward.** The core imports no adapter, framework or
   infrastructure module; adapters import the core. A framework's entry
   point, such as a request handler, is an adapter that calls the core.
   Why: a core that imports infrastructure cannot be built, tested or reused
   without it, and a framework upgrade then reaches every rule. Example: the
   core's `DoseLog` interface is imported by `SqliteDoseLog`; the core never
   imports the database driver.

4. **One adapter per third-party dependency.** A library, service or SDK
   outside the language's standard library is called from one adapter the
   project owns, not from the core and not from many places. Why: the
   dependency's failure modes, known anomalies and upgrades are handled in
   one place, and replacing it changes one file. Example: the HTTP client is
   used only in `PumpGateway`; the rest of the code calls `PumpGateway`.

## Boundaries

1. **An item is entered only through its interface.** Code outside a
   software item calls only what the item's interface exposes: no import of
   its internal modules, no access to its private state, no reliance on its
   storage layout or file format. Why: the interface is what the design
   describes and the tests verify, so a way around it bypasses both, and a
   change behind the interface breaks the caller. Example: billing calls
   `inventory.reserve(sku, count)`, not `inventory.store.rows[sku]`.

2. **An error crosses a boundary as the interface's own error.** An
   interface reports a failure in its own terms and keeps the error it
   received as the cause; it does not pass a dependency's error type
   through to its caller. Why: a caller that handles a dependency's error
   depends on that dependency, and a replacement then breaks it. Example:
   `PumpGateway` raises `PumpUnavailable` with the connection error as its
   cause, not the HTTP client's `ConnectionError`.

3. **One responsibility per item.** A software item has one responsibility,
   stated in one sentence without "and". Why: an item with two
   responsibilities changes for two reasons, and its requirements and tests
   mix concerns that belong apart. Example: `DoseScheduler` decides when a
   dose is due and `PumpDriver` delivers it, not one `PumpManager` that does
   both.

## Constraints

1. **A rule a tool can decide is an LLR with a test.** A structural rule that
   a tool can check, such as "this item performs no I/O" or "the core imports
   no adapter", is written as an LLR on the software item it binds and
   verified by an architecture test the project writes with its own tooling
   (an import linter or an architecture test library), annotated with that
   LLR. A rule that needs judgment stays a clause in this file. Why: a
   reviewer misses what a tool does not, and an LLR with no test fails the
   trace check. Example: "LLR: the dosing core imports no module that
   performs I/O", verified by an import-linter contract run in the test
   suite.

## Existing code

1. **These rules bind the structure a change writes.** Code a change adds or
   moves follows them. Existing code that breaks them is restructured only
   where a change edits it for its own reason, and only as far as that edit
   reaches; code that breaks them and is not edited is left alone. No change
   restructures a codebase wholesale for compliance. Why: a wholesale
   restructuring is a change of its own, with its own design and review, and
   mixing it into an unrelated change hides both. Example: a change that
   adds a clock read to a core function passes `now` in instead; the core
   function beside it that already reads the clock is left until a change
   edits it.
```

### T2 — `guidelines-file.sh` knows the kind `ARCHITECTURE`

**Files touched:** `scripts/guidelines-file.sh`, `tests/guidelines-file.bats`
**Parallel:** yes (merged after T1)
**Decisions:** D2, D7

Tests in `tests/guidelines-file.bats`:

- **Edit "guidelines-file: an unknown kind is exit 2, naming the known
  kinds":**
  - Run `guidelines-file.sh NO_SUCH_KIND src/a.sh` in place of
    `ARCHITECTURE`.
  - Expect `unknown kind: NO_SUCH_KIND (known: TEST CODE ARCHITECTURE)`.
  - Add `D2 (docs/plans/2026-10-14-architecture-guidelines.md)` to its
    annotation.
  - It goes red on the known-kinds list.
- **New "guidelines-file: ARCHITECTURE picks the unit's, the root's or the
  installed default file, as TEST does":** the CODE test of the same shape
  (`:79-92`), with `ARCHITECTURE` in place of `CODE` and
  `ARCHITECTURE_GUIDELINES.md` in place of `CODE_GUIDELINES.md`.
  - The fixture writes
    `.guardrails/templates/ARCHITECTURE_GUIDELINES.md`,
    `docs/ARCHITECTURE_GUIDELINES.md` and
    `apps/pump/docs/ARCHITECTURE_GUIDELINES.md`.
  - Annotation: `# verifies: D2, D7
    (docs/plans/2026-10-14-architecture-guidelines.md)`.
- **New "guidelines-file: a missing ARCHITECTURE default is exit 2 though
  the TEST default is installed":** the CODE test of the same shape
  (`:104-110`), with `ARCHITECTURE` in place of `CODE`.

Then, in `scripts/guidelines-file.sh`:
- line 35 becomes `KNOWN_KINDS='TEST CODE ARCHITECTURE'`;
- the header comment's citation adds
  `docs/plans/2026-10-14-architecture-guidelines.md D2`, rewrapped to fit.

Nothing else in the script changes: every path rule is already per kind.

### T3 — `develop-refactor` fixes architecture findings, and returns design changes

**Files touched:** `skills/develop-refactor/SKILL.md`,
`tests/develop-refactor.bats`
**Parallel:** yes
**Decisions:** D3, D6

Tests in `tests/develop-refactor.bats`, all annotated
`# verifies: D3 (docs/plans/2026-10-14-architecture-guidelines.md)`, with
D6 added where the floor is pinned:

- **Edit the first test, renamed "develop-refactor: the skill is named, and
  fixes one CODE or ARCHITECTURE review's findings":**
  - Pin the Preconditions phrase
    `with the findings of one \`review-conformance\` review against a code or architecture guidelines file`.
  - Pin, in the description line,
    `Load it only when develop-change dispatched you to fix CODE or ARCHITECTURE findings.`
- **New "develop-refactor: a finding that needs a design change comes back
  not fixed":** on the flattened file, pin
  - `a finding that needs an SDD or LLR item changed, or a different structure: you do not edit design items`;
  - the red flag row
    `| "The finding needs a design item reworded; I'll edit it" |`.
- **New "develop-refactor: the floor names the architecture items" (D6):**
  pin each of the five item texts exactly as T4 writes them, on the
  flattened file:
  - `every SDD item traces to a REQ`
  - `class C items have LLRs`
  - `a mechanism is stated for segregation between items of different classes`
  - `every third-party component is in \`soup.md\``
  - `a cross-unit dependency is declared in \`depends_on:\`, with \`segregated_from:\` where the classes differ`

Then edit `skills/develop-refactor/SKILL.md`:

- **description:**
  > Fix the findings of one CODE or ARCHITECTURE conformance review in a
  > guardrails project - each finding against the project's code or
  > architecture guidelines file, in a nested task worktree, with no
  > behavior change. Load it only when develop-change dispatched you to fix
  > CODE or ARCHITECTURE findings.
- **Preconditions, first bullet:** "against a code guidelines file" becomes
  "against a code or architecture guidelines file".
- **Step 4:** the list of reasons gains a fourth,
  > a finding that needs an SDD or LLR item changed, or a different
  > structure: you do not edit design items
- **Step 4's floor sentence:** add the five D6 items, in the order above,
  after the test items. It stays one sentence of `;`-separated items.
- **Red flags:** add the row
  > | "The finding needs a design item reworded; I'll edit it" | Report it as not fixed. A design change goes through `design-architecture`, and its alternatives are the user's. |

### T4 — `review-conformance` lists the architecture floor

**Files touched:** `skills/review-conformance/SKILL.md`,
`tests/review-conformance.bats`
**Parallel:** yes
**Decisions:** D6, D7

Tests in `tests/review-conformance.bats`:

- **Edit "review-conformance: the floor is listed in full":**
  - Add a `grep -qF` for each of the five D6 item texts, as T3 lists them.
  - Add `D6 (docs/plans/2026-10-14-architecture-guidelines.md)` to its
    annotation.
- **Edit "review-conformance: the old name is gone, and the description
  names both kinds":**
  - Rename it to "… names every kind".
  - Add a pin for `docs/ARCHITECTURE_GUIDELINES.md` in the description.
  - Annotate it with D7.

Then edit `skills/review-conformance/SKILL.md`:

- **Step 3's floor:** five bullets after `class C: tests at every touched
  SDD item's interface.`:
  - every SDD item traces to a REQ;
  - class C items have LLRs;
  - a mechanism is stated for segregation between items of different
    classes;
  - every third-party component is in `soup.md`;
  - a cross-unit dependency is declared in `depends_on:`, with
    `segregated_from:` where the classes differ.
- **The description's parenthesis:** it becomes
  `(such as docs/TEST_GUIDELINES.md, docs/CODE_GUIDELINES.md or docs/ARCHITECTURE_GUIDELINES.md)`.

### T5 — `tailor-guidelines` and `ratchet` know `ARCHITECTURE`

**Files touched:** `skills/tailor-guidelines/SKILL.md`,
`skills/ratchet/SKILL.md`, `skills/ratchet/references/upgrade-notes.md`,
`tests/tailor-guidelines.bats`
**Parallel:** yes
**Decisions:** D6, D7, D1, D3

Tests in `tests/tailor-guidelines.bats`:

- **Edit "ratchet: the scaffold installs every guidelines default and
  tailors TEST and CODE":**
  - Rename it to "… tailors TEST, CODE and ARCHITECTURE".
  - Pin `Run \`tailor-guidelines\` for \`TEST\`, \`CODE\` and \`ARCHITECTURE\``.
  - Add `D7 (docs/plans/2026-10-14-architecture-guidelines.md)`.
- **Edit "tailor-guidelines: the kinds are TEST and CODE, and CODE's
  examples are the project's":**
  - Rename it to "… the kinds are TEST, CODE and ARCHITECTURE, and
    CODE's and ARCHITECTURE's examples are the project's".
  - Pin the Preconditions
    `` `TEST` (`docs/TEST_GUIDELINES.md`), `CODE` (`docs/CODE_GUIDELINES.md`) or `ARCHITECTURE` (`docs/ARCHITECTURE_GUIDELINES.md`) ``.
  - Pin the Steps
    `for \`CODE\` and \`ARCHITECTURE\`, for every clause: ask for an example in the project's own stack`.
  - Keep the UI pin.
- **Edit "tailor-guidelines: a change that contradicts the floor is
  rejected, and the floor is listed":** add the five D6 pins.
- **New "upgrade notes: architecture guidelines are a project file":** the
  flattened section `## Architecture guidelines are a project file`
  contains each of:
  - `with no \`docs/ARCHITECTURE_GUIDELINES.md\` follows the installed default`
  - `guidelines-file.sh ARCHITECTURE`
  - `Run \`tailor-guidelines\` for \`ARCHITECTURE\``
  - `is an LLR with a test`
  - `\`guidelines-file.sh ARCHITECTURE\` exits 2 and the conformance reviews stop there`

  Annotate it with D1, D3 and D7.

Then edit the skills.

**`skills/tailor-guidelines/SKILL.md`:**
- **description:**
  - The parenthesis becomes `(such as docs/TEST_GUIDELINES.md,
    docs/CODE_GUIDELINES.md or docs/ARCHITECTURE_GUIDELINES.md)`.
  - "change its test or code guidelines" becomes "change its test, code or
    architecture guidelines".
- **Preconditions:** the kinds sentence becomes
  > You know the kind: `TEST` (`docs/TEST_GUIDELINES.md`), `CODE`
  > (`docs/CODE_GUIDELINES.md`) or `ARCHITECTURE`
  > (`docs/ARCHITECTURE_GUIDELINES.md`).
- **Step 3:** "for `CODE`, for every clause" becomes "for `CODE` and
  `ARCHITECTURE`, for every clause".
- **Step 5:** the floor list gains the five D6 bullets, after the test
  items. The sentence "A clause may tighten the floor, never loosen it."
  stays last.
- **The "generic examples" red flag:** its reality becomes "Ask for the
  project's own: Seams and Doubles for `TEST`, every clause for `CODE` and
  `ARCHITECTURE`."

**`skills/ratchet/SKILL.md:128`:** "Run `tailor-guidelines` for `TEST` and
`CODE`" becomes "Run `tailor-guidelines` for `TEST`, `CODE` and
`ARCHITECTURE`". Confirm the skill stays at most 2,000 words.

**`skills/ratchet/references/upgrade-notes.md`:** append, after
`## Code guidelines are a project file`:

```markdown
## Architecture guidelines are a project file

Architecture preferences are now a third guidelines file. An upgraded
project with no `docs/ARCHITECTURE_GUIDELINES.md` follows the installed
default, `.guardrails/templates/ARCHITECTURE_GUIDELINES.md`, which reaches
the project with the scripts: a domain-language public interface, a core
that performs no I/O behind adapters, items entered only through their
interfaces. Run `tailor-guidelines` for `ARCHITECTURE` to make the file the
project's own. `design-architecture` reads it, and `develop-change` runs one
more `review-conformance` review per file `guidelines-file.sh ARCHITECTURE`
prints. `develop-refactor` fixes the findings that need no design change;
the rest go to `design-architecture`. A structural rule the project wants a
tool to enforce, such as "this item performs no I/O", is an LLR with a test
the project writes with its own tooling; there is no config key for it.
Until the upgrade copies the scripts and templates,
`guidelines-file.sh ARCHITECTURE` exits 2 and the conformance reviews stop
there. No gate reads the file, so nothing goes red.
```

### T6 — `develop-change`, `design-architecture` and the record run the third review

**Files touched:** `skills/develop-change/SKILL.md`,
`skills/design-architecture/SKILL.md`,
`skills/merge-change/references/review-checklist.md`,
`templates/verification.md`, `README.md`, `tests/skills.bats`
**Parallel:** yes (wave 2: a sixth slot)
**Decisions:** D2, D3, D4

New tests in `tests/skills.bats`, beside the conformance tests at
`:1103-1176`. Each is annotated
`# verifies: D<n> (docs/plans/2026-10-14-architecture-guidelines.md)`:

- **"develop-change: the conformance reviews run for ARCHITECTURE too"**
  (D2):
  - Pin `sh .guardrails/scripts/guidelines-file.sh ARCHITECTURE \ $(git diff --name-only main...<change-branch>)`
    on the flattened `### The conformance reviews` section, as `:1113`
    does.
  - Pin `` `develop-refactor` for a `CODE` or `ARCHITECTURE` file's findings ``.
  - Pin, in Done when,
    `` Each conformance review, for `TEST`, `CODE` and `ARCHITECTURE`, ran ``.
- **"develop-change: an architecture finding that needs a design change is
  a stop"** (D3): on the flattened `### Derailment` section, pin
  - `an architecture finding \`develop-refactor\` returns as needing a design change`;
  - `` `design-architecture` ``;
  - `the alternatives are the user's`.
- **"design-architecture: reads the architecture guidelines file, and a
  departure names its clause"** (D2): on the flattened `## Steps`, pin
  - `the architecture guidelines file \`guidelines-file.sh ARCHITECTURE\` prints for the paths the design touches, and no other guidelines file`;
  - `A proposal that departs from a clause of that file names the clause, and the user decides.`
- **"design-architecture: one responsibility per item lives in the
  guidelines template"** (D4):
  - The flattened step 2 does not contain `one responsibility`, written
    `if …; then echo …; false; fi`.
  - `templates/ARCHITECTURE_GUIDELINES.md` contains
    `**One responsibility per item.**`. That half is green once T1 is
    merged. Watch only the first half red in T6, and say so in the
    `red -> green:` line.
- **"merge-change: the review checklist asks for the ARCHITECTURE reviews"
  and "verification template: guideline reviews name the ARCHITECTURE
  kind"** (D2): pin `guidelines-file.sh ARCHITECTURE` in each file.
- **"README: tailor-guidelines names the architecture guidelines file"**
  (D2): `README.md` contains `ARCHITECTURE_GUIDELINES.md`.

Then edit the files.

**`skills/develop-change/SKILL.md`:**
- **The conformance reviews:**
  - Add a third block line after the CODE one:
    `sh .guardrails/scripts/guidelines-file.sh ARCHITECTURE \` and
    `    $(git diff --name-only main...<change-branch>)`.
  - "If either exits 2" becomes "If any exits 2".
  - "For each file either prints" becomes "For each file any prints".
- **The fix paragraph:** "`develop-refactor` for a `CODE` file's findings"
  becomes "`develop-refactor` for a `CODE` or `ARCHITECTURE` file's
  findings". Add after that sentence:
  > An architecture finding `develop-refactor` returns as needing a design
  > change goes to `design-architecture` (Derailment).
- **Derailment:** "Two other stops are deliberate and are the user's call:"
  becomes "Three other stops are deliberate and are the user's call:". Add
  a third item to its list:
  > an architecture finding `develop-refactor` returns as needing a design
  > change, which `design-architecture` takes up: the alternatives are the
  > user's
- **Done when:** "Each conformance review, for `TEST` and for `CODE`, ran"
  becomes "Each conformance review, for `TEST`, `CODE` and `ARCHITECTURE`,
  ran".

**`skills/design-architecture/SKILL.md`:**
- **Step 1 ("Read first"):** after "`CONTEXT.md` (use the project's
  language),", add
  > the architecture guidelines file `guidelines-file.sh ARCHITECTURE`
  > prints for the paths the design touches, and no other guidelines file,
- **Step 2:** "Each item is one responsibility with a defined interface"
  becomes "Each item has a defined interface".
- **Step 3:** append
  > A proposal that departs from a clause of that file names the clause,
  > and the user decides.
- **Preconditions:** add
  > Or `develop-change` sent you an architecture finding that needs a
  > design change.

**`skills/merge-change/references/review-checklist.md:76-79`:** the
sentence becomes "the plan lists a conformance review for each file
`guidelines-file.sh TEST` prints for the diff and for each file
`guidelines-file.sh CODE` and `guidelines-file.sh ARCHITECTURE` print for
it, …". The rest of the sentence is unchanged, and `:2700-2701` still
match.

**`templates/verification.md:105`:** "One review per file
`guidelines-file.sh TEST`, `guidelines-file.sh CODE` or
`guidelines-file.sh ARCHITECTURE` printed".

**`README.md:45`:** the node becomes
`tailor-guidelines<br/>the project's TEST_GUIDELINES.md,<br/>CODE_GUIDELINES.md and ARCHITECTURE_GUIDELINES.md`.

### T7 — this repository's own architecture guidelines

**Files touched:** `docs/ARCHITECTURE_GUIDELINES.md`,
`tests/architecture-guidelines.bats`
**Parallel:** no (after T1; run by the dispatcher)
**Decisions:** D5

The dispatcher runs `tailor-guidelines` for `ARCHITECTURE` with the user:
- seed `docs/ARCHITECTURE_GUIDELINES.md` as a complete copy of
  `templates/ARCHITECTURE_GUIDELINES.md`;
- walk each clause, one per message;
- write the user's rulings, with POSIX sh examples for every clause kept.

First, three tests in `tests/architecture-guidelines.bats`, each annotated
`# verifies: D5 (docs/plans/2026-10-14-architecture-guidelines.md)`, each
watched red before the seed:
- **"architecture guidelines: this repository's file stands alone, naming
  no guardrails document or skill"**;
- **"architecture guidelines: every clause of this repository's file states
  a reason and an example"**;
- **"architecture guidelines: this repository's file is at most 1,500
  words"**.

A clause the user drops is recorded in this plan, under T7's Done note, with
the reason given.

### T8 — the boundary's test fake is the second implementation

**Files touched:** `templates/ARCHITECTURE_GUIDELINES.md`,
`tests/architecture-guidelines.bats`
**Parallel:** no (after T7)
**Decisions:** D8

New test "architecture guidelines: the boundary's test fake is the
interface's second implementation", annotated
`# verifies: D8 (docs/plans/2026-10-14-architecture-guidelines.md)`. On the
flattened `## Core and edges` section of the template, it pins
`The test fake at the boundary counts as the interface's second implementation`
and `the interface is the parameter the core takes, with no declared type`.
Watch it red.

Then, in the template's `Core and edges` clause 2, insert after its first
sentence:

> The test fake at the boundary counts as the interface's second
> implementation. In a language with duck or structural typing, the
> interface is the parameter the core takes, with no declared type.

Keep the template at most 1,300 words and every existing pin green: run
`sh tests/run-tests.sh tests/architecture-guidelines.bats`.

## Done

T3 done (merged a934c80):

```
red -> green: develop-refactor: the skill is named, and fixes one CODE or ARCHITECTURE review's findings — watched fail on the missing description pin
red -> green: develop-refactor: a finding that needs a design change comes back not fixed — watched fail on the missing step 4 reason
red -> green: develop-refactor: the floor names the architecture items — watched fail ("the floor lacks: every SDD item traces to a REQ")
```

T2 done (branch b46ab83; merged after T1):

```
red -> green: guidelines-file: an unknown kind is exit 2, naming the known kinds — watched fail on the known-kinds list ("(known: TEST CODE)")
red -> green: guidelines-file: ARCHITECTURE picks the unit's, the root's or the installed default file, as TEST does — watched fail with "unknown kind: ARCHITECTURE"
red -> green: guidelines-file: a missing ARCHITECTURE default is exit 2 though the TEST default is installed — watched fail ("unknown kind" instead of "no installed default")
```

T1 done (merged d8e0412; T2 merged after it, daf3850). Every red was the
template's absence, guarded explicitly in each test; no test was watched red
on one missing sentence of an existing file.

```
red -> green: architecture guidelines: the template's clauses, by heading and number — watched fail ("no templates/ARCHITECTURE_GUIDELINES.md")
red -> green: architecture guidelines: the template has the five headings, in order — watched fail (template absent)
red -> green: architecture guidelines: every clause states a reason and an example — watched fail (template absent)
red -> green: architecture guidelines: the boundaries D4 names are stated — watched fail (template absent)
red -> green: architecture guidelines: a rule a tool can decide is an LLR with a test — watched fail (template absent)
red -> green: architecture guidelines: the preface states the one-file rule and the floor rule — watched fail (template absent)
red -> green: architecture guidelines: the template stands alone, naming no guardrails document or skill — watched fail (template absent)
red -> green: architecture guidelines: the template is at most 1,300 words — watched fail (template absent)
```

T4 done (merged):

```
red -> green: review-conformance: the floor is listed in full — watched fail (`grep -qF 'every SDD item traces to a REQ'`)
red -> green: review-conformance: the old name is gone, and the description names every kind — watched fail (the docs/ARCHITECTURE_GUIDELINES.md description pin)
```

T5 done (merged):

```
red -> green: upgrade notes: architecture guidelines are a project file — watched fail ("no Architecture guidelines section")
red -> green: tailor-guidelines: a change that contradicts the floor is rejected, and the floor is listed — watched fail on 'every SDD item traces to a REQ'
red -> green: ratchet: the scaffold installs every guidelines default and tailors TEST, CODE and ARCHITECTURE — watched fail on the new Run `tailor-guidelines` pin
red -> green: tailor-guidelines: the kinds are TEST, CODE and ARCHITECTURE, and CODE's and ARCHITECTURE's examples are the project's — watched fail on the Preconditions kinds pin
```

T6 done (merged). Deviations from the plan text, each to keep an existing
pin green: the review checklist reads "for each file `guidelines-file.sh TEST`
prints for the diff, for each file `guidelines-file.sh ARCHITECTURE` prints
for it, and for each file `guidelines-file.sh CODE` prints for it"; the pin at
the CODE/TEST fixer test was updated to the new fix-paragraph wording; the
red flag "One reviewer can check both files" became "every file".

```
red -> green: develop-change: the conformance reviews run for ARCHITECTURE too — watched fail ("no ARCHITECTURE guidelines-file line")
red -> green: develop-change: an architecture finding that needs a design change is a stop — watched fail ("no architecture-finding stop")
red -> green: design-architecture: reads the architecture guidelines file, and a departure names its clause — watched fail ("step 1 does not read the architecture guidelines file")
red -> green: design-architecture: one responsibility per item lives in the guidelines template — watched fail on the first half only (step 2 still stated it); the template half was green from T1
red -> green: merge-change: the review checklist asks for the ARCHITECTURE reviews — watched fail
red -> green: verification template: guideline reviews name the ARCHITECTURE kind — watched fail
red -> green: README: tailor-guidelines names the architecture guidelines file — watched fail
```

T7 done (merged; tailored with the user, 2026-10-14). Kept and rewritten for
this repository: Domain 1 (the templates are the glossary), Domain 3 as
"one term, one meaning, across the repository", Boundaries 3 as "one job per
script and per skill", Constraints 1 as "a rule a script can decide is a bats
test", Existing code 1 with a script example. Dropped, with the user's
reasons:
- Domain 2 (a new public term enters the glossary): the templates teach
  their own grammar, and Domain 1 covers one term per concept.
- Core and edges, all four clauses: the user ruled the codebase is (meant to
  be) trivially simple; its scripts exist to do I/O and are tested whole
  against fixture repositories, so a pure core buys no test seam.
- Boundaries 1 (an item entered only through its interface) and Boundaries 2
  (an error crosses a boundary as the interface's own): dropped without a
  stated reason beyond the size of the codebase.

```
red -> green: architecture guidelines: this repository's file stands alone, naming no guardrails document or skill — watched fail ("no docs/ARCHITECTURE_GUIDELINES.md")
red -> green: architecture guidelines: every clause of this repository's file states a reason and an example — watched fail ("no docs/ARCHITECTURE_GUIDELINES.md")
red -> green: architecture guidelines: this repository's file is at most 1,500 words — watched fail ("no docs/ARCHITECTURE_GUIDELINES.md")
```

T8 done (merged):

```
red -> green: architecture guidelines: the boundary's test fake is the interface's second implementation — watched fail ("Core and edges lacks the test fake as second implementation")
```

## Conformance reviews

Round 1, TEST (`docs/TEST_GUIDELINES.md`): 0 findings; verdict "0 findings
(0 high, 0 medium, 0 low); none above low". Notes: watched-red is not
visible from the diff; `clauses_missing_reason_or_example` passes trivially
on a file with no numbered clauses, and nothing pins the clause list of
`docs/ARCHITECTURE_GUIDELINES.md`, which the file does not require.

Round 1, CODE (`docs/CODE_GUIDELINES.md`): verdict "2 findings (0 high, 1
medium, 1 low); one finding (finding-1, medium) is above low".

**finding-1**: guideline, medium — Names 3, "Name in concrete terms … no `data`, `info`, `item`, `value`, `result`, `manager`, `handle` or `process` alone" — tests/develop-refactor.bats:72

**finding-2**: guideline, low — Simplicity 2, Example: "a helper one script calls stays in that script; it moves to `lib.sh` when a second script needs it" (with Simplicity 4) — tests/architecture-guidelines.bats:11 — `clauses_missing_reason_or_example` copies the inline awk at tests/code-guidelines.bats:55-64.

Round 1, ARCHITECTURE (`docs/ARCHITECTURE_GUIDELINES.md`): verdict "4
findings — 0 high, 1 medium (finding-1), 3 low; one finding is above low".

**finding-1**: guideline, medium — Domain 2, "One term, one meaning, across the repository" — templates/ARCHITECTURE_GUIDELINES.md:102, skills/ratchet/references/upgrade-notes.md:662 — the example "this item performs no I/O" uses "unit" for a software item, not a units.yaml directory.

**finding-2**: guideline, low — Domain 2, "Where a second meaning is needed, it gets its own word." — templates/ARCHITECTURE_GUIDELINES.md, Boundaries 1 and 3 — a bare "item" means a software item there, a ledger entry elsewhere.

**finding-3**: guideline, low — Boundaries 1, "stated in one sentence without 'and' in ... the skill's description", with Existing code 1 — skills/tailor-guidelines/SKILL.md:3 — the edited description's first sentence still lists four actions joined by "and".

**finding-4**: guideline, low — step 4, a clause that refers to a document the project does not contain — docs/ARCHITECTURE_GUIDELINES.md:26-27 — the example cites `.guardrails/units.yaml`, which this repository does not have.

Dispositions: CODE finding-1 and finding-2, ARCHITECTURE finding-1, finding-3
and finding-4 dispatched as fixes (tags `fix-code-1`, `fix-arch-1`).
ARCHITECTURE finding-2: no change — each Boundaries clause says "software
item" at its first use, and the clause headings are pinned by
`architecture guidelines: the template's clauses, by heading and number`.

Round 1 fixes merged: `fix-code-1` (CODE finding-1: `item` renamed
`floor_rule` in tests/develop-refactor.bats; finding-2:
`clauses_missing_reason_or_example` moved to tests/helpers.bash and called by
both guidelines test files), `fix-arch-1` (ARCHITECTURE finding-1: "this item
performs no I/O" in the template and the upgrade notes; finding-3:
tailor-guidelines' description opens with one job; finding-4: the Domain 2
example names "a units manifest … in the form `templates/units.yaml` ships").

Round 2, TEST: 0 findings; verdict "0 findings (0 high, 0 medium, 0 low);
none above low". Note: the edited header comment in
tests/develop-refactor.bats has one overlong line (formatting, no clause).

Round 2, CODE: verdict "1 finding (0 high, 0 medium, 1 low); none above low".

**finding-1**: guideline, low — Simplicity 4, "No duplication between tasks" — tests/review-conformance.bats:31-36, tests/tailor-guidelines.bats:45-50, tests/develop-refactor.bats:72-77 — the same five architecture-floor `grep -qF` checks inline in three files.

Disposition: mechanical, fixed in the last round's fix dispatch (`fix-code-2`):
one helper in tests/helpers.bash checks the five floor items on a flattened
file.

Round 2, ARCHITECTURE: verdict "3 findings (0 high, 0 medium, 3 low); none
above low".

**finding-1**: guideline, low — Domain 2 — docs/plans/2026-10-14-architecture-guidelines.md:384, :605 — the plan's copies of the template and upgrade-note text still read "this unit performs no I/O".

**finding-2**: guideline, low — Constraints 1 — docs/ARCHITECTURE_GUIDELINES.md:32-34 — Boundaries 1's "one sentence without 'and'" is scan-checkable, and no test checks it.

**finding-3**: guideline, low — Constraints 1 — skills/develop-refactor/SKILL.md:36-44, D6 — D6 says the floor list is "in one form" in all three skills; develop-refactor's is a sentence lacking two test items, and nothing checks the form.

Dispositions (last round: nothing above low):
- finding-1: fixed in the plan (both copies now read "this item").
- finding-2: no change. Whether a script or skill has one job is judgment;
  "without 'and'" is the writing aid for it, not a rule a scan decides, and a
  scan would fail existing descriptions the Existing code clause spares.
- finding-3: D6's text corrected to state the develop-refactor exception,
  which predates this change; `fix-code-2`'s shared helper checks the five
  architecture items the same way in all three skills.

fix-code-2 merged: `states_architecture_floor` in tests/helpers.bash, called by the three floor tests. Conformance reviews converged in round 2: no finding above low in any of the three.

fix-review-1 (independent review round 1, findings 1-5) merged:

```
red -> green: upgrade notes: architecture guidelines are a project file (D3 pin) — watched fail ("no D3 routing of architecture findings") with the sentence removed
red -> green: architecture guidelines: every clause of this repository's file states a reason and an example (non-empty clause list) — watched fail ("docs/ARCHITECTURE_GUIDELINES.md has no clauses") on a copy cut to its preface
red -> green: develop-change: an architecture finding that needs a design change is a stop (renamed Derailment heading) — watched fail (no derailment section) before the heading was renamed
red -> green: design-architecture: an architecture finding stands in for the requirements, not for reading the config — watched fail on the old Preconditions
red -> green: architecture guidelines: the boundaries D4 names are stated (environment variable in Core and edges 2) — watched fail ("Core and edges 2 omits an access")
red -> green: architecture guidelines: a rule a tool can decide is an LLR with a test (language-neutral example) — watched fail ("the example is not language-neutral")
```
