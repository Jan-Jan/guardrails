# Test seams Implementation Plan

**Goal:** `develop-change` states where a test attaches and which test doubles it may use, so that a project's suite verifies behavior and leaves the implementation free to change; `merge-change`'s review checks it; this repository's two platform stubs get contract tests.
**Implements:** none. No item is claimed or amended: the toolkit keeps no REQ ledger of its own. Delivers D1 to D15 below; records PR-ttg99p, PR-dfndh4 and PR-qf5tkd (open); adds ADR-8ft3hb and ADR-4xh6cf.
**Safety class:** unclassified (the toolkit has no `.guardrails/config.yaml`).
**Verification:** `sh tests/run-tests.sh`; `check-ids.sh` and `check-trace.sh` against scratch copies of `main` and of the change, criterion no finding that `main` lacks.

Decided 2026-10-08 in a `grill-requirements` interview with the maintainer.
Change 1 of three: `testing-strategy` (a `/ratchet` interview and per-project
testing-strategy document, with `mutation_command`) and `check-test-doubles`
(a scan for mocks and seam violations) follow.

## Decisions

- **D1 (2026-10-08): a test attaches only to an interface that a REQ or LLR
  describes.** A private helper gets no direct test; it is covered through the
  interface above it. A complex internal that deserves its own tests gets an
  LLR first, which makes freezing its interface a recorded design decision. In
  a project without LLRs the seam is the REQ level, the public interface.
  Extends the class C rule (`develop-change` "every SDD item the change
  touches gets tests at its own interface") to every class.
- **D2 (2026-10-08): a user journey is a REQ only when it states an outcome
  no step's REQ states**: state carried across steps, recovery mid-journey,
  or an ordering constraint. Otherwise a journey test verifies the REQs of
  the steps it walks (`verifies: REQ-a, REQ-b`), which is a REQ-level seam
  under D1. A journey REQ that restates its steps verifies each step twice
  and doubles the edit when the journey changes.
- **D3 (2026-10-08): a deeper interface earns an LLR, and with it a direct
  test, when at least one holds:**
  1. *unreachable*: a case cannot be triggered through the REQ interface
     without faking code the project owns;
  2. *combinatorial*: driving its cases from the REQ interface multiplies past
     what is practical to enumerate;
  3. *intrinsic*: maths, parsing, encoding or a numerical transform whose
     algorithm has a contract worth stating independently of its caller.

  Otherwise the internal is not tested directly. A case reachable from the REQ
  interface with a boundary fake is tested there, even where a deeper seam
  would be easier. The size threshold for criterion 2 (roughly a dozen tests
  at the parent interface spent on one internal's cases) is guidance in
  `references/`, not a rule: no check can read it.
- **D4 (2026-10-08): test doubles.**
  1. No mock of code the project owns, and no assertion on how owned code was
     called.
  2. (Narrowed by D7 point 4.) Fakes only at process boundaries: network, clock, randomness, filesystem
     and storage, the operating system and hardware, other processes. Each
     boundary sits behind one adapter the project owns; the fake implements
     the adapter's interface, and code calls the adapter, never the
     third-party library directly.
  3. Every fake has a contract test: the same tests run against the real
     adapter and the fake wherever the real dependency is reachable in the
     test environment. This repository's own instance of drift: the BSD
     `date` stub accepted options it never applied (PR-w8k3np).
  4. An interaction at a boundary may be asserted only where the interaction
     is the requirement, such as an outgoing alarm message: that message is
     observable output.

  A strict no-doubles rule was rejected: it makes the robustness rule's
  dependency-failure and resource-exhaustion tests impossible.
- **D5 (2026-10-08): property-based tests.**
  1. Where an interface's cases are combinatorial (D3 criteria 2 and 3),
     prefer a property test, generated inputs checked against an invariant,
     over enumerated examples. Typical invariants: round-trip, idempotence,
     agreement with an oracle, monotonicity or bounds. A preference, not a
     rule: an interface with no useful invariant gets a property that
     restates the implementation.
  2. Every property test runs with a fixed seed or prints its seed on
     failure, so the failing run can be repeated.
  3. A counterexample a property test finds becomes a pinned example test
     beside it, with its `verifies:` annotation, before the fix, as
     `resolve-problem` treats any bug.

  Mandatory property tests under D3 criterion 2 were rejected for the same
  reason as point 1's caveat.
- **D6 (2026-10-08): change 1 sets what mutation evidence means; change 2
  (`testing-strategy`) sets whether a project must produce it.** The skill
  text states that mutation testing is how a project shows that D1's
  interface-only tests reach the internals, and what a surviving mutant
  means: a missing test *at the seam*, or dead code to delete. A survivor
  never justifies a test below the seam unless D3 holds. The obligation per
  class, a `mutation_command` and a score floor in `config.yaml` (after
  `coverage_command`), belong to change 2: the tool is per language, and an
  obligation with no command to run would be unchecked, which is how this
  repository's own mutation evidence decayed (PR-crcee5).

- **D7 (2026-10-08): UI seams.**
  1. `SKILL.md` gets one line: in a UI, the REQ interface is what the user
     perceives and does, plus what the app sends out; components, props,
     hooks, store shape and CSS classes are implementation.
  2. `references/ui-seams.md` carries the worked application: a thin UI over
     a framework-free core, tests driven through the DOM by accessible role
     and label, UI states enumerated (loading, empty, error, offline, ...),
     a real-browser suite only for what jsdom cannot do (service worker,
     offline, storage quota).
  3. A markup snapshot test carries no `verifies:` annotation: it checks
     markup, not behavior. Visual regression verifies a REQ only where the
     REQ is about appearance itself.
  4. (Limited to the normal case by D8.) **Services the project owns are not faked in REQ-level tests.** A
     backend, database or sync service that the codebase contains or that
     the app configuration declares as part of the system runs for real;
     only a service outside the codebase is faked (D4). This narrows D4
     point 2: the boundary is the codebase, not the process. The clock and
     randomness stay fakeable.

- **D8 (2026-10-08): an owned service is real on the good path; its
  failures may be faked.** D7 point 4 applies to the normal case only. A
  failure case (unreachable, timeout, rejected write, conflict) may come
  from fault injection on the real connection or from a fake of the owned
  service, as D4 allows at any boundary; the fake falls under D4 point 3,
  its contract test. Rejected: requiring every failure to be produced by the
  real service, which makes many robustness cases unreachable without
  test-only states in the service.

- **D9 (2026-10-08): a failure test may fake the successes that precede the
  failure**, where each of those successes is also verified against the real
  service by a normal-case test in the suite. The faked successes are setup,
  not evidence. Rejected: real successes with only the failing step faked,
  which ties every multi-step failure test to a mid-test fault-injection
  proxy.

- **D10 (2026-10-08): the rules bind the tests a change writes or edits, not
  the existing suite.** A new test follows D1 to D9. A change that must edit
  an existing violating test moves it to the seam instead of repairing it in
  place. A violating test that still passes is left alone: deleting it
  without a replacement at the seam loses coverage. No change rewrites a
  suite wholesale for compliance. Flagging existing violations as retrofit
  findings waits for change 3, whose scan can detect them.

- **D11 (2026-10-08): this change adds contract tests for the repository's two
  platform stubs**, `make_strict_awk` and `make_bsd_date`
  (`tests/helpers.bash`). Their tests in `tests/portability.bats` check each
  stub against its own specification; the new tests run the same
  assertions against the real BWK awk and BSD `date` where present and skip
  where absent. D10 protects adopters' suites; it does not exempt this
  repository from a rule it ships, and PR-w8k3np is the drift D4 point 3
  exists to catch. The fault injectors (`make_git_failing_on`,
  `make_failing_awk`, `make_stub_bats`) fall under D8 and need no contract
  test. (amended 2026-10-08, review round 3, finding-23: D14 is what
  classifies them as fault injectors, each a transport- or OS-level failure
  or an exit status with no output the code reads, needing no contract
  test. D8 concerns the failure cases of an owned service.)

- **D12 (2026-10-08): the independent review at `merge-change` step 6a
  checks the rules until change 3 can scan for them.** A section "## The
  test checklist" in `skills/merge-change/references/review-checklist.md`,
  which step 6a hands to every reviewer every round, asks of each new or
  edited test whether it attaches to an interface a REQ or LLR describes,
  with every double a boundary fake with a contract test, a fake of an owned
  service in a failure case under its contract test, or a fault injector
  (D1, D4, D8, D14); whether an owned service runs for real on the normal
  path (D9; amended 2026-10-08, review round 3, finding-23: the rule is D7
  point 4 and D8, not D9); and whether any markup snapshot carries a
  `verifies:` annotation (D7). (amended 2026-10-08, review round 2, finding-10: the text
  had named two questions beside `templates/verification.md`, which is not
  what was built.) Rejected: a
  `verify-before-merge` check, whose checks are mechanical, while choosing a
  seam is judgement.

- **D13 (2026-10-08): two ADRs.** ADR-8ft3hb records the seam rule (D1
  with D3, its exception path). ADR-4xh6cf records that owned services are
  real on the good path (D4, D7 point 4, D8, D9). The other decisions are
  mainstream practice, guidance, or scope and process, and fail the
  three-part test.

- **D14 (2026-10-08, review round 1, finding-4): a double that imitates
  service-specific content the code interprets is a fake, and needs a
  contract test (D4 point 3); a transport- or OS-level failure that imitates
  nothing service-specific is a fault injector, and needs none.** Fake: an
  HTTP 409 with an error body, a database constraint error, a tool error
  message the code parses. Fault injector: connection refused or reset, a
  timeout, a dropped request, a full disk, an exit status with no output the
  code reads. The review checklist allows, beside a boundary fake and a
  fault injector, a fake of an owned service in a failure case under its
  contract test (D8; finding-3).

- **D15 (2026-10-08, review round 2, finding-8): pin and declare scope.**
  The text tests pin each decision's operative clauses, listed explicitly in
  "Pinned clauses (D15)" below; wording beyond that list is the review's to
  judge, not the tests'. A reviewer judges test strength against the list.
  Each pin is a fixed-string grep of one line of the file; a whole-line
  match (`grep -qxF`) where a mutation could append to the line. Finding-9
  adds one clause to D4 point 2 under this list: a fake at the HTTP layer,
  by network interception, of a service outside the codebase is a boundary
  fake under the same contract test, and randomness stays fakeable beside
  the clock.

## Tasks

T1 and T3 run in parallel: their file sets are disjoint. T2 runs after T1,
because both add tests to `tests/skills.bats`.

### T1 — `develop-change` states where a test attaches

**Files touched:** `skills/develop-change/SKILL.md`, `skills/develop-change/references/test-seams.md`, `skills/develop-change/references/ui-seams.md`, `tests/skills.bats`
**Parallel:** yes (with T3)

1. **RED.** Append these tests to the end of `tests/skills.bats`:

   ~~~bash

   # --- test seams (docs/plans/2026-10-07-test-seams.md) ------------------------

   @test "develop-change: a test attaches only to an interface a REQ or LLR describes" {
       # verifies: D1, D2, D3 (docs/plans/2026-10-07-test-seams.md)
       skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
       seams="$BATS_TEST_DIRNAME/../skills/develop-change/references/test-seams.md"
       grep -qF '**A test calls only an interface that a REQ or LLR describes.**' "$skill"
       grep -qF '**A deeper interface gets a direct test only once it has an LLR**' "$skill"
       grep -qF 'A case reachable from above is tested there.' "$skill"
       grep -qF '1. **Unreachable.**' "$seams"
       grep -qF '2. **Combinatorial.**' "$seams"
       grep -qF '3. **Intrinsic.**' "$seams"
       grep -qF 'Convenience is not on the list.' "$seams"
   }

   @test "develop-change: doubles fake only at the codebase boundary, each with a contract test" {
       # verifies: D4, D8, D9 (docs/plans/2026-10-07-test-seams.md)
       skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
       seams="$BATS_TEST_DIRNAME/../skills/develop-change/references/test-seams.md"
       grep -qF '**Test doubles.** Never mock code the project owns or assert how it was' "$skill"
       grep -qF 'give every fake a contract test' "$skill"
       grep -qF 'A service the project owns runs for real' "$skill"
       grep -qF 'its failures may be injected or faked.' "$skill"
       grep -qF '3. **Every fake has a contract test.**' "$seams"
       grep -qF 'The faked successes are then setup, not evidence.' "$seams"
   }

   @test "develop-change: property tests repeat and pin, and a survivor never goes below the seam" {
       # verifies: D5, D6 (docs/plans/2026-10-07-test-seams.md)
       skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
       seams="$BATS_TEST_DIRNAME/../skills/develop-change/references/test-seams.md"
       grep -qF 'fix or print its seed, and pin each counterexample' "$skill"
       grep -qF 'seam, or dead code: never a test below the seam.' "$skill"
       grep -qF -- '- **Repeatable.**' "$seams"
       grep -qF -- '- **Pinned.**' "$seams"
       grep -qF 'A survivor never justifies a test below the seam' "$seams"
   }

   @test "develop-change: a UI's interface is what the user perceives, and a markup snapshot verifies nothing" {
       # verifies: D7 (docs/plans/2026-10-07-test-seams.md)
       skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
       ui="$BATS_TEST_DIRNAME/../skills/develop-change/references/ui-seams.md"
       grep -qF 'A markup snapshot carries no `verifies:` annotation.' "$skill"
       grep -qF 'The REQ interface of a UI is what the user perceives and does' "$ui"
       grep -qF -- '- **A markup snapshot carries no `verifies:` annotation.**' "$ui"
   }

   @test "develop-change: the seam rules bind new and edited tests, not the existing suite" {
       # verifies: D10 (docs/plans/2026-10-07-test-seams.md)
       skill="$BATS_TEST_DIRNAME/../skills/develop-change/SKILL.md"
       seams="$BATS_TEST_DIRNAME/../skills/develop-change/references/test-seams.md"
       grep -qF 'These rules bind the tests a change writes or edits.' "$skill"
       grep -qF 'No change rewrites a suite wholesale' "$seams"
   }
   ~~~

2. **Verify RED.** `sh tests/run-tests.sh tests/skills.bats`. Expected: 115
   tests, the five new ones `not ok`, each failing on its first `grep` (the
   SKILL.md text is absent), every other test `ok`.

3. **GREEN, `SKILL.md`.** In `skills/develop-change/SKILL.md`, insert this
   section after the **Bugs.** paragraph (the one ending "run `analyze-risks`
   before closing.") and before `### Delegation: dispatch every plan task`,
   with one blank line on each side:

   ~~~markdown
   ### Where a test attaches
   
   **A test calls only an interface that a REQ or LLR describes.** A private
   helper is covered through the interface above it. Without LLRs, the seam is
   the REQ level: the public interface. A user journey verifies the REQs of the
   steps it walks, unless it states an outcome none of them states.
   
   **A deeper interface gets a direct test only once it has an LLR**
   (`design-architecture`). It earns one only when a case cannot be triggered
   from above without faking code the project owns, when its cases multiply past
   enumeration from above, or when it is maths, parsing, encoding or a numerical
   transform. A case reachable from above is tested there.
   
   **Test doubles.** Never mock code the project owns or assert how it was
   called. Fake only at the codebase boundary, behind an adapter the project
   owns, and give every fake a contract test that runs against the real
   dependency wherever it is reachable. A service the project owns runs for real
   on the normal path; its failures may be injected or faked. Assert an
   interaction only where the interaction is the requirement.
   
   **Permutations and evidence.** Prefer a property test where cases are
   combinatorial; fix or print its seed, and pin each counterexample as an
   example test before the fix. A surviving mutant means a missing test at the
   seam, or dead code: never a test below the seam.
   
   **UI.** The REQ interface is what the user perceives and does, plus what the
   app sends out. A markup snapshot carries no `verifies:` annotation.
   
   These rules bind the tests a change writes or edits. An existing test that
   breaks them and must be edited moves to the seam; one that still passes is
   left alone.
   ~~~

   Add this row as the last row of the `## Red flags` table:

   ~~~markdown
   | "This helper is complex, I'll test it directly" | Give it an LLR first, or test it through the interface above (`references/test-seams.md`). |
   ~~~

   Replace the `## References` list with:

   ~~~markdown
   - `references/mutation-anchors.md` — read when the step 6 grep finds a hit.
   - `references/test-seams.md` — read when you are about to add an LLR to get a
     test seam or write a test double, or when a mutant survives.
   - `references/ui-seams.md` — read when the change has a user interface.
   - `references/rationale.md` — read when a rule here seems wrong for your case,
     or before proposing to change one.
   ~~~

   Check the ceiling: `wc -w < skills/develop-change/SKILL.md` prints at most
   2000 (measured at plan time: 1637 before, 348 words added, 1985; 1989 as
   built, after the References entry was reworded to the "read when" form
   `skill shape: the References section lists exactly the reference files`
   requires).

4. **GREEN, references.** Create `skills/develop-change/references/test-seams.md`
   with exactly this content:

   ~~~markdown
   # Where a test attaches, and the doubles it may use
   
   Read this before adding an LLR to get a test seam, before writing a test
   double, or when a mutant survives. `SKILL.md` "Where a test attaches" states
   the rules; this file gives the reasons and the boundaries.
   
   ## Why the seam is a requirement's interface
   
   A suite that tests every function holds the implementation in place: a
   refactor that keeps every behavior still breaks each test pinned to a
   function it moved. A test at an interface that a REQ or LLR describes breaks
   only when a behavior a requirement states changes. The `verifies:` annotation
   already ties every test to a requirement; the seam rule makes the
   requirement's interface the only place the test may call.
   
   Writing an LLR to get a seam is design work, done in `design-architecture`.
   That friction is deliberate. An LLR freezes an interface, and freezing one
   should be a recorded decision, not a side effect of a test.
   
   ## When a deeper interface earns an LLR
   
   At least one of these holds:
   
   1. **Unreachable.** A case cannot be triggered through the REQ interface
      without faking code the project owns. A retry policy whose third attempt
      only happens after two specific internal failures is an example.
   2. **Combinatorial.** Driving the internal's cases from the REQ interface
      multiplies past what is practical to enumerate. As guidance, not a rule:
      when roughly a dozen tests at the parent interface would be spent driving
      one internal's cases, that internal is a candidate.
   3. **Intrinsic.** Maths, parsing, encoding or a numerical transform whose
      algorithm has a contract worth stating independently of its caller.
   
   Convenience is not on the list. A case reachable from the REQ interface with a
   boundary fake is tested there, even where a deeper seam would be easier to
   write.
   
   Deep IO with complex error handling follows the same order. An error the code
   handles (retried, turned into a fallback, translated for the user) is
   observable at the REQ interface: trigger it through a boundary fake there.
   Where the error handling has a contract of its own (backoff, partial writes,
   rollback) and criterion 1 or 2 holds, the adapter becomes a software item with
   an LLR stating that contract, tested at its own interface against the real
   resource where possible: a temporary directory, a real database file.
   
   ## User journeys
   
   A journey test walks several REQs and verifies each of them:
   `verifies: REQ-a, REQ-b`. A journey is a REQ of its own only when it states an
   outcome none of its steps states: state carried across steps, recovery partway
   through, an ordering constraint. A journey REQ that restates its steps
   verifies each step twice and doubles the edit when the journey changes.
   
   ## Test doubles
   
   1. **No mock of code the project owns, and no assertion on how owned code was
      called.** These are the doubles that hold an implementation in place.
   2. **Fakes at the codebase boundary only.** A service, library or resource
      outside the codebase sits behind one adapter the project owns. Code calls
      the adapter, never the third-party interface directly, and the fake
      implements the adapter's interface. The clock and randomness are fakeable
      in the same way.
   3. **Every fake has a contract test.** The same assertions run against the
      fake and against the real dependency, wherever the real dependency is
      reachable in the test environment, and are skipped where it is not. A fake
      with no contract test drifts: it accepts what the real dependency rejects,
      and the tests built on it pass against behavior that never happens.
   4. **An interaction is asserted only where it is the requirement.** "The
      software shall send an alarm to the pager service": the outgoing message
      is observable output, so asserting it is a behavior test, not a mock.
   
   A fault injector, a double that makes a dependency fail on demand, is allowed
   at any boundary. It stands in for a failure, not for a behavior.
   
   A rule of no doubles at all was rejected: it makes the dependency-failure and
   resource-exhaustion tests of the robustness rule impossible.
   
   ## Services the project owns
   
   A backend, database or sync service that the codebase contains, or that the
   application configuration declares part of the system, runs for real in a
   REQ-level test of the normal case. Faking it there verifies the main behavior
   against something the project never ships.
   
   Its failures may be faked. A real service does not time out, refuse a
   connection or report a conflict on demand, so a failure case may come from:
   
   - fault injection on the real connection: a proxy that drops, delays or
     resets traffic, or a browser test's request interception aborting a real
     request;
   - the real service put into the failing state: conflicting data seeded, a
     small volume filled, a permission revoked;
   - a fake of the service, under the same contract test as any fake, so that
     its error responses are the ones the real service gives.
   
   A failure test may fake the successes that come before its failure, such as a
   first sync that succeeds before the second times out, where each of those
   successes is verified against the real service by a normal-case test in the
   suite. The faked successes are then setup, not evidence.
   
   The cost is test infrastructure: the owned services must run in the test
   environment, in containers or the equivalent.
   
   ## Property-based tests
   
   Where an interface's cases are combinatorial (criteria 2 and 3 above), prefer
   a property test: generated inputs, checked against an invariant that holds for
   all of them. Typical invariants:
   
   - round-trip: decoding what was encoded gives the input back;
   - idempotence: applying the operation twice equals applying it once;
   - agreement with an oracle: a slow, obviously correct version of the same
     function;
   - monotonicity or bounds.
   
   It is a preference, not a rule. An interface with no useful invariant gets a
   property that restates the implementation, which proves nothing.
   
   Two rules do bind:
   
   - **Repeatable.** Every property test runs with a fixed seed, or prints its
     seed on failure, so the failing run can be repeated.
   - **Pinned.** A counterexample a property test finds becomes an example test
     beside it, with its `verifies:` annotation, before the fix. It then stays
     covered when the generator changes.
   
   ## Mutation evidence
   
   Line coverage shows that a line ran, not that a test would notice it changing.
   Mutation testing changes the code and runs the suite: a mutant no test kills
   is a route the tests do not check. It is the evidence that tests at the seam
   reach the internals below it.
   
   A surviving mutant means one of two things:
   
   - a test is missing **at the seam**: add it there;
   - the mutated code is dead: delete it.
   
   A survivor never justifies a test below the seam unless one of the three
   criteria above holds. Whether a project must run mutation testing, with which
   command and to what score, is that project's testing-strategy decision.
   
   ## Existing suites
   
   These rules bind the tests a change writes or edits, not the suite that
   already exists. A change that must edit an existing test that breaks them
   moves it to the seam instead of repairing it in place: such a test usually
   broke because a refactor moved the internal it was pinned to. A test that
   breaks the rules and still passes is left alone, since deleting it without a
   replacement at the seam loses coverage. No change rewrites a suite wholesale
   for compliance.
   ~~~

   Create `skills/develop-change/references/ui-seams.md` with exactly this
   content:

   ~~~markdown
   # Testing a user interface at its seams
   
   Read this when the change has a user interface. It applies `SKILL.md` "Where
   a test attaches" and `references/test-seams.md` to one; it adds one rule of
   its own, on markup snapshots.
   
   ## The interface
   
   The REQ interface of a UI is what the user perceives and does, plus what the
   application sends to the outside world. Components, props, hooks, store shape
   and CSS classes are implementation: a test that names them breaks on a
   refactor that keeps every behavior.
   
   ## Keep the UI layer thin
   
   Put state, rules and transitions in a core that does not depend on the UI
   framework: reducers, state machines, view models. That core has an interface
   as well defined as a library's, and it is tested like one, with its
   permutations and properties. Most of what makes a UI hard to test is logic
   inside components.
   
   ## Feature tests through the DOM
   
   - Find elements the way a user does: by accessible role, label and visible
     text, not by test identifier or class name.
   - Render real child components, the real store and the real router.
   - Fake only what is outside the codebase, at the HTTP layer, plus the clock.
     A service the project owns runs for real on the normal path
     (`references/test-seams.md`, "Services the project owns").
   
   ## Enumerate the states
   
   List the states each screen can be in and test each: loading, empty, error,
   partial, stale, offline, permission denied. A core written as a state machine
   makes the list explicit, and the paths through it can be generated rather than
   written by hand.
   
   ## What only a real browser shows
   
   Keep a small suite in a real browser for what a simulated DOM cannot do: the
   service worker lifecycle and its update flow, offline behavior, caching,
   IndexedDB, storage quota, installation. For a progressive web app, offline is
   the main error route, and a full storage quota is the robustness rule's
   resource exhaustion.
   
   ## Snapshots and appearance
   
   - **A markup snapshot carries no `verifies:` annotation.** It records markup,
     not behavior: it fails on a refactor that changes nothing a user sees, and
     passes a regression that the markup does not show.
   - Visual regression verifies a REQ only where the REQ is about appearance
     itself, such as the color of an alarm.
   - An automated accessibility check is a cheap assertion worth running on
     every screen.
   ~~~

5. **Verify GREEN.** `sh tests/run-tests.sh tests/skills.bats`. Expected:
   115 tests, all `ok`, among them `skill shape: every SKILL.md is at most
   2,000 words` and `skill shape: the References section lists exactly the
   reference files`.

6. **Commit** (unsigned): `docs: develop-change states where a test attaches
   and which doubles it may use`.

**Done** (2026-10-08, `dfb3445`, merged `dae290b`). 115 passed, 0 failed in
`tests/skills.bats`; the RED run was 110 passed, 5 failed, the five new tests.

red -> green:
- `develop-change: a test attaches only to an interface a REQ or LLR describes` — watched fail for the right reason before the implementation existed (first grep: the SKILL.md sentence absent)
- `develop-change: doubles fake only at the codebase boundary, each with a contract test` — watched fail for the right reason before the implementation existed (first grep: the **Test doubles.** sentence absent)
- `develop-change: property tests repeat and pin, and a survivor never goes below the seam` — watched fail for the right reason before the implementation existed (first grep: the seed sentence absent)
- `develop-change: a UI's interface is what the user perceives, and a markup snapshot verifies nothing` — watched fail for the right reason before the implementation existed (first grep: the snapshot sentence absent)
- `develop-change: the seam rules bind new and edited tests, not the existing suite` — watched fail for the right reason before the implementation existed (first grep: the scope sentence absent)

**Note** (2026-10-08, review round 1). Steps 3 and 4 say "exactly this
content", but commit `43f9217` reworded two sentences after T1 merged. In
`skills/develop-change/SKILL.md`, "A user journey verifies the REQs of the
steps it walks, unless it states an outcome none of them states." became "A
user journey is a REQ only when it states an outcome none of its steps states;
otherwise it verifies theirs." In
`skills/develop-change/references/test-seams.md`, "Where an interface's cases
are combinatorial (criteria 2 and 3 above), prefer a property test" became
"Where an interface's cases are combinatorial, or it is maths, parsing or
encoding (criteria 2 and 3 above), prefer a property test". `SKILL.md` is
1990 words after the rewording (`wc -w`), not the 1989 that step 3 records
as built.

**Note** (2026-10-08, review round 3, findings 19-22). The steps above stay
as written; four text edits followed. Finding-19: the fault-injector
sentence in `skills/merge-change/references/review-checklist.md` now reads
"makes a transport or OS operation fail, or a command exit with no output
the code reads, and imitates nothing service-specific", carrying D14's exit
status. Finding-20: `SKILL.md` now reads "Prefer a property test where cases
are combinatorial or the code is maths, parsing or encoding", carrying D5's
scope (D3 criteria 2 and 3); `SKILL.md` is 1998 words (`wc -w`). Finding-21:
the opening of `skills/develop-change/references/ui-seams.md` says it adds
rules of its own on markup snapshots and visual regression, not one rule.
Finding-22: its line on an automated accessibility check, which no decision
backs, is deleted.

### T2 — the review checks the seam and the doubles

**Files touched:** `skills/merge-change/references/review-checklist.md`, `tests/skills.bats`
**Parallel:** no (serial, after T1)

1. **RED.** Append to the end of `tests/skills.bats`:

   ~~~bash

   @test "merge-change: the review checklist asks where each new test attaches and which doubles it uses" {
       # verifies: D12 (docs/plans/2026-10-07-test-seams.md)
       checklist="$BATS_TEST_DIRNAME/../skills/merge-change/references/review-checklist.md"
       grep -qF 'checklist applies when the diff touches documentation, and the test' "$checklist"
       grep -qxF '## The test checklist' "$checklist"
       grep -qF -- '- It calls an interface that a REQ or LLR describes, not a private' "$checklist"
       grep -qF -- '- Every test double is a fake at the codebase boundary with a contract' "$checklist"
       grep -qF -- '- A service the project owns runs for real on the normal path.' "$checklist"
       grep -qF -- '- No markup snapshot carries a `verifies:` annotation.' "$checklist"
   }
   ~~~

2. **Verify RED.** `sh tests/run-tests.sh tests/skills.bats`. Expected: 116
   tests, the new one `not ok` on its first `grep`, every other `ok`.

3. **GREEN.** In `skills/merge-change/references/review-checklist.md`,
   replace the two lines

   ~~~markdown
   every round. The severities apply to every review; the checklist applies when
   the diff touches documentation.
   ~~~

   with

   ~~~markdown
   every round. The severities apply to every review; the documentation
   checklist applies when the diff touches documentation, and the test
   checklist when it touches tests.
   ~~~

   Then append this section at the end of the file, after one blank line:

   ~~~markdown
   ## The test checklist

   The reviewer checks each new or edited test and raises a finding for each one
   that fails (`develop-change`, "Where a test attaches").

   - It calls an interface that a REQ or LLR describes, not a private
     helper. A direct test of a deeper interface has an LLR behind it.
   - Every test double is a fake at the codebase boundary with a contract
     test, or a fault injector. No test mocks code the project owns or asserts
     how owned code was called, unless the interaction is the requirement.
   - A service the project owns runs for real on the normal path.
   - No markup snapshot carries a `verifies:` annotation.
   ~~~

4. **Verify GREEN.** `sh tests/run-tests.sh tests/skills.bats`. Expected: 116
   tests, all `ok`.

5. **Commit** (unsigned): `docs: the step 6a review checks where tests attach
   and which doubles they use`.

**Done** (2026-10-08, `bcfc733`). 116 passed, 0 failed in `tests/skills.bats`.
The file's H1 still names only the documentation checklist; left for the
deslop pass.

red -> green:
- `merge-change: the review checklist asks where each new test attaches and which doubles it uses` — watched fail for the right reason before the implementation existed (first grep: the reworded opening paragraph absent)

### T3 — contract tests for the two platform stubs

**Files touched:** `tests/portability.bats`
**Parallel:** yes (with T1)

The stub tests in `tests/portability.bats` check `make_strict_awk` and
`make_bsd_date` against their own specification. This task moves each
assertion into a function that takes the directory whose tool it checks, keeps
the stub tests as calls to it, and adds a contract test that runs the same
function against the real BWK awk and BSD `date` where present (D11). Measured
at plan time on macOS (Darwin 27): `/usr/bin/awk -version` prints
`awk version 20200816`; given `-v kws='a:<newline>b:'` it exits 2 with
`newline in string`; `/bin/date -d "3 days ago"` and `-v--1d` exit 1;
`-v-3d` and a plain call exit 0. `/bin/date -v+0d` exits 0 there and fails
under GNU date, which has no `-v`.

1. **RED.** Insert these four tests immediately after the test
   `strict awk: passes every other invocation through to the real awk` (they
   call functions step 3 creates):

   ~~~bash

   @test "strict awk contract: the real BWK awk rejects a literal newline in a -v assignment" {
       # verifies: PR-v3j4s2, D11 (docs/plans/2026-10-07-test-seams.md)
       real=$(real_bwk_awk_dir) || skip "no BWK awk on this machine"
       awk_rejects_newline_in_assignment "$real"
   }

   @test "strict awk contract: the real BWK awk accepts the same list flattened to spaces" {
       # verifies: PR-v3j4s2, D11 (docs/plans/2026-10-07-test-seams.md)
       real=$(real_bwk_awk_dir) || skip "no BWK awk on this machine"
       awk_accepts_flattened_list "$real"
   }

   @test "strict awk contract: the real BWK awk takes a plain -v assignment" {
       # verifies: PR-v3j4s2, D11 (docs/plans/2026-10-07-test-seams.md)
       real=$(real_bwk_awk_dir) || skip "no BWK awk on this machine"
       awk_passes_plain_assignment "$real"
   }
   ~~~

   and this one immediately after `bsd date stub: rejects -d and a doubled
   sign in -v`:

   ~~~bash

   @test "bsd date contract: the real BSD date rejects -d and a doubled sign in -v" {
       # verifies: PR-yd2sft, D11 (docs/plans/2026-10-07-test-seams.md)
       real=$(real_bsd_date_dir) || skip "no BSD date on this machine"
       bsd_date_rejects_gnu_spellings "$real"
   }
   ~~~

2. **Verify RED.** `sh tests/run-tests.sh tests/portability.bats`. Expected
   on macOS: 17 tests, the four new ones `not ok` with
   `real_bwk_awk_dir: command not found` or `real_bsd_date_dir: command not
   found`, every other `ok`.

3. **GREEN.** Replace the comment block that opens with "The stub is the
   instrument every other test in this file depends on" and the three tests
   after it (`strict awk: rejects a literal newline in a -v assignment`,
   `strict awk: accepts the same list flattened to spaces`, `strict awk:
   passes every other invocation through to the real awk`) with:

   ~~~bash
   # The stub is the instrument every other test in this file depends on. An
   # instrument that never fires reports a clean bill of health for a broken
   # tree, so it is calibrated first, in both directions.
   #
   # Each assertion is a function that takes the directory whose awk it checks,
   # so the same assertions run against the stub and, as a contract test,
   # against the real BWK awk where this machine has one (D11 of
   # docs/plans/2026-10-07-test-seams.md). A stub checked only against its own
   # specification drifts from the tool it imitates.

   awk_rejects_newline_in_assignment() {
       run env PATH="$1:$PATH" awk -v kws='a:
   b:' 'BEGIN { print "ok" }' /dev/null
       [ "$status" -eq 2 ] || { echo "expected exit 2, got $status: $output"; false; }
       [[ "$output" == *"newline in string"* ]] || { echo "$output"; false; }
   }

   awk_accepts_flattened_list() {
       # The fix's premise: `split()` under the default FS splits on runs of
       # space, tab and newline alike, so the flattened list is the same list.
       run env PATH="$1:$PATH" awk -v kws='a: b:' \
           'BEGIN { n = split(kws, K); print "fields:", n, K[1], K[2] }' /dev/null
       [ "$status" -eq 0 ] || { echo "expected exit 0, got $status: $output"; false; }
       [ "$output" = "fields: 2 a: b:" ] || { echo "$output"; false; }
   }

   awk_passes_plain_assignment() {
       run env PATH="$1:$PATH" awk -v k=plain 'BEGIN { print k }' /dev/null
       [ "$status" -eq 0 ] || { echo "$output"; false; }
       [ "$output" = plain ] || { echo "$output"; false; }
   }

   # The directory of a real BWK awk, or status 1. BWK awk answers `-version`
   # with "awk version <date>"; gawk, mawk and busybox awk reject it as a
   # malformed -v assignment, so they never match.
   real_bwk_awk_dir() {
       for candidate in /usr/bin/awk "$(command -v awk)"; do
           [ -x "$candidate" ] || continue
           "$candidate" -version 2>/dev/null | grep -q '^awk version ' || continue
           dirname "$candidate"
           return 0
       done
       return 1
   }

   @test "strict awk: rejects a literal newline in a -v assignment" {
       # verifies: PR-v3j4s2
       bin=$(make_strict_awk)
       awk_rejects_newline_in_assignment "$bin"
   }

   @test "strict awk: accepts the same list flattened to spaces" {
       # verifies: PR-v3j4s2
       bin=$(make_strict_awk)
       awk_accepts_flattened_list "$bin"
   }

   @test "strict awk: passes every other invocation through to the real awk" {
       # verifies: PR-v3j4s2
       bin=$(make_strict_awk)
       awk_passes_plain_assignment "$bin"
   }
   ~~~

   The three contract tests from step 1 stay immediately after this block.

   Replace the test `bsd date stub: rejects -d and a doubled sign in -v` with:

   ~~~bash
   # Calibrated like the awk stub, and for the same reason: on macOS the real
   # date already behaves this way, so an instrument that never fired would be
   # invisible here and useless on the GNU box it exists for. The assertion is
   # shared with the contract test below.
   bsd_date_rejects_gnu_spellings() {
       run env PATH="$1:$PATH" date -d "3 days ago" +%Y-%m-%d
       [ "$status" -ne 0 ] || { echo "-d was accepted: $output"; false; }
       run env PATH="$1:$PATH" date -v--1d +%Y-%m-%d
       [ "$status" -ne 0 ] || { echo "-v--1d was accepted: $output"; false; }
       run env PATH="$1:$PATH" date -v-3d +%Y-%m-%d
       [ "$status" -eq 0 ] || { echo "a valid adjustment was rejected: $output"; false; }
       run env PATH="$1:$PATH" date +%Y-%m-%d
       [ "$status" -eq 0 ] || { echo "a plain call was rejected: $output"; false; }
   }

   # The directory of a real BSD date, or status 1. Only BSD date takes `-v`.
   real_bsd_date_dir() {
       for candidate in /bin/date /usr/bin/date "$(command -v date)"; do
           [ -x "$candidate" ] || continue
           "$candidate" -v+0d +%Y-%m-%d >/dev/null 2>&1 || continue
           dirname "$candidate"
           return 0
       done
       return 1
   }

   @test "bsd date stub: rejects -d and a doubled sign in -v" {
       # verifies: PR-yd2sft
       bin=$(make_bsd_date)
       bsd_date_rejects_gnu_spellings "$bin"
   }
   ~~~

   The contract test from step 1 stays immediately after it.

4. **Verify GREEN.** `sh tests/run-tests.sh tests/portability.bats`.
   Expected on macOS: 17 tests, all `ok`, none skipped. On a machine without
   BWK awk or BSD date the matching contract tests report `ok … # skip`.

5. **Calibrate the contract tests.** A contract test that passes against the
   real tool has to be shown able to fail. In a scratch directory outside the
   worktree, write a permissive `awk` (`#!/bin/sh` then `echo ok`) and a
   permissive `date` (`#!/bin/sh` then `exit 0`), both executable. Temporarily
   change `real=$(real_bwk_awk_dir)` in the first contract test, and
   `real=$(real_bsd_date_dir)` in the date contract test, to `real=<that
   scratch directory>`, then run the file. Expected: those two tests `not
   ok`, on `expected exit 2, got 0` and `-d was accepted` respectively.
   Revert both lines (`git diff tests/portability.bats` then shows only the
   step 1 and step 3 changes) and rerun: 17 `ok`. Report this as the
   `red -> green:` evidence for the contract tests, beside the step 2 failure.

6. **Commit** (unsigned): `test: the platform stubs share their assertions
   with contract tests against the real BWK awk and BSD date`.

**Done** (2026-10-08, `3ce8642` and `d2b8b15`). 17 passed, 0 failed, 0
skipped in `tests/portability.bats` on macOS.

**Deviation from steps 1 and 2.** As planned, `real=$(real_bwk_awk_dir) ||
skip` treated exit 127 (detector not yet defined) as "tool absent", so step 2
reported four skips, not four failures: a broken or renamed detector would
skip the contract test silently, forever. Re-dispatched with a changed
approach (`d2b8b15`): a helper `contract_tool_dir <detector> <tool>` sets
`$contract_dir` on success; detector status 1 means absent and skips, except
on macOS, where both tools ship and absence fails; any other status fails as a
broken detector. Each contract test opens with
`contract_tool_dir real_bwk_awk_dir "BWK awk"` (or `real_bsd_date_dir "BSD
date"`) and passes `"$contract_dir"` to its assertion. The skip branch could
not be exercised on this machine, which has both tools.

red -> green:
- `strict awk contract: the real BWK awk rejects a literal newline in a -v assignment` — detector renamed: `not ok`, `real_bwk_awk_dir failed with status 127`; against a permissive awk: `expected exit 2, got 0: ok`; reverted: ok against `/usr/bin/awk`
- `strict awk contract: the real BWK awk accepts the same list flattened to spaces` — detector renamed: `not ok`, status 127; against the permissive awk: output `ok`, not `fields: 2 a: b:`; reverted: ok
- `strict awk contract: the real BWK awk takes a plain -v assignment` — detector renamed: `not ok`, status 127; against the permissive awk: output `ok`, not `plain`; reverted: ok
- `bsd date contract: the real BSD date rejects -d and a doubled sign in -v` — detector forced to status 1: `not ok`, `real_bsd_date_dir found no BSD date on macOS, where it ships`; against a permissive date: `-d was accepted:`; reverted: ok against `/bin/date`

**Note (2026-10-08, review round 1, D14).** The repository's other doubles,
classified by D14: does the script under test interpret what the double
emits beyond its exit status? No contract test was added and no test was
edited (D10).

| Double | Emits | Read by the script | D14 |
|---|---|---|---|
| `make_git_failing_on`, `tests/helpers.bash:530` | exit 128 and a `fatal: stub failure of git …` line on stderr | exit status only: `scripts/lib.sh:786` `… \|\| return`, `scripts/finish-merge.sh:167` `… \|\| gr_die`; stderr passes through unparsed, and `tests/lib.bats:159` checks that pass-through by the stub's own sentinel, which imitates nothing of git's | fault injector |
| `make_failing_awk`, `tests/finish-merge.bats:155` | exit 2 and a line on stderr | exit status only: `scripts/finish-merge.sh:170-173` `wt=$(… awk -v want=…) \|\| gr_die` | fault injector |
| `make_failing_awk`, `tests/merge-preflight.bats:614` | exit 2 and a line on stderr | exit status only: `scripts/merge-preflight.sh:130-131` and `:212`, each `… \|\| gr_fail` | fault injector |
| `make_stub_bats`, `tests/run-tests.bats:6` | its arguments, one per line, exit 0 | nothing: `tests/run-tests.sh:112,114` `exec "$BATS"`; the test reads the argument vector, which is run-tests.sh's requirement | no contract test needed; a recording stub, not a fault injector as D11 calls it |
| `make_stub`, `tests/run-tests.bats:42` | the shell line it is given | per use: `getconf`/`sysctl` `exit 1` (`:229`, `:257-258`) by status only; `parallel` `parallel from moreutils` (`:219`), `getconf` `echo 4`/`1`/`abc`, `sysctl` `echo 3` are read at `tests/run-tests.sh:80-82` and `:97-102` | factory: the `exit 1` uses are fault injectors, the output uses are fakes |
| `make_gnu_parallel_stub`, `tests/run-tests.bats:49` | `GNU parallel 20260822` on `--version` | `tests/run-tests.sh:80-82` matches `*'GNU parallel'*` | fake |

D11's conclusion holds for its three named doubles: none needs a contract
test. `make_git_failing_on` and both `make_failing_awk` are fault injectors;
`make_stub_bats` is a recording stub that fails nothing. `make_gnu_parallel_stub`
and the output-emitting `make_stub` uses are fakes of `parallel`, `getconf`
and `sysctl` with no contract test; D10 leaves them as they are.

## Pinned clauses (D15)

Each seam test in `tests/skills.bats` pins the clauses below, and only
these: a reviewer judges the tests' strength against this list, and any
wording outside it against the decisions. "Phrase" is a fixed-string grep
(`grep -qF`) for the text within one line; "whole line" is `grep -qxF`, so
the line must be exactly the text, leading spaces included. The test is
the exact source of each string. Files: skill is
`skills/develop-change/SKILL.md`, seams is
`skills/develop-change/references/test-seams.md`, ui is
`skills/develop-change/references/ui-seams.md`, checklist is
`skills/merge-change/references/review-checklist.md`.

### develop-change: a test attaches only to an interface a REQ or LLR describes

Verifies D1, D2, D3.

- skill, phrase: `**A test calls only an interface that a REQ or LLR describes.**`
- skill, phrase: `**A deeper interface gets a direct test only once it has an LLR**`
- skill, phrase: `A case reachable from above is tested there.`
- skill, phrase: `It earns one only when a case cannot be triggered`
- skill, phrase: `A user journey is a REQ only when it`
- seams, phrase: `A journey is a REQ of its own only when it states an`
- seams, phrase: `1. **Unreachable.**`
- seams, phrase: `2. **Combinatorial.**`
- seams, phrase: `3. **Intrinsic.**`
- seams, phrase: `Convenience is not on the list.`
- skill, whole line: `states an outcome none of its steps states; otherwise it verifies theirs.`
- seams, whole line: `1. **Unreachable.** A case cannot be triggered through the REQ interface`
- seams, whole line: `   without faking code the project owns. A retry policy whose third attempt`
- skill, whole line: `helper is covered through the interface above it. Without LLRs, the seam is`
- skill, whole line: `the REQ level: the public interface. A user journey is a REQ only when it`
- skill, whole line: `from above without faking code the project owns, when its cases multiply past`
- skill, whole line: `enumeration from above, or when it is maths, parsing, encoding or a numerical`
- seams, whole line: `   multiplies past what is practical to enumerate. As guidance, not a rule:`
- seams, whole line: `3. **Intrinsic.** Maths, parsing, encoding or a numerical transform whose`
- seams, whole line: `   algorithm has a contract worth stating independently of its caller.`

### develop-change: doubles fake only at the codebase boundary, each with a contract test

Verifies D4, D8, D9, D14.

- skill, phrase: `**Test doubles.** Never mock code the project owns or assert how it was`
- skill, phrase: `give every fake a contract test`
- skill, phrase: `A service the project owns runs for real`
- skill, phrase: `its failures may be injected or faked.`
- skill, whole line: `on the normal path; its failures may be injected or faked. Assert an`
- skill, phrase: `interaction only where the interaction is the requirement.`
- seams, phrase: `4. **An interaction is asserted only where it is the requirement.**`
- seams, phrase: `3. **Every fake has a contract test.**`
- seams, phrase: `The faked successes are then setup, not evidence.`
- seams, phrase: `- **A fake**, with a contract test: a double that imitates service-specific`
- seams, phrase: `- **A fault injector**, with none: a transport- or OS-level failure, such as`
- skill, whole line: `called. Fake only at the codebase boundary, behind an adapter the project`
- skill, whole line: `owns, and give every fake a contract test that runs against the real`
- seams, whole line: `   reachable in the test environment, and are skipped where it is not. A fake`
- seams, whole line: `first sync that succeeds before the second times out, where each of those`
- seams, whole line: `successes is verified against the real service by a normal-case test in the`
- seams, whole line: `- a fake of the service, under the same contract test as any fake, so that`
- seams, whole line: `   implements the adapter's interface. A fake at the HTTP layer, intercepting`
- seams, whole line: `   the network calls to a service outside the codebase, is a boundary fake`
- seams, whole line: `   too, under the same contract test; the adapter above it then runs for`
- seams, whole line: `   real. The clock and randomness are fakeable in the same way.`
- skill, whole line: `dependency wherever it is reachable. A service the project owns runs for real`
- seams, whole line: `   the adapter, never the third-party interface directly, and the fake`
- seams, whole line: `   fake and against the real dependency, wherever the real dependency is`

### develop-change: property tests repeat and pin, and a survivor never goes below the seam

Verifies D5, D6.

- skill, phrase: `Prefer a property test where cases are`
- seams, phrase: `encoding (criteria 2 and 3 above), prefer a property test: generated inputs,`
- skill, phrase: `fix or print its seed, and pin each counterexample`
- skill, phrase: `seam, or dead code: never a test below the seam.`
- seams, phrase: `- **Repeatable.**`
- seams, phrase: `- **Pinned.**`
- seams, phrase: `A survivor never justifies a test below the seam`
- seams, whole line: `- the mutated code is dead: delete it.`
- skill, whole line: `example test before the fix. A surviving mutant means a missing test at the`
- seams, whole line: ``   beside it, with its `verifies:` annotation, before the fix. It then stays ``
- seams, whole line: `A survivor never justifies a test below the seam unless one of the three`
- seams, whole line: `criteria above holds. Whether a project must run mutation testing, with which`
- skill, whole line: `combinatorial or the code is maths, parsing or encoding;`

### develop-change: a UI's interface is what the user perceives, and a markup snapshot verifies nothing

Verifies D7.

- skill, phrase: `` A markup snapshot carries no `verifies:` annotation. ``
- ui, phrase: `The REQ interface of a UI is what the user perceives and does`
- ui, phrase: `` - **A markup snapshot carries no `verifies:` annotation.** ``
- ui, whole line: `## Keep the UI layer thin`
- ui, phrase: `text, not by test identifier or class name.`
- ui, phrase: `- Visual regression verifies a REQ only where the REQ is about appearance`
- ui, phrase: `A service the project owns runs for real on the normal path`
- ui, whole line: `  A service the project owns runs for real on the normal path`
- ui, whole line: `- Fake only what is outside the codebase, plus the clock and randomness. A`
- ui, whole line: `  fake at the HTTP layer, by network interception, is a boundary fake under`
- ui, whole line: `  the same contract test as any fake.`
- ui, whole line: `## Enumerate the states`
- ui, whole line: `List the states each screen can be in and test each: loading, empty, error,`
- ui, whole line: `## What only a real browser shows`
- ui, whole line: `Keep a small suite in a real browser for what a simulated DOM cannot do: the`
- skill, whole line: `**UI.** The REQ interface is what the user perceives and does, plus what the`
- skill, whole line: `` app sends out. A markup snapshot carries no `verifies:` annotation. ``
- ui, whole line: `application sends to the outside world. Components, props, hooks, store shape`
- ui, whole line: `and CSS classes are implementation: a test that names them breaks on a`

### develop-change: the seam rules bind new and edited tests, not the existing suite

Verifies D10.

- skill, phrase: `These rules bind the tests a change writes or edits.`
- skill, phrase: `An existing test that`
- skill, phrase: `breaks them and must be edited moves to the seam; one that still passes is`
- seams, phrase: `No change rewrites a suite wholesale`
- seams, whole line: `moves it to the seam instead of repairing it in place: such a test usually`
- skill, whole line: `left alone.`
- seams, whole line: `breaks the rules and still passes is left alone, since deleting it without a`

### merge-change: the review checklist asks where each new test attaches and which doubles it uses

Verifies D12, D14.

- checklist, phrase: `checklist applies when the diff touches documentation, and the test`
- checklist, whole line: `## The test checklist`
- checklist, phrase: `- It calls an interface that a REQ or LLR describes, not a private`
- checklist, phrase: `- Every test double is one of three kinds: a fake at the codebase boundary`
- checklist, phrase: `with a contract test; a fake of a service the project owns, in a failure`
- checklist, whole line: `  makes a transport or OS operation fail, or a command exit with no output`
- checklist, whole line: `  the code reads, and imitates nothing service-specific; a double that`
- checklist, phrase: `- A service the project owns runs for real on the normal path.`
- checklist, phrase: `` - No markup snapshot carries a `verifies:` annotation. ``
- checklist, whole line: `  helper. A direct test of a deeper interface has an LLR behind it.`
- checklist, whole line: `  project owns or asserts how owned code was called, unless the interaction`
- checklist, whole line: `  is the requirement.`
- checklist, whole line: `  case only, under its contract test; or a fault injector. A fault injector`


## Self-review (plan-change step 9)

1. **Implements:** none is claimed; every decision with a deliverable has a
   test: D1 to D3, D4/D8/D9, D5/D6, D7 and D10 in T1; D12 in T2; D11 in T3.
   D14 is pinned by "doubles fake only at the codebase boundary, each with a
   contract test" and "the review checklist asks where each new test
   attaches and which doubles it uses"; D15 is the "Pinned clauses (D15)"
   list, which those tests and the other four seam tests grep.
   D13 is the two ADR files, already committed. D2's journey rule and D9's
   faked setup are tested through the text that states them.
2. Every step shows the exact text, code, command and expected count.
3. Names used across tasks: the section is "Where a test attaches" in T1 and
   in T2's checklist; reference files `test-seams.md` and `ui-seams.md`.
4. T1 and T3 are parallel with disjoint file sets; T2 shares
   `tests/skills.bats` with T1 and is serial after it.

## Follow-ups outside this change

- `develop-change` step 6 (the mutation-anchor grep) ships to adopters but
  greps `docs/verification/*.mutations/`, which only this repository has.
  Recorded as PR-ttg99p; not fixed here.
- `tests/run-tests.bats` fakes GNU `parallel`, `getconf` and `sysctl` with
  parsed output that no contract test checks against the real tools (D4
  point 3, D14). Recorded as PR-dfndh4; not fixed here.
