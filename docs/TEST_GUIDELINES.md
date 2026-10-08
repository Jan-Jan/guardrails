# Test guidelines

This file states the project's test preferences. An agent reads this file
and no other guidelines file. The compliance floor the skills state wins any
conflict, and a clause that contradicts it is a finding against the clause.
A project that changes a clause rewrites its reason and examples with it.

## Seams

1. **A test calls only an interface that a REQ or LLR describes.** A private
   helper is covered through the interface above it. Without LLRs, the seam is
   the REQ level: the public interface. Why: a test pinned to a function
   breaks on a refactor that moves it and keeps every behavior; a test at a
   requirement's interface breaks only when a stated behavior changes.

   In this repository the interface is a script's command line. A bats test
   runs `sh scripts/<name>.sh` with arguments in a temporary repository and
   asserts on its output, its exit status and the files it leaves. A function
   in `scripts/lib.sh` is covered through the scripts that call it; a new
   test does not source the library to call one directly unless clause 2
   below allows it, and the existing direct tests in `tests/lib.bats` are
   spared (Existing suites). This repository keeps no REQ or LLR ledger of
   its own: a test verifies the problem report or the plan decision that
   states the behavior, at the same seam.

2. **A deeper interface gets a direct test only once a plan decision or a
   problem report states its contract.** Here that item plays the role an LLR
   plays in a project with a ledger: a function in `scripts/lib.sh` gets a new
   direct test only once a decision or problem item states its contract, and
   it earns one only where at least one of these holds:

   1. **Unreachable.** A case cannot be triggered through the REQ interface
      without faking code the project owns. A retry policy whose third attempt
      only happens after two specific internal failures is an example.
   2. **Combinatorial.** Driving the internal's cases from the REQ interface
      multiplies past what is practical to enumerate. As guidance, not a rule:
      when roughly a dozen tests at the parent interface would be spent
      driving one internal's cases, that internal is a candidate.
   3. **Intrinsic.** Maths, parsing, encoding or a numerical transform whose
      algorithm has a contract worth stating independently of its caller.

   Convenience is not on the list. A case reachable from the REQ interface
   with a boundary fake is tested there, even where a deeper seam would be
   easier. Why: a direct test freezes an interface, which should be a recorded
   design decision, not a side effect of a test.

3. **Deep IO with complex error handling follows the same order.** An error
   the code handles (retried, turned into a fallback, translated for the
   user) is observable at the REQ interface: trigger it through a boundary
   fake there. Where the error handling has a contract of its own (backoff,
   partial writes, rollback) and criterion 1 or 2 holds, the adapter is
   tested at its own interface once a plan decision or problem report
   states that contract in place of an LLR, against the real resource where
   possible: a temporary directory, a real git repository created in it.
   Why: a handled error is behavior a user sees; only a contract of its own
   earns the adapter a seam.

4. **A journey test verifies the REQs it walks**: `verifies: REQ-a, REQ-b`.
   A journey is a REQ of its own only when it states an outcome none of its
   steps states: state carried across steps, recovery partway through, an
   ordering constraint. Why: a journey REQ that restates its steps verifies
   each step twice and doubles the edit when the journey changes.

## Doubles

1. **No mock of code the project owns, and no assertion on how owned code was
   called.** These are the doubles that hold an implementation in place.

2. **Fakes at the codebase boundary only.** A service, library or resource
   outside the codebase sits behind one adapter the project owns. Code calls
   the adapter, never the third-party interface directly, and the fake
   implements the adapter's interface. A fake at the HTTP layer, intercepting
   the network calls to a service outside the codebase, is a boundary fake
   too, under the same contract test; the adapter above it then runs for
   real. The clock and randomness are fakeable in the same way.
   Why: below one adapter, everything the project owns runs for real, and the
   fake has one interface to imitate.

   In this repository the boundary is the tools a script runs: awk, sed,
   date, git, gpg. Each is reached by its name on `PATH`, and a fake
   implements that command line. `make_strict_awk` in `tests/helpers.bash`
   fakes BWK awk's rejection of a literal newline in a `-v` assignment, and
   `make_bsd_date` fakes BSD date's rejection of `-d` and of a doubled sign
   in `-v`, so a GNU host fails the way macOS does.

3. **Every fake has a contract test.** The same assertions run against the
   fake and against the real dependency, wherever the real dependency is
   reachable in the test environment, and are skipped where it is not. A fake
   with no contract test drifts: it accepts what the real dependency rejects,
   and the tests built on it pass against behavior that never happens.
   `tests/portability.bats` runs each assertion on `make_strict_awk` and
   `make_bsd_date` against the real BWK awk and BSD date too, skipped where
   the tool is absent and failed where it is absent on macOS, which ships
   both.

4. **An interaction is asserted only where it is the requirement.** "The
   software shall send an alarm to the pager service": the outgoing message
   is observable output, so asserting it is a behavior test, not a mock.
   Why: there the message is the behavior, so asserting it pins nothing the
   requirement does not state.

5. **A fault injector needs no contract test.** A double that makes a
   dependency fail on demand is allowed at any boundary. The line between it
   and a fake is what the double imitates:

   - **A fake**, with a contract test: a double that imitates service-specific
     content the code interprets, such as an HTTP 409 with an error body, a
     database constraint error, or a tool error message the code parses. Here:
     a stub `parallel` whose version line `tests/run-tests.sh` reads is this
     kind, and its missing contract test is recorded as PR-dfndh4.
   - **A fault injector**, with none: a transport- or OS-level failure, such as
     a connection refused or reset, a timeout, a full disk, or an exit status
     with no output the code reads. Nothing in it belongs to one service, so
     there is nothing to drift from. Here: a `PATH` stub that exits 1 and
     prints nothing, such as `make_stub getconf 'exit 1'` in
     `tests/run-tests.bats`.

   A rule of no doubles at all was rejected: it makes the dependency-failure
   and resource-exhaustion tests of the robustness rule impossible.
   The robustness rule is that every requirement gets abnormal-input tests
   (bad input, boundary values, resource exhaustion, dependency failure)
   beside its normal-case tests.

## Owned services

1. **A service the project owns runs for real on the normal path**, and
   its failures may be injected or faked. A backend, database or sync service
   that the codebase contains, or that the application configuration declares
   part of the system, runs for real in a REQ-level test of the normal case.
   Why: a fake of it there verifies the main behavior against something the
   project never ships, and a fake drifts from what it stands in for. A
   failure case may come from:

   - fault injection on the real connection: a proxy that drops or resets
     traffic;
   - the real service put into the failing state: conflicting data seeded;
   - a fake of the service, under the same contract test as any fake, so that
     its error responses are the ones the real service gives. A double that
     returns the service's own error, such as a conflict response with its
     body, is this kind, not a fault injector.

2. **A failure test may fake the successes before its failure**, such as a
   first sync that succeeds before the second times out, where each of those
   successes is verified against the real service by a normal-case test in the
   suite. The faked successes are then setup, not evidence.

3. **The cost is test infrastructure.** The owned services must run in the
   test environment, in containers or the equivalent. How a project provides
   them is its own test-environment decision.

## Property tests

1. **Generate inputs where an invariant holds for all of them.** Where an
   interface's cases are combinatorial, or it is maths, parsing or
   encoding (criteria 2 and 3 above), prefer a property test: generated inputs,
   checked against an invariant that holds for all of them. Typical
   invariants:

   - round-trip: decoding what was encoded gives the input back;
   - idempotence: applying the operation twice equals applying it once;
   - agreement with an oracle: a slow, obviously correct version of the same
     function;
   - monotonicity or bounds.

   It is a preference, not a rule. Where no invariant is useful, write none:
   a property that restates the implementation proves nothing.
   Why: a generator reaches inputs no one thought to write.

2. **Repeatable.** Every property test runs with a fixed seed, or prints its
   seed on failure, so the failing run can be repeated.

3. **Pinned.** A counterexample a property test finds becomes an example test
   beside it, with its `verifies:` annotation, before the fix. It then stays
   covered when the generator changes.

## Mutants

1. **A surviving mutant means a missing test at the
   seam, or dead code: never a test below the seam.** Line coverage shows
   that a line ran, not that a test would notice it changing; a mutant no
   test kills is a route the tests do not check. A survivor means one of:

   - a test is missing **at the seam**: add it there;
   - the mutated code is dead: delete it.

   A survivor never justifies a test below the seam unless one of the three
   criteria above holds. Whether a project must run mutation testing, with which
   command and to what score, is decided in this section; where it names no
   command, mutation testing is not required. This section names none.

2. **A mutation a verification record cites stays runnable.** Each
   `docs/verification/*.mutations/M*.sh` quotes one line of the script it
   mutates verbatim: most as a literal `old = '''…'''` followed by
   `assert s.count(old) == 1`, the older ones as a `sed` pattern. An edit to
   the quoted line stops the mutation applying, and the record that cites it
   can no longer be reproduced. While editing a script, run one grep per
   changed line from the repository root:

   ```sh
   grep -rn 'the exact line you changed' docs/verification/*.mutations/
   ```

   On a hit:

   - keep the edit: the anchor follows the script, the anchors of earlier
     changes included;
   - re-cut the anchor to the new text of the line, with the replacement text
     the same mutation applied to the new line;
   - prove the re-cut anchor applies: `tests/mutate.sh <the .mutations dir>`
     reports it as applied;
   - prove it still kills tests: apply it in a scratch copy of the tree, run
     the tests the record lists against it, and see at least one fail. An
     anchor that applies and kills nothing means the tests never covered that
     mutation: report it as a finding, not a green result;
   - commit the re-cut scripts with the change that edited the line.

   Why: `tests/mutations.bats` reports a mutation that no longer applies, but
   only when the full suite runs, after the edit is complete; the grep finds
   the hit while the edit is in progress. Nothing checks that a re-cut anchor
   still kills tests.

## Existing suites

1. **These rules bind the tests a change writes or edits.** They spare the
   existing suite: a change that must edit an existing test that breaks them
   moves it to the seam instead of repairing it in place: such a test usually
   broke because a refactor moved the internal it was pinned to. A test that
   breaks the rules and still passes is left alone, since deleting it without a
   replacement at the seam loses coverage. No change rewrites a suite wholesale
   for compliance.
