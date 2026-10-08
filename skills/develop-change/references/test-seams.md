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
   implements the adapter's interface. A fake at the HTTP layer, intercepting
   the network calls to a service outside the codebase, is a boundary fake
   too, under the same contract test; the adapter above it then runs for
   real. The clock and randomness are fakeable in the same way.
3. **Every fake has a contract test.** The same assertions run against the
   fake and against the real dependency, wherever the real dependency is
   reachable in the test environment, and are skipped where it is not. A fake
   with no contract test drifts: it accepts what the real dependency rejects,
   and the tests built on it pass against behavior that never happens.
4. **An interaction is asserted only where it is the requirement.** "The
   software shall send an alarm to the pager service": the outgoing message
   is observable output, so asserting it is a behavior test, not a mock.

A fault injector, a double that makes a dependency fail on demand, is allowed
at any boundary and needs no contract test, because it imitates nothing
service-specific. The line between a fault injector and a fake is what the
double imitates:

- **A fake**, with a contract test: a double that imitates service-specific
  content the code interprets, such as an HTTP 409 with an error body, a
  database constraint error, or a tool error message the code parses. The
  real service decides that content, so the double can drift from it.
- **A fault injector**, with none: a transport- or OS-level failure, such as
  a connection refused or reset, a timeout, a dropped request, a full disk,
  or an exit status with no output the code reads. Nothing in it belongs to
  one service, so there is nothing to drift from.

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
  its error responses are the ones the real service gives. A double that
  returns the service's own error, such as a conflict response with its body,
  is this kind, not a fault injector.

A failure test may fake the successes that come before its failure, such as a
first sync that succeeds before the second times out, where each of those
successes is verified against the real service by a normal-case test in the
suite. The faked successes are then setup, not evidence.

The cost is test infrastructure: the owned services must run in the test
environment, in containers or the equivalent.

## Property-based tests

Where an interface's cases are combinatorial, or it is maths, parsing or
encoding (criteria 2 and 3 above), prefer a property test: generated inputs,
checked against an invariant that holds for all of them. Typical invariants:

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
